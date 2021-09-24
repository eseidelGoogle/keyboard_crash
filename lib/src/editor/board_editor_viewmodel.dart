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

  final BoardDetails details;

  final _editorNodes = <String, EditorNode>{};
  List<EditorNode> get nodes => _editorNodes.values.toList();

  bool get isEmpty => details.isEmpty;
  bool get isNotEmpty => !isEmpty;
  int get length => details.length;

  @override
  void dispose() {
    _log.fine('Disposing view model');
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
      notifyListeners();
    }
  }

  void setDescription(String value) {
    if (details.description != value) {
      _log.fine('Updating description: $value');
      details.description = value;
      notifyListeners();
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
    notifyListeners();
  }

  void removeAt(int index, {bool notify = true}) {
    _log.info('Removing board node @[$index]');
    final block = details.removeAt(index);
    final node = _editorNodes.remove(block.uid);
    node?.dispose();
    notifyListeners();
  }

  EditorNode insert(int index, BoardBlock element, {bool focused = false}) {
    details.insertText(index, element);
    final node = getEditorNode(element.uid);
    if (focused) {
      node.focus.requestFocus();
    }
    notifyListeners();
    return node;
  }
  //
  // /// Selects a new node in the board.
  // void select(String? value) {
  //   if (value != null) {
  //     getEditorNode(value).focus.requestFocus();
  //   } else {
  //     FocusManager.instance.primaryFocus?.unfocus();
  //   }
  // }

  EditorNode getEditorNode(String uid) {
    return _editorNodes[uid] ??= EditorNode(
      block: details.data[uid]!,
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
      getEditorNode(prev.uid).focus.requestFocus();
      joined.value = TextEditingValue(
        text: joined.text + editor.text,
        selection: TextSelection.collapsed(offset: joined.text.length),
      );
      notifyListeners();
      return;
    }
  }
}

class EditorNode {
  EditorNode({
    required this.block,
    required this.onTextChanged,
  }) : text = '$kMarker${block.text}' {
    _log.finest('Created new text editor node: $uid');
    controller.addListener(_onEditorChanged);
  }

  static const kMarker = '\u0000';

  final BoardBlock block;

  final key = GlobalKey();
  final focus = FocusNode();

  String get uid => block.uid;

  static final _log = Logger('EditorNode');

  late final controller = TextEditingController(text: '$kMarker${block.text}');
  String text;

  final ValueChanged<EditorNode> onTextChanged;

  void dispose() {
    controller.removeListener(_onEditorChanged);
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
