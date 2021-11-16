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
                const NodeItem()
              ],
            );
          }),
        ),
      ),
    );
  }
}

class NodeItem extends StatelessWidget {
  const NodeItem({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<BoardEditorViewModel>(
      builder: (context, viewModel, child) {
        final node = viewModel.getEditorNode();

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
  DateTime _updated;
  bool _dirty;
  BoardBlock? block;

  BoardDetails({
    required this.id,
    String? name = '',
    DateTime? updated,
    bool? dirty,
  })  : _name = name,
        _updated = updated ?? DateTime.now(),
        _dirty = dirty ?? false;

  String? get name => _name;
  set name(String? value) {
    if (_name != value) {
      _name = value;
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

  void insertText(BoardBlock element) {
    block = element;
    dirty = true;
  }
}

class BoardBlock {
  int id = 0;
  String text = '';
  final String uid = '0';
}

class BoardEditorViewModel with ChangeNotifier {
  BoardEditorViewModel();

  final BoardDetails details = BoardDetails(id: 1);
  EditorNode? _editorNode;

  void setName(String value) {
    if (details.name != value) {
      details.name = value;
      notifyListeners();
    }
  }

  void appendText() {
    insert(BoardBlock());
  }

  EditorNode insert(BoardBlock element) {
    details.insertText(element);
    final node = getEditorNode();
    node.focus.requestFocus();
    notifyListeners();
    return node;
  }

  EditorNode getEditorNode() {
    _editorNode ??= EditorNode(
      block: details.block!,
      onTextChanged: onTextChanged,
    );
    return _editorNode!;
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
