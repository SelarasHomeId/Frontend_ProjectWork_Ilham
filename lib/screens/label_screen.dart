import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:selarashomeid/service/api_service.dart';
import 'package:selarashomeid/utils/general.dart';
import 'package:selarashomeid/widgets/loading_screen_widget.dart';

class LabelScreen extends StatefulWidget {
  const LabelScreen({super.key});

  @override
  State<LabelScreen> createState() => _LabelScreenState();
}

class _LabelScreenState extends State<LabelScreen> {
  late ValueNotifier<bool> onLoadingNotifier;
  late ValueNotifier<List<dynamic>> onDataNotifier;

  Color pickerColor = Color(0xff443a49);

  @override
  void initState() {
    onLoadingNotifier = ValueNotifier<bool>(false);
    onDataNotifier = ValueNotifier<List<dynamic>>([]);
    onLoadingLabel();
    super.initState();
  }

  Future<void> onLoadingLabel() async {
    onLoadingNotifier.value = false;
    final getData = await ApiService.handleLabel(
        method: "GET", params: {'no_paging': 'yes'});
    onDataNotifier.value = getData;
    onLoadingNotifier.value = false;
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
          title: Text('List Label'),
          actions: [
            ElevatedButton(
              onPressed: () async {
                await onLabelInputDialog(
                  context,
                  onClick: (labelname, color) async {
                    final stringColor = General().colorToString(color);

                    await ApiService.handleLabel(
                      method: "POST",
                      data: {
                        "title": labelname,
                        "color": stringColor,
                      },
                    );
                  },
                );

                await onLoadingLabel();
              },
              child: Text("Tambah Label"),
            )
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ValueListenableBuilder(
            valueListenable: onDataNotifier,
            builder: (context, listData, child) {
              return ListView.builder(
                itemCount: listData.length,
                itemBuilder: (context, index) {
                  final singleResponse = listData[index];

                  final currentColor = General().stringToColor(
                    singleResponse["color"].toString(),
                  );

                  final currentTitle = singleResponse["title"];
                  final isValidTitle = currentTitle != null &&
                      currentTitle is String &&
                      currentTitle.isNotEmpty;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: SizedBox(
                      height: 65,
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                Navigator.pop(context, singleResponse["id"]);
                              },
                              child: Row(
                                children: [
                                  SizedBox(
                                      width: 75,
                                      child: Text(
                                          isValidTitle ? currentTitle : " ")),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(8.0),
                                      decoration: BoxDecoration(
                                        color: currentColor,
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(16),
                                        ),
                                        border:
                                            Border.all(color: Colors.black12),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                ],
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () async {
                              await onLabelInputDialog(
                                context,
                                currentColor: currentColor,
                                textValue: currentTitle ?? "",
                                onClick: (labelName, color) async {
                                  final stringColor =
                                      General().colorToString(color);
                                  await ApiService.handleLabel(
                                    method: "PUT",
                                    labelId: singleResponse["id"],
                                    data: {
                                      "title": labelName,
                                      "color": stringColor,
                                    },
                                  );
                                },
                              );

                              await onLoadingLabel();
                            },
                            child: Icon(Icons.arrow_forward_ios_sharp),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

Future<void> onLabelInputDialog(
  BuildContext context, {
  Color? currentColor,
  String? textValue,
  required Future<void> Function(String labelName, Color color) onClick,
}) async {
  // return Navigator.push(
  //   context, builder: MaterialPageRoute(builder: (_) => LabelInputDialog());
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => LabelInputDialog(
        textValue: textValue,
        currentColor: currentColor,
        onClick: onClick,
      ),
    ),
  );
}

class LabelInputDialog extends StatefulWidget {
  final Color? currentColor;
  final String? textValue;
  final Future<void> Function(String labelName, Color color) onClick;
  const LabelInputDialog({
    super.key,
    this.currentColor,
    this.textValue,
    required this.onClick,
  });

  @override
  State<LabelInputDialog> createState() => _LabelInputDialogState();
}

class _LabelInputDialogState extends State<LabelInputDialog> {
  late Color pickedColor;
  late TextEditingController controller;
  late String currentTitle;

  late ValueNotifier<bool> onLoadingNotifier;

  @override
  void initState() {
    pickedColor = widget.currentColor ?? Colors.black;
    controller = TextEditingController(text: widget.textValue);
    currentTitle = widget.currentColor != null || widget.textValue != null
        ? "Update Label"
        : "Create Label";
    onLoadingNotifier = ValueNotifier<bool>(false);
    super.initState();
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
          title: Text(currentTitle),
          // actions: [
          //   ElevatedButton(
          //     onPressed: () {},
          //     child: Text("Tambah Label"),
          //   )
          // ],
        ),
        body: Padding(
          padding: EdgeInsets.all(18),
          child: SingleChildScrollView(
            child: SizedBox(
              // height: MediaQuery.of(context).size.height / 2,
              child: Column(
                children: [
                  TextFormField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'Enter Label Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                            12.0), // Mengubah sudut menjadi rounded
                      ),
                    ),
                  ),
                  SizedBox(height: 18),
                  SizedBox(
                    // height: MediaQuery.of(context).size.height / 2,
                    child: ColorPicker(
                      pickerColor: pickedColor,
                      onColorChanged: (value) {
                        setState(() {
                          pickedColor = value;
                        });
                      },
                    ),
                  ),
                  SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        onLoadingNotifier.value = true;
                        await widget.onClick(controller.text, pickedColor);
                        onLoadingNotifier.value = false;
                        Navigator.pop(context);
                      },
                      child: Text(currentTitle),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
        // actions: <Widget>[
        //   ElevatedButton(
        //     child: const Text('Got it'),
        //     onPressed: () {
        //       Navigator.of(context).pop();
        //     },
        //   ),
        // ],
      ),
    );
  }
}
