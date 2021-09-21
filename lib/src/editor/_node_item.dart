import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/board.dart';
import '_core.dart';
import '_divider.dart';
import '_text.dart';
import 'board_editor_viewmodel.dart';

class NodeItemView extends StatelessWidget {
  const NodeItemView(
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

        final child = ReorderableShortDelayDragStartListener(
          key: ValueKey('reorder-block-item-${block.uid}'),
          enabled: !node.focus.hasPrimaryFocus,
          index: index,
          child: block.render(context, index, viewModel, node.key,
              () => viewModel.removeAt(index)),
        );

        debugPrint('block type: ${block.type}');

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: const Color(0xffffffff),
            // const Color(0xfff8f8f8),
            // border: Border.all(
            //   color: Color(0x34000000),
            // ),

            // border: Border.all(
            //   color: editor.selection == null
            //       ? Colors.transparent
            //       : editor.selection?.index == index
            //           ? Colors.red
            //           : Colors.blue,
            // ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 0,
            vertical: 0,
          ),
          child: node.type == BlockType.text
              ? child
              : GestureDetector(
                  onTap: () => viewModel.select(block.uid),
                  child: Dismissible(
                    key: ValueKey('dismissible-block-item-${block.uid}'),
                    direction: DismissDirection.endToStart,
                    resizeDuration: const Duration(milliseconds: 400),
                    background: Container(
                      width: 88.0,
                      color: Colors.red,
                      alignment: AlignmentDirectional.centerEnd,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: const [
                          Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.white,
                          ), /**/
                        ],
                      ),
                    ),
                    onDismissed: (direction) {
                      viewModel.removeAt(index);
                    },
                    child: child,
                  ),
                ),
        );
      },
    );
  }
}

extension BlockRenderMixin on BoardBlock {
  Widget render(
    BuildContext context,
    int index,
    BoardEditorViewModel editor,
    Key key,
    VoidCallback? onRemove,
  ) {
    switch (type) {
      case BlockType.divider:
        return const DividerComponent();
      case BlockType.text:
        return TextComponent(this as TextBlock, index: index, key: key);
      default:
        return const Placeholder(strokeWidth: 1.0, color: Colors.blueAccent);
    }
  }
}
