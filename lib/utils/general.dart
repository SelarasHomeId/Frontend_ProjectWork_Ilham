import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class General {
  static Future<void> saveToSharedPreferences(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    data.forEach((key, value) async {
      if (value is String) {
        await prefs.setString(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      } else if (value is bool) {
        await prefs.setBool(key, value);
      } else {
        throw UnsupportedError(
            'Tipe data $key dengan nilai $value tidak didukung');
      }
    });
  }

  static Future<void> clearSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<void> removeFromSharedPreferences(String key) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(key)) {
      await prefs.remove(key);
    }
  }

  static Future<void> editSharedPreferences(
      String key, dynamic newValue) async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey(key)) {
      if (newValue is String) {
        await prefs.setString(key, newValue);
      } else if (newValue is int) {
        await prefs.setInt(key, newValue);
      } else if (newValue is double) {
        await prefs.setDouble(key, newValue);
      } else if (newValue is bool) {
        await prefs.setBool(key, newValue);
      } else {
        throw UnsupportedError('Tipe data untuk key "$key" tidak didukung');
      }
    }
  }

  static Future<Map<String, String>> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('id') ?? 0;
    final name = prefs.getString('name') ?? 'User Name';
    final email = prefs.getString('email') ?? 'user@example.com';
    final roleName = prefs.getString('roleName') ?? ' - ';
    final divisiName = prefs.getString('divisiName') ?? ' - ';
    final createdAt = prefs.getString('createdAt') ?? ' - ';
    final initials = General.getInitials(name);

    return {
      'id': id.toString(),
      'name': name,
      'email': email,
      'initials': initials,
      'roleName': roleName,
      'divisiName': divisiName,
      'createdAt': createdAt,
    };
  }

  String colorToString(Color color) {
    String colorString = color.value.toString(); // Mengubah menjadi string
    return colorString;
  }

  Color stringToColor(String colorString) {
    int colorInt = int.parse(colorString); // Mengonversi string ke integer
    Color color = Color(colorInt); // Mengubah integer menjadi Color
    return color;
  }

  static String buildQueryParams(Map<String, String>? params) {
    if (params == null || params.isEmpty) return '';
    return '?${Uri(queryParameters: params).query}';
  }

  static String justBuildQuery(Map<String, String>? params) {
    if (params == null || params.isEmpty) return '';
    return Uri(queryParameters: params).query;
  }

  static String getDateFilter(String filter) {
    DateTime now = DateTime.now();
    DateFormat formatter = DateFormat('yyyy-MM-dd'); // Format YYYY-MM-DD
    String startDate = "";
    String endDate = "";

    if (filter == "Today") {
      startDate = formatter.format(now);
      endDate = formatter.format(now);
    } else if (filter == "This Week") {
      DateTime startOfWeek =
          now.subtract(Duration(days: now.weekday - 1)); // Senin awal minggu
      DateTime endOfWeek =
          startOfWeek.add(Duration(days: 6)); // Minggu akhir minggu

      startDate = formatter.format(startOfWeek);
      endDate = formatter.format(endOfWeek);
    } else if (filter == "This Month") {
      DateTime startOfMonth = DateTime(now.year, now.month, 1);
      DateTime endOfMonth =
          DateTime(now.year, now.month + 1, 0); // Hari terakhir bulan ini

      startDate = formatter.format(startOfMonth);
      endDate = formatter.format(endOfMonth);
    }

    return startDate.isNotEmpty && endDate.isNotEmpty
        ? '$startDate' '_' '$endDate'
        : "";
  }

  static Future<void> showSnackBar(
    BuildContext context,
    dynamic message, {
    int? durationSeconds,
  }) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: SizedBox(
          width: 200, // Lebar maksimum Snackbar
          child: Center(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        duration: Duration(seconds: durationSeconds ?? 2),
        behavior: SnackBarBehavior.floating, // Supaya tidak full width
        margin: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // Snackbar rounded
        ),
        backgroundColor: Colors.black87, // Warna lebih elegan
      ),
    );
  }

  static String capitalizeEachWord(String input) {
    return input.split(' ').map((word) {
      return word.isNotEmpty
          ? word[0].toUpperCase() + word.substring(1).toLowerCase()
          : '';
    }).join(' ');
  }

  // Color Initials
  static Color getColorFromInitial(String initial) {
    final List<String> colors = [
      "#FF5733",
      "#33FF57",
      "#3357FF",
      "#FF33A1",
      "#A133FF",
      "#33FFF5",
      "#FF8C00",
      "#FFD700",
      "#ADFF2F",
      "#00FF7F",
      "#40E0D0",
      "#1E90FF",
      "#DC143C",
      "#FF4500",
      "#8A2BE2",
      "#4B0082",
      "#7FFF00",
      "#8B0000",
      "#00FA9A",
      "#FF69B4",
      "#4682B4",
      "#20B2AA",
      "#FF6347",
      "#BDB76B",
      "#F08080",
      "#556B2F",
      "#9370DB",
      "#DDA0DD",
      "#8B4513",
      "#2E8B57",
      "#A52A2A",
      "#708090",
      "#FFB6C1",
      "#6A5ACD",
      "#FA8072",
      "#778899",
      "#F4A460",
      "#008080",
      "#BA55D3",
      "#CD5C5C",
      "#00CED1",
      "#DA70D6",
      "#B22222",
      "#5F9EA0",
      "#FF00FF",
      "#DEB887",
      "#00BFFF",
      "#9932CC",
      "#D2691E",
      "#7B68EE",
      "#C71585",
      "#191970",
      "#DB7093",
      "#F5DEB3",
      "#6495ED",
      "#32CD32",
      "#8FBC8F",
      "#B8860B",
      "#2F4F4F",
      "#F0E68C",
      "#8B008B",
      "#E9967A",
      "#800000",
      "#FF7F50",
      "#DC143C",
      "#4169E1",
      "#DAA520",
      "#2E8B57",
      "#CD853F",
      "#8A2BE2",
      "#FF4500",
      "#D2691E",
      "#FFDAB9",
      "#ADFF2F",
      "#48D1CC",
      "#7CFC00",
      "#F0FFF0",
      "#5F9EA0",
      "#FFDEAD",
      "#9400D3",
      "#AFEEEE",
      "#FF1493",
      "#00FFFF",
      "#0000FF",
      "#008B8B",
      "#FF00FF",
      "#800080",
      "#008000",
      "#808000",
      "#800000",
      "#C0C0C0",
      "#FF6347",
      "#FFD700",
      "#6B8E23",
      "#4682B4",
      "#B0E0E6"
    ];

    int charSum = initial.length == 2
        ? initial.codeUnitAt(0) + initial.codeUnitAt(1)
        : initial.codeUnitAt(0);
    int index = charSum % colors.length;

    return Color(int.parse(colors[index].substring(1), radix: 16) + 0xFF000000);
  }

  static Color getContrastingTextColor(Color background) {
    return background.computeLuminance() < 0.5 ? Colors.white : Colors.black;
  }

  //Intials User
  static String getInitials(String name) {
    List<String> words = name.trim().split(RegExp(r"\s+"));
    if (words.isEmpty || words[0].isEmpty) return "";
    if (words.length > 1) {
      return (words[0][0] + words[words.length - 1][0]).toUpperCase();
    } else {
      return words[0][0].toUpperCase();
    }
  }

  static bool checkChecklistCompleted(String checklist) {
    List<String> parts = checklist.split('/');
    int x = int.parse(parts[0]);
    int y = int.parse(parts[1]);
    return x == y;
  }

  //===============Star Show Dialog==========================================
  static Future<void> showDialogAdd({
    required BuildContext context,
    required String title,
    required String hintText,
    required TextEditingController controller,
    required Future<bool> Function(String) onConfirm,
    String? Function(String)? validate,
    Color headerColor = Colors.green,
    Color? buttonColor,
    String confirmButtonText = 'Simpan',
    String cancelButtonText = 'Batal',
  }) async {
    await showDialog(
      context: context,
      builder: (context) {
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
                  color: headerColor,
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
                title,
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
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: hintText,
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
                      cancelButtonText,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),

                  // Confirm Button
                  TextButton(
                    onPressed: () async {
                      final input = controller.text.trim();

                      // Validation
                      if (validate != null) {
                        final error = validate(input);
                        if (error != null) {
                          ScaffoldMessenger.of(context).removeCurrentSnackBar();
                          General.showSnackBar(context, error);
                          return;
                        }
                      }

                      // Execute confirmation logic
                      try {
                        final success = await onConfirm(input);
                        if (success) {
                          controller.clear();
                          Navigator.of(context).pop();
                        }
                      } catch (e) {
                        General.showSnackBar(context, 'Error: $e');
                      }
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: buttonColor ?? headerColor,
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      confirmButtonText,
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

  static Future<bool?> showDialogConfirmDelete({
    required BuildContext context,
    required String title,
    required String message,
    required String additionalMessage,
    required String confirmButtonText,
    required String cancelButtonText,
    IconData? coreIcon,
    MaterialColor? coreTheme,
  }) async {
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
                  color: coreTheme ?? Colors.red,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child: Icon(
                    coreIcon ?? Icons.delete,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                    if (additionalMessage != "") ...[
                      SizedBox(height: 5),
                      Text(
                        additionalMessage, // Menggunakan argumen baru
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: coreTheme ?? Colors.red,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      cancelButtonText,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(
                      backgroundColor: coreTheme != null
                          ? coreTheme.shade800
                          : Colors.red[800],
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      confirmButtonText,
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
    return confirm;
  }

  static Future<bool?> showDialogConfirmCustom({
    required BuildContext context,
    required IconData coreIcon,
    required MaterialColor coreTheme,
    required String title,
    required String message,
    required String additionalMessage,
    required String confirmButtonText,
    required String cancelButtonText,
  }) async {
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
                  color: coreTheme,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child: Icon(
                    coreIcon,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                    if (additionalMessage != "") ...[
                      SizedBox(height: 5),
                      Text(
                        additionalMessage, // Menggunakan argumen baru
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: coreTheme,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      cancelButtonText,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(
                      backgroundColor: coreTheme.shade800,
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      confirmButtonText,
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
    return confirm;
  }

  static Future<bool?> showDialogDelete({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmButtonText,
    required String cancelButtonText,
  }) async {
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
                  color: Colors.red,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.delete,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                title,
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
                  message,
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
                      backgroundColor: Colors.grey[600],
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      cancelButtonText,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red[800],
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      confirmButtonText,
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
    return confirm;
  }

  static Future<void> showDialogEdit({
    required BuildContext context,
    required TextEditingController controller,
    required List<dynamic> existingItems,
    required String itemName,
    required String hintText,
    required String emptyFieldMessage,
    required String duplicateMessage,
    required Future<void> Function(Map<String, dynamic> data) onSave,
  }) async {
    return showDialog(
      context: context,
      builder: (context) {
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
                  color: const Color.fromARGB(255, 76, 81, 175),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child: Icon(Icons.edit, size: 80, color: Colors.white),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Edit $itemName',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: hintText + itemName,
                    hintStyle: TextStyle(color: Colors.grey[500]),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      controller.text = '';
                      Navigator.pop(context);
                    },
                    style: _buttonStyle(Colors.grey[600]!),
                    child: Text('Batal', style: TextStyle(color: Colors.white)),
                  ),
                  TextButton(
                    onPressed: () async {
                      final inputText = controller.text.trim();

                      if (inputText.isEmpty) {
                        General.showDialogError(
                            context: context,
                            title: 'Error',
                            message: emptyFieldMessage,
                            confirmButtonText: "Oke");
                        return;
                      }

                      // if (inputText.length > 20) {
                      //   Navigator.pop(context);
                      //   Future.delayed(Duration(milliseconds: 100), () {
                      //     showSnackBar(context,
                      //         'Nama $itemName tidak boleh lebih dari 20 karakter');
                      //   });
                      //   return;
                      // }

                      final isDuplicate = existingItems.any((item) =>
                          item['name'].toLowerCase() ==
                          inputText.toLowerCase());
                      if (isDuplicate) {
                        General.showDialogError(
                            context: context,
                            title: 'Error',
                            message: duplicateMessage,
                            confirmButtonText: "Oke");
                        return;
                      }

                      Navigator.pop(context);
                      final confirm = await showDialogConfirmEdit(
                        context: context,
                        title: "Konfirmasi",
                        message:
                            "Apakah anda Yakin Ingin Mengubah Nama $itemName Ini?",
                        confirmButtonText: "Ya, Ubah",
                        cancelButtonText: "Batal",
                      );

                      if (confirm == true) {
                        try {
                          await onSave({'name': inputText});
                          controller.text = "";
                        } catch (e) {
                          showSnackBar(
                              context, 'Gagal memperbarui $itemName: $e');
                        }
                      }
                    },
                    style: _buttonStyle(Color.fromARGB(255, 76, 81, 175)),
                    child:
                        Text('Simpan', style: TextStyle(color: Colors.white)),
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

  static ButtonStyle _buttonStyle(Color color) {
    return TextButton.styleFrom(
      backgroundColor: color,
      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  static Future<bool?> showDialogConfirmEdit({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmButtonText,
    required String cancelButtonText,
  }) async {
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
                  color: const Color.fromARGB(255, 7, 14, 150),
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.question_mark_sharp,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                title,
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
                  message,
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
                      backgroundColor: Colors.grey[600],
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      cancelButtonText,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 38, 47, 225),
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      confirmButtonText,
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
    return confirm;
  }

  static Future<bool?> showDialogError({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmButtonText,
  }) async {
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
                  color: Colors.red,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.error,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                title,
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
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.red[800],
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  confirmButtonText,
                  style: TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
    return confirm;
  }

  static Future<bool?> showDialogInfo({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmButtonText,
  }) async {
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
                  color: Colors.blue,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.info,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                title,
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
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  confirmButtonText,
                  style: TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
    return confirm;
  }

  static Future<bool?> showDialogSuccess({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmButtonText,
  }) async {
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
                  color: Colors.green,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.check,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                title,
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
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.green[800],
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  confirmButtonText,
                  style: TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
    return confirm;
  }

  static Future showDialogMessage({
    required BuildContext context,
    required String title,
    required String message,
  }) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
              maxWidth: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Section
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: AnimatedScale(
                      duration: Duration(milliseconds: 500),
                      scale: 1.2,
                      child: Icon(
                        Icons.email, // Icon tetap statis
                        color: Colors.white,
                        size: 80,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 5),

                // Title
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 5),

                // Scrollable Content
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 5),

                // Close Button
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Tutup',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  static String? validatePassword(
    String flag,
    String? value,
  ) {
    if (value == null || value.isEmpty) {
      return '$flag wajib diisi';
    }
    if (value.length < 8) {
      return '$flag minimal 8 karakter';
    }
    if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
      return '$flag harus mengandung huruf';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return '$flag harus mengandung angka';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return '$flag harus mengandung karakter khusus (!@#\$%^&* dll)';
    }
    return null;
  }
}

//===============End Show Dialog

class ValueListenableBuilder2<A, B> extends StatelessWidget {
  final ValueListenable<A> first;
  final ValueListenable<B> second;
  final Widget Function(BuildContext, A, B, Widget?) builder;

  const ValueListenableBuilder2({
    Key? key,
    required this.first,
    required this.second,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: first,
      builder: (context, valueA, _) {
        return ValueListenableBuilder<B>(
          valueListenable: second,
          builder: (context, valueB, child) {
            return builder(context, valueA, valueB, child);
          },
        );
      },
    );
  }
}
