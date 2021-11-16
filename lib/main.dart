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
        create: (context) => BoardEditorViewModel(),
        builder: (context, child) => Scaffold(
          appBar: AppBar(),
          body:
              Consumer<BoardEditorViewModel>(builder: (context, editor, child) {
            return Column(
              children: [
                TextFormField(
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
        final node = viewModel.node;

        return TextField(
          // Focus node and controller seem required?
          focusNode: node.focus,
          controller: node.controller,
        );
      },
    );
  }
}

class BoardEditorViewModel with ChangeNotifier {
  EditorNode node = EditorNode();

  void setName(String value) {
    notifyListeners();
  }
}

class EditorNode {
  // MARKER SEEMS REQUIRED?
  static const kMarker = '\u0000';

  final focus = FocusNode();

  late final controller = TextEditingController(text: kMarker);
}
