import 'package:keyboard_crash/src/model/board.dart';

class BoardService {
  @override
  noSuchMethod(Invocation invocation) {
    if (invocation.runtimeType == Future) {
      return Future.value();
    }
    return super.noSuchMethod(invocation);
  }

  Future updateBlocks(BoardDetails board) async {}

  delete(int id) {}
}
