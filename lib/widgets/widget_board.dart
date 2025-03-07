import 'package:flutter/material.dart';
import 'package:selarashomeid/screens/detail_task_screen.dart';
import 'package:selarashomeid/service/api_service.dart';

import 'board/appflowy_board.dart';

class WidgetBoard extends StatefulWidget {
  final AppFlowyBoardScrollController boardController;
  final AppFlowyBoardController controller;
  final Future<void> Function(int boardId) addTask;
  final Future<void> Function(int boardId) deleteBoard;
  final Future<void> Function(int boardId, String newName) renameBoard;
  final Future<void> Function(int boardId, int newWorkspaceId) moveBoard;
  final Future<void> Function() onLoadBoard;
  const WidgetBoard({
    super.key,
    required this.boardController,
    required this.controller,
    required this.addTask,
    required this.deleteBoard,
    required this.renameBoard,
    required this.moveBoard,
    required this.onLoadBoard,
  });

  @override
  State<WidgetBoard> createState() => _WidgetBoardState();
}

class _WidgetBoardState extends State<WidgetBoard> {
  Future<void> onMenuSelected(String value, dynamic columnData) async {
    switch (value) {
      case 'move':
        int? newWorkspaceId =
            await _showMoveDialog(columnData.headerData.groupWorkspaceId);
        if (newWorkspaceId != null) {
          final currentId = int.parse(columnData.id);
          await widget.moveBoard(currentId, newWorkspaceId);
        }
        break;
      case 'rename':
        String? newName =
            await _showRenameDialog(columnData.headerData.groupName);
        if (newName != null && newName.isNotEmpty) {
          final currentId = int.parse(columnData.id);
          await widget.renameBoard(currentId, newName);
        }
        break;
      case 'delete':
        bool confirmed = await _showDeleteConfirmationDialog();
        if (confirmed) {
          final currentId = int.parse(columnData.id);
          await widget.deleteBoard(currentId);
        }
        break;
    }
  }

  Future<bool> _showDeleteConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Konfirmasi Hapus"),
              content: Text("Kamu yakin ingin menghapus board?"),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context, false), // Tidak jadi delete
                  child: Text("Batal"),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context, true), // Konfirmasi delete
                  child: Text("Hapus", style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<String?> _showRenameDialog(String currentName) async {
    TextEditingController _controller =
        TextEditingController(text: currentName);

    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Rename Board"),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: "New Board Name",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null), // Batal rename
              child: Text("Batal"),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, _controller.text), // Konfirmasi rename
              child: Text("Rename", style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  Future<int?> _showMoveDialog(String currentWorkspaceId) async {
    List<Map<String, dynamic>> workspaces = [];
    int? selectedWorkspaceId = int.tryParse(currentWorkspaceId) ?? 0;

    try {
      final response = await ApiService.workspaceFind();
      workspaces = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat workspace: $e')),
      );
    }

    return await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Move to"),
          content: StatefulBuilder(
            builder: (context, setState) {
              return DropdownButtonFormField<int>(
                value: selectedWorkspaceId,
                items: workspaces.map((workspace) {
                  return DropdownMenuItem<int>(
                    value: workspace['id'],
                    child: Text(workspace['name']),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  setState(() {
                    selectedWorkspaceId = newValue;
                  });
                },
                decoration: InputDecoration(
                  labelText: "Select Workspace",
                  border: OutlineInputBorder(),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null), // Batal pindah
              child: Text("Batal"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(
                  context, selectedWorkspaceId), // Konfirmasi pindah
              child: Text("Move", style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

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
          child: InkWell(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetailTaskScreen(
                      boardId: int.tryParse(group.id)!,
                      taskId: int.tryParse(groupItem.id)!,
                    ),
                  ),
                );

                await widget.onLoadBoard();
              },
              child: _buildCard(groupItem)),
        );
      },
      boardScrollController: widget.boardController,
      footerBuilder: (context, columnData) {
        return AppFlowyGroupFooter(
          icon: const Icon(Icons.add, size: 20),
          title: const Text('Add Task'),
          height: 50,
          margin: config.groupBodyPadding,
          onAddButtonClick: () async {
            final currentId = int.parse(columnData.id);
            await widget.addTask(currentId);
          },
        );
      },
      headerBuilder: (context, columnData) {
        return AppFlowyGroupHeader(
          icon: const Icon(Icons.lightbulb_circle),
          title: Expanded(
              child: Text(
                  '${columnData.headerData.groupName} (${columnData.headerData.groupTaskTotal})')),
          moreIcon: PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz, size: 20), // Icon More
            onSelected: (String value) =>
                onMenuSelected(value, columnData), // Handle menu click
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'move',
                child: Text('Move'),
              ),
              PopupMenuItem<String>(
                value: 'rename',
                child: Text('Rename'),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Text('Delete'),
              ),
            ],
          ),
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
  final String currentId;

  TextItem(
    this.s,
    this.currentId,
  );

  @override
  String get id => currentId;
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
