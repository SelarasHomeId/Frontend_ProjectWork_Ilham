import 'package:flutter/material.dart';
import 'package:selarashomeid/service/api_service.dart';
import 'package:selarashomeid/widget_board.dart';
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
          debugPrint('Move item from $fromIndex to $toIndex');
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
      setState(() {
        _boards.removeWhere((board) => board['id'] == boardId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Board berhasil dihapus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus board: $e')),
      );
    }
  }

  void _showCreateBoardDialog() {
    TextEditingController _controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Tambahkan Board'),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(hintText: 'Masukkan nama board'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = _controller.text.trim();
                if (name.isNotEmpty) {
                  _createBoard(name);
                  Navigator.of(context).pop();
                }
              },
              child: Text('Tambah'),
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
          title: Text('Tambahkan Task'),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(hintText: 'Masukkan nama Task'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = _controller.text.trim();
                if (name.isNotEmpty) {
                  _createTask(boardId, name);
                  Navigator.of(context).pop();
                }
              },
              child: Text('Tambah'),
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
            OutlinedButton(
              onPressed: () {
                _showCreateBoardDialog();
              },
              child: Text(
                "Tambah Board",
              ),
            )
          ],
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _boards.isEmpty
                ? Center(child: Text('Tidak ada board untuk workspace ini'))
                : WidgetBoard(
                    controller: controller,
                    boardController: boardController,
                    addTask: (boardId) async {
                      _showCreateTaskDialog(boardId);
                    },
                    onLoadBoard: () async {
                      return onLoadListBoard();
                    },
                  )
        // SingleChildScrollView(
        //     scrollDirection: Axis.horizontal,
        //     child: Row(
        //       children: [
        //         ..._boards.map((board) {
        //           return GestureDetector(
        //             onLongPress: () {
        //               _deleteBoard(board['id']);
        //             },
        //             child: _buildBoard(
        //               board['name'],
        //               Color.fromRGBO(216, 216, 216, 1),
        //               board['task_total'],
        //             ),
        //           );
        //         }),
        //         _buildAddBoardContainer(),
        //       ],
        //     ),
        // ),
        );
  }

  Widget _buildBoard(String title, Color color, int taskTotal) {
    return Container(
      width: 200,
      height: 200,
      margin: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title section
          Container(
            padding: EdgeInsets.all(16.0),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ),
          // Task section
          Center(
            child: Container(
              padding: EdgeInsets.all(16.0),
              child: Text(
                '$taskTotal Tasks',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddBoardContainer() {
    return GestureDetector(
      onTap: _showCreateBoardDialog,
      child: Container(
        width: 200,
        height: 200,
        margin: EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'Tambahkan Board',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
