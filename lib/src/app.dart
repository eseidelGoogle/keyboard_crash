import 'package:flutter/material.dart';
import 'package:keyboard_crash/src/editor/board_editor_viewmodel.dart';
import 'package:keyboard_crash/src/editor/layout.dart';
import 'package:keyboard_crash/src/editor/model.dart';
import 'package:provider/provider.dart';

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
          body: BoardLayout(board),
        ),
      ),
    );
  }
}
