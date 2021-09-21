import 'package:flutter/material.dart';
import '../model/board.dart';
import 'board_editor_viewmodel.dart';

import '_core.dart';

class DividerComponent extends StatelessWidget {
  const DividerComponent({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      height: 32,
      child: const Divider(height: 32.0, thickness: 1.0, color: Color(0xfff2f2f2)),
    );
  }
}

final insertDividerCommand = EditorCommand.exec((BoardEditorViewModel editor) {
  editor.insertBlock(DividerBlock());
});
