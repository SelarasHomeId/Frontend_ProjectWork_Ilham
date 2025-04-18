import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';
import 'package:selarashomeid/screens/home_screen.dart';
import 'package:selarashomeid/screens/label_screen.dart';
import 'package:selarashomeid/service/api_service.dart';
import 'package:selarashomeid/utils/file_picker.dart';
import 'package:selarashomeid/utils/general.dart';
import 'package:selarashomeid/widgets/loading_screen_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:just_audio/just_audio.dart';

class DetailTaskScreen extends StatefulWidget {
  final int boardId;
  final int taskId;
  // final String workspace;
  // final int workspaceId;

  const DetailTaskScreen({
    super.key,
    required this.boardId,
    required this.taskId,
    // required this.workspace,
    // required this.workspaceId,
  });

  @override
  State<DetailTaskScreen> createState() => _DetailTaskScreenState();
}

class _DetailTaskScreenState extends State<DetailTaskScreen> {
  late Future<Map<String, String>> userProfileFuture;

  late ValueNotifier<bool> onExpandableValue;

  late TextEditingController textDescController;
  late TextEditingController textTitleController;
  late TextEditingController textCommentController;
  late TextEditingController textChecklistController;
  late TextEditingController _itemTextController = TextEditingController();

  late FocusNode focusNode;
  late FocusNode titleFocusNode;
  late FocusNode descFocusNode;

  late ValueNotifier<bool> onLoadingNotifier;
  late ValueNotifier<List<Map<String, dynamic>>> onFileNotifier;
  late ValueNotifier<bool> onLoadingFileNotifier;
  late ValueNotifier<List<Map<String, dynamic>>> onCommentNotifier;
  late ValueNotifier<List<Map<String, dynamic>>> onChecklistNotifier;
  late ValueNotifier<Map<int, List<Map<String, dynamic>>>> checklistItems;

  late ValueNotifier<bool> onLoadingCommentNotifier;
  late ValueNotifier<bool> onLoadingChecklistNotifier;

  late ValueNotifier<List<(String labelName, Color color, int id)>>
      notifierLabelColor;
  late List<int> currentLabelIds;

  late ValueNotifier<List<Map<String, dynamic>>> assignedMembersNotifier;
  late ValueNotifier<bool> isMemberExpanded;
  late Set<int> _selectedUserIds;

  String? currentDesc;
  String? currentTitle;
  String? currentComment;
  String? currentDate;
  File? _selectedCover;
  late ValueNotifier<DateTime?> onEndDateNotifier;
  late ValueNotifier<bool> currentWatch;
  late ValueNotifier<bool> currentIsCompleted;
  late ValueNotifier<int> currentWorkspaceId;
  late ValueNotifier<int> currentBoardId;
  late ValueNotifier<String?> currentCover;
  late ValueNotifier<bool> showSaveDescButton;

  late int workspaceId;
  late String workspaceName;
  late String boardName;
  late String latestUpdatedAt;
  late String latestUpdatedBy;

  bool imageLoaded = false;
  bool _isLoading = true;
  TextEditingController _searchController = TextEditingController();
  List<dynamic> users = [];
  List<dynamic> filteredUsers = [];
  List<Map<String, dynamic>> assignedMembers = [];

  loadInitialData() async {
    await onLoadValue();
    await loadFile();
    setState(() {});
  }

  @override
  void initState() {
    userProfileFuture = General.getUserProfile();

    onExpandableValue = ValueNotifier<bool>(false);
    onLoadingNotifier = ValueNotifier<bool>(false);

    notifierLabelColor =
        ValueNotifier<List<(String labelName, Color color, int id)>>([]);
    currentLabelIds = [];
    onEndDateNotifier = ValueNotifier<DateTime?>(null);
    onFileNotifier = ValueNotifier<List<Map<String, dynamic>>>([]);
    onLoadingFileNotifier = ValueNotifier<bool>(false);
    onCommentNotifier = ValueNotifier<List<Map<String, dynamic>>>([]);
    onChecklistNotifier = ValueNotifier<List<Map<String, dynamic>>>([]);
    checklistItems = ValueNotifier<Map<int, List<Map<String, dynamic>>>>({});
    onLoadingCommentNotifier = ValueNotifier<bool>(false);
    onLoadingChecklistNotifier = ValueNotifier<bool>(false);
    _itemTextController = TextEditingController();

    textDescController = TextEditingController();
    textTitleController = TextEditingController();
    textCommentController = TextEditingController();
    textChecklistController = TextEditingController();
    currentWatch = ValueNotifier<bool>(false);
    currentIsCompleted = ValueNotifier<bool>(false);
    currentCover = ValueNotifier<String?>(null);
    assignedMembersNotifier = ValueNotifier<List<Map<String, dynamic>>>([]);
    isMemberExpanded = ValueNotifier<bool>(true);
    titleFocusNode = FocusNode();
    descFocusNode = FocusNode();

    currentBoardId = ValueNotifier<int>(0);
    currentWorkspaceId = ValueNotifier<int>(0);
    showSaveDescButton = ValueNotifier<bool>(false);

    showSaveDescButton = ValueNotifier<bool>(false);
    _selectedUserIds = {};

    workspaceName = "";
    boardName = "";
    latestUpdatedAt = "";
    latestUpdatedBy = "";

    textDescController.addListener(() {
      final now = textDescController.text.trim();
      final original = (currentDesc ?? '').trim();
      showSaveDescButton.value = now != original;
    });
    Future.wait(
      [
        onLoadValue(),
        loadFile(),
      ],
    );
    super.initState();

    fetchUsers();
    loadInitialData();
  }

