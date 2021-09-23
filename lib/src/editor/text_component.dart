import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keyboard_crash/src/editor/model.dart';
import 'package:provider/provider.dart';

import 'board_editor_viewmodel.dart';

class TextComponent extends StatelessWidget {
  const TextComponent(
    this.block, {
    Key? key,
  }) : super(key: key);

  final BoardBlock block;
  String get uid => block.uid;

  @override
  Widget build(BuildContext context) {
    return Consumer<BoardEditorViewModel>(
      builder: (context, viewModel, child) {
        var node = viewModel.getEditorNode(uid);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 0),
          child: TextField(
            autofocus: node.focus.hasPrimaryFocus,
            onTap: () {
              viewModel.select(uid);
            },
            scrollPadding: const EdgeInsets.all(64.0),
            focusNode: node.focus,
            textInputAction: TextInputAction.newline,
            textCapitalization: TextCapitalization.sentences,
            maxLines: null,
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: Color(0xff898989),
              fontWeight: FontWeight.w400,
              fontSize: 14,
              height: 1 + (3 / 7),
              letterSpacing: 0.15,
            ),
            controller: node.controller,
            onChanged: node.onChanged,
            inputFormatters: [
              FirstLetterUpperCaseTextFormatter(),
            ],
            onEditingComplete: () {
              // no-op to prevent Flutter taking focus away from us!
              debugPrint('Nuh ah Flutter! We want to manage focus :)');
            },
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(vertical: 2),
              // border: InputBorder.none,
              // isDense: true,
              // contentPadding: EdgeInsets.zero,
            ),
          ),
        );
      },
    );
  }
}

class FirstLetterUpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String s = newValue.text;
    String upperCasedString = s;
    if (s.length > 1 &&
        s[1].toUpperCase() != s[1] &&
        s.startsWith(EditorNode.kMarker)) {
      upperCasedString = '${s[0]}${s[1].toUpperCase()}${s.substring(2)}';
    }
    return TextEditingValue(
      text: upperCasedString,
      selection: newValue.selection,
    );
  }
}
