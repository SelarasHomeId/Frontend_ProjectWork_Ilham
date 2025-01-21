import 'package:flutter/material.dart';
import 'package:selarashomeid/screens/notification_screen.dart';
import 'package:selarashomeid/screens/search_screen.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  @override
  final Size preferredSize;

  AppBarWidget({Key? key})
      : preferredSize = Size.fromHeight(kToolbarHeight),
        super(key: key);

  Route _createRoute(Widget targetScreen) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0); // Mulai dari kanan
        const end = Offset.zero; // Berakhir di posisi normal
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

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.red[900],
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.menu),
          color: Colors.white,
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.search),
          color: Colors.white,
          onPressed: () {
            Navigator.of(context).push(_createRoute(SearchScreen()));
          },
        ),
        IconButton(
          icon: Icon(Icons.notifications),
          color: Colors.white,
          onPressed: () {
            Navigator.of(context).push(_createRoute(NotificationScreen()));
          },
        ),
      ],
    );
  }
}
