import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:keyboard_crash/src/editor/model.dart';
import 'package:logging/logging.dart';

class BoardEditorViewModel with ChangeNotifier {
  BoardEditorViewModel(this.details);

  static final _log = Logger('BoardEditorViewModel');

  /// The parent scroll controller to use for scrollable widgets within the board editor view.
  final scrollController = ScrollController();

  final BoardDetails details;

  /// The period of time between sending save requests to the API.
  final _throttleDuration = const Duration(seconds: 30);

  final _editorNodes = <String, EditorNode>{};
  EditorNode? _selection;
  Timer? _timer;

  EditorNode? get selection => _selection;
  List<EditorNode> get nodes => _editorNodes.values.toList();

  bool get isEmpty => details.isEmpty;
  bool get isNotEmpty => !isEmpty;
  int get length => details.length;

  bool get hasTextSelection => _selection != null;

  bool get dirty => details.dirty;

  void markNeedsSave({bool notify = true}) {
    if (!dirty || _timer == null) {
      _log.fine('Marking board state dirty');
      details.dirty = true;
      _timer ??= Timer(_throttleDuration, saveBoard);

      if (notify) {
        notifyListeners();
      }
    } else {
      _log.fine('Board state already marked dirty');
    }
  }

  void markSaveComplete() {
    _log.fine('Marking board as saved');
    details.dirty = false;
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _log.fine('Disposing view model');
    saveBoard();
    for (final node in _editorNodes.values) {
      node.dispose();
    }
    _editorNodes.clear();
    super.dispose();
  }

  void setName(String value) {
    if (details.name != value) {
      _log.fine('Updating title: $value');
      details.name = value;
      markNeedsSave();
    }
  }

  void setDescription(String value) {
    if (details.description != value) {
      _log.fine('Updating description: $value');
      details.description = value;
      markNeedsSave();
    }
  }

  int indexOfNode(EditorNode node) {
    return details.blocks.indexOf(node.uid);
  }

  void appendText() {
    insert(length, BoardBlock(), focused: true);
  }

  void moveBlock(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) {
      return;
    }

