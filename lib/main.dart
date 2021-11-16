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
              children: [TextFormField(), const NodeItem()],
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
      builder: (context, model, child) {
        return TextField(
          // Focus node and controller seem required?
          focusNode: model.focus,
          controller: model.controller,
        );
      },
    );
  }
}

class BoardEditorViewModel with ChangeNotifier {
  // MARKER SEEMS REQUIRED?
  static const kMarker = '\u0000';

  final focus = FocusNode();

  late final controller = TextEditingController(text: kMarker);
}
