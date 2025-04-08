import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';
import 'package:selarashomeid/screens/label_screen.dart';
import 'package:selarashomeid/service/api_service.dart';
import 'package:selarashomeid/utils/file_picker.dart';
import 'package:selarashomeid/utils/general.dart';
import 'package:selarashomeid/widgets/loading_screen_widget.dart';
import 'package:selarashomeid/widgets/workspace_widget.dart';

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

  late FocusNode focusNode;
  late FocusNode titleFocusNode;
  late FocusNode descFocusNode;

  late ValueNotifier<bool> onLoadingNotifier;
  late ValueNotifier<List<Map<String, dynamic>>> onFileNotifier;
  late ValueNotifier<bool> onLoadingFileNotifier;
  late ValueNotifier<List<Map<String, dynamic>>> onCommentNotifier;
  late ValueNotifier<bool> onLoadingCommentNotifier;

  late ValueNotifier<List<(String labelName, Color color, int id)>>
      notifierLabelColor;
  late List<int> currentLabelIds;

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

  late int workspaceId;
  late String workspaceName;

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
    onLoadingCommentNotifier = ValueNotifier<bool>(false);

    textDescController = TextEditingController();
    textTitleController = TextEditingController();
    textCommentController = TextEditingController();
    currentWatch = ValueNotifier<bool>(false);
    currentIsCompleted = ValueNotifier<bool>(false);
    currentCover = ValueNotifier<String?>(null);

    titleFocusNode = FocusNode();
    descFocusNode = FocusNode();

    currentBoardId = ValueNotifier<int>(0);
    currentWorkspaceId = ValueNotifier<int>(0);

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
    final isCompleted = getUpdatedData["is_completed"];
    final assignToUser = getUpdatedData['assign_to_user'];
    final title = getUpdatedData["title"];
    final watch = getUpdatedData["watch"];
    final label = getUpdatedData["label"];
    final workspaceIdCurrent = getUpdatedData["workspace"]["id"];
    final boardId = getUpdatedData["board_id"];
    final cover = getUpdatedData["cover"];
    final date = getUpdatedData["due_date"];

    final workspaceData = getUpdatedData["workspace"];
    workspaceId = workspaceData["id"];
    workspaceName = workspaceData["name"];

    final labelData = label != null ? label["data"] as List : [];
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

    textTitleController.text = General.capitalizeEachWord(title ?? "");
    textDescController.text = desc ?? "";
    currentTitle = title;
    currentWatch.value = watch;
    currentDesc = desc;
    currentWorkspaceId.value = workspaceIdCurrent;
    currentBoardId.value = boardId;
    currentDate = date;
    currentCover.value = cover != null ? cover["view"].toString() : null;
    currentIsCompleted.value = isCompleted;
    final assignedMemberData = assignToUser != null ? assignToUser["data"] as List : [];
    if (assignedMemberData.isNotEmpty) {
      assignedMembers = assignedMemberData.map((item) {
        return item as Map<String, dynamic>;
      }).toList();
    }
    onLoadingNotifier.value = false;
  }

  @override
  void dispose() {
    onExpandableValue.dispose();
    onLoadingNotifier.dispose();

    textDescController.dispose();
    textTitleController.dispose();
    textCommentController.dispose();
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
        // setState(() {});
        General.showSnackBar(context, "cover added");
      }
    }
  }

  void deteleTask(int taskId) async {
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
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => WorkspaceWidget(
                workspace: workspaceName,
                workspaceId: workspaceId,
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
      _searchUserByName();
    });
  }

  void _showAddMemberDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding:
                  EdgeInsets.all(0), // Remove extra padding around content
              titlePadding:
                  EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Add Member",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(
                          context); // Menutup dialog ketika icon X ditekan
                    },
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search field for filtering users
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search User...",
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        _searchUserByName();
                      },
                    ),
                  ),
                  SizedBox(height: 10),
                  // Loading indicator or list of users
                  _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : Expanded(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = filteredUsers[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: General.getColorFromInitial(
                                      General.getInitials(user['name'])),
                                  child: Text(
                                    General.getInitials(user['name']),
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(user['name']),
                                subtitle: Text(user['email']),
                                onTap: () {
                                  // Tindakan ketika item user dipilih
                                  print("Selected user: ${user['name']}");
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
                      style: TextButton.styleFrom(
                        minimumSize: Size(100, 36), // Lebar dan tinggi minimum
                      ),
                      onPressed: () {
                        Navigator.pop(context); // Menutup dialog
                      },
                      child:
                          Text('Cancel', style: TextStyle(color: Colors.red)),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: Size(100, 36), // Lebar dan tinggi minimum
                      ),
                      onPressed: () {
                        // Logika untuk melakukan tindakan Done
                        Navigator.pop(context); // Menutup dialog
                      },
                      child:
                          Text('Done', style: TextStyle(color: Colors.green)),
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

  void _searchUserByName() {
    String keyword = _searchController.text.toLowerCase();

    if (keyword.isEmpty) {
      setState(() {
        filteredUsers = users; // Reset to show all users
      });
      return;
    }

    setState(() {
      filteredUsers = users
          .where((user) => user['name'].toLowerCase().contains(keyword))
          .toList();
    });
  }

  Widget _buildMember(List<dynamic> assignedMembers) {
    return ExpansionPanelList(
      elevation: 1,
      expandedHeaderPadding: EdgeInsets.all(0),
      expansionCallback: (int index, bool isExpanded) {
        setState(() {
          // Toggle expansion state when clicked
          isExpanded = !isExpanded;
        });
      },
      children: [
        ExpansionPanel(
          headerBuilder: (BuildContext context, bool isExpanded) {
            return InkWell(
              onTap: () {
                setState(() {
                  isExpanded = !isExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Assigned Members', // Change the header title as needed
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            );
          },
          body: assignedMembers.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('No members assigned yet.'),
                )
              : Wrap(
                  children: assignedMembers.map<Widget>((member) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: General.getColorFromInitial(
                                General.getInitials(member['name'])),
                            child: Text(
                              General.getInitials(member['name']),
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            member['name'],
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
          isExpanded: true, // Set this to true by default for expanded state
        ),
      ],
    );
  }

  //end assogn to user==========================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !titleFocusNode.hasFocus && !descFocusNode.hasFocus,
      onPopInvokedWithResult: (didPop, result) {
        if (titleFocusNode.hasFocus) {
          titleFocusNode.unfocus();
        }
        if (descFocusNode.hasFocus) {
          descFocusNode.unfocus();
        }
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
                onPressed: () {
                  // Aksi ketika tombol back ditekan
                  Navigator.pop(context); // Contoh aksi kembali
                },
                color: Colors.white, // Menentukan warna tombol back
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
                          break;
                        case 'move':
                          Map<String, int>? dataDialog = await _showMoveDialog(
                              currentWorkspaceId.value, currentBoardId.value);
                          if (dataDialog != null) {
                            final data = {"board_id": dataDialog["board_id"]};

                            await ApiService.handleTask(
                              method: 'PUT',
                              data: data,
                              taskId: widget.taskId,
                            );
                          }
                          General.showSnackBar(context, "task moved");
                          break;
                        case 'delete':
                          deteleTask(widget.taskId);
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
                        value: currentCover.value == null ? 'add_cover' : 'del_cover',
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
                        value: 'move',
                        child: Row(
                          children: [
                            Icon(Icons.move_to_inbox),
                            SizedBox(width: 8),
                            Text('Pindah Board'),
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
                      Padding(
                          padding: const EdgeInsets.only(bottom: 8),
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

                      _buildUserInfo(userProfileFuture),
                      SizedBox(height: 20),

                      // Quick Actions
                      _buildQuickActions(onExpandableValue),

                      SizedBox(height: 20),

                      // _buildMember(assignedMembers),
                      // SizedBox(height: 20),

                      // Add Card Description
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Update Description: Berhasil')),
                            );
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

                      // Start and Due Dates
                      Text("Due Date",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(
                        height: 10,
                      ),
                      _buildDatePickers(),

                      SizedBox(height: 20),

                      // Comments Section
                      Text("Comments",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      _buildAddCommentSection(widget.taskId),

                      // **Gunakan ValueListenableBuilder untuk update komentar tanpa fetch ulang**
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
                            // **Menampilkan daftar komentar**
                            child: _buildCommentList(),
                          );
                        },
                      ),

                      SizedBox(height: 30),
                      Text("Attachment",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      listFileWidget(),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat workspace: $e')),
        );
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

  Future<void> loadFile() async {
    onLoadingFileNotifier.value = true;
    final getFileList = await ApiService.handleTaskFile(
      method: "GET",
      taskId: widget.taskId,
    );

    onFileNotifier.value = (getFileList is List
        ? getFileList.map((e) {
            return {
              "id": e["id"],
              "fileName": e["file"]["name"],
              "filePath": e["file"]["view"],
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

  // Fungsi untuk onRefresh RefreshIndicator
  Future<void> _handleRefresh() async {
    await Future.wait([
      onLoadValue(),
      loadComments(),
      loadFile(),
    ]);
  }

  Widget _buildUserInfo(Future<Map<String, String>> userProfileFuture) {
    return FutureBuilder<Map<String, String>>(
        future: userProfileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container();
          }

          final currentData = snapshot.data;
          return Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue,
                child: Text(currentData!["initials"].toString()),
              ),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentData["name"].toString(),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    currentData["email"].toString(),
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ],
          );
        });
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

                            onLoadingNotifier.value = false;
                            onLoadingFileNotifier.value = false;
                          },
                          child: Text('Add Attachment')),
                      SizedBox(width: 10),
                      ElevatedButton(
                          onPressed: _showAddMemberDialog,
                          child: Text('Members')),
                    ],
                  ),
                  isExpanded: expandletrue,
                ),
              ]);
        });
  }

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
            hintText: 'Add card description',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.all(10),
          ),
          maxLines: 3,
        ),
        ValueListenableBuilder(
          valueListenable: textDescController,
          builder: (context, value, child) {
            if (currentDesc != value.text) {
              return ElevatedButton(
                onPressed: onSubmitButton,
                child: Text("Simpan"),
              );
            }

            return Container();
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

  Widget _buildDatePickers() {
    return Row(
      children: [
        _buildDateField(),
      ],
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: () async {
        var datePicker = await showDatePicker(
          context: context,
          firstDate: DateTime(2000),
          lastDate: DateTime(2500),
          fieldLabelText: "Waktu Akhir Task",
        );

        if (datePicker != null && mounted) {
          final currentTime = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
          );

          if (currentTime != null) {
            onLoadingNotifier.value = true;

            datePicker = datePicker.copyWith(
              hour: currentTime.hour,
              minute: currentTime.minute,
            );

            final timeToLocal = datePicker.toLocal();
            final dueDate =
                DateFormat("yyyy-MM-dd HH:mm:ss").format(timeToLocal);

            final getUpdatedData = await ApiService.handleTask(
              method: 'PUT',
              // workspaceId: widget.workspaceId,
              taskId: widget.taskId,
              boardId: widget.boardId,
              data: {'due_date': dueDate},
            );

            if (getUpdatedData != null) {
              onEndDateNotifier.value = datePicker;
            }

            onLoadingNotifier.value = false;
          }
        }
      },
      child: ValueListenableBuilder(
        valueListenable: onEndDateNotifier,
        builder: (context, value, child) {
          final currentDateTime = value != null
              ? DateFormat('EEEE, dd MMMM yyyy - HH:mm WIB').format(value)
              : null;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                child: currentDateTime == null
                    ? GestureDetector(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5), // Menambahkan padding
                          decoration: BoxDecoration(
                            color: Colors
                                .transparent, // Bisa diganti warna background jika diperlukan
                            border: Border.all(
                                color: Colors
                                    .blue), // Menambahkan border dengan warna biru
                            borderRadius: BorderRadius.circular(
                                50), // Membuat border dengan radius 50
                          ),
                          child: Text(
                            'Select Due Date',
                            style: TextStyle(), // Tidak ada underline kali ini
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          Text(
                            currentDateTime,
                            style: TextStyle(decoration: TextDecoration.none),
                          ),
                          SizedBox(width: 10),
                          GestureDetector(
                            child: Icon(
                              Icons.edit,
                              color: const Color.fromARGB(255, 114, 114, 114),
                            ),
                          ),
                          SizedBox(width: 10),
                          GestureDetector(
                            onTap: () async {
                              onLoadingNotifier.value = true;

                              final getUpdatedData =
                                  await ApiService.handleTask(
                                method: 'PUT',
                                // workspaceId: widget.workspaceId,
                                taskId: widget.taskId,
                                boardId: widget.boardId,
                                data: {'due_date': ''},
                              );

                              if (getUpdatedData != null) {
                                onEndDateNotifier.value = null;
                              }

                              onLoadingNotifier.value = false;
                            },
                            child: Icon(
                              Icons.cancel,
                              color: const Color.fromARGB(255, 114, 114, 114),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

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
        // ValueListenableBuilder(
        //   valueListenable: textCommentController,
        //   builder: (context, value, child) {
        //     if (textCommentController.text.isNotEmpty) {
        //       return ElevatedButton(
        //         onPressed: () async {
        //           await _addComment(taskId);
        //         },
        //         child: Text("Kirim"),
        //       );
        //     }
        //     return Container();
        //   },
        // ),
      ],
    );
  }

  Widget listFileWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ValueListenableBuilder(
          valueListenable: onFileNotifier,
          builder: (context, listFile, child) {
            return SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: listFile.length,
                itemBuilder: (context, index) {
                  final fileType =
                      (listFile[index]["name"] ?? "").toString().split(".");
                  final filePath =
                      (listFile[index]["filePath"] ?? "").toString();

                  return Container(
                    width: 150,
                    height: 150,
                    margin: EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFFC4C4C4),
                      border: Border.all(
                        color: Colors.transparent,
                        width: 5,
                      ),
                      borderRadius: BorderRadius.circular(5),
                      image: DecorationImage(
                        // image: NetworkImage(fileDoc.file_url),
                        image: getImage(fileType.last, filePath),
                        fit: BoxFit.cover,
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
      return AssetImage("assets/pdf_icon.jpg");
    case "docx":
      return AssetImage("assets/doc_icon.jpg");
    default:
      return NetworkImage(path);
  }
}
