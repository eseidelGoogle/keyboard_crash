import 'package:flutter/cupertino.dart';

import 'package:uuid/uuid.dart';
import 'package:uuid/uuid_util.dart';

final _uuid = Uuid(options: {'grng': UuidUtil.cryptoRNG()});

String uuid() => _uuid.v4();

class BoardDetails with ChangeNotifier {
  final int id;
  String? _name;
  String _description;
  final List<String> blocks;
  final Map<String, BoardBlock> data;
  DateTime _updated;
  bool _dirty;

  BoardDetails({
    required this.id,
    String? name = '',
    String description = '',
    List<String> blocks = const [],
    Map<String, BoardBlock>? data,
    DateTime? updated,
    bool? dirty,
  })  : _name = name,
        _description = description,
        _updated = updated ?? DateTime.now(),
        _dirty = dirty ?? false,
        data = data ?? {},
        blocks =
            blocks.where((key) => data?.containsKey(key) ?? false).toList();

  bool get isEmpty => blocks.isEmpty;

  List<BoardBlock> toBlocks() {
    final blocks = this.blocks.where(data.containsKey).toList();
    return List.generate(
        blocks.length, (index) => data[blocks[index]] as BoardBlock);
  }

  String? get name => _name;
  set name(String? value) {
    if (_name != value) {
      _name = value;
      dirty = true;
    }
  }

  String get description => _description;
  set description(String value) {
    if (_description != value) {
      _description = value;
      dirty = true;
    }
  }

  DateTime get updated => _updated;
  set updated(DateTime value) {
    if (_updated != value) {
      _updated = value;
      dirty = true;
    }
  }

  bool get dirty => _dirty;
  set dirty(bool value) {
    _dirty = value;
    notifyListeners();
  }

  BoardBlock? getBlock(String uid) {
    return data[uid];
  }

  void removeBlock(String uid) {
    blocks.remove(uid);
    data.remove(uid);
    dirty = true;
  }

  BoardBlock? elementAt(int index) {
    return getBlock(blocks[index]);
  }

  BoardBlock removeAt(int index) {
    final uid = blocks.removeAt(index);
    try {
      return data.remove(uid)!;
    } finally {
      dirty = true;
    }
  }

  void insertText(int index, BoardBlock element) {
    blocks.insert(index, element.uid);
    data[element.uid] = element;
    dirty = true;
  }

  void moveBlock(int oldIndex, int newIndex) {
    // Fill the empty space if the new location is after the old location. This prevents skipping a
    // spot when dropped.
    if (oldIndex <= newIndex) {
      newIndex--;
    }
    final block = blocks.removeAt(oldIndex);
    // Clamp the insertion point to be the updated length of the list.
    blocks.insert(newIndex.clamp(0, blocks.length), block);
    dirty = true;
  }

  int get length => blocks.where(data.containsKey).length;

  void add(BoardBlock element) {
    blocks.add(element.uid);
    data[element.uid] = element;
    dirty = true;
  }

  set length(int newLength) {
    if (newLength < length) {
      for (int i = newLength; i < length; i++) {
        data.remove(blocks[i]);
      }
    }
    blocks.length = newLength;
    dirty = true;
  }

  BoardBlock operator [](int index) {
    final key = blocks[index];

    if (!data.containsKey(key)) {
      // print('Asked for missing block at [$index]: $key');
      // print('  Board nodes: $blocks');
      // print('  Board data keys: ${data.keys}');
      // print('  Board data blocks: $data');
      // print('Asked for missing block at [$index]: $key');
      throw FlutterError('Asked for missing block at [$index]: $key');
    }
    return data[key]!;
  }

  void operator []=(int index, BoardBlock value) {
    blocks[index] = value.uid;
    data[value.uid] = value;
    dirty = true;
  }
}

class BoardBlock {
  BoardBlock({
    this.id = 0,
    String? uid,
    this.text = '',
  }) : uid = uid ?? uuid();

  int id;
  String text;
  final String uid;
}
