import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:keyboard_crash/src/editor/board_service.dart';
import 'package:keyboard_crash/src/util/view_model_mixin.dart';
import 'package:logging/logging.dart';
import '../model/board.dart';
import '_core.dart';
import '_divider.dart';
import '_text.dart';
import 'utils.dart';

enum BusyKey { publish, saved, load, refresh, update, share, delete }

/// [BoardEditorViewModel] holds the state and business logic for the [BoardDocumentEditor] widget.
///
/// It is the responsibility of the [BoardEditorViewModel] to provide the [MutableBoard] instance to edit
/// and to manage the editing, creating, reordering, and deleting of nodes within the board.
///
/// The [BoardEditorViewModel] also tracks the currently active/selected item within the board details
/// node list. This is used to manage the insertion point of nodes, and to allow us to react to a
/// node becoming active/inactivated.
class BoardEditorViewModel with ChangeNotifier, ViewModelMixin {
  BoardEditorViewModel(
    BoardDetails board, [
    BoardService? boards,
  ])  : _board = board,
        _boards = boards ?? BoardService();

  static final _log = Logger('BoardEditorViewModel');
  static const kAllowJoiningLines = true;
  static const kLineMarker = kAllowJoiningLines ? nullUnicode : '';
  static const kLineStartOffset = kLineMarker.length;

  /// [BoardService] instance for interacting with the API and the local board cache.
  final BoardService _boards;

  /// The current [BoardDetails] being edited.
  final BoardDetails _board;

  /// The parent scroll controller to use for scrollable widgets within the board editor view.
  final scrollController = ScrollController();

  /// The period of time between sending save requests to the API.
  final _throttleDuration = const Duration(seconds: 30);

  final _editorNodes = <String, EditorNode>{};
  EditorNode? _selection;
  Timer? _timer;
  final _keyboard = KeyboardVisibilityController();
  bool _showButtonBar = false;

  EditorNode? get selection => _selection;
  List<EditorNode> get nodes => _editorNodes.values.toList();

  bool get isKeyboardVisible => _keyboard.isVisible;
  bool get isButtonBarVisible => (isKeyboardVisible || true) && _showButtonBar;

  BoardDetails get details => _board;
  bool get isSaved => true;
  bool get isEmpty => _board.isEmpty;
  bool get isNotEmpty => !isEmpty;
  int get length => _board.length;
  bool get isMine => true;
  bool get isPublished => _board.published;
  bool get readOnly => !isMine;

  bool get isBusySaving => busy(BusyKey.saved);
  bool get isBusyPublishing => busy(BusyKey.publish);
  bool get isBusyLoading => busy(BusyKey.load);
  bool get isBusyRefreshing => busy(BusyKey.refresh);
  bool get isBusyUpdating => busy(BusyKey.update);
  bool get isBusySharing => busy(BusyKey.share);
  bool get isBusyDeleting => busy(BusyKey.delete);

  set showButtonBar(bool value) {
    if (_showButtonBar != value) {
      _showButtonBar = value;
      notifyListeners();
    }
  }

  bool get hasTextSelection {
    return _selection?.type == BlockType.text;
  }

  bool get dirty => _board.dirty;

  void markNeedsSave({bool notify = true}) {
    if (!dirty) {
      _board.dirty = true;
      _timer ??= Timer(_throttleDuration, saveBoard);

      if (notify) {
        notifyListeners();
      }
    }
  }

  void markSaveComplete() {
    _board.dirty = false;
    _timer?.cancel();
    _timer = null;
  }

  void onButtonPressed(BuildContext context, BoardButton button) {
    var block = _selection?.block;
    switch (button) {
      case BoardButton.h1:
      case BoardButton.h2:
      case BoardButton.h3:
      case BoardButton.body:
        executeCommand(TextButtonPressedCommand(button,
            value: (block as TextBlock?)?.text));
        break;
      case BoardButton.divider:
        executeCommand(insertDividerCommand);
        break;
      case BoardButton.place:
        // TODO: Handle this case.
        break;
      case BoardButton.list:
        // TODO: Handle this case.
        break;
      case BoardButton.photo:
        // TODO: Handle this case.
        break;
      case BoardButton.link:
        // TODO: Handle this case.
        break;
    }
  }

  @override
  void dispose() {
    saveBoard();
    for (final node in _editorNodes.values) {
      node.dispose();
    }
    _editorNodes.clear();
    super.dispose();
  }

  void markPlaceUpdated() {
    notifyListeners();
  }

  void setName(String value) {
    if (_board.name != value) {
      _board.name = value;
      markNeedsSave();
    }
  }

