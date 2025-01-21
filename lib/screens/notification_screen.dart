import 'package:flutter/material.dart';

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String selectedFilter = "Today";
  bool showUnreadOnly = false;

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
              // Mark all as read logic (to be implemented later)
              print("Mark all as read");
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
              child: ListView(
                children: [
                  if (!showUnreadOnly || (showUnreadOnly && true))
                    ListTile(
                      leading: Icon(Icons.notifications),
                      title: Text("New message from Alice"),
                      subtitle: Text("Today, 10:00 AM"),
                    ),
                  if (!showUnreadOnly || (showUnreadOnly && false))
                    ListTile(
                      leading: Icon(Icons.notifications),
                      title: Text("Your order has been shipped"),
                      subtitle: Text("Yesterday, 4:00 PM"),
                    ),
                  if (!showUnreadOnly || (showUnreadOnly && true))
                    ListTile(
                      leading: Icon(Icons.notifications),
                      title: Text("Reminder: Meeting at 3 PM"),
                      subtitle: Text("Today, 9:00 AM"),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: NotificationScreen(),
  ));
}
