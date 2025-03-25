import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';
import 'package:selarashomeid/screens/label_screen.dart';
import 'package:selarashomeid/service/api_service.dart';
import 'package:selarashomeid/utils/file_picker.dart';
import 'package:selarashomeid/utils/general.dart';
import 'package:selarashomeid/widgets/loading_screen_widget.dart';

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

  late ValueNotifier<bool> onExpandableValue;

  late TextEditingController textDescController;
  late TextEditingController textTitleController;
  late TextEditingController textCommentController;

  late FocusNode focusNode;
  late FocusNode titleFocusNode;

  late ValueNotifier<bool> onLoadingNotifier;
  late ValueNotifier<List<Map<String, dynamic>>> onFileNotifier;
  late ValueNotifier<bool> onLoadingFileNotifier;
  late ValueNotifier<List<Map<String, dynamic>>> onCommentNotifier;
  late ValueNotifier<bool> onLoadingCommentNotifier;

  late ValueNotifier<(String labelName, Color color)?> notifierLabelColor;

  String? currentDesc;
  String? currentTitle;
  String? currentComment;
  late ValueNotifier<DateTime?> onEndDateNotifier;
  late ValueNotifier<bool> currentWatch;

  @override
  void initState() {
    userProfileFuture = General.getUserProfile();

    onExpandableValue = ValueNotifier<bool>(false);
    onLoadingNotifier = ValueNotifier<bool>(false);

    notifierLabelColor = ValueNotifier<(String labelName, Color color)?>(null);
    onEndDateNotifier = ValueNotifier<DateTime?>(null);
    onFileNotifier = ValueNotifier<List<Map<String, dynamic>>>([]);
    onLoadingFileNotifier = ValueNotifier<bool>(false);
    onCommentNotifier = ValueNotifier<List<Map<String, dynamic>>>([]);
    onLoadingCommentNotifier = ValueNotifier<bool>(false);

    textDescController = TextEditingController();
    textTitleController = TextEditingController();
    textCommentController = TextEditingController();
    currentWatch = ValueNotifier<bool>(false);
    focusNode = FocusNode();
    titleFocusNode = FocusNode();

    Future.wait(
      [
        onLoadValue(),
        loadFile(),
      ],
    );
    super.initState();
  }

  Future<void> onLoadValue() async {
    onLoadingNotifier.value = true;
    final getUpdatedData = await ApiService.handleDetailTask(
      widget.taskId,
    );

    final desc = getUpdatedData["description"];
    final title = getUpdatedData["title"];
    final watch = getUpdatedData["watch"];
    final label = getUpdatedData["label"];
    final comment = getUpdatedData["commnet"];
    final labelData = label != null ? label["data"] as List : [];
    if (labelData.isNotEmpty) {
      final tyrParceColor = int.tryParse(labelData.first["color"]);

      notifierLabelColor.value = (
        labelData.first["title"],
        (tyrParceColor == null
            ? Colors.black
            : General().stringToColor(labelData.first["color"])),
      );
    }

    await loadComments();

    textTitleController.text = General.capitalizeEachWord(title ?? "");
    textDescController.text = desc ?? "";
    currentTitle = title;
    currentWatch.value = watch;
    currentDesc = desc;
    currentComment = comment;
    onLoadingNotifier.value = false;
  }

  @override
  void dispose() {
    onExpandableValue.dispose();
    onLoadingNotifier.dispose();

    textDescController.dispose();
    textTitleController.dispose();
    textCommentController.dispose();
    focusNode.dispose();
    titleFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
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
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: Colors.white,
              ),
              onSelected: (String result) async {
                switch (result) {
                  case 'watch':
                    final valueWatch = !currentWatch.value;
                    final data = {"watch": valueWatch};

                    final response = await ApiService.handleTask(
                      method: 'PUT',
                      data: data,
                      taskId: widget.taskId,
                    );

                    if (response != null) {
                      // Jika API berhasil, kita update text controller dengan nilai yang dikirim
                      currentWatch.value =
                          valueWatch; // Pastikan text controller memiliki nilai terbaru
                    }
                    break;
                  case 'move':
                    // Tindakan untuk pindah board
                    break;
                  case 'delete':
                    // Tindakan untuk hapus task
                    break;
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'watch',
                  child: Row(
                    children: [
                      Icon(currentWatch.value == false
                          ? Icons.visibility
                          : Icons.visibility_off),
                      SizedBox(width: 8),
                      Text(currentWatch.value == false
                          ? "Watch"
                          : "Stop Watching"),
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
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUserInfo(userProfileFuture),
                SizedBox(height: 20),

                // Quick Actions
                _buildQuickActions(onExpandableValue),

                SizedBox(height: 20),

                // Add Card Description
                Text("Description",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                _buildCardDescription(
                  textDescController: textDescController,
                  focusNode: focusNode,
                  onSubmitButton: () async {
                    final getUpdatedData = await ApiService.handleTask(
                      method: 'PUT',
                      taskId: widget.taskId,
                      boardId: widget.boardId,
                      data: {'description': textDescController.text},
                    );

                    if (getUpdatedData != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Update Description: Berhasil')),
                      );
                      currentDesc = textDescController.text;
                    }
                  },
                ),

                SizedBox(height: 20),

                // Labels
                Text("Labels",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                _buildLabelsButton(
                  onAddingLabel: (labelId) async {
                    onLoadingNotifier.value = true;
                    final getUpdatedData = await ApiService.handleTask(
                      method: 'PUT',
                      taskId: widget.taskId,
                      boardId: widget.boardId,
                      data: {'label': labelId},
                    );

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
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(
                  height: 10,
                ),
                _buildDatePickers(),

                SizedBox(height: 20),

                // Comments Section
                Text("Comments",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                listFileWidget(),
              ],
            ),
          ),
        ),
      ),
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
          "user_name": response['created_by']
              ['name'], // Ambil dari created_by task
        };
      }).toList();
    }

    onLoadingCommentNotifier.value = false;
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
                                MultipartFile.fromPath(
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
                      ElevatedButton(onPressed: () {}, child: Text('Members')),
                    ],
                  ),
                  isExpanded: expandletrue,
                ),
              ]);
        });
    // return Column(
    //   crossAxisAlignment: CrossAxisAlignment.start,
    //   children: [
    //     Text(
    //       'Quick Actions',
    //       style: TextStyle(fontWeight: FontWeight.bold),
    //     ),
    //     SizedBox(height: 10),
    //     Wrap(
    //       children: [
    //         ElevatedButton(onPressed: () {}, child: Text('Add Checklist')),
    //         SizedBox(width: 10),
    //         ElevatedButton(onPressed: () {}, child: Text('Add Attachment')),
    //         SizedBox(width: 10),
    //         ElevatedButton(onPressed: () {}, child: Text('Members')),
    //       ],
    //     ),
    //   ],
    // );
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
      {required Future<void> Function(String) onAddingLabel}) {
    return Row(
      children: [
        ElevatedButton(
          onPressed: () async {
            final id = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LabelScreen(),
              ),
            );
            await onAddingLabel(id.toString());
          },
          child: Text('Labels'),
        ),
        ValueListenableBuilder(
          valueListenable: notifierLabelColor,
          builder: (context, value, child) {
            if (value != null) {
              return Container(
                margin: EdgeInsets.only(left: 8),
                padding: EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  color: value.$2,
                ),
                child: Text(value.$1),
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
                backgroundColor: Colors.blueAccent,
                child: Text(comment['user_name'][0].toUpperCase()),
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
            CircleAvatar(
              backgroundColor: Colors.blue,
              child: FutureBuilder<Map<String, String>>(
                future: userProfileFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return Text('U');
                  return Text(snapshot.data!['initials'] ?? 'U');
                },
              ),
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
      return AssetImage("assets/images/pdf.png");
    case "doc":
    case "docx":
      return AssetImage("assets/images/doc.png");
    default:
      return NetworkImage(path);
  }
}
