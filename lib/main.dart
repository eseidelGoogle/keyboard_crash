import 'dart:math';
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

        return TextField(
          autofocus: node.focus.hasPrimaryFocus,
          focusNode: node.focus,
          controller: node.controller,
          onChanged: node.onChanged,
        );
      },
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

    var value = text.substring(EditorNode.kMarker.length);
    if (value == block.text) {
      return;
    }

    final lines = text.split('\n');
    block.text = lines.first;
  }
}

class EditorNode {
  EditorNode({
    required this.block,
    required this.onTextChanged,
  }) : text = '$kMarker${block.text}';

  // MARKER SEEMS REQUIRED?
  static const kMarker = '\u0000';

  final BoardBlock block;

  final focus = FocusNode();

  String get uid => block.uid;

  late final controller = TextEditingController(text: '$kMarker${block.text}');
  String text;

  final ValueChanged<EditorNode> onTextChanged;

  void onChanged(String value) {
    if (text != value) {
      text = value;
      onTextChanged(this);
    }
  }
}