  void setDescription(String value) {
    if (_board.description != value) {
      _board.description = value;
      markNeedsSave();
    }
  }

  int indexOfNode(EditorNode node) {
    return indexOfUid(node.uid);
  }

  int indexOfUid(String uid) {
    return _board.blocks.indexOf(uid);
  }

  void executeCommand(EditorCommand command) {
    command.execute(this);
    notifyListeners();
  }

  void moveBlock(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) {
      return;
    }

    _board.moveBlock(oldIndex, newIndex);
    markNeedsSave();
  }

  void removeAt(int index, {bool notify = true}) {
    _log.info('Removing board node @[$index]');
    final block = _board.removeAt(index);
    final node = _editorNodes.remove(block.uid);
    node?.dispose();
    markNeedsSave();
  }

  EditorNode insert(int index, BoardBlock element, {bool focused = false}) {
    _board.insert(index, element);
    final node = getEditorNode(element.uid);
    if (focused) {
      node.focus.requestFocus();
      _selection = node;
      showButtonBar = true;
    }
    markNeedsSave();
    return node;
  }

  EditorNode add(BoardBlock element, {bool focused = false}) {
    return insert(length, element, focused: focused);
  }

  void insertBlock(BoardBlock block) {
    final selection = _selection;
    _log.fine(
        'Inserting node into board: [selection=$selection, block=$block]');

    if (selection == null) {
      _log.fine('Appending new block to the end of the board');
      add(block, focused: true);
      markNeedsSave();
      return;
    }

    final current = selection.block;
    int index = indexOfNode(selection);
    if (index > _board.length) {
      _log.warning(
          'Board has too many elements: $index', null, StackTrace.current);
      index = index.clamp(0, _board.length);
    }

    if (current is TextBlock && current.text.isEmpty) {
      _log.fine('Inserting new block before empty text block');
      insert(index, block);
      markNeedsSave();
      return;
    }

    _log.fine('Adding new block after current block: $block');

    insert(++index, block);
    insert(++index, TextBlock(), focused: true);
    markNeedsSave();
  }

  EditorNode? insertBlocks(List<BoardBlock> blocks) {
    final selection = _selection;
    _log.fine(
        'Inserting multiple nodes into board: [selection=$selection, block=$blocks]');

    EditorNode? last;

    if (selection == null) {
      _log.fine('Appending new block to the end of the board');
      for (final block in blocks) {
        last = add(block, focused: true);
      }
      markNeedsSave();
      return last;
    }

    final current = selection.block;
    int index = indexOfNode(selection);
    if (index > _board.length) {
      _log.warning(
          'Board has too many elements: $index', null, StackTrace.current);
      index = index.clamp(0, _board.length);
    }

    bool replace = (current is TextBlock && current.text.isEmpty);

    if (!replace) {
      ++index;
    }

    for (final block in blocks) {
      last = insert(index++, block);
      _log.fine('Adding new block after current block: $block');
    }

    if (!replace) {
      last = insert(index, TextBlock(), focused: true);
    }

    markNeedsSave();
    return last;
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
    showButtonBar = true;
  }

  void clearSelection() {
    if (_selection != null) {
      _selection!.focus.unfocus();
      _selection = null;
      notifyListeners();
    }
  }

  bool isTextButton(BoardButton? button) {
    switch (button) {
      case BoardButton.h1:
      case BoardButton.h2:
      case BoardButton.h3:
      case BoardButton.body:
        return true;
      default:
        return false;
    }
  }

  Future<void> saveBoard() async {
    _log.fine('Checking if board needs saving: $dirty');
    if (!dirty) {
      return;
    }

    _timer?.cancel();
    _timer = null;

    _log.fine('Checking board for missing block data');
    final missing = _board.blocks.whereNot(_board.data.containsKey).toList();
    if (missing.isNotEmpty) {
      _log.fine('Removing missing blocks: $missing');
      _board.blocks.retainWhere(_board.data.containsKey);
    }

    _log.fine('Saving board details');
    final update =
        await runBusyFuture(_boards.updateBlocks(_board), key: BusyKey.update);

    for (final block in _board.blocks) {
      final newNode = update.data[block];
      final oldNode = _board.data[block];
      if (newNode != null && oldNode != null && newNode.id != oldNode.id) {
        oldNode.id = newNode.id;
      }
    }

    markSaveComplete();
  }

  EditorNode getEditorNode(String uid) {
    return _editorNodes[uid] ??= EditorNode(
      block: _board.data[uid]!,
      onSelected: selectEditorNode,
      onTextChanged: onTextChanged,
      marker: kLineMarker,
    );
  }

  void onTextChanged(EditorNode node) {
    final editor = node.controller;
    final block = node.block as TextBlock;

    if (!editor.text.startsWith(kLineMarker)) {
      return onLineDeleted(node);
    }

    if (editor.text.substring(kLineStartOffset) == block.text ||
        editor.text == block.text) {
      return onSelectionChanged(node);
    }

    var value = editor.text.substring(kLineStartOffset);
    var text = block.text;
    if (value == text) {
      return;
    }

    final lines = editor.text.split('\n');
    block.text = lines.first;

    if (lines.length == 1) {
      markNeedsSave(notify: false);
      return;
    }

    // _log.info('Multiple lines detected. Splitting additional lines to new text fields');
    editor.value = TextEditingValue(
      text: lines.first,
      selection: TextSelection.collapsed(offset: lines.first.length),
    );

    var index = indexOfNode(node);
    for (int i = 1; i < lines.length - 1; i++) {
      final line = lines[i];
      // _log.info('[${node.uid}]: adding text node: $line');
      _board.insert(index + i, TextBlock(text: line));
    }

    final last = insert(index + lines.length - 1, TextBlock(text: lines.last),
        focused: true);
    if (lines.last.trim().isNotEmpty) {
      last.controller.selection =
          const TextSelection.collapsed(offset: kLineStartOffset);
    }
  }

  void onLineDeleted(EditorNode node) {
    final editor = node.controller;
    var index = indexOfNode(node);

    for (int i = index - 1; i >= 0; --i) {
      final block = _board[i];
      if (block is! TextBlock) {
        continue;
      }

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
    // _log.fine('[${node.uid}]: Ignoring join from first text block (nothing to join to)');
  }

  void onSelectionChanged(EditorNode node) {
    final controller = node.controller;
    if (controller.selection.base.offset == 0) {
      final extentOffset = controller.selection.extentOffset;
      final selection = controller.selection.copyWith(
        baseOffset: kLineStartOffset,
        extentOffset: max(kLineStartOffset, extentOffset),
      );
      final text = controller.text;
      final composing = controller.value.composing;
      _log.finest('Moving cursor to in front of marker character:');
      _log.finest(
          '    TextEditingController(text: \u2524$text\u251C, composing: $composing)');
      _log.finest('    Selection: ${controller.selection} -> $selection');
      controller.value =
          TextEditingValue(text: controller.text, selection: selection);
    }
  }
}

