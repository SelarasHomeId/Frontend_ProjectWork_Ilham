import 'package:flutter/material.dart';

import 'widgets/board/appflowy_board.dart';

class WidgetBoard extends StatefulWidget {
  final AppFlowyBoardScrollController boardController;
  final AppFlowyBoardController controller;
  final Future<void> Function(int boardId) addTask;
  const WidgetBoard({
    super.key,
    required this.boardController,
    required this.controller,
    required this.addTask,
  });

  @override
  State<WidgetBoard> createState() => _WidgetBoardState();
}

class _WidgetBoardState extends State<WidgetBoard> {
  @override
  Widget build(BuildContext context) {
    final config = AppFlowyBoardConfig(
      groupBackgroundColor: Color.fromARGB(255, 210, 218, 250),
      stretchGroupHeight: false,
    );
    return AppFlowyBoard(
      groupConstraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width - 80,
      ),
      controller: widget.controller,
      cardBuilder: (context, group, groupItem) {
        return AppFlowyGroupCard(
          key: ValueKey(groupItem.id),
          child: _buildCard(groupItem),
        );
      },
      boardScrollController: widget.boardController,
      footerBuilder: (context, columnData) {
        return AppFlowyGroupFooter(
          icon: const Icon(Icons.add, size: 20),
          title: const Text('Update'),
          height: 50,
          margin: config.groupBodyPadding,
          onAddButtonClick: () {
            widget.boardController.scrollToBottom(columnData.id);
          },
        );
      },
      headerBuilder: (context, columnData) {
        return AppFlowyGroupHeader(
          icon: const Icon(Icons.lightbulb_circle),
          title: Expanded(child: Text(columnData.headerData.groupName)),
          // SizedBox(
          //   width: 60,
          //   child: TextField(
          //     controller: TextEditingController()
          //       ..text = columnData.headerData.groupName,
          //     onSubmitted: (val) {
          //       widget.controller
          //           .getGroupController(columnData.headerData.groupId)!
          //           .updateGroupName(val);
          //     },
          // ),
          // ),
          addIcon: InkWell(
            child: const Icon(Icons.add, size: 20),
            onTap: () async {
              final currentId = int.parse(columnData.id);
              await widget.addTask(currentId);
            },
          ),
          moreIcon: const Icon(Icons.more_horiz, size: 20),
          height: 50,
          margin: config.groupBodyPadding,
        );
      },
      config: config,
    );
  }

  Widget _buildCard(AppFlowyGroupItem item) {
    if (item is TextItem) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Text(item.s),
        ),
      );
    }

    if (item is RichTextItem) {
      return RichTextCard(item: item);
    }

    throw UnimplementedError();
  }
}

class RichTextCard extends StatefulWidget {
  final RichTextItem item;
  const RichTextCard({
    required this.item,
    Key? key,
  }) : super(key: key);

  @override
  State<RichTextCard> createState() => _RichTextCardState();
}

class _RichTextCardState extends State<RichTextCard> {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.item.title,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 10),
            Text(
              widget.item.subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            )
          ],
        ),
      ),
    );
  }
}

class TextItem extends AppFlowyGroupItem {
  final String s;

  TextItem(this.s);

  @override
  String get id => s;
}

class RichTextItem extends AppFlowyGroupItem {
  final String title;
  final String subtitle;

  RichTextItem({required this.title, required this.subtitle});

  @override
  String get id => title;
}

extension HexColor on Color {
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
