import 'package:flutter/material.dart';
import 'package:selarashomeid/screens/detail_task_screen.dart';
import 'package:selarashomeid/service/api_service.dart';
import 'package:selarashomeid/utils/general.dart';
import 'package:intl/intl.dart';

import 'board/appflowy_board.dart';

class WidgetBoard extends StatefulWidget {
  final AppFlowyBoardScrollController boardController;
  final AppFlowyBoardController controller;
  final Future<void> Function(int boardId) addTask;
  final Future<void> Function(int boardId) deleteBoard;
  final Future<void> Function(int boardId, String newName) renameBoard;
  final Future<void> Function(int boardId, int newWorkspaceId) moveBoard;
  final Future<void> Function(int taskId, bool isCompleted) completedChange;
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
    required this.completedChange,
  });

  @override
  State<WidgetBoard> createState() => _WidgetBoardState();
}

class _WidgetBoardState extends State<WidgetBoard> {
  Map<String, bool> _loadingCheckboxMap = {};

  Future<void> onCompletedChange(int taskId, bool isCompleted) async {
    setState(() => _loadingCheckboxMap[taskId.toString()] = true);
    await widget.completedChange(taskId, isCompleted);
    setState(() => _loadingCheckboxMap[taskId.toString()] = false);
  }

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
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Agar checkbox di atas dan di kiri
          children: [
            // Container pertama untuk checkbox (paling kiri)
            Align(
              alignment: Alignment.centerLeft,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: Checkbox(
                  key: ValueKey(item.isCompleted),
                  value: item.isCompleted,
                  onChanged: _loadingCheckboxMap[item.id] == true
                      ? null
                      : (bool? value) {
                          onCompletedChange(int.parse(item.id), value!);
                        },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            // Container kedua untuk title dan ikon description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment
                    .start, // Judul dan ikon akan diatur vertikal
                children: [
                  // Menambahkan cover jika item.cover tidak kosong
                  if (item.cover.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(
                          bottom: 8), // Memberikan jarak antara cover dan title
                      child: Image(
                        image: NetworkImage(item.cover[
                            "view"]), // Menggunakan NetworkImage untuk menampilkan gambar
                        fit: BoxFit.cover,
                        width: double
                            .infinity, // Membuat gambar memenuhi lebar kontainer
                        height: 120, // Mengatur tinggi gambar cover
                      ),
                    ),
                  ],

                  // Title
                  Text(
                    General.capitalizeEachWord(item.title),
                    style: TextStyle(
                      color: item.isCompleted ? Colors.grey : Colors.black,
                      decoration:
                          item.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),

                  // Row untuk menampilkan ikon description dan ikon alarm bersama dengan teks jika ada
                  Row(
                    children: [
                      if (item.watch == true) ...[
                        Icon(
                          Icons.remove_red_eye_outlined, // Ikon dokumen
                          size: 20, // Ukuran ikon
                          color: Colors.grey, // Warna ikon
                        ),
                        SizedBox(
                            width:
                                5), // Memberikan jarak antara ikon deskripsi dan ikon lainnya
                      ],
                      // Ikon description jika item.description = true
                      if (item.description == true) ...[
                        Icon(
                          Icons.description, // Ikon dokumen
                          size: 20, // Ukuran ikon
                          color: Colors.grey, // Warna ikon
                        ),
                        SizedBox(
                            width:
                                5), // Memberikan jarak antara ikon deskripsi dan ikon lainnya
                      ],

                      // Ikon alarm dan due date jika ada
                      if (item.dueDate != null) ...[
                        // Memberikan jarak antara icon description dan icon alarm
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6), // Padding untuk ikon dan teks
                          decoration: BoxDecoration(
                            color: item.isCompleted
                                ? Colors.green.withOpacity(
                                    0.2) // Background hijau jika completed
                                : (DateTime.parse(item.dueDate!)
                                        .isBefore(DateTime.now())
                                    ? Colors.red.withOpacity(
                                        0.2) // Background merah jika overdue
                                    : Colors.black.withOpacity(
                                        0.1)), // Background hitam jika belum overdue
                            borderRadius: BorderRadius.circular(
                                50), // Membuat sudut melengkung pada background
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.alarm, // Ikon jam
                                size: 20, // Ukuran ikon
                                color: item.isCompleted
                                    ? Colors.green
                                    : (DateTime.parse(item.dueDate!)
                                            .isBefore(DateTime.now())
                                        ? Colors.red
                                        : Colors
                                            .black), // Menentukan warna ikon
                              ),
                              SizedBox(width: 8),
                              Text(
                                // Format tanggal sesuai kondisi
                                DateFormat(item.dueDate!.substring(0, 4) !=
                                            DateTime.now().year.toString()
                                        ? 'MMM dd, yyyy'
                                        : 'MMM dd')
                                    .format(DateTime.parse(item.dueDate!)),
                                style: TextStyle(
                                  color: item.isCompleted
                                      ? Colors.green
                                      : (DateTime.parse(item.dueDate!)
                                              .isBefore(DateTime.now())
                                          ? Colors.red
                                          : Colors
                                              .black), // Menentukan warna teks berdasarkan kondisi
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    throw UnimplementedError();
  }
}

class TextItem extends AppFlowyGroupItem {
  final String currentId;
  final int boardId;
  final String title;
  final bool isCompleted;
  final bool description;
  final Map<String, dynamic> cover;
  final String? dueDate;
  final bool watch;

  TextItem(
    this.currentId,
    this.boardId,
    this.title,
    this.isCompleted,
    this.description,
    this.cover,
    this.dueDate,
    this.watch,
  );

  @override
  String get id => currentId;
}