  Future<void> onLoadValue() async {
    onLoadingNotifier.value = true;
    final getUpdatedData = await ApiService.handleDetailTask(
      widget.taskId,
    );

    final desc = getUpdatedData["description"];
    textDescController.text = desc ?? "";
    currentDesc = desc ?? "";
    final isCompleted = getUpdatedData["is_completed"];
    final assignToUser = getUpdatedData['assign_to_user'];
    final title = getUpdatedData["title"];
    final watch = getUpdatedData["watch"];
    final label = getUpdatedData["label"];
    final workspaceIdCurrent = getUpdatedData["workspace"]["id"];
    final boardId = getUpdatedData["board_id"];
    final cover = getUpdatedData["cover"];
    final updatedAt = getUpdatedData["updated_at"];
    final updatedBy = getUpdatedData["updated_by"]["name"] != ""
        ? getUpdatedData["updated_by"]["name"]
        : getUpdatedData["created_by"]["name"];

    final date = getUpdatedData["due_date"];
    if (date != null && date.isNotEmpty) {
      onEndDateNotifier.value = DateTime.parse(date);
    } else {
      onEndDateNotifier.value = null;
    }

    final workspaceData = getUpdatedData["workspace"];
    workspaceId = workspaceData["id"];
    workspaceName = workspaceData["name"];
    final response =
        await ApiService.handleBoard(method: "GET", workspaceId: workspaceId);
    if (response.isNotEmpty) {
      List<Map<String, dynamic>> dataBoard =
          List<Map<String, dynamic>>.from(response);
      if (dataBoard.any((b) => b['id'] == boardId)) {
        final matchedBoard = dataBoard.firstWhere((b) => b['id'] == boardId);
        boardName = matchedBoard['name'];
      }
    }

    latestUpdatedAt = updatedAt;
    latestUpdatedBy = updatedBy;

    final labelData =
        (label != null && label["data"] != null) ? label["data"] as List : [];
    if (labelData.isNotEmpty) {
      currentLabelIds =
          labelData.map<int>((item) => item["id"] as int).toList();
      notifierLabelColor.value = labelData.map((item) {
        final parsedColor = int.tryParse(item["color"]) ?? 0;
        return (
          item["title"].toString(),
          parsedColor == 0
              ? Colors.black
              : General().stringToColor(item["color"]),
          item["id"] as int,
        );
      }).toList();
    }

    await loadComments();
    await loadChecklists();

    textTitleController.text = General.capitalizeEachWord(title ?? "");
    currentTitle = title;
    currentWatch.value = watch;
    currentDesc = desc;
    currentWorkspaceId.value = workspaceIdCurrent;
    currentBoardId.value = boardId;
    currentDate = date;
    currentCover.value = cover != null ? cover["view"].toString() : null;
    currentIsCompleted.value = isCompleted;
    final assignedMemberData =
        assignToUser != null ? assignToUser["data"] as List : [];
    if (assignedMemberData.isNotEmpty) {
      assignedMembers = assignedMemberData.map((item) {
        return item as Map<String, dynamic>;
      }).toList();
    }
    assignedMembersNotifier.value = assignedMemberData.map((item) {
      return item as Map<String, dynamic>;
    }).toList();
    onLoadingNotifier.value = false;
  }

