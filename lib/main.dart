import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  runApp(MaterialApp(
    home: ChangeNotifierProvider(
      create: (context) => BoardEditorViewModel(),
      builder: (context, child) => Scaffold(
        appBar: AppBar(),
        body: Consumer<BoardEditorViewModel>(builder: (context, editor, child) {
          return Column(
            children: [TextFormField(), const NodeItem()],
          );
        }),
      ),
    ),
  ));
}

class NodeItem extends StatelessWidget {
  const NodeItem({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<BoardEditorViewModel>(
      builder: (context, node, child) {
        return TextField(
          controller: node.controller,
        );
      },
    );
  }
}

class BoardEditorViewModel with ChangeNotifier {
  // MARKER SEEMS REQUIRED?
  static const kMarker = '\u0000';

  late final controller = TextEditingController(text: kMarker);
}
