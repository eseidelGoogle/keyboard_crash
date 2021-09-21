import 'package:flutter/material.dart';
import 'package:keyboard_crash/src/editor/board_editor_viewmodel.dart';
import 'package:keyboard_crash/src/editor/layout.dart';
import 'package:keyboard_crash/src/model/board.dart';
import 'package:provider/provider.dart';

/// The Widget that configures your application.
class MyApp extends StatelessWidget {
  const MyApp({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final board = BoardDetails(
      id: 1,
      author: const UserSummary(
          uid: "user-uid-1234", name: 'Test User', username: 'test.user'),
      created: DateTime.now().subtract(const Duration(days: 30)),
    );
    return MaterialApp(
      theme: ThemeData(),
      home: ChangeNotifierProvider(
        create: (context) => BoardEditorViewModel(board),
        builder: (context, child) => Scaffold(
          appBar: AppBar(
            title: const Text('Keyboard Crash Repro'),
          ),
          body: FutureBuilder<BoardDetails>(
            future: Future.value(board),
            initialData: board,
            builder: (context, snapshot) => BoardLayout(snapshot.data),
          ),
        ),
      ),
    );
  }
}
