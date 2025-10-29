import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../url.dart';

class ChatHistoryProvider with ChangeNotifier {
  Uri _apiJoin(String path) {
    final base = Uri.parse(urlLocal.trim());
    final clean = path.startsWith('/') ? path.substring(1) : path;
    final joinedPath = base.path.isEmpty
        ? '/$clean'
        : (base.path.endsWith('/') ? '${base.path}$clean' : '${base.path}/$clean');
    return Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: joinedPath,
    );
  }

  /// EXACT: /messages?phone=...&chat_id=...&access_hash=...
  Future<List<Map<String, dynamic>>> fetchMessages({
    required String phone,
    required int chatId,
    required int accessHash,
  }) async {
    final u = _apiJoin('messages').replace(queryParameters: {
      'phone': phone,
      'chat_id': chatId.toString(),
      'access_hash': accessHash.toString(),
    });

    final res = await http.get(u, headers: {'Accept': 'application/json'});

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    final root = json.decode(res.body);
    final arr = (root is Map && root['messages'] is List)
        ? (root['messages'] as List)
        : const [];
    return arr.cast<Map<String, dynamic>>();
  }
}

