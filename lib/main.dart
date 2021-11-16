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
          // Focus node and controller seem required?
          focusNode: node.focus,
          controller: node.controller,
          onChanged: node.onChanged,
        );
      },
    );
  }
}

class BoardDetails with ChangeNotifier {
  BoardBlock? block;

  // Probably not needed.
  set name(String? value) {
    notifyListeners();
  }

  void insertText(BoardBlock element) {
    block = element;
    notifyListeners();
  }
}

class BoardBlock {
  String text = '';
}

class BoardEditorViewModel with ChangeNotifier {
  BoardEditorViewModel();

  final BoardDetails details = BoardDetails();
  EditorNode? _editorNode;

  void setName(String value) {
    notifyListeners();
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
    _editorNode ??= EditorNode();
    return _editorNode!;
  }
}

class EditorNode {
  EditorNode() : text = kMarker;

  // MARKER SEEMS REQUIRED?
  static const kMarker = '\u0000';

  final focus = FocusNode();

  late final controller = TextEditingController(text: text);
  String text;

  void onChanged(String value) {
    text = value;
  }
}
