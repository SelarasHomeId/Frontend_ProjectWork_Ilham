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
import 'package:selarashomeid/utils/connection_checker.dart';
import 'package:selarashomeid/utils/file_picker.dart';
import 'package:selarashomeid/utils/general.dart';
import 'package:selarashomeid/widgets/loading_screen_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:just_audio/just_audio.dart';
import 'package:photo_view/photo_view.dart';

class DetailTaskScreen extends StatefulWidget {
  final int boardId;
  final int taskId;

  const DetailTaskScreen({
    super.key,
    required this.boardId,
    required this.taskId,
  });

  @override
  State<DetailTaskScreen> createState() => _DetailTaskScreenState();
}

class _DetailTaskScreenState extends State<DetailTaskScreen> {
  late Future<Map<String, String>> userProfileFuture;
  Map<String, String> userProfile = {};
  late ValueNotifier<bool> onExpandableValue;

  late TextEditingController textDescController;
  late TextEditingController textTitleController;
  late TextEditingController textCommentController;
  late TextEditingController textEditCommentController =
      TextEditingController();
  late TextEditingController textChecklistController;
  late TextEditingController _itemTextController = TextEditingController();
  late TextEditingController _checklistEditTextController =
      TextEditingController();

  late FocusNode focusNode;
  late FocusNode titleFocusNode;
  late FocusNode descFocusNode;
  late FocusNode commentFocusNode;
  late FocusNode editCommentFocusNode;
  late FocusNode checklistFocusNode;

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
    userProfileFuture.then((data) {
      setState(() {
        userProfile = data;
      });
    });
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
    _checklistEditTextController = TextEditingController();

    textDescController = TextEditingController();
    textTitleController = TextEditingController();
    textCommentController = TextEditingController();
    textEditCommentController = TextEditingController();
    textChecklistController = TextEditingController();
    currentWatch = ValueNotifier<bool>(false);
    currentIsCompleted = ValueNotifier<bool>(false);
    currentCover = ValueNotifier<String?>(null);
    assignedMembersNotifier = ValueNotifier<List<Map<String, dynamic>>>([]);
    isMemberExpanded = ValueNotifier<bool>(true);

    titleFocusNode = FocusNode();
    descFocusNode = FocusNode();
    checklistFocusNode = FocusNode();
    commentFocusNode = FocusNode();

    currentBoardId = ValueNotifier<int>(0);
    currentWorkspaceId = ValueNotifier<int>(0);
    showSaveDescButton = ValueNotifier<bool>(false);

    _selectedUserIds = {};

    workspaceName = "";
    boardName = "";
    latestUpdatedAt = "";
    latestUpdatedBy = "";

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

  Future<void> onLoadDesc() async {
    textDescController.addListener(() {
      final now = textDescController.text.trim();
      final original = (currentDesc ?? '').trim();
      showSaveDescButton.value = now != original;
    });
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
    textDescController.addListener(() {
      final now = textDescController.text.trim();
      final original = (currentDesc ?? '').trim();
      showSaveDescButton.value = now != original;
    });
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
    textEditCommentController.dispose();
    textChecklistController.dispose();
    _itemTextController.dispose();
    _checklistEditTextController.dispose();

    titleFocusNode.dispose();
    descFocusNode.dispose();
    checklistFocusNode.dispose();
    commentFocusNode.dispose();

    super.dispose();
  }

//Start Cover=========================================================
  Future<void> _pickCover() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        _selectedCover = File(pickedImage.path);
      });

      final fileStream = await http.MultipartFile.fromPath(
        'cover',
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
    final confirm = await General.showDialogDelete(
      context: context,
      title: 'Hapus Cover',
      message: 'Apakah Anda yakin ingin menghapus cover untuk task ini?',
      confirmButtonText: 'Hapus',
      cancelButtonText: 'Batal',
    );

    if (confirm == true) {
      try {
        final response = await ApiService.handleTask(
          method: 'PUT',
          data: {"delete_cover": true},
          taskId: taskId,
        );
        if (response != null) {
          await onLoadValue();
          setState(() {});
          General.showSnackBar(context, "Cover deleted");
        }
      } catch (e) {
        General.showSnackBar(context, "Cover error when delete, cause: $e");
      }
    }
  }

