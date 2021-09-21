import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import 'board_editor_viewmodel.dart';
import '_core.dart';

mixin ButtonBarStyle {
  static final unselectedButton = OutlinedButton.styleFrom(
    minimumSize: const Size(40, 32),
    padding: const EdgeInsets.all(0),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(16),
      ),
    ),
  );

  static final selectedButton = OutlinedButton.styleFrom(
    minimumSize: const Size(40, 32),
    side: const BorderSide(
      color: Color(0xff313131),
    ),
    padding: const EdgeInsets.all(0),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(16),
      ),
    ),
  );

  ButtonStyle get current => selectedButton;
  ButtonStyle get button => unselectedButton;
}

class BoardButtonBar extends StatelessWidget with ButtonBarStyle {
  const BoardButtonBar({
    Key? key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final ScrollController _scrollBarController = ScrollController();
    return Consumer<BoardEditorViewModel>(
      builder: (context, viewModel, child) => Row(
        children: [
          Expanded(
            child: Scrollbar(
              isAlwaysShown: true,
              thickness: 1,
              radius: Radius.zero,
              controller: _scrollBarController,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(8.0),
                scrollDirection: Axis.horizontal,
                controller: _scrollBarController,
                child: Row(
                  children: [
                    OutlinedButton(
                      style: viewModel.selection?.button == BoardButton.h1
                          ? current
                          : button,
                      onPressed: () {
                        viewModel.onButtonPressed(context, BoardButton.h1);
                      },
                      child: const Text(
                        'H1',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Work Sans',
                          fontSize: 15,
                          letterSpacing: 0.15,
                          color: Color(0xff313131),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    OutlinedButton(
                      style: viewModel.selection?.button == BoardButton.h2
                          ? current
                          : button,
                      onPressed: () {
                        viewModel.onButtonPressed(context, BoardButton.h2);
                      },
                      child: const Text(
                        'H2',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Work Sans',
                          fontSize: 14,
                          letterSpacing: 0.15,
                          color: Color(0xff313131),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    OutlinedButton(
                      style: viewModel.selection?.button == BoardButton.h3
                          ? current
                          : button,
                      onPressed: () {
                        viewModel.onButtonPressed(context, BoardButton.h3);
                      },
                      child: const Text(
                        'H3',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Work Sans',
                          fontSize: 14,
                          letterSpacing: 0.15,
                          color: Color(0xff313131),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    OutlinedButton(
                      style: viewModel.selection?.button == BoardButton.body
                          ? current
                          : button,
                      onPressed: () {
                        viewModel.onButtonPressed(context, BoardButton.body);
                      },
                      child: const Text(
                        'body',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          letterSpacing: 0.15,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    OutlinedButton(
                      style: button,
                      onPressed: () => viewModel.onButtonPressed(
                          context, BoardButton.divider),
                      child: const Icon(Icons.horizontal_rule, size: 24),
                    ),
                    const SizedBox(width: 5),
                    OutlinedButton(
                      style: button,
                      onPressed: () {
                        viewModel.onButtonPressed(context, BoardButton.place);
                      },
                      child: const Icon(Icons.place, size: 24),
                    ),
                    const SizedBox(width: 5),
                    OutlinedButton(
                      style: button,
                      onPressed: () {
                        viewModel.onButtonPressed(context, BoardButton.list);
                      },
                      child: const Icon(Icons.list),
                    ),
                    const SizedBox(width: 5),
                    OutlinedButton(
                      style: button,
                      onPressed: () {
                        viewModel.onButtonPressed(context, BoardButton.photo);
                      },
                      child: const Icon(Icons.insert_photo_rounded),
                    ),
                    const SizedBox(width: 5),
                    OutlinedButton(
                      style: button,
                      onPressed: () {
                        viewModel.onButtonPressed(context, BoardButton.link);
                      },
                      child: const Icon(Icons.link),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            height: 60,
            width: 60,
            child: Row(
              children: [
                Container(
                  width: 1,
                  height: 48,
                  color: Colors.black.withOpacity(0.05),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.keyboard_hide_outlined,
                    color: Color(0xff313131),
                  ),
                  onPressed: () {
                    viewModel.clearSelection();
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
