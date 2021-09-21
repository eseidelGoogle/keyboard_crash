import 'package:flutter/material.dart';
import 'package:keyboard_crash/src/util/uuid.dart';

class BoardDetails with ChangeNotifier {
  final int id;

  String? _name;

  String _description;

  final UserSummary author;

  List<SaveDetails> saves;

  final List<String> blocks;

  final Map<String, BoardBlock> data;

  int saveCount;

  final DateTime created;

  DateTime _updated;

  DateTime? _publishDate;

  bool _published;

  final String token;

  String? _image;

  String? _secondary;

  String? _tertiary;

  bool _dirty;

  BoardDetails({
    required this.id,
    String? name = '',
    String description = '',
    required this.author,
    this.saves = const [],
    List<String> blocks = const [],
    Map<String, BoardBlock>? data,
    required this.created,
    int? placeCount,
    int? saveCount,
    DateTime? updated,
    DateTime? publishDate,
    bool published = false,
    String? token,
    String? image,
    String? secondary,
    String? tertiary,
    bool? dirty,
  })  : _name = name,
        _description = description,
        _updated = updated ?? created,
        _publishDate = publishDate,
        _published = published,
        token = token ?? '',
        saveCount = saveCount ?? saves.length,
        _image = image,
        _secondary = secondary,
        _tertiary = tertiary,
        _dirty = dirty ?? false,
        data = data ?? {},
        blocks = blocks.where((key) => data?.containsKey(key) ?? false).toList();

  String get uid => author.uid;

  bool get isEmpty => blocks.isEmpty;

  List<BoardBlock> toBlocks() {
    final blocks = this.blocks.where(data.containsKey).toList();
    return List.generate(blocks.length, (index) => data[blocks[index]] as BoardBlock);
  }

  int get placeCount => 0;
  int get collectionCount => 0;

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

  DateTime? get publishDate => _publishDate;

  set publishDate(DateTime? value) {
    if (_publishDate != value) {
      _publishDate = value;
      dirty = true;
    }
  }

  bool get published => _published;

  set published(bool value) {
    if (_published != value) {
      _published = value;
      dirty = true;
    }
  }

  String? get image => _image;

  set image(String? value) {
    if (_image != value) {
      _image = value;
      dirty = true;
    }
  }

  String? get secondary => _secondary;

  set secondary(String? value) {
    if (_secondary != value) {
      _secondary = value;
      dirty = true;
    }
  }

  String? get tertiary => _tertiary;

  set tertiary(String? value) {
    if (_tertiary != value) {
      _tertiary = value;
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

  void insert(int index, BoardBlock element) {
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

abstract class BoardBlock {
  int id;

  final String uid;

  final BlockType type;

  BoardBlock(this.id, String? uid, this.type) : uid = uid ?? uuid();
}

class DividerBlock extends BoardBlock {
  DividerBlock({
    int id = 0,
    String? uid,
    BlockType type = BlockType.divider,
  }) : super(id, uid, type);
}

class TextBlock extends BoardBlock {
  String text;

  BoardTextType style;

  TextBlock({
    int id = 0,
    String? uid,
    this.text = '',
    this.style = BoardTextType.body1,
    BlockType type = BlockType.text,
  }) : super(id, uid, type);
}

enum BlockType { text, divider, place, list, photo, link }

enum BoardTextType {
  heading1,
  heading2,
  heading3,
  body1,
  body2,
  caption,
  overline
}

class UserSummary {
  final String uid;
  final String name;
  final String? username;
  final String? photo;
  final String? cover;
  final String? website;
  final String? instagram;
  final String? bio;
  final DateTime? updated;

  const UserSummary({
    required this.uid,
    required this.name,
    required this.username,
    this.photo,
    this.cover,
    this.website,
    this.instagram,
    this.bio,
    this.updated,
  });

  String get cacheType => 'user.summary';
  String get cacheKey => uid;

  String? get instagramUrl =>
      instagram?.isNotEmpty == true ? 'https://instagram.com/$instagram' : null;

  bool get isComplete => username?.isNotEmpty == true;
}

class SaveDetails extends UserSummary {
  final int user;

  final UserRole role;

  final UserState state;

  final DateTime added;

  const SaveDetails({
    required this.user,
    required this.role,
    required this.state,
    required this.added,
    required String uid,
    required String name,
    required String? username,
    String? photo,
    String? cover,
    String? bio,
    String? website,
    String? instagram,
    DateTime? updated,
  }) : super(
          uid: uid,
          name: name,
          username: username,
          photo: photo,
          cover: cover,
          website: website,
          instagram: instagram,
          bio: bio,
          updated: updated,
        );
}

enum UserRole {
  owner,

  editor,

  guest,

  viewer,

  follower,

  none
}

enum UserState {
  unknown,

  joined,

  declined
}
