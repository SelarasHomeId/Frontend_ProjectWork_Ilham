import 'package:flutter/material.dart';
import 'package:selarashomeid/service/api_service.dart';
import 'package:selarashomeid/widgets/widget_board.dart';
import 'package:selarashomeid/widgets/board/appflowy_board.dart';

class WorkspaceWidget extends StatefulWidget {
  final String workspace;
  final int workspaceId;

  const WorkspaceWidget({
    super.key,
    required this.workspace,
    required this.workspaceId,
  });

  @override
  // ignore: library_private_types_in_public_api
  _WorkspaceWidgetState createState() => _WorkspaceWidgetState();
}

class _WorkspaceWidgetState extends State<WorkspaceWidget> {
  List<Map<String, dynamic>> _boards = [];
  String _coverView = "";
  String currentWorkspace = "";

  late AppFlowyBoardController controller;

  late AppFlowyBoardScrollController boardController;

  bool isMovingGroup = false;

  @override
  void initState() {
    super.initState();
    currentWorkspace = widget.workspace;
    _fetchWorkspace();
    _fetchBoards();
  }

  @override
  void didUpdateWidget(covariant WorkspaceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.workspaceId != oldWidget.workspaceId) {
      currentWorkspace = widget.workspace;
      _fetchWorkspace();
      _fetchBoards();
    }
  }

  Future<void> _fetchWorkspace() async {
    try {
      final params = {'id': widget.workspaceId.toString()};
      final workspace = await ApiService.workspaceFind(params: params);
      setState(() {
        if (workspace[0]['cover'] != null) {
          _coverView = workspace[0]['cover']['view'];
        } else {
          _coverView = "";
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat workspace: $e')),
      );
    }
  }

  Future<void> onLoadListBoard() async {
    final Set<String> newBoardIds =
        _boards.map((b) => b["id"].toString()).toSet();

    List<AppFlowyGroupData> updatedGroups = [];

    for (final singleBoard in _boards) {
      try {
        final String currentBoardId = singleBoard["id"].toString();
        final getDataTask = await ApiService.handleTask(
            method: 'GET',
            boardId: int.parse(currentBoardId),
            params: {'no_paging': 'yes'});

        var taskAsList = <AppFlowyGroupItem>[];
        for (final singleTask in (getDataTask as List)) {
          taskAsList.add(
            TextItem(
              singleTask["id"].toString(),
              singleTask["board_id"],
              singleTask["title"],
              singleTask["is_completed"],
              singleTask["description"],
              singleTask["cover"] != null
                  ? {
                      "view": singleTask["cover"]?["view"] ?? "",
                      "content": singleTask["cover"]?["content"] ?? "",
                      "id": singleTask["cover"]?["id"] ?? "",
                      "name": singleTask["cover"]?["name"] ?? "",
                    }
                  : {},
              singleTask["due_date"],
              singleTask["watch"],
              singleTask["comment"],
              singleTask["label"] != null
                  ? {
                      "count": singleTask["label"]?["count"] ?? "",
                      "data": (singleTask["label"]?["data"] as List?)
                              ?.map((item) => {
                                    "color": item["color"],
                                    "id": item["id"],
                                    "title": item["title"]
                                  })
                              .toList() ??
                          []
                    }
                  : {},
              singleTask["checklist"],
              singleTask["assign_to_user"] != null
                  ? {
                      "count": singleTask["assign_to_user"]?["count"] ?? "",
                      "data": (singleTask["assign_to_user"]?["data"] as List?)
                              ?.map((item) => {
                                    "email": item["email"],
                                    "id": item["id"],
                                    "name": item["name"]
                                  })
                              .toList() ??
                          []
                    }
                  : {},
              singleTask["file"],
            ),
          );
        }

        final existingGroupIndex = controller.groupDatas.indexWhere(
          (group) => group.id == currentBoardId,
        );

        if (existingGroupIndex != -1) {
          // Update data board & task
          final updatedGroup = AppFlowyGroupData(
            id: currentBoardId,
            name: singleBoard["name"],
            task_total: singleBoard["task_total"].toString(),
            workspace_id: singleBoard["workspace_id"].toString(),
            items: taskAsList,
          );

          updatedGroups.add(updatedGroup);
        } else {
          // Tambahkan board baru jika belum ada
          updatedGroups.add(AppFlowyGroupData(
            id: currentBoardId,
            name: singleBoard["name"],
            task_total: singleBoard["task_total"].toString(),
            workspace_id: singleBoard["workspace_id"].toString(),
            items: taskAsList,
          ));
        }
      } catch (e, stackTrace) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat board: $e')),
        );
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    controller.groupDatas
        .where((group) => !newBoardIds.contains(group.id))
        .toList()
        .forEach((group) => controller.removeGroup(group.id));
    controller.clear();
    for (var group in updatedGroups) {
      controller.addGroup(group);
    }
    setState(() {});
  }

  Future<void> _fetchBoards() async {
    try {
      boardController = AppFlowyBoardScrollController();
      controller = AppFlowyBoardController(
        onMoveGroup: (fromGroupId, fromIndex, toGroupId, toIndex) {
          isMovingGroup = true;
          _updateSortNumbers(fromIndex, toIndex);
          isMovingGroup = false;
        },
        onMoveGroupItem: (groupId, fromIndex, toIndex) {
          Future.microtask(() async {
            try {
              final getDataTask = await ApiService.handleTask(
                method: 'GET',
                boardId: int.parse(groupId),
                params: {'no_paging': 'yes'},
              );

              List<Map<String, dynamic>> tasks =
                  List<Map<String, dynamic>>.from(getDataTask ?? []);

              if (tasks.isEmpty) return;

              if (fromIndex >= 0 &&
                  fromIndex < tasks.length &&
                  toIndex >= 0 &&
                  toIndex < tasks.length) {
                final task = tasks.removeAt(fromIndex);
                tasks.insert(toIndex, task);
                List<Future<void>> updateFutures = [];
                for (int i = 0; i < tasks.length; i++) {
                  updateFutures.add(_editTask(
                    taskId: tasks[i]['id'],
                    sortNumber: i + 1,
                  ));
                }
                await Future.wait(updateFutures);
                await onLoadListBoard();
              }
            } catch (e) {
              debugPrint('Error updating task order: $e');
            }
          });
        },
        onMoveGroupItemToGroup: (fromGroupId, fromIndex, toGroupId, toIndex) {
          Future.microtask(() async {
            try {
              final fromTasks = await ApiService.handleTask(
                method: 'GET',
                boardId: int.parse(fromGroupId),
                params: {'no_paging': 'yes'},
              );

              List<Map<String, dynamic>> tasksFrom =
                  List<Map<String, dynamic>>.from(fromTasks ?? []);
              if (tasksFrom.isEmpty) return;
              final toTasks = await ApiService.handleTask(
                method: 'GET',
                boardId: int.parse(toGroupId),
                params: {'no_paging': 'yes'},
              );

              List<Map<String, dynamic>> tasksTo =
                  List<Map<String, dynamic>>.from(toTasks ?? []);
              final task = tasksFrom.removeAt(fromIndex);
              tasksTo.insert(toIndex, task);
              await _editTask(
                taskId: task['id'],
                boardId: int.parse(toGroupId),
                sortNumber: toIndex + 1,
              );

              List<Future<void>> updateFuturesFrom = [];
              for (int i = 0; i < tasksFrom.length; i++) {
                updateFuturesFrom.add(_editTask(
                  taskId: tasksFrom[i]['id'],
                  sortNumber: i + 1,
                ));
              }

              List<Future<void>> updateFuturesTo = [];
              for (int i = 0; i < tasksTo.length; i++) {
                updateFuturesTo.add(_editTask(
                  taskId: tasksTo[i]['id'],
                  sortNumber: i + 1,
                ));
              }

              await Future.wait([...updateFuturesFrom, ...updateFuturesTo]);
              await onLoadListBoard();
            } catch (e) {
              debugPrint('Error moving task: $e');
            }
          });
        },
      );
      final boards = await ApiService.handleBoard(
        method: 'GET',
        workspaceId: widget.workspaceId,
        params: {'no_paging': 'yes'},
      );
      setState(() {
        _boards = boards;
      });
      await onLoadListBoard();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat board: $e')),
      );
    }
  }

  Future<void> _createBoard(String name) async {
    try {
      await ApiService.handleBoard(
        method: 'POST',
        workspaceId: widget.workspaceId,
        data: {'name': name, 'workspace_id': widget.workspaceId},
      );
      final boards = await ApiService.handleBoard(
        method: 'GET',
        workspaceId: widget.workspaceId,
        params: {'no_paging': 'yes'},
      );
      setState(() {
        _boards = boards;
      });
      onLoadListBoard();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambahkan board: $e')),
      );
    }
  }

  Future<void> _createTask(int boardId, String title) async {
    try {
      await ApiService.handleTask(
        method: 'POST',
        boardId: boardId,
        data: {'title': title, 'board_id': boardId},
      );
      final boards = await ApiService.handleBoard(
        method: 'GET',
        workspaceId: widget.workspaceId,
        params: {'no_paging': 'yes'},
      );
      setState(() {
        _boards = boards;
      });
      onLoadListBoard();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambahkan board: $e')),
      );
    }
  }

  Future<void> _deleteBoard(int boardId) async {
    try {
      await ApiService.handleBoard(
        method: 'DELETE',
        workspaceId: widget.workspaceId,
        boardId: boardId,
      );
      final boards = await ApiService.handleBoard(
        method: 'GET',
        workspaceId: widget.workspaceId,
        params: {'no_paging': 'yes'},
      );
      setState(() {
        _boards = boards;
      });
      onLoadListBoard();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus board: $e')),
      );
    }
  }

  Future<void> _editBoard({
    required int boardId,
    String? name,
    int? workspaceId,
    int? sortNumber,
  }) async {
    try {
      Map<String, dynamic> updatedData = {};

      if (name != null) updatedData['name'] = name;
      if (workspaceId != null) updatedData['workspace_id'] = workspaceId;
      if (sortNumber != null) updatedData['sort_number'] = sortNumber;

      if (updatedData.isNotEmpty) {
        await ApiService.handleBoard(
          method: 'PUT',
          workspaceId: widget.workspaceId,
          boardId: boardId,
          data: updatedData,
        );
      }
      final boards = await ApiService.handleBoard(
        method: 'GET',
        workspaceId: widget.workspaceId,
        params: {'no_paging': 'yes'},
      );
      setState(() {
        _boards = boards;
      });
      onLoadListBoard();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui board: $e')),
      );
    }
  }

  Future<void> _editTask({
    required int taskId,
    int? boardId,
    bool? isCompleted,
    int? sortNumber,
  }) async {
    try {
      Map<String, dynamic> updatedData = {};

      if (boardId != null) updatedData['board_id'] = boardId;
      if (isCompleted != null) updatedData['is_completed'] = isCompleted;
      if (sortNumber != null) updatedData['sort_number'] = sortNumber;

      if (updatedData.isNotEmpty) {
        await ApiService.handleTask(
          method: 'PUT',
          taskId: taskId,
          data: updatedData,
        );
      }

      final boards = await ApiService.handleBoard(
        method: 'GET',
        workspaceId: widget.workspaceId,
        params: {'no_paging': 'yes'},
      );
      setState(() {
        _boards = boards;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui task: $e')),
      );
    }
  }

  void _updateSortNumbers(int fromIndex, int toIndex) async {
    if (!isMovingGroup || fromIndex == toIndex) return;

    final movedBoard = _boards.removeAt(fromIndex);
    _boards.insert(toIndex, movedBoard);

    List<Future<void>> updateFutures = [];

    for (int i = 0; i < _boards.length; i++) {
      final board = _boards[i];
      final newSortNumber = i + 1;

      if (board['sort_number'] != newSortNumber) {
        board['sort_number'] = newSortNumber;
        updateFutures.add(_editBoard(
          boardId: board['id'],
          sortNumber: newSortNumber,
        ));
      }
    }

    try {
      await Future.wait(updateFutures);
    } catch (e) {
      debugPrint('Error updating board sort numbers: $e');
    }
  }

  void _showCreateBoardDialog() {
    TextEditingController _controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Tambahkan Board',
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width * 0.05,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Masukkan nama board',
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[400]!),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 12, horizontal: 0),
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
              ),
              child: Text(
                'Batal',
                style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.04),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final name = _controller.text.trim();
                if (name.isNotEmpty) {
                  _createBoard(name);
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4C6A92),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Tambah',
                style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.04,
                    color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCreateTaskDialog(int boardId) {
    TextEditingController _controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Tambahkan Task',
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width * 0.05,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Masukkan nama Task',
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[400]!),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 12, horizontal: 0),
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
              ),
              child: Text(
                'Batal',
                style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.04),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final name = _controller.text.trim();
                if (name.isNotEmpty) {
                  _createTask(boardId, name);
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4C6A92),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Tambah',
                style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.04,
                    color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleRefresh() async {
    await Future.wait([
      _fetchWorkspace(),
      onLoadListBoard(),
      _fetchBoards(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    // Cek apakah workspace berubah dan perlu pemuatan ulang data
    if (currentWorkspace != widget.workspace) {
      _fetchBoards();
      currentWorkspace = widget.workspace;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.workspace,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: OutlinedButton(
              onPressed: () {
                _showCreateBoardDialog();
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: Color(0xFF4C6A92),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.04,
                  vertical: MediaQuery.of(context).size.height * 0.01,
                ),
              ),
              child: Text(
                "+ Add Board",
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.04,
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh, // Handle refresh action
        child: Stack(
          children: [
            // Background Image
            if (_coverView.isNotEmpty)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(_coverView),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

            // Konten utama dengan scroll vertikal
            SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: ScrollConfiguration(
                    key: ValueKey('list'),
                    behavior: ScrollBehavior().copyWith(overscroll: false),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        WidgetBoard(
                          controller: controller,
                          boardController: boardController,
                          addTask: (boardId) async {
                            _showCreateTaskDialog(boardId);
                          },
                          onLoadBoard: () async {
                            await onLoadListBoard();
                          },
                          deleteBoard: (boardId) async {
                            await _deleteBoard(boardId);
                          },
                          renameBoard: (boardId, newName) async {
                            await _editBoard(boardId: boardId, name: newName);
                          },
                          moveBoard: (boardId, newWorkspaceId) async {
                            await _editBoard(
                                boardId: boardId, workspaceId: newWorkspaceId);
                          },
                          completedChange: (taskId, isCompleted) async {
                            await _editTask(
                                taskId: taskId, isCompleted: isCompleted);
                            await onLoadListBoard();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