/// An [EditorNode] is a single node in the board that is able to manage its focus and editing state.
///
/// Most [EditorNode]s are fairly inert, except [TextBlock] editor nodes, which manage text editing
/// and other tasks such as merging and splitting text editor blocks.
class EditorNode {
  EditorNode({
    required this.block,
    this.onSelected,
    this.onTextChanged,
    this.marker = nullUnicode,
  }) {
    final block = this.block;
    _log.finest('Created new editor node: $uid [${block.runtimeType}]');
    if (block is TextBlock) {
      controller.text = '$marker${block.text}';
      controller.addListener(_onTextChanged);
      focus.addListener(_onFocusChanged);
    }
  }

  static final _log = Logger('EditorNode');

  final BoardBlock block;
  final String marker;

  final ValueChanged<EditorNode>? onSelected;
  final ValueChanged<EditorNode>? onTextChanged;

  final key = GlobalKey();
  final focus = FocusNode();
  late final controller = TextEditingController();

  String get uid => block.uid;
  BlockType get type => block.type;
  BoardButton get button => block.boardButton;

  void dispose() {
    controller.removeListener(_onTextChanged);
    focus.removeListener(_onFocusChanged);
  }

  void _onTextChanged() {
    onTextChanged?.call(this);
  }

  void _onFocusChanged() {
    // _log.finest('Editor node focus changed: [uid=$uid, $focus]');
    if (focus.hasFocus) {
      onSelected?.call(this);
    }
  }

  EditorNode copyWith({
    int? index,
    BoardBlock? block,
  }) {
    return EditorNode(
      block: block ?? this.block,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditorNode &&
          runtimeType == other.runtimeType &&
          block == other.block &&
          focus == other.focus &&
          controller == other.controller;

  @override
  int get hashCode => block.hashCode ^ focus.hashCode ^ controller.hashCode;

  @override
  String toString() {
    return 'EditorSelection{block: ${block.uid}, type: ${block.runtimeType}, focus: $focus, text: ┤${controller.text}├}';
  }
}
