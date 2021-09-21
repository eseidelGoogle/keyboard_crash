import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../model/board.dart';
import 'board_editor_viewmodel.dart';

/// A [BoardButton] is used to indicate the currently active element within the board being edited.
///
/// This can then be used to update the state of the editor bar
enum BoardButton { h1, h2, h3, body, divider, place, list, photo, link }

extension BoardBlockButtonExtension on BoardBlock {
  BoardButton get boardButton {
    switch (type) {
      case BlockType.text:
        switch ((this as TextBlock).style) {
          case BoardTextType.heading1:
            return BoardButton.h1;
          case BoardTextType.heading2:
            return BoardButton.h2;
          case BoardTextType.heading3:
            return BoardButton.h3;
          case BoardTextType.body1:
          case BoardTextType.body2:
          case BoardTextType.caption:
          case BoardTextType.overline:
            return BoardButton.body;
        }
      case BlockType.divider:
        return BoardButton.divider;
      case BlockType.place:
        return BoardButton.place;
      case BlockType.list:
        return BoardButton.list;
      case BlockType.photo:
        return BoardButton.photo;
      case BlockType.link:
        return BoardButton.link;
    }
  }
}

/// An [EditorCommand] is an interface for commands to be executed against the current [MutableBoard].
abstract class EditorCommand {
  static EditorCommand exec(EditorCommandFunction exec) {
    return _FunctionCommand(exec);
  }

  void execute(BoardEditorViewModel model);
}

typedef EditorCommandFunction = void Function(BoardEditorViewModel model);

class _FunctionCommand implements EditorCommand {
  _FunctionCommand(this._exec);

  final EditorCommandFunction _exec;

  @override
  void execute(BoardEditorViewModel model) {
    _exec(model);
  }
}

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
      delay: kLongPressTimeout - const Duration(milliseconds: 100),
    );
  }
}

/// Renders a placeholder for a missing item with a small message to indicate what went wrong.
class MissingItem extends StatelessWidget {
  const MissingItem(this.message, {Key? key}) : super(key: key);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.red,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Placeholder(fallbackHeight: 64.0, fallbackWidth: 64.0),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(message, maxLines: null),
            ),
          ),
        ],
      ),
    );
  }
}
