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
  bool _isLoading = true;
  String currentWorkspace = "";

  late AppFlowyBoardController controller;

  late AppFlowyBoardScrollController boardController;

  @override
  void initState() {
    super.initState();
    _fetchBoards();
    currentWorkspace = widget.workspace;
  }

  Future<void> onLoadListBoard() async {
    if (controller.groupDatas.isNotEmpty) {
      controller.clear();
    }

    for (final singleBoard in _boards) {
      try {
        final currentBoardId = singleBoard["id"];
        final getDataTask = await ApiService.handleTask(
          method: 'GET',
          boardId: currentBoardId,
        );

        var taskAsList = <AppFlowyGroupItem>[];
        for (final singleTask in (getDataTask as List)) {
          taskAsList.add(
            TextItem(
              singleTask["title"],
              singleTask["id"].toString(),
            ),
          );
        } //ambil data task
        // final taskAsList =
        //     (getDataTask as List).map((e) => TextItem(e["title"])).toList();

        final groupData = AppFlowyGroupData(
            id: singleBoard["id"].toString(),
            name: singleBoard["name"],
            task_total: singleBoard["task_total"].toString(),
            workspace_id: singleBoard["workspace_id"].toString(),
            items: taskAsList); //masukin data task baru
        controller.addGroup(groupData); //nampilin grup kedalam board
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat board: $e')),
        );
      }
    }
  }

  Future<void> _fetchBoards() async {
    try {
      boardController = AppFlowyBoardScrollController();
      controller = AppFlowyBoardController(
        onMoveGroup: (fromGroupId, fromIndex, toGroupId, toIndex) {
          _updateSortNumbers(fromIndex, toIndex);
        },
        onMoveGroupItem: (groupId, fromIndex, toIndex) {
          debugPrint('Move $groupId:$fromIndex to $groupId:$toIndex');
        },
        onMoveGroupItemToGroup: (fromGroupId, fromIndex, toGroupId, toIndex) {
          debugPrint('Move $fromGroupId:$fromIndex to $toGroupId:$toIndex');
        },
      );
      final boards = await ApiService.handleBoard(
        method: 'GET',
        workspaceId: widget.workspaceId,
      );
      setState(() {
        _boards = boards;
      });
      await onLoadListBoard();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
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
      );

      setState(() {
        _boards = boards;
        _isLoading = false;
      });
      controller.clear();
      onLoadListBoard();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Board berhasil ditambahkan')),
      );
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
        // workspaceId: widget.workspaceId,
        boardId: boardId,
        data: {'title': title, 'board_id': boardId},
      );
      final boards = await ApiService.handleBoard(
        method: 'GET',
        workspaceId: widget.workspaceId,
      );

      setState(() {
        _boards = boards;
        _isLoading = false;
      });
      controller.clear();
      onLoadListBoard();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Board berhasil ditambahkan')),
      );
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
      );

      setState(() {
        _boards = boards;
        _isLoading = false;
      });
      controller.clear();
      onLoadListBoard();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Board berhasil dihapus')),
      );
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
      );

      setState(() {
        _boards = boards;
        _isLoading = false;
      });

      controller.clear();
      onLoadListBoard();
      if (sortNumber == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Board berhasil diperbarui')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui board: $e')),
      );
    }
  }

  void _updateSortNumbers(int fromIndex, int toIndex) {
    if (fromIndex == toIndex) return;

    // Ambil board yang dipindahkan
    var movedBoard = _boards[fromIndex];
    int movedBoardId = movedBoard['id'];
    int movedBoardSortNumber = movedBoard['sort_number'];

    // Tentukan rentang update
    int minSort = fromIndex < toIndex
        ? movedBoardSortNumber
        : _boards[toIndex]['sort_number'];
    int maxSort = fromIndex < toIndex
        ? _boards[toIndex]['sort_number']
        : movedBoardSortNumber;

    // Update sort_number untuk boards dalam rentang yang terdampak
    for (var board in _boards) {
      int currentSort = board['sort_number'];

      if (currentSort >= minSort && currentSort <= maxSort) {
        int newSortNumber;
        if (board['id'] == movedBoardId) {
          newSortNumber = toIndex + 1; // Pindahkan board ke posisi baru
        } else {
          newSortNumber = fromIndex < toIndex
              ? currentSort - 1
              : currentSort + 1; // Geser yang lain
        }

        // Panggil API untuk update
        _editBoard(
          boardId: board['id'],
          sortNumber: newSortNumber,
        );
      }
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

  @override
  Widget build(BuildContext context) {
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
                      fontSize: MediaQuery.of(context).size.width * 0.04),
                ),
              ),
            ),
          ],
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _boards.isEmpty
                ? Center(child: Text('Tidak ada board untuk workspace ini'))
                : ScrollConfiguration(
                    behavior: ScrollBehavior().copyWith(overscroll: false),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        WidgetBoard(
                          controller: controller,
                          boardController: boardController,
                          addTask: (boardId) async {
                            _showCreateTaskDialog(boardId);
                          },
                          onLoadBoard: () async {
                            return onLoadListBoard();
                          },
                          deleteBoard: (boardId) async {
                            _deleteBoard(boardId);
                          },
                          renameBoard: (boardId, newName) async {
                            _editBoard(boardId: boardId, name: newName);
                          },
                          moveBoard: (boardId, newWorkspaceId) async {
                            _editBoard(
                                boardId: boardId, workspaceId: newWorkspaceId);
                          },
                        ),
                      ],
                    )));
  }
}
