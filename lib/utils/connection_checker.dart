import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectionChecker extends StatefulWidget {
  final Widget child;

  const ConnectionChecker({required this.child, super.key});

  @override
  State<ConnectionChecker> createState() => _ConnectionCheckerState();
}

class _ConnectionCheckerState extends State<ConnectionChecker> {
  bool _hasConnection = true;
  late StreamSubscription _subscription;
  Timer? _periodicTimer;

  @override
  void initState() {
    super.initState();
    _checkConnection();

    _subscription = Connectivity().onConnectivityChanged.listen((status) {
      _checkConnection();
    });

    _periodicTimer = Timer.periodic(Duration(seconds: 10), (_) {
      _checkConnection();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _periodicTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    bool isConnected = connectivityResult != ConnectivityResult.none;

    if (isConnected) {
      try {
        final result = await InternetAddress.lookup('google.com');
        if (result.isEmpty || result[0].rawAddress.isEmpty) {
          isConnected = false;
        }
      } on SocketException catch (_) {
        isConnected = false;
      }
    }

    setState(() => _hasConnection = isConnected);
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        if (!_hasConnection) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/no_internet.gif',
                    width: 150,
                    height: 150,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ups! Koneksi internet kamu terputus 😞\nCek kembali jaringanmu ya.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return widget.child;
      },
    );
  }
}