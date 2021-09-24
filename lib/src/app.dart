import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'editor/board_editor_viewmodel.dart';
import 'editor/model.dart';
import 'editor/node_item.dart';

/// The Widget that configures your application.
class MyApp extends StatelessWidget {
  const MyApp({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final board = BoardDetails(id: 1);
    return MaterialApp(
      theme: ThemeData(),
      home: ChangeNotifierProvider(
        create: (context) => BoardEditorViewModel(board),
        builder: (context, child) => Scaffold(
          appBar: AppBar(
            title: const Text('Keyboard Crash Repro'),
          ),
          body: Consumer<BoardEditorViewModel>(
            builder: (context, editor, child) {
              return Column(
                children: [
                  Expanded(
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                const SizedBox(
                                  height: 272,
                                  width: double.infinity,
                                  child: FlutterLogo(),
                                ),
                                TextFormField(
                                  initialValue: board.name ?? '',
                                  onChanged: editor.setName,
                                  decoration: const InputDecoration(
                                    hintText: 'Untitled',
                                  ),
                                ),
                                TextFormField(
                                  initialValue: board.description,
                                  onChanged: editor.setDescription,
                                  decoration: const InputDecoration(
                                    hintText: '+ add a description',
                                  ),
                                ),
                              ],
                            ),
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
              );
            },
          ),
        ),
      ),
    );
  }
}
