import 'package:flutter/material.dart';
import 'package:selarashomeid/screens/notification_screen.dart';
import 'package:selarashomeid/screens/search_screen.dart';
import 'package:selarashomeid/service/api_service.dart';
import 'package:selarashomeid/service/web_socket.dart';
import 'package:selarashomeid/utils/general.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:app_badger/app_badger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AppBarWidget extends StatefulWidget implements PreferredSizeWidget {
  @override
  final Size preferredSize;

  AppBarWidget({Key? key})
      : preferredSize = const Size.fromHeight(kToolbarHeight),
        super(key: key);

  @override
  _AppBarWidgetState createState() => _AppBarWidgetState();
}

class _AppBarWidgetState extends State<AppBarWidget> {
  bool isLoading = false;
  int notificationCount = 0;
  int notificationCountBefore = 0;
  String selectedFilter = "Today";
  late WebSocket webSocket;
  final AudioPlayer _player = AudioPlayer();
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Route _createRoute(Widget targetScreen) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }

  Future<void> fetchNotifications() async {
    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    try {
      final response = await ApiService.getNotifications(token, selectedFilter);

      if (response != null && response['success'] == true) {
        final data = response['data'];
        if (data != null) {
          setState(() {
            final int currentCount = notificationCount;
            notificationCountBefore = currentCount;
            notificationCount = data['count_unread'] ?? 0;
            isLoading = false;
          });

          bool isSupported = await AppBadger.isBadgeSupported();
          if (isSupported) {
            if (notificationCount > 0 && notificationCount > notificationCountBefore) {
              await AppBadger.updateBadgeCount(notificationCount);
              await General.sendNotification(_notificationsPlugin, notificationCount, "Ada Notifikasi Baru Nih Buat Kamu", null);
            } else {
              await AppBadger.removeBadge();
              await General.sendNotification(_notificationsPlugin, 0, null, null);
            }
          } else {
            General.showSnackBar(context, "Device tidak mendukung badge");
          }
          
          return;
        }
      }
      setState(() {
        notificationCount = 0;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      General.showSnackBar(context, e.toString());
    }
  }

  void _playSound() async {
    try {
      await _player.play(AssetSource('notif_sound.ogg'));
    } catch (e) {
      debugPrint("Error when play sound: $e");
    }
  }

  Future<void> initWebSocket() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('id') ?? 0;
    webSocket = WebSocket(
      userId: id.toString(),
      onDataReceive: (data) {
        if (data != null) {
          if (data['is_new'] == true && data['count'] > notificationCount) {
            fetchNotifications();
            _playSound();
          }
        }
      },
    );
    await webSocket.connect();
  }

  Future<void> _initialize() async {
    await fetchNotifications();
    if (notificationCount > 0) {
      _playSound();
    }
  }

  @override
  void initState() {
    super.initState();
    _initialize();
    initWebSocket();
  }

  @override
  void dispose() {
    webSocket.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.red[900],
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          color: Colors.white,
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.push(context, _createRoute(SearchScreen())),
          child: const Text(
            'Search Task',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications),
              color: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  _createRoute(NotificationScreen()),
                ).then((_) => fetchNotifications());
              },
            ),
            if (notificationCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 6, 22, 144),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    notificationCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
          ],
        ),
      ],
    );
  }
}
