import 'package:flutter/material.dart';
import '../model/board.dart';

import '_core.dart';

class UnknownComponent extends StatelessWidget {
  const UnknownComponent({
    Key? key,
    required this.type,
  }) : super(key: key);

  final BlockType type;

  @override
  Widget build(BuildContext context) {
    return MissingItem('Unknown component/block type: $type');
  }
}