  @override
  void dispose() {
    onExpandableValue.dispose();
    onLoadingNotifier.dispose();

    textDescController.dispose();
    textTitleController.dispose();
    textCommentController.dispose();
    textChecklistController.dispose();
    _itemTextController.dispose();
    // focusNode.dispose();
    titleFocusNode.dispose();
    descFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        _selectedCover = File(pickedImage.path);
      });

      final fileStream = await http.MultipartFile.fromPath(
        'cover', // nama field yang diharapkan backend
        _selectedCover!.path,
      );

      onLoadingNotifier.value = true;
      final response = await ApiService.handleTask(
        method: 'PUT',
        taskId: widget.taskId,
        data: {}, // tetap dikirim walau kosong
        listFile: [fileStream], // ini penting!
      );
      onLoadingNotifier.value = false;

      if (response != null) {
        await onLoadValue();
        setState(() {});
        General.showSnackBar(context, "cover added");
      }
    }
  }

  void deleteCover(int taskId) async {
    final confirm = await showDialog<bool>(
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
                  color: Colors.red, // Mengubah warna menjadi merah
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.delete, // Menambahkan ikon tong sampah
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Hapus Cover',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Apakah Anda yakin ingin menghapus cover untuk task ini?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      backgroundColor:
                          Colors.grey[600], // Warna abu-abu untuk Cancel
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Batal',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(
                      backgroundColor:
                          Colors.red[800], // Warna merah untuk Delete
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Hapus',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );

    if (confirm == true) {
      try {
        final response = await ApiService.handleTask(
          method: 'PUT',
          data: {"delete_cover": true},
          taskId: widget.taskId,
        );
        if (response != null) {
          await onLoadValue();
          setState(() {});
          General.showSnackBar(context, "cover deleted");
        }
      } catch (e) {
        General.showSnackBar(context, "cover error when delete, cause: $e");
      }
    }
  }

  void deleteTask(int taskId) async {
    final confirm = await showDialog<bool>(
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
                  color: Colors.red, // Mengubah warna menjadi merah
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.delete, // Menambahkan ikon tong sampah
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Hapus Task',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Apakah Anda yakin ingin menghapus task ini?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      backgroundColor:
                          Colors.grey[600], // Warna abu-abu untuk Cancel
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Batal',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(
                      backgroundColor:
                          Colors.red[800], // Warna merah untuk Delete
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Hapus',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );

    if (confirm == true) {
      try {
        print('[DELETE_TASK] User konfirmasi penghapusan');
        final response =
            await ApiService.handleTask(method: 'DELETE', taskId: taskId);
        print('[DELETE_TASK] Response dari API: $response');

        if (response != null && response['message'] == 'success delete!') {
          print('[DELETE_TASK] Task berhasil dihapus. Menampilkan snackbar');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Task berhasil dihapus!')),
          );

          // ⏳ Kasih jeda 500ms sebelum navigasi
          await Future.delayed(Duration(milliseconds: 500));

          print('[DELETE_TASK] Navigasi ke WorkspaceWidget');
          final prefs = await SharedPreferences.getInstance();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => HomeScreen(
                roleId: prefs.getInt("roleId")!,
                token: prefs.getString("token")!,
                toWorkspaceName: workspaceName,
                toWorkspaceId: workspaceId,
              ),
            ),
            (route) => false,
          );
        } else {
          print('[DELETE_TASK] Response tidak sesuai ekspektasi.');
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Gagal menghapus task.')));
        }
      } catch (e) {
        print('[DELETE_TASK] Terjadi error saat hapus task: $e');
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Terjadi error: $e')));
      }
    }
  }

  Future<void> toggleCompleteStatus() async {
    final newStatus = !currentIsCompleted.value;
    final data = {"is_completed": newStatus};

    final response = await ApiService.handleTask(
      method: 'PUT',
      data: data,
      taskId: widget.taskId,
    );

    if (response != null) {
      await onLoadValue();
      setState(() {});
      General.showSnackBar(
        context,
        newStatus ? "Task marked as complete" : "Task marked as incomplete",
      );
    }
  }

  //assign to user============================================================
  Future<void> fetchUsers() async {
    setState(() => _isLoading = true);
    print("Fetching users...");

    try {
      final result = await ApiService.handleUser(
          method: 'GET', params: {'no_paging': 'yes'});

      print("Fetched users: $result"); // Cek apakah data berhasil diambil

      if (result != null) {
        setState(() {
          users = result['data'];
          filteredUsers = users; // Store original users
        });
      }
    } catch (e) {
      print("Error fetching users: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
    } finally {
      setState(() => _isLoading = false);
      print("Loading complete");
    }

    _searchController.addListener(() {
      _searchUserByName(setState);
    });
  }

  void _showAddMemberDialog() {
    _selectedUserIds =
        assignedMembersNotifier.value.map((u) => u['id'] as int).toSet();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Add Member",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search User...",
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => _searchUserByName(dialogSetState),
                    ),
                  ),
                  SizedBox(height: 10),
                  _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : filteredUsers.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text("No users found."),
                            )
                          : SizedBox(
                              height: 200,
                              child: ListView.builder(
                                itemCount: filteredUsers.length,
                                itemBuilder: (context, index) {
                                  final user = filteredUsers[index];
                                  final isSelected =
                                      _selectedUserIds.contains(user['id']);

                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          General.getColorFromInitial(
                                              General.getInitials(
                                                  user['name'])),
                                      child: Text(
                                        General.getInitials(user['name']),
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    title: Text(user['name']),
                                    subtitle: Text(user['email']),
                                    trailing: isSelected
                                        ? Icon(Icons.check_circle,
                                            color: Colors.green)
                                        : null,
                                    onTap: () {
                                      dialogSetState(() {
                                        if (isSelected) {
                                          _selectedUserIds.remove(user['id']);
                                        } else {
                                          _selectedUserIds.add(user['id']);
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                ],
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      child:
                          Text("Cancel", style: TextStyle(color: Colors.red)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    TextButton(
                      child:
                          Text("Done", style: TextStyle(color: Colors.green)),
                      onPressed: () async {
                        try {
                          final res = await ApiService.handleTask(
                            method: "PUT",
                            taskId: widget.taskId,
                            data: {
                              "assign_to_user": _selectedUserIds.toList(),
                            },
                          );

                          if (res != null) {
                            await onLoadValue();
                            setState(() {});
                            General.showSnackBar(
                                context, "User berhasil di-assign");
                          }

                          Navigator.pop(context);
                        } catch (e) {
                          General.showSnackBar(
                              context, "Gagal assign user: $e");
                        }
                      },
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _searchUserByName(void Function(void Function()) dialogSetState) {
    final keyword = _searchController.text.toLowerCase();

    dialogSetState(() {
      filteredUsers = keyword.isEmpty
          ? users
          : users
              .where((user) => user['name'].toLowerCase().contains(keyword))
              .toList();
    });
  }

  Widget _buildMemberSection() {
    return ValueListenableBuilder2<List<Map<String, dynamic>>, bool>(
      first: assignedMembersNotifier,
      second: isMemberExpanded,
      builder: (context, members, expanded, _) {
        return ExpansionPanelList(
          elevation: 1,
          expandedHeaderPadding: EdgeInsets.all(0),
          expansionCallback: (int index, bool isExpanded) {
            isMemberExpanded.value = isExpanded;
          },
          children: [
            ExpansionPanel(
              headerBuilder: (context, isExpanded) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Assigned Members',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                );
              },
              isExpanded: expanded,
              body: members.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('No members assigned yet.'),
                    )
                  : Column(
                      children: members.map((member) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: General.getColorFromInitial(
                                General.getInitials(member['name'])),
                            child: Text(
                              General.getInitials(member['name']),
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(member['name']),
                          subtitle:
                              Text(member['role'] + ' - ' + member['divisi']),
                          trailing: IconButton(
                            icon: Icon(Icons.close, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: Text("Konfirmasi"),
                                  content: Text(
                                      "Apakah yakin ingin menghapus user ini?"),
                                  actions: [
                                    TextButton(
                                      child: Text("Batal"),
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                    ),
                                    TextButton(
                                      child: Text("Hapus"),
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                try {
                                  // Buat array baru tanpa user yang dihapus
                                  final remainingIds = assignedMembersNotifier
                                      .value
                                      .where((u) => u['id'] != member['id'])
                                      .map((u) => u['id'] as int)
                                      .toList();

                                  final res = await ApiService.handleTask(
                                    method: "PUT",
                                    taskId: widget.taskId,
                                    data: {
                                      "assign_to_user": remainingIds,
                                    },
                                  );

                                  if (res != null) {
                                    await onLoadValue();
                                    setState(() {});
                                    General.showSnackBar(
                                        context, "Berhasil menghapus user");
                                  }
                                } catch (e) {
                                  General.showSnackBar(
                                      context, "Gagal menghapus: $e");
                                }
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        );
      },
    );
  }

//end assogn to user==========================================================

//==================Start File Preview=========================================
  void showPDFPreview(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.8,
          child: SfPdfViewer.network(
            url,
            canShowScrollHead: true,
            canShowScrollStatus: true,
          ),
        ),
      ),
    );
  }

  void showAudioPreview(BuildContext context, String url) {
    final player = AudioPlayer();
    player.setUrl(url);
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Preview Audio",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                StreamBuilder<PlayerState>(
                  stream: player.playerStateStream,
                  builder: (context, snapshot) {
                    final playerState = snapshot.data;
                    final playing = playerState?.playing ?? false;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(playing
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_fill),
                          iconSize: 48,
                          onPressed: () {
                            if (playing) {
                              player.pause();
                            } else {
                              player.play();
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.stop_circle),
                          iconSize: 48,
                          onPressed: () {
                            player.stop();
                          },
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    player.dispose();
                    Navigator.of(context).pop();
                  },
                  child: Text("Tutup"),
                )
              ],
            ),
          ),
        );
      },
    ).then((_) {
      player.dispose(); // pastikan dispose saat keluar dialog
    });
  }
//===================End File Preview==========================================

//=======================Widget Build===========================================
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !titleFocusNode.hasFocus && !descFocusNode.hasFocus,
      onPopInvokedWithResult: (didPop, result) async {
        if (titleFocusNode.hasFocus) titleFocusNode.unfocus();
        if (descFocusNode.hasFocus) descFocusNode.unfocus();

        if (didPop) return;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          titleFocusNode.unfocus();
          descFocusNode.unfocus();
        },
        child: ValueListenableBuilder(
          valueListenable: onLoadingNotifier,
          builder: (context, value, child) {
            return Stack(
              children: [
                child ?? Container(),
                if (value) ...{
                  loadingScreenWidget(context),
                },
              ],
            );
          },
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.red[900],
              title: TextField(
                controller: textTitleController,
                focusNode: titleFocusNode,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                ),
                onEditingComplete: () async {
                  // Fungsi ini dipanggil ketika TextField selesai diedit (gagal fokus atau tekan "enter")
                  final value = textTitleController.text;

                  // Pastikan nilai tidak kosong dan lakukan update API jika sudah selesai editing
                  if (value.isNotEmpty) {
                    final data = {"title": value};

                    final response = await ApiService.handleTask(
                      method: 'PUT',
                      data: data,
                      taskId: widget.taskId,
                    );

                    if (response != null) {
                      // Jika API berhasil, kita update text controller dengan nilai yang dikirim
                      textTitleController.text =
                          value; // Pastikan text controller memiliki nilai terbaru
                    }
                    titleFocusNode.unfocus();
                  }
                },
              ),
              leading: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () async {
                  print("⬅️ Back button ditekan");
                  final currentText = textDescController.text;
                  final originalText = currentDesc ?? '';
                  print("🔍 currentText: '$currentText'");
                  print("📦 originalText: '$originalText'");

                  if (currentText != originalText) {
                    print("⚠️ Deskripsi berubah, tampilkan dialog");

                    final shouldExit = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("Perubahan Belum Disimpan"),
                        content: Text(
                            "Anda Memiliki Perubahan yang belum disimpan, yakin ingin keluar?"),
                        actions: [
                          TextButton(
                            child: Text("Tidak"),
                            onPressed: () {
                              print("🚫 Batal keluar");
                              Navigator.of(context).pop(false);
                            },
                          ),
                          TextButton(
                            child: Text("Iya"),
                            onPressed: () {
                              print("✅ Keluar tanpa simpan");
                              Navigator.of(context).pop(true);
                            },
                          ),
                        ],
                      ),
                    );

                    if (shouldExit == true && context.mounted) {
                      Navigator.pop(context);
                    }
                  } else {
                    print("🟢 Tidak ada perubahan, keluar langsung");
                    Navigator.pop(context);
                  }
                },
                color: Colors.white,
              ),
              actions: [
                Padding(
                  padding: EdgeInsets.only(top: 10.0),
                  child: PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: Colors.white,
                    ),
                    offset: Offset(0, 40),
                    onSelected: (String result) async {
                      switch (result) {
                        case 'complete_toggle':
                          await toggleCompleteStatus();
                          break;

                        case 'watch':
                          final valueWatch = !currentWatch.value;
                          final data = {"watch": valueWatch};

                          final response = await ApiService.handleTask(
                            method: 'PUT',
                            data: data,
                            taskId: widget.taskId,
                          );

                          if (response != null) {
                            currentWatch.value = valueWatch;
                          }
                          break;
                        case 'add_cover':
                          _pickCover();
                          break;
                        case 'del_cover':
                          deleteCover(widget.taskId);
                          break;
                        case 'delete':
                          deleteTask(widget.taskId);
                          break;
                        case 'member':
                          _showAddMemberDialog();
                          break;
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      PopupMenuItem<String>(
                        value: 'complete_toggle',
                        child: Row(
                          children: [
                            Icon(
                              currentIsCompleted.value
                                  ? Icons.unpublished_outlined
                                  : Icons.check,
                              color: currentIsCompleted.value
                                  ? Colors.red
                                  : Colors.green,
                            ),
                            SizedBox(width: 8),
                            Text(
                              currentIsCompleted.value
                                  ? "Mark as Incomplete"
                                  : "Mark as Complete",
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'watch',
                        child: Row(
                          children: [
                            Icon(
                              currentWatch.value == false
                                  ? Icons.visibility
                                  : Icons.visibility,
                              color: currentWatch.value == false
                                  ? Colors.blueGrey
                                  : Colors.blue[900],
                            ),
                            SizedBox(width: 8),
                            Text(currentWatch.value == false
                                ? "Watch"
                                : "Stop Watching"),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: currentCover.value == null
                            ? 'add_cover'
                            : 'del_cover',
                        child: Row(
                          children: [
                            Icon(currentCover.value == null
                                ? Icons.image
                                : Icons.broken_image),
                            SizedBox(width: 8),
                            Text(currentCover.value == null
                                ? "Add Cover"
                                : "Delete Cover"),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete),
                            SizedBox(width: 8),
                            Text('Delete Task'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'member',
                        child: Row(
                          children: [
                            Icon(Icons.person_add),
                            SizedBox(width: 8),
                            Text('Add Member'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: _handleRefresh, // Tambahkan ini
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  physics:
                      const AlwaysScrollableScrollPhysics(), // Penting untuk refresh indicator
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cover
                      Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: currentCover.value == null
                              ? Image.asset(
                                  'assets/no_cover.png', // Gambar default dari assets
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 120,
                                )
                              : Image.network(
                                  currentCover.value.toString(),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 120,
                                )),
                      SizedBox(height: 20),

                      //Show Workspace and Board Data
                      _buildShowSummaryTask(),
                      SizedBox(height: 20),
                      // Quick Actions
                      _buildQuickActions(onExpandableValue),
                      SizedBox(height: 20),

                      // Assigned Member/user
                      _buildMemberSection(),
                      SizedBox(height: 20),

                      // Description
                      Text("Description",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      _buildCardDescription(
                        textDescController: textDescController,
                        focusNode: descFocusNode,
                        onSubmitButton: () async {
                          final getUpdatedData = await ApiService.handleTask(
                            method: 'PUT',
                            taskId: widget.taskId,
                            boardId: widget.boardId,
                            data: {'description': textDescController.text},
                          );

                          if (getUpdatedData != null && context.mounted) {
                            General.showSnackBar(
                                context, 'Update Deskripsi: Berhasil');
                            currentDesc = textDescController.text;
                          } else {
                            General.showSnackBar(
                                context, 'Gagal Update Deskripsi ');
                            currentDesc = textDescController.text;
                          }
                        },
                      ),
                      SizedBox(height: 20),

                      // Labels
                      Text("Labels",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      _buildLabelsButton(
                        onAddingLabel: (labelId) async {
                          onLoadingNotifier.value = true;
                          if (!currentLabelIds.contains(labelId)) {
                            currentLabelIds.add(labelId);
                          }
                          final getUpdatedData = await ApiService.handleTask(
                              method: 'PUT',
                              taskId: widget.taskId,
                              boardId: widget.boardId,
                              data: {'label': currentLabelIds},
                              contentType: 'application/json');

                          if (getUpdatedData != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Update Label: Berhasil')),
                            );
                            await onLoadValue();
                          }
                        },
                      ),
                      SizedBox(height: 20),

                      // Due Dates
                      Text("Due Date",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(
                        height: 10,
                      ),
                      _buildDatePickers(),
                      SizedBox(height: 20),

                      // Attachment
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "Attachment",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            "(hold to preview & click to download)",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                      listFileWidget(),
                      SizedBox(height: 20),

                      // Checklist
                      Text("Checklist",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      _buildAddChecklistSection(widget
                          .taskId), // Menggunakan widget untuk menambah checklist
                      ValueListenableBuilder(
                        valueListenable:
                            onLoadingChecklistNotifier, // Gunakan notifikasi loading untuk checklist
                        builder: (context, value, child) {
                          return Container(
                            constraints: BoxConstraints(maxHeight: 300),
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            // Menampilkan daftar checklist
                            child: _buildChecklistList(),
                          );
                        },
                      ),
                      SizedBox(height: 20),

                      // Comments
                      Text("Comments",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      _buildAddCommentSection(widget.taskId),
                      ValueListenableBuilder(
                        valueListenable: onLoadingNotifier,
                        builder: (context, value, child) {
                          return Container(
                            constraints: BoxConstraints(maxHeight: 300),
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: _buildCommentList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

//=======================End Widget Build===========================================
  Future<Map<String, int>?> _showMoveDialog(
      int workspaceId, int boardId) async {
    List<Map<String, dynamic>> workspaces = [];
    List<Map<String, dynamic>> boards = [];
    int? selectedWorkspaceId = workspaceId;
    int? selectedBoardId = boardId;

    try {
      final response = await ApiService.workspaceFind();
      if (response.isNotEmpty) {
        workspaces = List<Map<String, dynamic>>.from(response);
        if (!workspaces.any((w) => w['id'] == selectedWorkspaceId)) {
          selectedWorkspaceId = workspaces.first['id']; // Default workspace
        }
      }
    } catch (e) {
      if (mounted) {
        General.showSnackBar(context, 'Gagal memuat workspace: $e');
      }
    }

    Future<void> loadBoards(int workspaceId) async {
      try {
        final response = await ApiService.handleBoard(
            method: "GET", workspaceId: workspaceId);
        if (response.isNotEmpty) {
          boards = List<Map<String, dynamic>>.from(response);
          if (!boards.any((b) => b['id'] == selectedBoardId)) {
            selectedBoardId = boards.first['id']; // Default board
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal memuat board: $e')),
          );
        }
      }
    }

    await loadBoards(selectedWorkspaceId!);

    return await showDialog<Map<String, int>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Move to"),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dropdown Workspace
                  DropdownButtonFormField<int>(
                    value: selectedWorkspaceId,
                    items: workspaces.map((workspace) {
                      return DropdownMenuItem<int>(
                        value: workspace['id'],
                        child: Text(workspace['name']),
                      );
                    }).toList(),
                    onChanged: (int? newValue) async {
                      setState(() {
                        selectedWorkspaceId = newValue;
                        selectedBoardId = null;
                      });
                      await loadBoards(selectedWorkspaceId!);
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      labelText: "Select Workspace",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Dropdown Board
                  DropdownButtonFormField<int>(
                    value: selectedBoardId,
                    items: boards.map((board) {
                      return DropdownMenuItem<int>(
                        value: board['id'],
                        child: Text(board['name']),
                      );
                    }).toList(),
                    onChanged: (int? newValue) {
                      setState(() {
                        selectedBoardId = newValue;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: "Select Board",
                      border: OutlineInputBorder(),
                    ),
                    isExpanded: true,
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null), // Batal
              child: Text("Batal"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(
                context,
                {
                  'workspace_id': selectedWorkspaceId!,
                  'board_id': selectedBoardId!
                },
              ), // Konfirmasi
              child: Text("Move", style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

//================= Load File dan Comment======================================
  Future<void> loadFile() async {
    onLoadingFileNotifier.value = true;
    final getFileList = await ApiService.handleTaskFile(
        method: "GET", taskId: widget.taskId, params: {'no_paging': 'yes'});

    onFileNotifier.value = (getFileList is List
        ? getFileList.map((e) {
            return {
              "id": e["id"],
              "fileName": e["file"]["name"],
              "filePath": e["file"]["view"],
              "fileExt": e["file"]["ext"],
              "fileDownload": e["file"]["content"],
            };
          }).toList()
        : <Map<String, dynamic>>[]);

    onLoadingFileNotifier.value = false;
  }

  Future<void> loadComments() async {
    onLoadingCommentNotifier.value = true;

    final response = await ApiService.handleDetailTask(widget.taskId);

    final getComment = response['comment'];
    if (response != null && getComment != null) {
      final getCommentData = getComment['data'];
      final commentData = getCommentData != null && getCommentData is List
          ? getCommentData
          : [];

      onCommentNotifier.value = commentData.map((e) {
        return {
          "id": e["id"],
          "comment": e["comment"],
          "created_at": e["created_at"],
          // Jika perlu menampilkan user, mungkin perlu penyesuaian dari API
          "user_name": e['created_by']['name'], // Ambil dari created_by task
        };
      }).toList();
    }

    onLoadingCommentNotifier.value = false;
  }

  Future<void> loadChecklists() async {
    onLoadingChecklistNotifier.value = true;

    final response = await ApiService.handleDetailTask(widget.taskId);

    final getChecklist = response['checklist'];
    if (response != null && getChecklist != null) {
      final getChecklistData = getChecklist['data'];
      final checklistData = getChecklistData != null && getChecklistData is List
          ? getChecklistData
          : [];

      checklistItems.value.clear(); // Reset checklistItems dulu

      for (final checklist in checklistData) {
        checklistItems.value[checklist["id"]] = List<Map<String, dynamic>>.from(
          checklist["item"]?["data"] ?? [],
        );
      }

      onChecklistNotifier.value = checklistData.map((checklist) {
        return {
          "id": checklist["id"],
          "title": checklist["title"],
          "is_completed": checklist["is_completed"] ?? false,
        };
      }).toList();
    }

    onLoadingChecklistNotifier.value = false;
  }

  //==============================End Load File dan Comment=====================

  // Fungsi untuk onRefresh RefreshIndicator==================================
  Future<void> _handleRefresh() async {
    await Future.wait([
      onLoadValue(),
      loadComments(),
      loadChecklists(),
      loadFile(),
    ]);
  }
//End Refresh Indicator======================================================

//Start Summary And Quick Aactions
  Widget _buildShowSummaryTask() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.all(5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kiri: Informasi workspace dan board
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (workspaceName != "") ...[
                    Text(
                      workspaceName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                  if (boardName != "") ...[
                    SizedBox(height: 4),
                    Text(
                      boardName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                  if (latestUpdatedAt != "" || latestUpdatedBy != "") ...[
                    SizedBox(height: 12),
                    Text(
                      'Latest Update: ${DateFormat('yyyy-MM-dd hh:mm:ss').format(DateTime.parse(latestUpdatedAt).toLocal())}\nBy $latestUpdatedBy',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Kanan: Tombol "Move"
            ElevatedButton(
              onPressed: () async {
                Map<String, int>? dataDialog = await _showMoveDialog(
                  currentWorkspaceId.value,
                  currentBoardId.value,
                );

                if (dataDialog != null) {
                  final data = {"board_id": dataDialog["board_id"]};

                  final response = await ApiService.handleTask(
                    method: 'PUT',
                    data: data,
                    taskId: widget.taskId,
                  );

                  if (response != null) {
                    General.showSnackBar(context, "Task berhasil dipindahkan");
                    await onLoadValue();
                    setState(() {});
                  } else {
                    General.showSnackBar(context, "Gagal memindahkan task");
                  }
                } else {
                  print("❌ Aksi pindah dibatalkan user");
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text("Move"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(ValueNotifier<bool> onExpandableValue) {
    return ValueListenableBuilder(
        valueListenable: onExpandableValue,
        builder: (context, expandletrue, _) {
          return ExpansionPanelList(
              expansionCallback: (int index, bool isExpanded) {
                onExpandableValue.value = isExpanded;
              },
              children: [
                ExpansionPanel(
                  headerBuilder: (BuildContext context, bool isExpanded) {
                    return InkWell(
                      onTap: () {
                        final currentValueExpandale = onExpandableValue.value;
                        onExpandableValue.value = !currentValueExpandale;
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text('Quick Actions'),
                      ),
                    );
                  },
                  body: Wrap(
                    children: [
                      ElevatedButton(
                          onPressed: () {}, child: Text('Add Checklist')),
                      SizedBox(width: 10),
                      ElevatedButton(
                          onPressed: () async {
                            onLoadingNotifier.value = true;
                            onLoadingFileNotifier.value = true;

                            AsPathResponse? croppedValue;
                            await uploadPhotoFromFile(
                              context,
                              filePicked: (onFilePicker, type) {
                                final path = onFilePicker.path;
                                final mimeType = lookupMimeType(path!);
                                MediaType fileType = MediaType.parse(mimeType!);

                                croppedValue = AsPathResponse(
                                  path: path,
                                  fileName: onFilePicker.name
                                      .toString()
                                      .replaceAll(" ", "_"),
                                  fileExtension:
                                      type.toString().replaceAll("jpeg", "jpg"),
                                  fileType: fileType,
                                );
                              },
                              cropImages: (onSelectedPhoto) async {
                                croppedValue = await cropImages(
                                  context: context,
                                  path: onSelectedPhoto,
                                );
                              },
                            );

                            final currentCropped = croppedValue;
                            if (currentCropped != null) {
                              final listFile = await Future.wait([
                                http.MultipartFile.fromPath(
                                  'file',
                                  currentCropped.path!,
                                  contentType: currentCropped.fileType,
                                )
                              ]);

                              await ApiService.handleTaskFile(
                                method: 'POST',
                                // workspaceId: widget.workspaceId,
                                taskId: widget.taskId,
                                listFile: listFile,
                                data: {
                                  "task_id": widget.taskId.toString(),
                                },
                              );
                            }
                            loadFile();
                            onLoadingNotifier.value = false;
                            onLoadingFileNotifier.value = false;
                          },
                          child: Text('Add Attachment')),
                      SizedBox(width: 10),
                      ElevatedButton(
                          onPressed: _showAddMemberDialog,
                          child: Text('Add Members')),
                    ],
                  ),
                  isExpanded: expandletrue,
                ),
              ]);
        });
  }
// end quick actions and summary========================================

  Widget _buildCardDescription({
    required TextEditingController textDescController,
    required FocusNode focusNode,
    required Future<void> Function() onSubmitButton,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: textDescController,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: 'Masukan Deskripsi',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.all(10),
          ),
          maxLines: 3,
        ),
        SizedBox(height: 10),
        ValueListenableBuilder<bool>(
          valueListenable: showSaveDescButton,
          builder: (context, show, child) {
            return show
                ? ElevatedButton(
                    onPressed: () async {
                      await onSubmitButton();
                      // Setelah submit berhasil, reset currentDesc
                      currentDesc = textDescController.text;
                      showSaveDescButton.value = false;
                    },
                    child: Text("Simpan"),
                  )
                : SizedBox();
          },
        ),
      ],
    );
  }

  Widget _buildLabelsButton(
      {required Future<void> Function(int) onAddingLabel}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton(
          onPressed: () async {
            final id = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LabelScreen(),
              ),
            );
            if (id != null) {
              await onAddingLabel(id);
            }
          },
          child: Text('Labels'),
        ),
        SizedBox(height: 8), // Jarak antara tombol dan label
        ValueListenableBuilder(
          valueListenable: notifierLabelColor,
          builder: (context, value, child) {
            if (value.isNotEmpty) {
              return SizedBox(
                height: 40, // Sesuaikan tinggi agar label terlihat
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: value.map((label) {
                      return GestureDetector(
                        onTap: () async {
                          final confirmDelete = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text("Hapus Label?"),
                              content: Text(
                                  "Apakah Anda yakin ingin menghapus label '${label.$1}'?"),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text("Batal"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text("Hapus"),
                                ),
                              ],
                            ),
                          );

                          if (confirmDelete == true) {
                            // Hapus label dari daftar
                            currentLabelIds.remove(label.$3);

                            // Perbarui ValueNotifier
                            notifierLabelColor.value =
                                List.from(notifierLabelColor.value)
                                  ..remove(label);

                            // Kirim data terbaru ke API
                            onLoadingNotifier.value = true;
                            final getUpdatedData = await ApiService.handleTask(
                              method: 'PUT',
                              taskId: widget.taskId,
                              boardId: widget.boardId,
                              data: {'label': currentLabelIds},
                              contentType: 'application/json',
                            );

                            if (getUpdatedData != null && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Label berhasil dihapus')),
                              );
                            }
                            onLoadingNotifier.value = false;
                          }
                        },
                        child: Container(
                          margin: EdgeInsets.only(right: 8),
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            color: label.$2, // Warna dari label
                          ),
                          child: Text(
                            label.$1, // Nama label
                            style: TextStyle(
                                color: Colors.white), // Teks lebih kontras
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            }
            return Container();
          },
        ),
      ],
    );
  }

//=========== Date dan Due Date===========================================

  Widget _buildDatePickers() {
    return ValueListenableBuilder<DateTime?>(
      valueListenable: onEndDateNotifier,
      builder: (context, selectedDate, child) {
        final dateText = selectedDate != null
            ? DateFormat('EEEE, dd MMMM yyyy - HH:mm WIB').format(selectedDate)
            : 'Belum ada Deadline';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Teks Deadline
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                dateText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: selectedDate != null ? Colors.black : Colors.grey,
                ),
              ),
            ),

            // Tombol Pilih Tanggal & Hapus
            Row(
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.calendar_today),
                  label: Text("Pilih Tanggal"),
                  onPressed: () => _pickDueDate(context),
                ),
                SizedBox(width: 10),
                if (selectedDate != null)
                  ElevatedButton.icon(
                    icon: Icon(Icons.cancel),
                    label: Text(
                      "Hapus",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      onLoadingNotifier.value = true;

                      final getUpdatedData = await ApiService.handleTask(
                        method: 'PUT',
                        taskId: widget.taskId,
                        boardId: widget.boardId,
                        data: {'due_date': ''},
                      );

                      if (getUpdatedData != null) {
                        onEndDateNotifier.value = null;
                      }

                      onLoadingNotifier.value = false;
                    },
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickDueDate(BuildContext context) async {
    final initialDate = onEndDateNotifier.value ?? DateTime.now();

    final datePicker = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2500),
      fieldLabelText: "Waktu Akhir Task",
    );

    if (datePicker != null && context.mounted) {
      final currentTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (currentTime != null) {
        final selectedDate = datePicker.copyWith(
          hour: currentTime.hour,
          minute: currentTime.minute,
        );

        final now = DateTime.now();

        // ✅ VALIDASI: waktu tidak boleh di masa lalu
        if (selectedDate.isBefore(now)) {
          General.showSnackBar(context, "Waktu Deadline Tidak Valid");
          return;
        }

        final dueDate =
            DateFormat("yyyy-MM-dd HH:mm:ss").format(selectedDate.toLocal());

        onLoadingNotifier.value = true;

        try {
          final getUpdatedData = await ApiService.handleTask(
            method: 'PUT',
            taskId: widget.taskId,
            boardId: widget.boardId,
            data: {'due_date': dueDate},
          );

          if (getUpdatedData != null) {
            onEndDateNotifier.value = selectedDate;
            General.showSnackBar(
                context, "Waktu Deadline berhasil ditambahkan");
          } else {
            General.showSnackBar(context, "Gagal Menambahkan Tanggal e");
          }
        } catch (e) {
          General.showSnackBar(context, "Gagal Menambahkan Tanggal e: $e");
        }

        onLoadingNotifier.value = false;
      }
    }
  }

  //============================================================================

// =============== COMMENT =====================================================
  Widget _buildCommentList() {
    return ValueListenableBuilder(
      valueListenable: onCommentNotifier,
      builder: (context, commentList, child) {
        if (commentList.isEmpty) {
          return Center(child: Text('Belum ada komentar'));
        }

        return ListView.builder(
          shrinkWrap: true,
          // physics: NeverScrollableScrollPhysics(),
          itemCount: commentList.length,
          itemBuilder: (context, index) {
            final comment = commentList[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: General.getColorFromInitial(
                    General.getInitials(comment['user_name'])),
                child: Text(General.getInitials(comment['user_name'])),
              ),
              title: Text(comment['user_name']),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(comment['comment']),
                  Text(
                    DateFormat('dd MMM yyyy HH:mm').format(
                      DateTime.parse(comment['created_at']).toLocal(),
                    ),
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _addComment(int taskId) async {
    if (textCommentController.text.isEmpty) return;

    final data = {"comment": textCommentController.text};

    final response = await ApiService.handleComment(
      method: 'POST',
      data: data,
      taskId: taskId,
    );

    if (response != null) {
      textCommentController.clear();
      await loadComments();
    }
  }

  Widget _buildAddCommentSection(int taskId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FutureBuilder<Map<String, String>>(
              future: userProfileFuture,
              builder: (context, snapshot) {
                String initial =
                    General.getInitials(snapshot.data?['name'] ?? 'U');
                return CircleAvatar(
                  backgroundColor: General.getColorFromInitial(initial),
                  child: Text(initial),
                );
              },
            ),
            SizedBox(width: 10),
            Expanded(
              flex: 6,
              child: TextField(
                controller: textCommentController,
                decoration: InputDecoration(
                  hintText: 'Add comment',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(10),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                  onTap: () async {
                    await _addComment(taskId);
                  },
                  child: Icon(Icons.send)),
            )
          ],
        ),
        SizedBox(height: 10),
      ],
    );
  }
  //===================================End Comment==============================

//======================Start Checklist=========================================
  Widget _buildChecklistList() {
    return ValueListenableBuilder(
      valueListenable:
          onChecklistNotifier, // Memastikan onChecklistNotifier yang berisi data checklist
      builder: (context, checklistList, child) {
        if (checklistList.isEmpty) {
          return Center(child: Text('Belum ada checklist'));
        }

        return ListView.builder(
          shrinkWrap: true,
          itemCount: checklistList.length,
          itemBuilder: (context, index) {
            final checklist = checklistList[index];
            bool isCompleted = checklist['is_completed'] ?? false;

            return Card(
              margin: EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Row(
                  children: [
                    // Menampilkan judul checklist
                    Text(
                      checklist['title'] ?? 'No title',
                      style: TextStyle(
                        decoration:
                            isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    Spacer(),
                    // Button untuk menambah item pada checklist
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () {
                        _showAddItemDialog(checklist[
                            'id']); // Menampilkan dialog untuk menambah item
                      },
                    ),
                    // Button untuk menghapus checklist
                    IconButton(
                      icon: Icon(Icons.remove_circle),
                      onPressed: () async {
                        // Menghapus checklist
                        await _removeChecklist(checklist['id']);
                      },
                    ),
                  ],
                ),
                subtitle: Column(
                  children: [
                    // Tampilkan item checklist
                    _buildItemList(checklist[
                        'id']), // Tampilkan item berdasarkan ID checklist
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildItemList(int checklistId) {
    // Ambil daftar item untuk checklist tertentu
    final items = checklistItems.value[checklistId] ??
        []; // Menggunakan checklistItems.value

    return ListView.builder(
      shrinkWrap: true,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        bool isChecked = item['is_completed'] ?? false;

        return ListTile(
          title: Text(
            item['title'] ?? 'No item',
            style: TextStyle(
              decoration: isChecked
                  ? TextDecoration.lineThrough
                  : null, // Menandai teks yang sudah dicentang
            ),
          ),
          trailing: Checkbox(
            value: isChecked,
            onChanged: (bool? value) {
              // Update status item checklist saat diubah
              _toggleItemCompletion(checklistId, item['id'], value!);
            },
          ),
        );
      },
    );
  }

  Future<void> _showAddItemDialog(int checklistId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Item'),
          content: TextField(
            controller: _itemTextController,
            decoration: InputDecoration(hintText: 'Enter item title'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final itemTitle = _itemTextController.text.trim();
                if (itemTitle.isNotEmpty) {
                  await _addItemToChecklist(checklistId, itemTitle);
                  _itemTextController.clear();
                  Navigator.pop(context);
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addItemToChecklist(int checklistId, String itemTitle) async {
    final data = {
      'title': itemTitle,
      'is_completed': false, // default item is not completed
    };

    final response = await ApiService.handleChecklist(
      method: 'POST',
      checklistId: checklistId,
      data: data,
    );

    if (response != null) {
      await loadChecklists(); // Refresh checklist setelah menambah item
    }
  }

  Future<void> _toggleItemCompletion(
      int checklistId, int itemId, bool isCompleted) async {
    final data = {'is_completed': isCompleted};

    final response = await ApiService.handleChecklist(
      method: 'PUT',
      checklistId: checklistId,
      data: data,
    );

    if (response != null) {
      // Setelah update, refresh checklist
      await loadChecklists(); // Refresh checklist setelah mengupdate status item
    }
  }

  Future<void> _removeChecklist(int checklistId) async {
    final response = await ApiService.handleChecklist(
      method: 'DELETE',
      checklistId: checklistId,
    );

    if (response != null) {
      await loadChecklists(); // Refresh checklist setelah menghapus checklist
    }
  }

  Future<void> _toggleChecklistStatus(int checklistId, bool newStatus) async {
    final data = {"is_completed": newStatus};

    final response = await ApiService.handleChecklist(
      method: 'PUT',
      checklistId: checklistId,
      data: data,
    );

    if (response != null) {
      await loadChecklists(); // Refresh checklist setelah update
    }
  }

  Widget _buildAddChecklistSection(int taskId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 6,
              child: TextField(
                controller: textChecklistController,
                decoration: InputDecoration(
                  hintText: 'Add checklist item',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(10),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () async {
                  await _addChecklist(taskId);
                },
                child: Icon(Icons.send),
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
      ],
    );
  }

  Future<void> _addChecklist(int taskId) async {
    if (textChecklistController.text.isEmpty) return;

    final data = {"title": textChecklistController.text, "is_completed": false};

    final response = await ApiService.handleChecklist(
      method: 'POST',
      taskId: taskId,
      data: data,
    );

    if (response != null) {
      textChecklistController.clear();
      await loadChecklists(); // Load checklist setelah berhasil ditambahkan
    }
  }

//======================End Checklist===========================================
  Widget listFileWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ValueListenableBuilder(
          valueListenable: onFileNotifier,
          builder: (context, listFile, child) {
            return SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: listFile.length,
                itemBuilder: (context, index) {
                  final fileName =
                      (listFile[index]["fileName"] ?? "").toString();
                  final fileType =
                      (listFile[index]["fileExt"] ?? "").toString();
                  final filePath =
                      (listFile[index]["filePath"] ?? "").toString();
                  final fileDownload =
                      (listFile[index]["fileDownload"] ?? "").toString();

                  return GestureDetector(
                    onTap: () async {
                      if (await canLaunchUrl(Uri.parse(fileDownload))) {
                        await launchUrl(Uri.parse(fileDownload),
                            mode: LaunchMode.externalApplication);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Tidak dapat membuka tautan")),
                        );
                      }
                    },
                    onLongPress: () {
                      if (fileType.toLowerCase() == "pdf") {
                        showPDFPreview(context, fileDownload);
                      } else if (fileType.toLowerCase() == "mp3") {
                        showAudioPreview(context, fileDownload);
                      } else {
                        showDialog(
                          context: context,
                          builder: (_) => Dialog(
                            insetPadding: EdgeInsets.all(20),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          height: 300,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            image: DecorationImage(
                                              image:
                                                  getImage(fileType, filePath),
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        Text(
                                          fileName,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text("Tutup"),
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      width: 150,
                      margin: EdgeInsets.only(right: 10),
                      child: Column(
                        children: [
                          Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              color: Color(0xFFC4C4C4),
                              border: Border.all(
                                color: Colors.transparent,
                                width: 5,
                              ),
                              borderRadius: BorderRadius.circular(5),
                              image: DecorationImage(
                                image: getImage(fileType, filePath),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

ImageProvider getImage(String fileFormat, String path) {
  switch (fileFormat) {
    case "pdf":
      return AssetImage("assets/pdf.png");
    case "docx":
      return AssetImage("assets/docx.png");
    case "pptx":
      return AssetImage("assets/pptx.png");
    case "csv":
      return AssetImage("assets/csv.png");
    case "mp3":
      return AssetImage("assets/mp3.png");
    case "mp4":
      return AssetImage("assets/mp4.png");
    case "txt":
      return AssetImage("assets/txt.png");
    case "xlsx":
      return AssetImage("assets/xlsx.png");
    default:
      return NetworkImage(path);
  }
}