//========end Cover===================================================
  void deleteTask(int taskId) async {
    final confirm = await General.showDialogDelete(
      context: context,
      title: 'Hapus Task',
      message: 'Apakah Anda yakin ingin menghapus task ini?',
      confirmButtonText: 'Hapus',
      cancelButtonText: 'Batal',
    );

    if (confirm == true) {
      try {
        print('[DELETE_TASK] User konfirmasi penghapusan');
        final response =
            await ApiService.handleTask(method: 'DELETE', taskId: taskId);
        print('[DELETE_TASK] Response dari API: $response');

        if (response != null && response['message'] == 'success delete!') {
          print('[DELETE_TASK] Task berhasil dihapus. Menampilkan snackbar');

          General.showSnackBar(context, 'Task berhasil dihapus!');

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
          General.showSnackBar(context, 'Gagal menghapus task.');
        }
      } catch (e) {
        print('[DELETE_TASK] Terjadi error saat hapus task: $e');
        General.showSnackBar(context, 'Terjadi error: $e');
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
      General.showSnackBar(context, 'Failed to load data: $e');
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
              content: SizedBox(
                width: double.maxFinite,
                height: 500, // <-- batasi tinggi dialog
                child: Column(
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
                            : Expanded(
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
                                      subtitle: Text(
                                          '${user['role']['name']} - ${user['divisi']['name']}'),
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
        return Container(
          margin: EdgeInsets.symmetric(
              vertical: 8, horizontal: 8), // Margin di sekitar panel
          decoration: BoxDecoration(
            color: Colors.white, // Background color untuk container
            borderRadius: BorderRadius.circular(12), // Sudut membulat
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1), // Warna shadow
                blurRadius: 6, // Blur shadow
                spreadRadius: 2, // Spread shadow
              ),
            ],
          ),

          child: ExpansionPanelList(
            elevation: 1,
            expandedHeaderPadding: EdgeInsets.all(0),
            expansionCallback: (int index, bool isExpanded) {
              isMemberExpanded.value = isExpanded;
            },
            children: [
              ExpansionPanel(
                backgroundColor: Colors.white,
                headerBuilder: (context, isExpanded) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Assigned Members',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                                final confirm = await General.showDialogDelete(
                                    context: context,
                                    title: "Hapus User",
                                    message:
                                        "Apakah Yakin Ingin Menghapus User ini?",
                                    confirmButtonText: "Hapus",
                                    cancelButtonText: "Batal");

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
          ),
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

  void showImagePreview(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: PhotoView(
            imageProvider: NetworkImage(url),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
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
    return ConnectionChecker(
        child: PopScope(
      canPop: !titleFocusNode.hasFocus && !descFocusNode.hasFocus,
      onPopInvokedWithResult: (didPop, result) async {
        if (titleFocusNode.hasFocus) titleFocusNode.unfocus();
        if (descFocusNode.hasFocus) descFocusNode.unfocus();
        if (checklistFocusNode.hasFocus) checklistFocusNode.unfocus();
        if (commentFocusNode.hasFocus) commentFocusNode.unfocus();

        if (didPop) return;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          titleFocusNode.unfocus();
          descFocusNode.unfocus();
          checklistFocusNode.unfocus();
          commentFocusNode.unfocus();
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
                  final value = textTitleController.text;

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
                            Icon(
                              Icons.delete,
                              color: Colors.red[900],
                            ),
                            SizedBox(width: 8),
                            Text('Delete Task'),
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
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.black,
                                width: 0.5), // Border tipis
                            borderRadius:
                                BorderRadius.circular(8), // Radius container
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                                7.5), // Radius sedikit lebih kecil dari container
                            child: currentCover.value == null
                                ? Image.asset(
                                    'assets/no_cover.png',
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 120,
                                  )
                                : Image.network(
                                    currentCover.value.toString(),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 120,
                                  ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),

                      //Show Workspace and Board Data
                      _buildShowSummaryTask(),
                      SizedBox(height: 10),

                      // Quick Actions
                      _buildQuickActions(onExpandableValue),
                      SizedBox(height: 10),

                      // Assigned Member/user
                      _buildMemberSection(),
                      SizedBox(height: 10),

                      // Description
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
                          await onLoadDesc();
                        },
                      ),
                      SizedBox(height: 20),

                      // Labels
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
                            General.showSnackBar(
                                context, 'Update Label: Berhasil');
                            await onLoadValue();
                          }
                        },
                      ),
                      SizedBox(height: 20),

                      // Due Dates
                      _buildDatePickers(),
                      SizedBox(height: 20),

                      // Attachment
                      listFileWidget(),
                      SizedBox(height: 20),

                      // Checklist
                      _buildAddChecklistSection(widget.taskId),
                      SizedBox(height: 20),

                      // Comments
                      _buildAddCommentSection(widget.taskId),
                      SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ));
  }

