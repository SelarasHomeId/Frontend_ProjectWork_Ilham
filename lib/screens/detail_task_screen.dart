import 'package:flutter/material.dart';
import 'package:selarashomeid/screens/label_screen.dart';
import 'package:selarashomeid/service/api_service.dart';
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
  late FocusNode focusNode;

  late ValueNotifier<bool> onLoadingNotifier;
  late ValueNotifier<(String labelName, Color color)?> notifierLabelColor;

  String? currentDesc;

  @override
  void initState() {
    userProfileFuture = General.getUserProfile();

    onExpandableValue = ValueNotifier<bool>(false);
    onLoadingNotifier = ValueNotifier<bool>(false);

    notifierLabelColor = ValueNotifier<(String labelName, Color color)?>(null);

    textDescController = TextEditingController();
    focusNode = FocusNode();

    onLoadValue();
    super.initState();
  }

  Future<void> onLoadValue() async {
    onLoadingNotifier.value = true;
    final getUpdatedData = await ApiService.handleDetailTask(
      widget.taskId,
    );

    final desc = getUpdatedData["description"];
    final label = getUpdatedData["label"];
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

    textDescController.text = desc ?? "";
    currentDesc = desc;
    onLoadingNotifier.value = false;
  }

  @override
  void dispose() {
    onExpandableValue.dispose();
    onLoadingNotifier.dispose();

    textDescController.dispose();
    focusNode.dispose();
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
          title: Text('Project Planning'),
          // actions: [
          //   IconButton(
          //     icon: Icon(Icons.more_vert),
          //     onPressed: () {},
          //   ),
          // ],
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
                _buildCardDescription(
                  textDescController: textDescController,
                  focusNode: focusNode,
                  onSubmitButton: () async {
                    final getUpdatedData = await ApiService.handleTask(
                      method: 'PUT',
                      // workspaceId: widget.workspaceId,
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
                _buildLabelsButton(
                  onAddingLabel: (labelId) async {
                    onLoadingNotifier.value = true;
                    final getUpdatedData = await ApiService.handleTask(
                      method: 'PUT',
                      // workspaceId: widget.workspaceId,
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
                _buildDatePickers(),

                SizedBox(height: 20),

                // Add Comments
                _buildAddCommentSection(),
              ],
            ),
          ),
        ),
      ),
    );
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
                          onPressed: () {}, child: Text('Add Attachment')),
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
        _buildDateField('Start date'),
        SizedBox(width: 20),
        _buildDateField('Due date'),
      ],
    );
  }

  Widget _buildDateField(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        SizedBox(
          width: 150,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Select $label',
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddCommentSection() {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text('IH'),
        ),
        SizedBox(width: 10),
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Add comment',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(10),
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.send),
          onPressed: () {},
        ),
      ],
    );
  }
}
