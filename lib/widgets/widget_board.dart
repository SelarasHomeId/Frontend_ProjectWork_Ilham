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
        final currentId = int.parse(columnData.id);
        await _showRenameDialog(currentId, columnData.headerData.groupName);
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
    return await General.showDialogConfirmDelete(
          context: context,
          title: "Konfirmasi Hapus",
          message: "Kamu yakin ingin menghapus board?",
          additionalMessage:
              "Menghapus board akan menghapus semua task di dalamnya.",
          confirmButtonText: "Hapus",
          cancelButtonText: "Batal",
        ) ??
        false;
  }

  Future _showRenameDialog(int currentId, String currentName) async {
    TextEditingController _controller =
        TextEditingController(text: currentName);

    General.showDialogEdit(
      context: context,
      controller: _controller,
      existingItems: [],
      itemName: 'Board',
      hintText: 'Masukkan nama baru untuk Board',
      emptyFieldMessage: 'Nama tidak boleh kosong',
      duplicateMessage: 'Nama sudah ada, pilih nama lain',
      onSave: (data) async {
        try {
          await widget.renameBoard(currentId, data['name']);
          General.showSnackBar(context, "Berhasil Update Board");
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal memperbarui board: $e')),
          );
        }
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
      General.showSnackBar(context, 'Gagal memuat workspace: $e');
    }

    return await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 13, 20, 158),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child:
                      Icon(Icons.move_to_inbox, size: 80, color: Colors.white),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Move to Workspace',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: StatefulBuilder(
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
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, null), // Batal
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child:
                        Text('Cancel', style: TextStyle(color: Colors.white)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(
                        context, selectedWorkspaceId), // Konfirmasi
                    style: TextButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 13, 20, 158),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Move', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              SizedBox(height: 20),
            ],
          ),
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
            child: _buildCard(groupItem),
          ),
        );
      },
      boardScrollController: widget.boardController,
      footerBuilder: (context, columnData) {
        double screenWidth = MediaQuery.of(context).size.width;
        double paddingValueHorizontal = screenWidth * 0.22;
        double paddingValueVertical = screenWidth * 0.025;
        double iconSize = screenWidth * 0.06;
        double textFontSize = screenWidth * 0.04;

        return TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Colors.blueGrey,
            padding: EdgeInsets.symmetric(
                horizontal: paddingValueHorizontal,
                vertical: paddingValueVertical),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () async {
            final currentId = int.parse(columnData.id);
            await widget.addTask(currentId);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: iconSize, color: Colors.white),
              SizedBox(width: screenWidth * 0.02),
              Text(
                'Add Task',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: textFontSize,
                ),
              ),
            ],
          ),
        );
      },
      headerBuilder: (context, columnData) {
        double screenWidth = MediaQuery.of(context).size.width;
        double iconSize = screenWidth * 0.07;
        double spacing = screenWidth * 0.01;

        return AppFlowyGroupHeader(
          icon: const Icon(Icons.lightbulb_circle,
              size: 20, color: Colors.black87),
          title: Expanded(
            child: Text(
              '${columnData.headerData.groupName} (${columnData.headerData.groupTaskTotal})',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          moreIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  Icons.add_circle,
                  size: iconSize,
                  color: Colors.black87,
                ),
                onPressed: () async {
                  final currentId = int.parse(columnData.id);
                  await widget.addTask(currentId);
                },
              ),
              SizedBox(width: spacing),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_horiz,
                  size: iconSize,
                  color: Colors.black87,
                ),
                onSelected: (String value) => onMenuSelected(value, columnData),
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'move',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.move_to_inbox, size: 18),
                      title: const Text('Move', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'rename',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.edit, size: 18),
                      title:
                          const Text('Rename', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.delete, size: 18),
                      title:
                          const Text('Delete', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
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
      return AbsorbPointer(
        absorbing: item.canAccess == false,
        child: Opacity(
          opacity: item.canAccess == false ? 0.5 : 1.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.center, // Agar checkbox di atas dan di kiri
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

                      // Label
                      if (item.label.isNotEmpty) ...[
                        Wrap(
                          spacing: 5, // Jarak antar ikon
                          runSpacing:
                              3, // Jarak antar baris jika ikon terlalu banyak
                          children: [
                            for (var label in item.label["data"] as List)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.label, // Ikon label
                                    size: 20, // Ukuran ikon
                                    color: Color(int.parse(
                                        label["color"])), // Warna dari JSON
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                      SizedBox(height: 3),
                      // Title
                      Text(
                        General.capitalizeEachWord(item.title),
                        style: TextStyle(
                          color: item.isCompleted ? Colors.grey : Colors.black,
                          decoration:
                              item.isCompleted ? TextDecoration.lineThrough : null,
                          fontSize: 16,
                        ),
                      ),
                      // Row untuk menampilkan ikon description dan ikon alarm bersama dengan teks jika ada
                      if (item.watch == true ||
                          item.description == true ||
                          item.comment != 0 ||
                          item.file != 0 ||
                          item.dueDate != null ||
                          item.checklist != null) ...[
                        SizedBox(height: 5),
                        Wrap(
                          spacing: 5,
                          runSpacing: 3,
                          children: [
                            if (item.watch == true) ...[
                              Icon(
                                Icons.remove_red_eye_outlined, // Ikon dokumen
                                size: 20, // Ukuran ikon
                                color: Colors.grey, // Warna ikon
                              ),
                            ],
                            // Ikon description jika item.description = true
                            if (item.description == true) ...[
                              Icon(
                                Icons.description, // Ikon dokumen
                                size: 20, // Ukuran ikon
                                color: Colors.grey, // Warna ikon
                              ),
                            ],
                            if (item.comment != 0) ...[
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.comment, // Ikon komentar
                                    size: 20, // Ukuran ikon
                                    color: Colors.grey, // Warna ikon
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    '${item.comment}', // Menampilkan jumlah komentar
                                    style: TextStyle(
                                      fontSize: 14, // Ukuran teks
                                      color: Colors.grey, // Warna teks
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            if (item.file != 0) ...[
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.attachment, // Ikon komentar
                                    size: 20, // Ukuran ikon
                                    color: Colors.grey, // Warna ikon
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    '${item.file}', // Menampilkan jumlah komentar
                                    style: TextStyle(
                                      fontSize: 14, // Ukuran teks
                                      color: Colors.grey, // Warna teks
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            // Ikon alarm dan due date jika ada
                            if (item.dueDate != null) ...[
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 3), // Padding untuk ikon dan teks
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
                                    SizedBox(width: 8),
                                  ],
                                ),
                              ),
                            ],
                            if (item.checklist != null) ...[
                              // Memberikan jarak antara icon description dan icon alarm
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 3), // Padding untuk ikon dan teks
                                decoration: BoxDecoration(
                                  color: General.checkChecklistCompleted(
                                          item.checklist!)
                                      ? Colors.green.withOpacity(
                                          0.2) // Background hijau jika completed
                                      : Colors.black.withOpacity(
                                          0.1), // Background hitam jika belum overdue
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.checklist, // Ikon jam
                                      size: 20, // Ukuran ikon
                                      color: General.checkChecklistCompleted(
                                              item.checklist!)
                                          ? Colors.green
                                          : Colors.black, // Menentukan warna ikon
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      item.checklist!,
                                      style: TextStyle(
                                        color: General.checkChecklistCompleted(
                                                item.checklist!)
                                            ? Colors.green
                                            : Colors
                                                .black, // Menentukan warna teks berdasarkan kondisi
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                      if (item.assignToUser.isNotEmpty) ...[
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 5, // Jarak antar ikon
                          runSpacing:
                              3, // Jarak antar baris jika ikon terlalu banyak
                          children: [
                            for (var member in item.assignToUser["data"] as List)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: General.getColorFromInitial(
                                        General.getInitials(member['name'])),
                                    child: Text(
                                      General.getInitials(member['name']),
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: General.getContrastingTextColor(
                                              General.getColorFromInitial(
                                                  General.getInitials(
                                                      member['name'])))),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
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
  final int comment;
  final Map<String, dynamic> label;
  final String? checklist;
  final Map<String, dynamic> assignToUser;
  final int file;
  final bool canAccess;

  TextItem(
    this.currentId,
    this.boardId,
    this.title,
    this.isCompleted,
    this.description,
    this.cover,
    this.dueDate,
    this.watch,
    this.comment,
    this.label,
    this.checklist,
    this.assignToUser,
    this.file,
    this.canAccess,
  );

  @override
  String get id => currentId;
}