//=======================End Widget Build===========================================
  Future<Map<String, int>?> _showMoveDialog(
      int workspaceId, int boardId) async {
    List<Map<String, dynamic>> workspaces = [];
    List<Map<String, dynamic>> boards = [];
    int? selectedWorkspaceId = workspaceId;
    int? selectedBoardId = boardId;

    setState(() {
      _isLoading = true;
    });
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
          General.showSnackBar(context, 'Gagal memuat board: $e');
        }
      }
    }

    await loadBoards(selectedWorkspaceId!);

    setState(() {
      _isLoading = false;
    });

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
          "is_history": e["is_history"],
          "updated_at": e["updated_at"],
          "user_name": e['created_by']['name'],
          "user_id": e['created_by']['id'],
        };
      }).toList();
    }

    onLoadingCommentNotifier.value = false;
  }

  Future<void> loadChecklists() async {
    onLoadingChecklistNotifier.value = true;

    final checklistData = await ApiService.handleChecklist(
        method: 'GET', taskId: widget.taskId, params: {'no_paging': 'yes'});

    if (checklistData != null) {
      checklistItems.value.clear();

      for (final checklist in checklistData) {
        checklistItems.value[checklist["id"]] = List<Map<String, dynamic>>.from(
          checklist["item"]?["data"] ?? [],
        );
      }

      onChecklistNotifier.value =
          (checklistData as List).map<Map<String, dynamic>>((checklist) {
        final map = checklist as Map<String, dynamic>;
        return {
          "id": map["id"],
          "title": map["title"],
          "task_id": map["task_id"],
          "check_persentase": map["check_persentase"],
          "item_count": map["item"]["count"],
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
      color: Colors.white,
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
              child: _isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text('Move'),
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
        return Container(
          margin: EdgeInsets.symmetric(
              vertical: 8, horizontal: 8), // Margin di sekitar panel
          decoration: BoxDecoration(
            color: Colors.white, // Background color untuk container
            borderRadius: BorderRadius.circular(12), // Sudut membulat
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1), // Warna shadow
                blurRadius: 6, // Blur shadow
                spreadRadius: 2, // Spread shadow
              ),
            ],
          ),
          child: ExpansionPanelList(
            elevation: 0, // Menghilangkan shadow default
            expandedHeaderPadding: EdgeInsets.all(16),
            expansionCallback: (int index, bool isExpanded) {
              onExpandableValue.value = isExpanded;
            },
            children: [
              ExpansionPanel(
                backgroundColor: expandletrue ? Colors.white38 : Colors.white70,
                headerBuilder: (BuildContext context, bool isExpanded) {
                  return InkWell(
                    onTap: () {
                      final currentValueExpandale = onExpandableValue.value;
                      onExpandableValue.value = !currentValueExpandale;
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Quick Actions',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  );
                },
                body: Padding(
                  padding:
                      const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: Wrap(
                    runSpacing: 15,
                    spacing: 10,
                    children: [
                      // Baris Pertama: Checklist & Members
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.9,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  _showAddChecklistDialog(widget.taskId);
                                },
                                icon: Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                label: Text(
                                  'Add Checklist',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color.fromARGB(255, 27, 169, 11),
                                  padding: EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 20,
                                  shadowColor:
                                      const Color.fromARGB(255, 255, 255, 255)
                                          .withOpacity(0.4),
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Flexible(
                              child: ElevatedButton.icon(
                                icon: Icon(
                                  Icons.person_add_alt_1_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                onPressed: _showAddMemberDialog,
                                label: Text(
                                  'Add Members',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color.fromARGB(255, 144, 9, 156),
                                  padding: EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 20),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 10,
                                  shadowColor:
                                      const Color.fromARGB(255, 255, 255, 255)
                                          .withOpacity(0.4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Baris Kedua: Attachment
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: MediaQuery.of(context).size.width * 0.8,
                        ),
                        child: ElevatedButton.icon(
                          icon: Icon(
                            Icons.attach_file_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
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
                                taskId: widget.taskId,
                                listFile: listFile,
                                data: {
                                  "task_id": widget.taskId.toString(),
                                },
                              );
                            }
                            loadFile();
                            loadComments();
                            onLoadingNotifier.value = false;
                            onLoadingFileNotifier.value = false;
                          },
                          label: Text(
                            'Add Attachment',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 9, 61, 150),
                            padding: EdgeInsets.symmetric(
                                vertical: 12, horizontal: 25),
                            minimumSize: Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 10,
                            shadowColor: Colors.black.withOpacity(0.4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                isExpanded: expandletrue,
              ),
            ],
          ),
        );
      },
    );
  }

// end quick actions and summary========================================

  Widget _buildCardDescription({
    required TextEditingController textDescController,
    required FocusNode focusNode,
    required Future<void> Function() onSubmitButton,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(3, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Description",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(
            height: 10,
          ),
          TextField(
            controller: textDescController,
            focusNode: descFocusNode,
            decoration: InputDecoration(
              hintText: 'Masukan Deskripsi',
              hintStyle: TextStyle(color: Colors.grey[500]),
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
                      focusNode: descFocusNode,
                      onPressed: () async {
                        FocusScope.of(context).requestFocus(FocusNode());
                        await onSubmitButton();
                        currentDesc = textDescController.text;
                        showSaveDescButton.value = false;
                      },
                      child: Text("Simpan"),
                    )
                  : SizedBox();
            },
          )
        ],
      ),
    );
  }

//===================================Label=====================================
  Widget _buildLabelsButton(
      {required Future<void> Function(int) onAddingLabel}) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, // Warna background box
        borderRadius: BorderRadius.circular(12), // Radius sudut kotak
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), // Warna shadow
            spreadRadius: 2, // Jarak shadow
            blurRadius: 5, // Ukuran blur shadow
            offset: Offset(0, 3), // Posisi shadow
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Labels",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(
            height: 10,
          ),
          ElevatedButton.icon(
            icon: Icon(Icons.add),
            label: Text('Add Label'),
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
                            final confirmDelete =
                                await General.showDialogDelete(
                                    context: context,
                                    title: "Hapus Label",
                                    message: "Apakah Yakin Menghapus Label ?",
                                    confirmButtonText: "Hapus",
                                    cancelButtonText: "Batal");

                            if (confirmDelete == true) {
                              // Hapus label dari daftar
                              currentLabelIds.remove(label.$3);

                              // Perbarui ValueNotifier
                              notifierLabelColor.value =
                                  List.from(notifierLabelColor.value)
                                    ..remove(label);

                              // Kirim data terbaru ke API
                              onLoadingNotifier.value = true;
                              final getUpdatedData =
                                  await ApiService.handleTask(
                                method: 'PUT',
                                taskId: widget.taskId,
                                boardId: widget.boardId,
                                data: {'label': currentLabelIds},
                                contentType: 'application/json',
                              );

                              if (getUpdatedData != null && context.mounted) {
                                General.showSnackBar(
                                    context, 'Label berhasil dihapus');
                              }
                              onLoadingNotifier.value = false;
                            }
                          },
                          child: Container(
                            margin: EdgeInsets.only(right: 8),
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12)),
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
      ),
    );
  }
//=====================end Label============================================

