import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:keyboard_crash/src/editor/model.dart';
import 'package:provider/provider.dart';

import 'board_editor_viewmodel.dart';
import 'board_header_view.dart';
import 'node_item.dart';

class BoardLayout extends StatelessWidget {
  const BoardLayout(
    this.board, {
    Key? key,
  }) : super(key: key);

  final BoardDetails? board;

  @override
  Widget build(BuildContext context) {
    return Consumer<BoardEditorViewModel>(
      builder: (context, editor, child) {
        return WillPopScope(
          onWillPop: () async {
            await editor.saveBoard();
            editor.clearSelection();
            return true;
          },
          child: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  controller: editor.scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: BoardHeaderView(
                        board: editor.details,
                        onNameChanged: (value) {
                          editor.setName(value);
                        },
                        onDescriptionChanged: (value) {
                          editor.setDescription(value);
                        },
                      ),
                    ),
                    if (editor.isEmpty)
                      SliverToBoxAdapter(
                        child: GestureDetector(
                          onTap: () {
                            editor.appendText();
                          },
                          child: const Padding(
                            padding: EdgeInsets.only(left: 20, top: 16),
                            child: Text('Tap here to start building'),
                          ),
                        ),
                      )
                    else
                      SliverReorderableList(
                        onReorder: editor.moveBlock,
                        proxyDecorator: (child, index, animation) {
                          return Material(
                            child: FadeTransition(
                              opacity: animation,
                              child: PhysicalModel(
                                color: Colors.white,
                                elevation: 8,
                                shadowColor: Colors.black45,
                                borderRadius: BorderRadius.circular(4),
                                child: ChangeNotifierProvider.value(
                                  value: editor,
                                  child: child,
                                ),
                              ),
                            ),
                          );
                        },
                        itemCount: editor.details.length,
                        itemBuilder: (context, index) => NodeItem(
                          index,
                          key: ValueKey(editor.details[index].uid),
                        ),
                      ),
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          editor.appendText();
                        },
                        child: const SizedBox(
                          height: 240.0,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
