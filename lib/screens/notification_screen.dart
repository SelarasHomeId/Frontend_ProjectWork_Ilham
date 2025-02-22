import 'package:flutter/material.dart';
import 'package:selarashomeid/screens/detail_task_screen.dart';
import 'package:selarashomeid/service/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String selectedFilter = "Today";
  bool showUnreadOnly = false;
  bool isLoading = false;
  List<NotificationItem> notifications = [];

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  // Fungsi untuk mengambil notifikasi
  Future<void> fetchNotifications() async {
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    // Panggil ApiService untuk mendapatkan notifikasi
    final response = await ApiService.getNotifications(token, selectedFilter);

    if (response != null && response['success'] == true) {
      final dynamic data = response['data'];
      if (data == null || data['data'] == null || data['data'] is! List) {
        setState(() {
          notifications = [];
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ga ada notifikasi buat kamu hari ini')),
        );
        return;
      }

      final List<dynamic> dataList = data['data'];

      if (dataList.isEmpty) {
        setState(() {
          notifications = [];
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ga ada notifikasi buat kamu hari ini')),
        );
      } else {
        setState(() {
          notifications =
              dataList.map((item) => NotificationItem.fromJson(item)).toList();
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
      String message = response?['data']['message'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get notifications, cause:$message')),
      );
    }
  }

  Future<void> setNotificationAsRead(int id, int taskId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    // Panggil ApiService untuk mendapatkan notifikasi
    final response = await ApiService.setNotificationsAsRead(token, id);

    if (response != null && response['success'] == true) {
      fetchNotifications();
      final taskDetail = await ApiService.handleDetailTask(taskId);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetailTaskScreen(
            boardId: taskDetail["board_id"],
            taskId: taskDetail["id"],
          ),
        ),
      );
    } else {
      String message = response?['data']['message'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Failed to set notification as read, cause:$message')),
      );
    }
  }

  Future<void> setNotificationAsAllRead(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    // Panggil ApiService untuk mendapatkan notifikasi
    final response = await ApiService.setNotificationsAsRead(token, id);

    if (response != null && response['success'] == true) {
      fetchNotifications();
    } else {
      String message = response?['data']['message'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Failed to set notification as read, cause:$message')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.red[900],
        title: Text("Notifications"),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.done_all),
            onPressed: () {
              notifications.forEach((item) {
                setNotificationAsAllRead(item.id);
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  value: selectedFilter,
                  items: ["Today", "This Week", "This Month"]
                      .map((filter) => DropdownMenuItem(
                            value: filter,
                            child: Text(filter),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedFilter = value!;
                      fetchNotifications();
                    });
                  },
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      showUnreadOnly = !showUnreadOnly;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                          showUnreadOnly ? Colors.white : Colors.grey[700],
                      foregroundColor:
                          showUnreadOnly ? Colors.black : Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          side: BorderSide(color: Colors.black, width: 1.0))),
                  child: Text("Unread"),
                ),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : notifications.isEmpty
                      ? Center(child: Text("No notifications"))
                      : ListView.builder(
                          itemCount: notifications.length,
                          itemBuilder: (context, index) {
                            final notification = notifications[index];
                            if (showUnreadOnly && notification.isRead) {
                              return SizedBox
                                  .shrink(); // Skip if marked as read
                            }

                            return ListTile(
                              leading: Icon(Icons.notifications),
                              title: Text(notification.title),
                              subtitle: Text(notification.message),
                              trailing: Icon(
                                notification.isRead
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: notification.isRead
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              onTap: () async {
                                setNotificationAsRead(
                                    notification.id, notification.task_id);
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationItem {
  final int id;
  final int task_id;
  final String title;
  final String message;
  final String createdAt;
  final bool isRead;

  NotificationItem({
    required this.id,
    required this.task_id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'],
      task_id: json['task_id'],
      title: json['title'],
      message: json['message'],
      createdAt: json['created_at'],
      isRead: json['is_read'],
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: NotificationScreen(),
  ));
}
