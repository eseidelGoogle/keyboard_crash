import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:keyboard_crash/src/editor/board_header_view.dart';
import 'package:keyboard_crash/src/model/board.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import '_buttons.dart';
import '_node_item.dart';
import '_text.dart';

import 'board_editor_viewmodel.dart';

class BoardLayout extends StatelessWidget {
  const BoardLayout(
    this.board, {
    Key? key,
  }) : super(key: key);

  static final _log = Logger('BoardLayout');

  final BoardDetails? board;

  @override
  Widget build(BuildContext context) {
    _log.finest('Received board: $board');
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
                        onChangeCover: () {
                          showAboutDialog(context: context);
                        },
                        onFocusChanged: (hasFocus) {
                          if (hasFocus) {
                            editor.showButtonBar = false;
                          }
                        },
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
                            editor.executeCommand(AppendBodyTextCommand());
                          },
                          child: const Padding(
                            padding: EdgeInsets.only(left: 20, top: 16),
                            child: Text(
                              'Tap here to start building your board...',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 14,
                                height: 1.4,
                                color: Color(0xFFb1b1b1),
                                letterSpacing: 0.15,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
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
                                child: MultiProvider(
                                  providers: [
                                    ChangeNotifierProvider.value(value: editor),
                                  ],
                                  child: child,
                                ),
                              ),
                            ),
                          );
                        },
                        itemCount: editor.details.length,
                        itemBuilder: (context, index) => NodeItemView(
                          index,
                          key: ValueKey(editor.details[index].uid),
                        ),
                      ),
                    // const SliverToBoxAdapter(
                    //   child: Padding(
                    //     padding: EdgeInsets.all(8.0),
                    //     child: Divider(color: Colors.black),
                    //   ),
                    // ),
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          editor.executeCommand(AppendBodyTextCommand());
                        },
                        child: const SizedBox(
                          height: 240.0,
                        ),
                      ),
                    )
                  ],
                ),
              ),
              if (editor.isButtonBarVisible) const BoardButtonBar(),
              if (kDebugMode && kShowFocusState)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Wrap(
                    spacing: 8.0,
                    children: [
                      KeyValue('isKeyboardVisible', editor.isKeyboardVisible),
                      KeyValue('selection', editor.selection),
                      KeyValue('hasTextSelection', editor.hasTextSelection),
                      KeyValue('selection', editor.selection?.button),
                      KeyValue('block', editor.selection?.block),
                      KeyValue(
                          'focus', editor.nodes.map((e) => e.focus.hasFocus)),
                      KeyValue('primaryFocus',
                          editor.nodes.map((e) => e.focus.hasPrimaryFocus)),
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

const kShowFocusState = false;

class KeyValue extends StatelessWidget {
  const KeyValue(
    this.label,
    this.value, {
    Key? key,
  }) : super(key: key);

  final String label;
  final Object? value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: '$label: ',
        style: Theme.of(context).textTheme.subtitle1,
        children: [
          TextSpan(
            text: value?.toString(),
            style: const TextStyle(
                color: Colors.blueAccent, fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }
}
