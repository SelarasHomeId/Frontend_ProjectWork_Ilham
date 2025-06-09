import 'dart:convert';

import 'package:centrifuge/centrifuge.dart' as centrifuge;
import 'package:flutter/widgets.dart';
import 'package:selarashomeid/service/api_service.dart';
import 'package:selarashomeid/utils/constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WebSocket {
  late centrifuge.Client _client;
  centrifuge.Subscription? _subscription;
  late String userId;
  late Function(dynamic data) onDataReceive;

  WebSocket({required this.userId, required this.onDataReceive});

  Future<void> connect() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || userId.isEmpty) return;

    _client = centrifuge.createClient(
      '$baseUrlSocket/websocket',
      centrifuge.ClientConfig(name: 'dart', token: token),
    );

    _client.connected.listen((event) {
      debugPrint("✅ Connected: ${event.client}");
      _subscribeToChannel();
    });

    _client.disconnected.listen((event) {
      debugPrint('❌ Disconnected: code=${event.code}, reason=${event.reason}');

      switch (event.code) {
        case 109:
          debugPrint(
            '🔄 Token expired. Attempting to refresh token and reconnect...',
          );
          _handleTokenExpired(token);
          break;
        case 3500:
          debugPrint('🔄 Token invalid. Attempting to reconnect...');
          _handleTokenInvalid();
          break;
        case 3000:
          debugPrint(
            '🚪 Manual disconnect (e.g., debugPrintout). No reconnect needed.',
          );
          break;
        default:
          debugPrint(
            '⚠️ Unexpected disconnect code. Attempting to reconnect...',
          );
          _reconnect();
      }
    });

    await _client.connect();
  }

  void _subscribeToChannel() {
    final channel = userId;
    _subscription = _client.newSubscription(channel);

    _subscription?.publication.listen((event) {
      final Map<String, dynamic> message = json.decode(utf8.decode(event.data));
      debugPrint('📩 Received: $message');
      onDataReceive(message);
    });

    _subscription?.subscribe();
  }

  Future<Map<String, dynamic>?> sendRpc(
    String method,
    Map<String, dynamic> data,
  ) async {
    try {
      if (_client.state != centrifuge.State.connected) {
        debugPrint('❌ Cannot send RPC: Client is not connected.');
        await _reconnect();
        if (_client.state != centrifuge.State.connected) {
          return null;
        }
      }

      final encodedData = jsonEncode(data);
      debugPrint('📤 Sending RPC: method=$method, data=$encodedData');

      final response = await _client.rpc(method, utf8.encode(encodedData));

      final decodedResponse = json.decode(utf8.decode(response.data));
      debugPrint('📥 RPC Response: $decodedResponse');

      return decodedResponse as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ RPC Error: $e');
      return null;
    }
  }

  Future<void> disconnect() async {
    await _client.disconnect();
  }

  Future<void> _handleTokenExpired(String? token) async {
    final newToken = await ApiService.refreshTokenForWebSocket(token);
    if (newToken != null) {
      await _client.disconnect();
      await connect();
    } else {
      debugPrint('❌ Failed to refresh token.');
    }
  }

  Future<void> _handleTokenInvalid() async {
    await _client.disconnect();
    await connect();
  }

  Future<void> _reconnect() async {
    await _client.disconnect();
    await connect();
  }
}
