import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  runApp(const MyApp());
}

/// The Widget that configures your application.
class MyApp extends StatelessWidget {
  const MyApp({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ChangeNotifierProvider(
        create: (context) => BoardEditorViewModel()..appendText(),
        builder: (context, child) => Scaffold(
          appBar: AppBar(),
          body:
              Consumer<BoardEditorViewModel>(builder: (context, editor, child) {
            return Column(
              children: [
                TextFormField(
                  initialValue: '',
                  onChanged: editor.setName,
                ),
                const NodeItem(
                  0,
                )
              ],
            );
          }),
        ),
      ),
    );
  }
}

class NodeItem extends StatelessWidget {
  const NodeItem(
    this.index, {
    Key? key,
  }) : super(key: key);

  final int index;

  @override
  Widget build(BuildContext context) {
    return Consumer<BoardEditorViewModel>(
      builder: (context, viewModel, child) {
        final block = viewModel.details[index];
        final node = viewModel.getEditorNode(block.uid);

        return ReorderableShortDelayDragStartListener(
          key: ValueKey('reorder-block-item-${block.uid}'),
          index: index,
          child: TextField(
            autofocus: node.focus.hasPrimaryFocus,
            focusNode: node.focus,
            textInputAction: TextInputAction.newline,
            textCapitalization: TextCapitalization.sentences,
            maxLines: null,
            controller: node.controller,
            onChanged: node.onChanged,
          ),
        );
      },
    );
  }
}

/// A [ReorderableShortDelayDragStartListener] that has a delay slightly less
/// than a long press so that we can support dragging a [TextField].
class ReorderableShortDelayDragStartListener
    extends ReorderableDelayedDragStartListener {
  const ReorderableShortDelayDragStartListener({
    Key? key,
    required int index,
    required Widget child,
    bool enabled = true,
  }) : super(key: key, index: index, child: child, enabled: enabled);

  @override
  MultiDragGestureRecognizer createRecognizer() {
    return DelayedMultiDragGestureRecognizer(
      debugOwner: this,
      delay: kLongPressTimeout - const Duration(milliseconds: 50),
    );
  }
}

class BoardDetails with ChangeNotifier {
  final int id;
  String? _name;
  String _description;
  final List<String> blocks;
  final Map<String, BoardBlock> data;
  DateTime _updated;
  bool _dirty;

  BoardDetails({
    required this.id,
    String? name = '',
    String description = '',
    List<String> blocks = const [],
    Map<String, BoardBlock>? data,
    DateTime? updated,
    bool? dirty,
  })  : _name = name,
        _description = description,
        _updated = updated ?? DateTime.now(),
        _dirty = dirty ?? false,
        data = data ?? {},
        blocks =
            blocks.where((key) => data?.containsKey(key) ?? false).toList();

  bool get isEmpty => blocks.isEmpty;

  List<BoardBlock> toBlocks() {
    final blocks = this.blocks.where(data.containsKey).toList();
    return List.generate(
        blocks.length, (index) => data[blocks[index]] as BoardBlock);
  }

  String? get name => _name;
  set name(String? value) {
    if (_name != value) {
      _name = value;
      dirty = true;
    }
  }

  String get description => _description;
  set description(String value) {
    if (_description != value) {
      _description = value;
      dirty = true;
    }
  }

  DateTime get updated => _updated;
  set updated(DateTime value) {
    if (_updated != value) {
      _updated = value;
      dirty = true;
    }
  }

  bool get dirty => _dirty;
  set dirty(bool value) {
    _dirty = value;
    notifyListeners();
  }

  BoardBlock removeAt(int index) {
    final uid = blocks.removeAt(index);
    try {
      return data.remove(uid)!;
    } finally {
      dirty = true;
    }
  }

  void insertText(int index, BoardBlock element) {
    blocks.insert(index, element.uid);
    data[element.uid] = element;
    dirty = true;
  }

  void moveBlock(int oldIndex, int newIndex) {}

  int get length => blocks.where(data.containsKey).length;

  void add(BoardBlock element) {
    blocks.add(element.uid);
    data[element.uid] = element;
    dirty = true;
  }

  BoardBlock operator [](int index) {
    final key = blocks[index];

    if (!data.containsKey(key)) {
      throw FlutterError('Asked for missing block at [$index]: $key');
    }
    return data[key]!;
  }

  void operator []=(int index, BoardBlock value) {
    blocks[index] = value.uid;
    data[value.uid] = value;
    dirty = true;
  }
}

String uuid() => Random().nextDouble().toString();

class BoardBlock {
  BoardBlock({
    this.id = 0,
    String? uid,
    this.text = '',
  }) : uid = uid ?? uuid();

  int id;
  String text;
  final String uid;
}

class BoardEditorViewModel with ChangeNotifier {
  BoardEditorViewModel();

  final BoardDetails details = BoardDetails(id: 1);
  final _editorNodes = <String, EditorNode>{};

  bool get isEmpty => details.isEmpty;
  int get length => details.length;

  @override
  void dispose() {
    for (final node in _editorNodes.values) {
      node.dispose();
    }
    _editorNodes.clear();
    super.dispose();
  }

  void setName(String value) {
    if (details.name != value) {
      details.name = value;
      notifyListeners();
    }
  }

  int indexOfNode(EditorNode node) {
    return details.blocks.indexOf(node.uid);
  }

  void appendText() {
    insert(length, BoardBlock(), focused: true);
  }

  void moveBlock(int oldIndex, int newIndex) {}

  void removeAt(int index, {bool notify = true}) {
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

    node.text = lines.first;
    node.controller.value = TextEditingValue(
      text: lines.first,
      selection: TextSelection.collapsed(offset: lines.first.length),
    );

    var index = indexOfNode(node);
    for (int i = 1; i < lines.length - 1; i++) {
      final line = lines[i];
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
    controller.addListener(_onEditorChanged);
  }

  static const kMarker = '\u0000';

  final BoardBlock block;

  final key = GlobalKey();
  final focus = FocusNode();

  String get uid => block.uid;

  late final controller = TextEditingController(text: '$kMarker${block.text}');
  String text;

  final ValueChanged<EditorNode> onTextChanged;

  void dispose() {
    controller.removeListener(_onEditorChanged);
  }

  void onChanged(String value) {
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
      controller.selection = selection;
    }
  }
}
