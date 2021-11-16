import 'package:flutter/material.dart';

// https://github.com/flutter/flutter/issues/90238
// Reproduction instructions
// Launch in iOS simulator
// Click on the top FormField, type "www😄😄😄", will require clicking on
// soft keyboard for ascii, switching to emoji, then clicking there.
// Click on the second field, type "www😄" and iOS keyboard will hang!

void main() async {
  runApp(MaterialApp(
    home: Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [TextFormField(), const NodeItem()],
      ),
    ),
  ));
}

class NodeItem extends StatefulWidget {
  const NodeItem({
    Key? key,
  }) : super(key: key);

  @override
  State<NodeItem> createState() => _NodeItemState();
}

class _NodeItemState extends State<NodeItem> {
  // This text seems to be required, unclear why:
  late final controller = TextEditingController(text: '\u0000');

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      // Originally Provider was causing the rebuilds, but this seem to
      // work too:
      onChanged: (_) => setState(() {}),
    );
  }
}
