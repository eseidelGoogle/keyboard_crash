import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'board_editor_viewmodel.dart';

class NodeItem extends StatelessWidget {
  const NodeItem(
    this.index, {
    Key? key,
  }) : super(key: key);

  final int index;

  @override
  Widget build(BuildContext context) {
    return Consumer<BoardEditorViewModel>(
      builder: (context, viewModel, child) {
        final block = viewModel.details[index];
        final node = viewModel.getEditorNode(block.uid);

        return ReorderableShortDelayDragStartListener(
          key: ValueKey('reorder-block-item-${block.uid}'),
          // enabled: !node.focus.hasPrimaryFocus,
          index: index,
          child: TextField(
            autofocus: node.focus.hasPrimaryFocus,
            focusNode: node.focus,
            textInputAction: TextInputAction.newline,
            textCapitalization: TextCapitalization.sentences,
            maxLines: null,
            controller: node.controller,
            onChanged: node.onChanged,
          ),
        );
      },
    );
  }
}

/// A [ReorderableShortDelayDragStartListener] that has a delay slightly less
/// than a long press so that we can support dragging a [TextField].
class ReorderableShortDelayDragStartListener
    extends ReorderableDelayedDragStartListener {
  const ReorderableShortDelayDragStartListener({
    Key? key,
    required int index,
    required Widget child,
    bool enabled = true,
  }) : super(key: key, index: index, child: child, enabled: enabled);

  @override
  MultiDragGestureRecognizer createRecognizer() {
    return DelayedMultiDragGestureRecognizer(
      debugOwner: this,
      delay: kLongPressTimeout - const Duration(milliseconds: 50),
    );
  }
}