//=========== Date dan Due Date===========================================

  Widget _buildDatePickers() {
    return ValueListenableBuilder<DateTime?>(
      valueListenable: onEndDateNotifier,
      builder: (context, selectedDate, child) {
        final dateText = selectedDate != null
            ? DateFormat('EEEE, dd MMMM yyyy - HH:mm WIB').format(selectedDate)
            : 'Belum ada Deadline';

        return Container(
          width: MediaQuery.of(context).size.width,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white, // Warna background box
            borderRadius: BorderRadius.circular(12), // Radius sudut kotak
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1), // Warna shadow
                spreadRadius: 2, // Jarak shadow
                blurRadius: 5, // Ukuran blur shadow
                offset: Offset(0, 3), // Posisi shadow
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Due Date",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(
                height: 5,
              ),
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
          ),
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
              leading: comment['is_history'] == true
                  ? Image.asset(
                      'assets/selaras_logo2.png',
                      width: 40,
                      height: 40,
                    )
                  : CircleAvatar(
                      backgroundColor: General.getColorFromInitial(
                        General.getInitials(comment['user_name']),
                      ),
                      child: Text(
                        General.getInitials(comment['user_name']),
                      ),
                    ),
              title: Text(comment['user_name']),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(comment['comment']),
                  Text(
                    DateFormat('dd MMM yyyy HH:mm').format(
                      DateTime.parse(comment['updated_at']).toLocal(),
                    ),
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              trailing: (comment['is_history'] == false &&
                      comment['user_id'] ==
                          int.tryParse(userProfile['id'].toString()))
                  ? PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert),
                      offset: Offset(0, 40),
                      onSelected: (String result) async {
                        switch (result) {
                          case 'edit':
                            _showEditCommentDialog(
                                comment['id'], comment['comment']);
                            break;
                          case 'delete':
                            await _deleteComment(comment['id']);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    )
                  : null,
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

  Future<void> _showEditCommentDialog(
      int commentId, String currentComment) async {
    textEditCommentController.text = currentComment;

    await General.showDialogEdit(
      context: context,
      controller: textEditCommentController,
      existingItems: [],
      itemName: 'Comment',
      hintText: 'Enter your comment: ',
      emptyFieldMessage: 'Comment cannot be empty.',
      duplicateMessage: 'Duplicate comment found.',
      onSave: (data) async {
        final updatedComment = data['name'];
        try {
          await _editComment(commentId, updatedComment);
        } catch (e) {
          General.showSnackBar(context, 'Failed to update comment: $e');
        }
      },
    );
  }

  Future<void> _editComment(int commentId, String comment) async {
    final data = {"comment": comment};

    final response = await ApiService.handleComment(
      method: 'PUT',
      data: data,
      commentId: commentId,
    );

    if (response != null) {
      textEditCommentController.clear();
      await loadComments();
    }
  }

  Future<void> _deleteComment(int commentId) async {
    final response = await ApiService.handleComment(
      method: 'DELETE',
      commentId: commentId,
    );

    if (response != null) {
      await loadComments();
    }
  }

  Widget _buildAddCommentSection(int taskId) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Container(
      padding: EdgeInsets.all(16), // Padding di dalam container
      decoration: BoxDecoration(
        color: Colors.white, // Warna background box
        borderRadius: BorderRadius.circular(12), // Radius sudut kotak
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), // Warna shadow
            spreadRadius: 2, // Jarak shadow
            blurRadius: 5, // Ukuran blur shadow
            offset: Offset(0, 3), // Posisi shadow
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Comments",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Row(
            children: [
              FutureBuilder<Map<String, String>>(
                future: userProfileFuture,
                builder: (context, snapshot) {
                  String initial =
                      General.getInitials(snapshot.data?['name'] ?? 'U');
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.black, // Warna border
                        width: 1, // Ketebalan border
                      ),
                    ),
                    child: CircleAvatar(
                      radius: screenWidth * 0.065,
                      backgroundColor: General.getColorFromInitial(initial),
                      child: Text(
                        initial,
                        style: TextStyle(
                          fontSize: screenWidth *
                              0.06, // Ukuran font sesuai dengan lebar layar
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A365D), // Warna teks
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(width: 10),
              Expanded(
                flex: 6,
                child: TextField(
                  controller: textCommentController,
                  focusNode: commentFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Add Comment',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    suffixIcon: InkWell(
                      onTap: () async {
                        await _addComment(taskId);
                      },
                      child: Icon(Icons.check_circle),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
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
    );
  }
  //===================================End Comment==============================

//======================Start Checklist=========================================
  Widget _buildChecklistList() {
    return ValueListenableBuilder(
      valueListenable: onChecklistNotifier,
      builder: (context, checklistList, child) {
        if (checklistList.isEmpty) {
          return Center(child: Text('Belum ada checklist'));
        }

        return ListView.builder(
          shrinkWrap: true,
          itemCount: checklistList.length,
          itemBuilder: (context, index) {
            final checklist = checklistList[index];

            return Card(
              color: Colors.white,
              margin: EdgeInsets.symmetric(vertical: 5),
              child: ListTile(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Menampilkan judul checklist dengan scroll horizontal + onTap
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: GestureDetector(
                              onTap: () {
                                _showEditChecklistDialog(
                                    checklist['id'], checklist['title']);
                              },
                              child: Row(
                                children: [
                                  Text(
                                    checklist['title'] ?? 'No title',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Tombol tambah item
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            _showAddItemDialog(checklist['id']);
                          },
                        ),
                        // Tombol hapus checklist
                        IconButton(
                          icon: Icon(Icons.remove_circle),
                          onPressed: () async {
                            await _removeChecklist(checklist['id']);
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    // Progress bar & label persentase
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                            begin: 0,
                            end: double.tryParse(checklist['check_persentase']
                                        ?.replaceAll('%', '') ??
                                    '0')! /
                                100,
                          ),
                          duration: Duration(milliseconds: 800),
                          builder: (context, value, child) {
                            return LinearProgressIndicator(
                              value: value,
                              minHeight: 6,
                              color: Colors.green,
                              backgroundColor: Colors.grey[300],
                            );
                          },
                        ),
                        SizedBox(height: 4),
                        Text(
                          checklist['check_persentase'] ?? '0%',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                      ],
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

  Future<void> _showEditChecklistDialog(
      int checklistId, String currentTitle) async {
    _checklistEditTextController.text = currentTitle;
    await showDialog(
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
                  color: Color.fromARGB(255, 13, 20, 158),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child: Icon(Icons.edit_note, size: 80, color: Colors.white),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Edit Checklist',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _checklistEditTextController,
                  decoration: InputDecoration(
                    hintText: 'Enter checklist title',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      _checklistEditTextController.clear();
                      Navigator.pop(context);
                    },
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
                    onPressed: () async {
                      final itemTitle =
                          _checklistEditTextController.text.trim();
                      if (itemTitle.isNotEmpty) {
                        await _editChecklist(checklistId, itemTitle);
                        _checklistEditTextController.clear();
                        Navigator.pop(context);
                      }
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 13, 20, 158),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Edit', style: TextStyle(color: Colors.white)),
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

  Widget _buildItemList(int checklistId) {
    final items = checklistItems.value[checklistId] ?? [];

    return ListView.builder(
      shrinkWrap: true,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        bool isChecked = item['is_completed'] ?? false;

        return ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.025,
          ),
          leading: Checkbox(
            key: ValueKey(isChecked),
            value: isChecked,
            onChanged: (bool? value) async {
              await _toggleItemCompletion(item['id'], !isChecked);
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  _showEditChecklistItemDialog(item['id'], item['title']);
                },
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                    maxHeight: MediaQuery.of(context).size.height * 0.06,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(
                      item['title'] ?? 'No item',
                      style: TextStyle(
                        color: isChecked ? Colors.grey : Colors.black,
                        decoration:
                            isChecked ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: true,
                    ),
                  ),
                ),
              ),
              if (item['due_date'] != null || item['assign_to_user'] != null)
                SizedBox(height: MediaQuery.of(context).size.height * 0.006),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item['due_date'] != null)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.012,
                        vertical: MediaQuery.of(context).size.height * 0.004,
                      ),
                      decoration: BoxDecoration(
                        color: isChecked
                            ? Colors.green.withOpacity(0.2)
                            : (DateTime.parse(item['due_date'])
                                    .isBefore(DateTime.now())
                                ? Colors.red.withOpacity(0.2)
                                : Colors.black.withOpacity(0.1)),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.alarm,
                            size: MediaQuery.of(context).size.width * 0.05,
                            color: isChecked
                                ? Colors.green
                                : (DateTime.parse(item['due_date'])
                                        .isBefore(DateTime.now())
                                    ? Colors.red
                                    : Colors.black),
                          ),
                          SizedBox(
                              width: MediaQuery.of(context).size.width * 0.02),
                          Text(
                            DateFormat(item['due_date'].substring(0, 4) !=
                                        DateTime.now().year.toString()
                                    ? 'MMM dd, yyyy'
                                    : 'MMM dd')
                                .format(DateTime.parse(item['due_date'])),
                            style: TextStyle(
                              color: isChecked
                                  ? Colors.green
                                  : (DateTime.parse(item['due_date'])
                                          .isBefore(DateTime.now())
                                      ? Colors.red
                                      : Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (item['due_date'] != null &&
                      item['assign_to_user'] != null)
                    SizedBox(
                        height: MediaQuery.of(context).size.height * 0.008),
                  if (item['assign_to_user'] != null)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var member
                              in item['assign_to_user']["data"] as List)
                            Padding(
                              padding: EdgeInsets.only(
                                  right: MediaQuery.of(context).size.width *
                                      0.013),
                              child: CircleAvatar(
                                radius:
                                    MediaQuery.of(context).size.width * 0.042,
                                backgroundColor: General.getColorFromInitial(
                                    General.getInitials(member['name'])),
                                child: FittedBox(
                                  child: Text(
                                    General.getInitials(member['name']),
                                    style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width *
                                              0.03,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: Colors.black,
            ),
            offset: Offset(0, MediaQuery.of(context).size.height * 0.05),
            onSelected: (String result) async {
              switch (result) {
                case 'move':
                  Map<String, int>? dataDialog =
                      await _showMoveItemDialog(checklistId);

                  if (dataDialog != null) {
                    final data = {
                      "task_checklist_id": dataDialog["task_checklist_id"]
                    };

                    final response = await ApiService.handleChecklistItem(
                        method: 'PUT', data: data, checklistItemId: item['id']);

                    if (response != null) {
                      await loadChecklists();
                      General.showSnackBar(
                          context, "Item berhasil dipindahkan");
                    } else {
                      General.showSnackBar(context, "Gagal memindahkan item");
                    }
                  }
                case 'due_date':
                  await _pickDueDateChecklistItem(context, item['id']);
                  break;
                case 'member':
                  ValueNotifier<List<Map<String, dynamic>>> assignedMembers =
                      ValueNotifier<List<Map<String, dynamic>>>(
                    List<Map<String, dynamic>>.from(
                        item['assign_to_user']?["data"] ?? []),
                  );
                  await _showAssignedMembersChecklistItemDialog(
                      context, assignedMembers, item['id']);
                  break;
                case 'convert':
                  bool confirmed =
                      await _showConvertItemChecklistToTaskConfirmationDialog();
                  if (confirmed) {
                    await _convertItemChecklistToTask(item['id']);
                  }
                  break;
                case 'delete':
                  bool confirmed =
                      await _showDeleteItemChecklistConfirmationDialog();
                  if (confirmed) {
                    await _deleteItemChecklist(item['id']);
                  }
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'move',
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz),
                    SizedBox(width: 8),
                    Text('Move Item'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'due_date',
                child: Row(
                  children: [
                    Icon(Icons.calendar_today),
                    SizedBox(width: 8),
                    Text('Add Due Date'),
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
              PopupMenuItem<String>(
                value: 'convert',
                child: Row(
                  children: [
                    Icon(Icons.add_task),
                    SizedBox(width: 8),
                    Text('Convert to Task'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete),
                    SizedBox(width: 8),
                    Text('Delete Item'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAddChecklistDialog(int taskId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Checklist'),
          content: TextField(
            controller: textChecklistController,
            decoration: InputDecoration(hintText: 'Enter Checklist title'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                textChecklistController.clear();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final itemTitle = textChecklistController.text.trim();
                if (itemTitle.isNotEmpty) {
                  await _addChecklist(taskId);
                  textChecklistController.clear();
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

  Future<void> _showAddItemDialog(int checklistId) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.add,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),

              // Title Section
              SizedBox(height: 20),
              Text(
                'Add Item',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              // Input Field
              SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _itemTextController,
                  decoration: InputDecoration(
                    hintText: 'Enter item title',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Cancel Button
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),

                  // Add Button
                  TextButton(
                    onPressed: () async {
                      final itemTitle = _itemTextController.text.trim();
                      if (itemTitle.isNotEmpty) {
                        await _addItemToChecklist(checklistId, itemTitle);
                        _itemTextController.clear();
                        Navigator.pop(context);
                      }
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Add',
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
  }

  Future<void> _addItemToChecklist(int checklistId, String itemTitle) async {
    final data = {
      'title': itemTitle,
    };

    final response = await ApiService.handleChecklistItem(
      method: 'POST',
      checklistId: checklistId,
      data: data,
    );

    if (response != null) {
      await loadChecklists();
      await loadComments();
    }
  }

  Future<void> _editChecklist(int checklistId, String itemTitle) async {
    final data = {
      'title': itemTitle,
    };

    final response = await ApiService.handleChecklist(
      method: 'PUT',
      checklistId: checklistId,
      data: data,
    );

    if (response != null) {
      await loadChecklists(); // Refresh checklist setelah menambah item
    }
  }

  Future<void> _showEditChecklistItemDialog(
      int itemId, String currentTitle) async {
    _checklistEditTextController.text = currentTitle;

    await General.showDialogEdit(
      context: context,
      controller: _checklistEditTextController,
      existingItems: [],
      itemName: 'Checklist Item',
      hintText: 'Enter checklist item title',
      emptyFieldMessage: 'Item title cannot be empty.',
      duplicateMessage: 'Duplicate item title found.',
      onSave: (data) async {
        final updatedTitle = data['name'];
        try {
          await _editChecklistItem(itemId, updatedTitle);
        } catch (e) {
          General.showSnackBar(context, 'Failed to update checklist item: $e');
        }
      },
    );
  }

  Future<void> _editChecklistItem(int itemId, String itemTitle) async {
    final data = {
      'title': itemTitle,
    };

    final response = await ApiService.handleChecklistItem(
      method: 'PUT',
      checklistItemId: itemId,
      data: data,
    );

    if (response != null) {
      await loadChecklists(); // Refresh checklist setelah menambah item
    }
  }

  Future<void> _toggleItemCompletion(int itemId, bool isCompleted) async {
    final data = {'is_completed': isCompleted};

    final response = await ApiService.handleChecklistItem(
      method: 'PUT',
      checklistItemId: itemId,
      data: data,
    );

    if (response != null) {
      // Setelah update, refresh checklist
      await loadChecklists(); // Refresh checklist setelah mengupdate status item
    }
  }

  Future<bool> _showDeleteItemChecklistConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Konfirmasi Hapus"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Kamu yakin ingin menghapus item checklist?"),
                ],
              ),
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

  Future<void> _deleteItemChecklist(int itemId) async {
    final response = await ApiService.handleChecklistItem(
      method: 'DELETE',
      checklistItemId: itemId,
    );

    if (response != null) {
      await loadChecklists();
      await loadComments();
    }
  }

  Future<bool> _showConvertItemChecklistToTaskConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Konfirmasi Konversi Item Checklist ke Task"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Kamu yakin ingin konversi item checklist?"),
                  Text(
                    "Konversi item checklist akan menghapus item dan membuat task baru di board yang sama.",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context, false), // Tidak jadi delete
                  child: Text("Batal"),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context, true), // Konfirmasi delete
                  child: Text("Convert",
                      style: TextStyle(color: Colors.green[700])),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _convertItemChecklistToTask(int itemId) async {
    final response = await ApiService.handleChecklistItem(
      method: 'PATCH',
      checklistItemId: itemId,
    );

    if (response != null) {
      await loadChecklists();
      await loadComments();
    }
  }

  Future<void> _removeChecklist(int checklistId) async {
    final response = await ApiService.handleChecklist(
      method: 'DELETE',
      checklistId: checklistId,
    );

    if (response != null) {
      await loadChecklists();
      await loadComments();
    }
  }

  Future<void> _pickDueDateChecklistItem(
      BuildContext context, int itemId) async {
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
          final response = await ApiService.handleChecklistItem(
            method: 'PUT',
            checklistItemId: itemId,
            data: {'due_date': dueDate},
          );

          if (response != null) {
            // Setelah update, refresh checklist
            await loadChecklists(); // Refresh checklist setelah mengupdate status item
          }
        } catch (e) {
          General.showSnackBar(context, "Gagal Menambahkan Tanggal e: $e");
        }

        onLoadingNotifier.value = false;
      }
    }
  }

  Future<void> _showAssignedMembersChecklistItemDialog(
      BuildContext context,
      ValueNotifier<List<Map<String, dynamic>>> assignedMembers,
      int itemId) async {
    final members = assignedMembers.value;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 13, 20, 158),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  Icon(Icons.people_alt, size: 50, color: Colors.white),
                  SizedBox(height: 10),
                  Text('Assigned Members',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: members.isEmpty
                  ? Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text('No members assigned yet.',
                          style: TextStyle(fontSize: 16)),
                    )
                  : SizedBox(
                      height: 300,
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: members.length,
                        separatorBuilder: (_, __) => Divider(height: 1),
                        itemBuilder: (context, index) {
                          final member = members[index];
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[100],
                            ),
                            margin: EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: General.getColorFromInitial(
                                    General.getInitials(member['name'])),
                                child: Text(
                                  General.getInitials(member['name']),
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(member['name'],
                                  style:
                                      TextStyle(fontWeight: FontWeight.w500)),
                              subtitle: Text(
                                  '${member['role']} • ${member['divisi']}',
                                  style: TextStyle(fontSize: 12)),
                              trailing: IconButton(
                                icon: Icon(Icons.close, size: 20),
                                color: Colors.red[400],
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => Dialog(
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16)),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Color.fromARGB(
                                                  255, 13, 20, 158),
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                      top: Radius.circular(16)),
                                            ),
                                            child: Center(
                                              child: Text("Konfirmasi",
                                                  style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white)),
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.all(16),
                                            child: Text(
                                                "Apakah yakin ingin menghapus user ini?",
                                                textAlign: TextAlign.center),
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, false),
                                                style: TextButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.grey[600],
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8)),
                                                ),
                                                child: Text('Batal',
                                                    style: TextStyle(
                                                        color: Colors.white)),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, true),
                                                style: TextButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.red[400],
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8)),
                                                ),
                                                child: Text('Hapus',
                                                    style: TextStyle(
                                                        color: Colors.white)),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 16),
                                        ],
                                      ),
                                    ),
                                  );

                                  if (confirm == true) {
                                    try {
                                      final remainingIds = assignedMembers.value
                                          .where((u) => u['id'] != member['id'])
                                          .map((u) => u['id'] as int)
                                          .toList();

                                      final res =
                                          await ApiService.handleChecklistItem(
                                        method: 'PUT',
                                        checklistItemId: itemId,
                                        data: {"assign_to_user": remainingIds},
                                      );

                                      if (res != null) {
                                        await loadChecklists();
                                        Navigator.pop(context);
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
                            ),
                          );
                        },
                      ),
                    ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () async {
                      await loadChecklists();
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('Tutup', style: TextStyle(color: Colors.white)),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      _showAddMemberChecklistItemDialog(
                          context, assignedMembers, itemId);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 13, 20, 158),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('Add Member',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showAddMemberChecklistItemDialog(BuildContext context,
      ValueNotifier<List<Map<String, dynamic>>> assignedMembers, int itemId) {
    _selectedUserIds = assignedMembers.value.map((u) => u['id'] as int).toSet();

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
              content: SizedBox(
                width: double.maxFinite,
                height: 500,
                child: Column(
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
                            : Expanded(
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
                                      subtitle: Text(
                                          '${user['role']['name']} - ${user['divisi']['name']}'),
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
                          final res = await ApiService.handleChecklistItem(
                            method: 'PUT',
                            checklistItemId: itemId,
                            data: {
                              "assign_to_user": _selectedUserIds.toList(),
                            },
                          );

                          if (res != null) {
                            await loadChecklists();
                            Navigator.pop(context);
                            General.showSnackBar(
                                context, "User berhasil di-assign");
                          }
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

  Future<Map<String, int>?> _showMoveItemDialog(int taskChecklistId) async {
    List<Map<String, dynamic>> taskChecklists = [];
    int? selectedTaskChecklisId = taskChecklistId;

    try {
      final response = await ApiService.handleChecklist(
          method: 'GET', taskId: widget.taskId, params: {'no_paging': 'yes'});
      if (response.isNotEmpty) {
        taskChecklists =
            (response as List).map<Map<String, dynamic>>((checklist) {
          final map = checklist as Map<String, dynamic>;
          return {
            "id": map["id"],
            "title": map["title"],
            "task_id": map["task_id"],
            "check_persentase": map["check_persentase"],
            "item_count": map["item"]["count"],
          };
        }).toList();
        if (!taskChecklists.any((w) => w['id'] == selectedTaskChecklisId)) {
          selectedTaskChecklisId = taskChecklists.first['id'];
        }
      }
    } catch (e) {
      if (mounted) {
        General.showSnackBar(context, 'Gagal memuat checklist: $e');
      }
    }

    return await showDialog<Map<String, int>>(
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
                  color: Color.fromARGB(255, 13, 20, 158),
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
                'Move Item',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return DropdownButtonFormField<int>(
                      value: selectedTaskChecklisId,
                      items: taskChecklists.map((taskChecklist) {
                        return DropdownMenuItem<int>(
                          value: taskChecklist['id'],
                          child: Text(taskChecklist['title'] ?? ''),
                        );
                      }).toList(),
                      onChanged: (int? newValue) {
                        setState(() {
                          selectedTaskChecklisId = newValue;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: "Select Checklist",
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
                    onPressed: () => Navigator.pop(context, null),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Batal', style: TextStyle(color: Colors.white)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(
                      context,
                      {'task_checklist_id': selectedTaskChecklisId!},
                    ),
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

  Widget _buildAddChecklistSection(int taskId) {
    return Container(
      padding: EdgeInsets.all(16), // Padding di dalam container
      decoration: BoxDecoration(
        color: Colors.white, // Warna background box
        borderRadius: BorderRadius.circular(12), // Radius sudut kotak
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), // Warna shadow
            spreadRadius: 2, // Jarak shadow
            blurRadius: 5, // Ukuran blur shadow
            offset: Offset(0, 3), // Posisi shadow
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Checklist",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 6,
                child: TextField(
                  controller: textChecklistController,
                  focusNode: checklistFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Add checklist item',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    suffixIcon: InkWell(
                      onTap: () async {
                        await _addChecklist(taskId);
                      },
                      child: Icon(Icons.check_circle),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          ValueListenableBuilder(
            valueListenable: onLoadingChecklistNotifier,
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
        ],
      ),
    );
  }

  Future<void> _addChecklist(int taskId) async {
    if (textChecklistController.text.isEmpty) return;

    final data = {
      "title": textChecklistController.text,
    };

    final response = await ApiService.handleChecklist(
      method: 'POST',
      taskId: taskId,
      data: data,
    );

    if (response != null) {
      textChecklistController.clear();
      await loadChecklists();
      await loadComments();
    }
  }

//======================End Checklist===========================================

//================================Start Attachment==============================
  void _deleteFile(int fileId) async {
    try {
      // Memanggil API untuk menghapus file
      await ApiService.handleTaskFile(
        method: 'DELETE',
        taskId: widget.taskId,
        fileId: fileId, // ID file yang akan dihapus
      );

      // Jika berhasil, lakukan sesuatu, misalnya memuat ulang data
      setState(() {
        loadFile();
        loadComments();
      });

      // Tampilkan snackbar atau feedback kepada pengguna
      General.showSnackBar(context, "File berhasil dihapus");
    } catch (e) {
      // Tangani error jika terjadi kesalahan
      General.showSnackBar(context, "Gagal menghapus file, coba lagi.");
    }
  }

  void _showDeleteConfirmationDialog(int fileId) async {
    final confirm = await General.showDialogDelete(
        context: context,
        title: "Hapus File",
        message: "Apakah Anda Yakin Ingin Menghapus File Ini ? ",
        confirmButtonText: "Hapus",
        cancelButtonText: "Batal");

    if (confirm == true) {
      _deleteFile(fileId);
    }
  }

  Widget listFileWidget() {
    return Container(
      padding: EdgeInsets.all(16), // Padding di dalam container
      decoration: BoxDecoration(
        color: Colors.white, // Warna background box
        borderRadius: BorderRadius.circular(12), // Radius sudut kotak
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), // Warna shadow
            spreadRadius: 2, // Jarak shadow
            blurRadius: 5, // Ukuran blur shadow
            offset: Offset(0, 3), // Posisi shadow
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Attachment",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.left,
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

          SizedBox(
            height: 10,
          ),
          ValueListenableBuilder(
            valueListenable: onFileNotifier,
            builder: (context, listFile, child) {
              if (listFile.isEmpty) {
                return Container(
                  constraints: BoxConstraints(
                      maxHeight: 200, minHeight: 200, minWidth: 350),
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      'Belum ada Attachment',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              } else {
                return SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: listFile.length,
                    itemBuilder: (context, index) {
                      final fileId = (listFile[index]["id"] ?? 0);
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
                              SnackBar(
                                  content: Text("Tidak dapat membuka tautan")),
                            );
                          }
                        },
                        onLongPress: () {
                          if (fileType.toLowerCase() == "pdf") {
                            showPDFPreview(context, fileDownload);
                          } else if (fileType.toLowerCase() == "mp3") {
                            showAudioPreview(context, fileDownload);
                          } else if (fileType.toLowerCase() == "png" ||
                              fileType.toLowerCase() == "jpg" ||
                              fileType.toLowerCase() == "jpeg") {
                            showImagePreview(context, filePath);
                          } else {
                            showDialog(
                              context: context,
                              builder: (_) => Dialog(
                                insetPadding: EdgeInsets.all(20),
                                child: SingleChildScrollView(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Column(
                                          children: [
                                            // Gambar file
                                            Container(
                                              height: 300,
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                image: DecorationImage(
                                                  image: getImage(
                                                      fileType, filePath),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            // Nama file di bawah gambar
                                            SizedBox(
                                                height:
                                                    10), // Menambahkan jarak antara gambar dan nama file
                                            Text(
                                              fileName,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize:
                                                    16, // Anda bisa menyesuaikan ukuran font di sini
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines:
                                                  2, // Membatasi dua baris jika nama file terlalu panjang
                                            ),
                                          ],
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text("Tutup"),
                                      ),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                children: [
                                  // Gambar File
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
                                  ), // </Container> untuk gambar file

                                  // Tombol Hapus
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () =>
                                          _showDeleteConfirmationDialog(fileId),
                                      child: CircleAvatar(
                                        backgroundColor: Colors.red,
                                        radius: 15,
                                        child: Icon(
                                          Icons.delete,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                      ), // </CircleAvatar>
                                    ), // </GestureDetector>
                                  ), // </Positioned>
                                ],
                              ), // </Stack>

                              // Nama file di bawah gambar
                              SizedBox(height: 4),
                              Text(
                                fileName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12),
                              ), // </Text>
                            ],
                          ), // </Column>
                        ), // </Container>
                      ); // </GestureDetector>
                    }, // </itemBuilder>
                  ), // </ListView.builder>
                ); // </SizedBox>
              }
            }, // </builder dari ValueListenableBuilder>
          ), // </ValueListenableBuilder>
        ],
      ),
    );
    // </Column>
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
}