    details.moveBlock(oldIndex, newIndex);
    markNeedsSave(notify: false);
    notifyListeners();
  }

  void removeAt(int index, {bool notify = true}) {
    _log.info('Removing board node @[$index]');
    final block = details.removeAt(index);
    final node = _editorNodes.remove(block.uid);
    node?.dispose();
    markNeedsSave(notify: false);
    notifyListeners();
  }

  EditorNode insert(int index, BoardBlock element, {bool focused = false}) {
    details.insertText(index, element);
    final node = getEditorNode(element.uid);
    if (focused) {
      node.focus.requestFocus();
      _selection = node;
    }
    markNeedsSave(notify: false);
    notifyListeners();
    return node;
  }

  /// Selects a new node in the board.
  void select(String? value) {
    if (value == null) {
      // _log.fine('Clearing current selection: ($_selection -> null)');
      clearSelection();
    } else {
      selectEditorNode(getEditorNode(value));
    }
  }

  void selectEditorNode(EditorNode selection) {
    if (selection != _selection) {
      _selection = selection;
      notifyListeners();
    }
    selection.focus.requestFocus();
  }

  void clearSelection() {
    if (_selection != null) {
      _selection!.focus.unfocus();
      _selection = null;
      notifyListeners();
    }
  }

  Future<void> saveBoard() async {
    _log.fine('Checking if board needs saving: $dirty');
    if (!dirty) {
      return;
    }

    _timer?.cancel();
    _timer = null;

    _log.fine('Simulating save');
    final update = await Future.delayed(
      const Duration(seconds: 1),
      () => details..updated = DateTime.now(),
    );

    for (final block in details.blocks) {
      final newNode = update.data[block];
      final oldNode = details.data[block];
      if (newNode != null && oldNode != null && newNode.id == null) {
        oldNode.id = Random.secure().nextInt(1000);
      }
    }

    markSaveComplete();
  }

  EditorNode getEditorNode(String uid) {
    return _editorNodes[uid] ??= EditorNode(
      block: details.data[uid]!,
      onSelected: selectEditorNode,
      onTextChanged: onTextChanged,
    );
  }

  void onTextChanged(EditorNode node) {
    final block = node.block;
    final text = node.text;

    if (!text.startsWith(EditorNode.kMarker)) {
      return onLineDeleted(node);
    }

    var value = text.substring(EditorNode.kMarker.length);
    if (value == block.text) {
      return;
    }

    final lines = text.split('\n');
    block.text = lines.first;

    if (lines.length == 1) {
      markNeedsSave(notify: false);
      return;
    }

    // _log.info('Multiple lines detected. Splitting additional lines to new text fields');
    node.text = lines.first;
    node.controller.value = TextEditingValue(
      text: lines.first,
      selection: TextSelection.collapsed(offset: lines.first.length),
    );

    var index = indexOfNode(node);
    for (int i = 1; i < lines.length - 1; i++) {
      final line = lines[i];
      _log.finest('[${node.uid}]: adding text node: $line');
      details[index + i] = BoardBlock(text: line);
    }

    final last = insert(
      index + lines.length - 1,
      BoardBlock(text: lines.last),
      focused: true,
    );
    if (lines.last.trim().isNotEmpty) {
      last.controller.selection = const TextSelection.collapsed(
        offset: EditorNode.kMarker.length,
      );
    }
  }

  void onLineDeleted(EditorNode node) {
    final editor = node.controller;
    var index = indexOfNode(node);

    for (int i = index - 1; i >= 0; --i) {
      final block = details[i];

      final prev = getEditorNode(block.uid);
      final joined = prev.controller;

      removeAt(index, notify: false);
      select(prev.uid);
      joined.value = TextEditingValue(
        text: joined.text + editor.text,
        selection: TextSelection.collapsed(offset: joined.text.length),
      );
      markNeedsSave();
      return;
    }
  }
}

class EditorNode {
  EditorNode({
    required this.block,
    required this.onSelected,
    required this.onTextChanged,
  }) : text = '$kMarker${block.text}' {
    _log.finest('Created new text editor node: $uid');
    controller.addListener(_onEditorChanged);
    focus.addListener(_onFocusChanged);
  }

  static const kMarker = '\u0000';

  final BoardBlock block;

  final key = GlobalKey();
  final focus = FocusNode();

  String get uid => block.uid;

  static final _log = Logger('EditorNode');

  late final controller = TextEditingController(text: '$kMarker${block.text}');
  String text;

  final ValueChanged<EditorNode> onSelected;
  final ValueChanged<EditorNode> onTextChanged;

  void dispose() {
    controller.removeListener(_onEditorChanged);
    focus.removeListener(_onFocusChanged);
  }

  void onChanged(String value) {
    _log.info('EditorNode.onChanged($value)');
    if (text != value) {
      text = value;
      onTextChanged(this);
    }
  }

  void _onEditorChanged() {
    if (controller.selection.base.offset == 0) {
      final extentOffset = controller.selection.extentOffset;
      final selection = controller.selection.copyWith(
        baseOffset: kMarker.length.clamp(0, controller.text.length),
        extentOffset:
            max(kMarker.length, extentOffset).clamp(0, controller.text.length),
      );
      _log.finest('Moving cursor to in front of marker character:');
      _log.finest(
          '    TextEditingController(text: \u2524$text\u251C [${text.length}]');
      _log.finest('    Selection: ${controller.selection} -> $selection');
      controller.selection = selection;
    }
  }

  void _onFocusChanged() {
    if (focus.hasFocus) {
      onSelected(this);
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditorNode &&
          runtimeType == other.runtimeType &&
          block == other.block &&
          focus == other.focus &&
          text == text;

  @override
  int get hashCode => block.hashCode ^ focus.hashCode ^ text.hashCode;
}
