import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/board.dart';
import '_core.dart';
import 'board_editor_viewmodel.dart';
import 'utils.dart';

class TextComponent extends StatelessWidget {
  const TextComponent(
    this.block, {
    Key? key,
    String? uid,
    required this.index,
    this.readOnly = false,
  })  : _uid = uid,
        super(key: key);

  final TextBlock block;
  final String? _uid;
  final int index;
  final bool readOnly;
  String get uid => _uid ?? block.uid;

  @override
  Widget build(BuildContext context) {
    return Consumer<BoardEditorViewModel>(
      builder: (context, viewModel, child) {
        var node = viewModel.getEditorNode(uid);
        return Padding(
          padding: block.style.textPadding,
          child: TextField(
            autofocus: node.focus.hasPrimaryFocus,
            onTap: () {
              viewModel.select(uid);
              viewModel.showButtonBar = true;
            },
            scrollPadding: const EdgeInsets.all(64.0),
            focusNode: node.focus,
            textInputAction: TextInputAction.newline,
            textCapitalization: TextCapitalization.sentences,
            maxLines: null,
            style: block.style.textStyle,
            controller: node.controller,
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

class TextComponentView extends StatelessWidget {
  const TextComponentView({
    Key? key,
    required this.node,
  }) : super(key: key);

  final TextBlock node;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: node.style.textPadding,
      child: Text(
        node.text,
        style: node.style.textStyle,
        maxLines: null,
      ),
    );
  }
}

class AppendBodyTextCommand implements EditorCommand {
  @override
  void execute(BoardEditorViewModel editor) {
    editor.add(TextBlock(), focused: true);
  }
}

class TextButtonPressedCommand implements EditorCommand {
  const TextButtonPressedCommand(
    this.pressed, {
    this.value,
  });

  final BoardButton pressed;
  final String? value;

  BoardTextType get textType {
    switch (pressed) {
      case BoardButton.h1:
        return BoardTextType.heading1;
      case BoardButton.h2:
        return BoardTextType.heading2;
      case BoardButton.h3:
        return BoardTextType.heading3;
      case BoardButton.body:
        return BoardTextType.body1;

      case BoardButton.divider:
      case BoardButton.place:
      case BoardButton.list:
      case BoardButton.photo:
      case BoardButton.link:
        throw UnimplementedError();
    }
  }

  @override
  void execute(BoardEditorViewModel editor) {
    final block = editor.selection?.block;
    if (block is TextBlock) {
      if (block.boardButton != pressed) {
        block.style = textType;
      }
      return;
    }

    final textBlock = TextBlock(style: textType, text: value ?? '');
    editor.insertBlock(textBlock);
  }
}

extension BoardButtonExtension on BoardButton {
  TextButtonPressedCommand pressed() {
    return TextButtonPressedCommand(this);
  }
}
