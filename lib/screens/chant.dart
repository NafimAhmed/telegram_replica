// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:mime/mime.dart';
// import 'package:path/path.dart' as p;
// import 'package:permission_handler/permission_handler.dart';
// import 'package:provider/provider.dart';
// import '../providers/telegraph_qg_provider.dart';
//
// class ChatScreen extends StatefulWidget {
//   final String phone;
//   final int chatId;
//   final int accessHash;
//   final String name;
//   final String username;
//
//   const ChatScreen({
//     super.key,
//     required this.phone,
//     required this.chatId,
//     required this.accessHash,
//     required this.name,
//     required this.username,
//   });
//
//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }
//
// class _ChatScreenState extends State<ChatScreen> {
//   // ==== CONFIG ====
//   static const String _wsUrl = 'ws://192.168.0.247:8080/chat_ws';
//   static const String _apiBase = 'http://192.168.0.247:8080'; // <- change if needed
//   static const Duration _wsPingEvery = Duration(seconds: 22);
//
//   final ScrollController _scrollController = ScrollController();
//   final TextEditingController _msgCtrl = TextEditingController();
//   final ImagePicker _picker = ImagePicker();
//   WebSocket? _socket;
//
//   bool _loading = true;
//   bool _sending = false;
//   bool _typing = false;
//
//   // Seed tracker so UI loads even before sending
//   bool _gotSeed = false;
//
//   // Reply-to
//   int? _replyToMsgId;
//   Map<String, dynamic>? _replyToMsgMap;
//
//   // WS helpers
//   Timer? _pingTimer;
//   Timer? _reconnectTimer;
//   Timer? _typingDebounce;
//   int _reconnectAttempt = 0;
//   final Set<String> _seenIds = {}; // for de-dupe (server IDs or temp ids)
//   final String _clientInstance = DateTime.now().millisecondsSinceEpoch.toString();
//
//   // Track temp_id → list index for progress & finalize
//   final Map<String, int> _tempIndex = {};
//
//   @override
//   void initState() {
//     super.initState();
//     // প্রথমে WS connect করি, যাতে INIT → seed/new_message তাড়াতাড়ি আসে
//     _connectWebSocket();
//
//     // যদি ১.২ সেকেন্ডে seed না আসে, REST দিয়ে ব্যাকফিল করি
//     Future.delayed(const Duration(milliseconds: 1200), () {
//       if (mounted && !_gotSeed) {
//         _fetchAndLoad();
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     _pingTimer?.cancel();
//     _reconnectTimer?.cancel();
//     _typingDebounce?.cancel();
//     _socket?.close();
//     _scrollController.dispose();
//     _msgCtrl.dispose();
//     super.dispose();
//   }
//
//   // ================================
//   // 🔌 WebSocket Connect (self-healing)
//   // ================================
//   Future<void> _connectWebSocket() async {
//     try {
//       _reconnectTimer?.cancel();
//       _socket = await WebSocket.connect(_wsUrl);
//       _reconnectAttempt = 0;
//       debugPrint("✅ WS Connected");
//
//       // Init frame (server expects this as first message)
//       _socket!.add(jsonEncode({
//         "phone": widget.phone,
//         "chat_id": widget.chatId,
//         "access_hash": widget.accessHash,
//       }));
//       // INIT-এর পর সাথে সাথে একটা ping — কিছু proxy/servers তাতে ইভেন্ট ফ্লাশ করে দেয়
//       _socket!.add(jsonEncode({"action": "ping"}));
//
//       // Start server ping (keep-alive)
//       _pingTimer?.cancel();
//       _pingTimer = Timer.periodic(_wsPingEvery, (_) {
//         if (_socket?.readyState == WebSocket.open) {
//           _socket!.add(jsonEncode({"action": "ping"}));
//         }
//       });
//
//       _socket!.listen(
//             (raw) => _handleWsFrame(raw),
//         onDone: _scheduleReconnect,
//         onError: (err) {
//           debugPrint("⚠️ WS error: $err");
//           _scheduleReconnect();
//         },
//         cancelOnError: true,
//       );
//     } catch (e) {
//       debugPrint("⚠️ WS connect failed: $e");
//       _scheduleReconnect();
//     }
//   }
//
//   void _scheduleReconnect([_]) {
//     _pingTimer?.cancel();
//     _reconnectAttempt++;
//     final delay = Duration(seconds: _reconnectBackoffSeconds(_reconnectAttempt));
//     debugPrint("↩️ Reconnect in ${delay.inSeconds}s (attempt $_reconnectAttempt)");
//     _reconnectTimer?.cancel();
//     _reconnectTimer = Timer(delay, _connectWebSocket);
//   }
//
//   int _reconnectBackoffSeconds(int n) {
//     final v = 1 << (n.clamp(0, 5)); // 1,2,4,8,16,32
//     return v > 30 ? 30 : v;
//   }
//
//   // ================================
//   // 📨 Handle WS frames
//   // ================================
//   void _handleWsFrame(String raw) {
//     if (!mounted) return;
//     final provider = Provider.of<TelegraphProvider>(context, listen: false);
//
//     try {
//       final data = jsonDecode(raw);
//
//       // Heartbeat or pong
//       if (data["action"] == "_hb" || data["status"] == "pong") return;
//
//       // Server errors
//       if (data["status"] == "error") {
//         final detail = (data["detail"] ?? "unknown error").toString();
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Server error: $detail")));
//         return;
//       }
//
//       // Listener ack → UI আনব্লক
//       if (data["status"] == "listening") {
//         if (mounted && _loading) setState(() => _loading = false);
//         return;
//       }
//
//       // Typing events
//       if (data["action"] == "typing") {
//         setState(() => _typing = true);
//         return;
//       }
//       if (data["action"] == "typing_stopped") {
//         setState(() => _typing = false);
//         return;
//       }
//
//       // send_queued: get temp_id and bind to newest pending bubble if needed
//       if (data["action"] == "send_queued") {
//         final tempId = data["temp_id"]?.toString();
//         if (tempId != null) {
//           // find first pending (top of list) and attach temp_id
//           final idx = provider.messages.indexWhere(
//                 (m) => (m["pending"] == true) && (m["is_out"] == true) && (m["temp_id"] == null),
//           );
//           if (idx != -1) {
//             provider.messages[idx]["temp_id"] = tempId;
//             _tempIndex[tempId] = idx;
//             provider.notifyListeners();
//           }
//         }
//         return;
//       }
//
//       // Upload progress for a specific temp_id
//       if (data["action"] == "upload_progress") {
//         final tempId = data["temp_id"]?.toString();
//         final prog = (data["progress"] is num) ? (data["progress"] as num).toDouble() : 0.0;
//         if (tempId != null && _tempIndex.containsKey(tempId)) {
//           final idx = _tempIndex[tempId]!;
//           if (idx >= 0 && idx < provider.messages.length) {
//             provider.messages[idx]["uploading"] = true;
//             provider.messages[idx]["progress"] = prog;
//             provider.notifyListeners();
//           }
//         }
//         return;
//       }
//
//       // Final confirmation
//       if (data["action"] == "send_done") {
//         final tempId = data["temp_id"]?.toString();
//         final msgId = data["msg_id"];
//         final date = (data["date"] ?? DateTime.now().toIso8601String()).toString();
//         if (tempId != null && _tempIndex.containsKey(tempId)) {
//           final idx = _tempIndex[tempId]!;
//           if (idx >= 0 && idx < provider.messages.length) {
//             provider.messages[idx]["id"] = msgId?.toString() ?? provider.messages[idx]["id"];
//             provider.messages[idx]["pending"] = false;
//             provider.messages[idx]["uploading"] = false;
//             provider.messages[idx]["progress"] = 100.0;
//             provider.messages[idx]["time"] = date;
//             provider.notifyListeners();
//           }
//           if (msgId != null) _seenIds.add(msgId.toString());
//           _tempIndex.remove(tempId);
//         }
//         // echoed new_message আসবে—de-dupe করব
//         return;
//       }
//
//       // Send failed
//       if (data["action"] == "send_failed") {
//         final tempId = data["temp_id"]?.toString();
//         if (tempId != null && _tempIndex.containsKey(tempId)) {
//           final idx = _tempIndex[tempId]!;
//           if (idx >= 0 && idx < provider.messages.length) {
//             provider.messages[idx]["pending"] = false;
//             provider.messages[idx]["uploading"] = false;
//             provider.messages[idx]["progress"] = 0.0;
//             provider.messages[idx]["text"] = "${provider.messages[idx]["text"] ?? ""} (failed)";
//             provider.notifyListeners();
//           }
//         }
//         return;
//       }
//
//       // SEED: initial messages pushed by server
//       if (data["action"] == "seed" && data["messages"] is List) {
//         _gotSeed = true;
//         if (mounted && _loading) setState(() => _loading = false);
//
//         final List<dynamic> arr = data["messages"];
//         // server sends newest-last. Our ListView reverse:true (newest top),
//         // so add from last→first to keep newest at index 0.
//         for (int i = arr.length - 1; i >= 0; i--) {
//           final mapped = _mapServerMessage(arr[i]);
//           if (mapped == null) continue;
//           final id = mapped["id"]?.toString();
//           if (id != null && _seenIds.contains(id)) continue;
//           if (id != null) _seenIds.add(id);
//           provider.messages.insert(0, mapped);
//         }
//         provider.notifyListeners();
//         return;
//       }
//
//       // PRIMARY MESSAGE (new_message OR generic with id)
//       if (data["action"] == "new_message" || data.containsKey("id")) {
//         if (mounted && _loading) setState(() => _loading = false);
//
//         final mapped = _mapServerMessage(data);
//         if (mapped == null) return;
//
//         final id = mapped["id"]?.toString();
//         if (id != null && _seenIds.contains(id)) return; // de-dupe
//         if (id != null) _seenIds.add(id);
//
//         // If it's our own outgoing echo, try to merge with pending by text match fallback:
//         final isOut = mapped["is_out"] == true;
//         if (isOut && mapped["type"] == "text") {
//           final idx = provider.messages.indexWhere((m) {
//             final bool pending = (m["pending"] == true) && (m["is_out"] == true);
//             final sameText = (m["text"] ?? "") == (mapped["text"] ?? "");
//             return pending && sameText;
//           });
//           if (idx != -1) {
//             provider.messages[idx] = mapped;
//             provider.notifyListeners();
//             return;
//           }
//         }
//
//         // Normal insert
//         provider.messages.insert(0, mapped);
//         provider.notifyListeners();
//         return;
//       }
//
//       // (Older path) Explicit call_event
//       if (data["action"] == "call_event") {
//         final mapped = _mapCallEvent(data);
//         if (mapped == null) return;
//         final id = mapped["id"]?.toString();
//         if (id != null && _seenIds.contains(id)) return;
//         if (id != null) _seenIds.add(id);
//         provider.messages.insert(0, mapped);
//         provider.notifyListeners();
//         return;
//       }
//     } catch (e) {
//       debugPrint("⚠️ WS parse error: $e");
//     }
//   }
//
//   // ================================
//   // 📨 Load messages (initial REST, optional fallback)
//   // ================================
//   Future<void> _fetchAndLoad() async {
//     final provider = Provider.of<TelegraphProvider>(context, listen: false);
//     try {
//       await provider.fetchMessages(widget.phone, widget.chatId, widget.accessHash);
//     } catch (_) {
//       // optional
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }
//
//   // ================================
//   // ✉️ Send text
//   // ================================
//   Future<void> _sendText() async {
//     final text = _msgCtrl.text.trim();
//     if (text.isEmpty) return;
//
//     setState(() => _sending = true);
//     final provider = Provider.of<TelegraphProvider>(context, listen: false);
//
//     final payload = {
//       "action": "send",
//       "text": text,
//       if (_replyToMsgId != null) "reply_to": _replyToMsgId,
//       // Backward compatibility (older builds expected these again):
//       "phone": widget.phone,
//       "chat_id": widget.chatId,
//       "access_hash": widget.accessHash,
//       "client_instance": _clientInstance,
//     };
//
//     try {
//       // optimistic pending bubble
//       final pendingId = "pending:${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(999999)}";
//       provider.messages.insert(0, {
//         "id": pendingId,
//         "text": text,
//         "is_out": true,
//         "time": _nowIso(),
//         "type": "text",
//         "pending": true,
//         "uploading": false,
//         "progress": 0.0,
//         "temp_id": null,
//         if (_replyToMsgId != null) "reply_to": _replyToMsgId,
//         if (_replyToMsgMap != null) "reply_preview": _replyPreviewText(_replyToMsgMap!),
//       });
//       _seenIds.add(pendingId);
//       provider.notifyListeners();
//
//       _socket?.add(jsonEncode(payload));
//       _msgCtrl.clear();
//       _clearReply();
//     } catch (e) {
//       debugPrint("⚠️ send text error: $e");
//     } finally {
//       if (mounted) setState(() => _sending = false);
//     }
//   }
//
//   // ================================
//   // Typing events
//   // ================================
//   void _typingStart() {
//     _typingDebounce?.cancel();
//     if (_socket?.readyState == WebSocket.open) {
//       _socket!.add(jsonEncode({"action": "typing_start"}));
//     }
//     _typingDebounce = Timer(const Duration(seconds: 2), _typingStop);
//   }
//
//   void _typingStop() {
//     if (_socket?.readyState == WebSocket.open) {
//       _socket!.add(jsonEncode({"action": "typing_stop"}));
//     }
//   }
//
//   // ================================
//   // Picker & Send File
//   // ================================
//   Future<void> _ensurePerms() async {
//     await [Permission.camera, Permission.photos, Permission.storage].request();
//   }
//
//   Future<void> _pickImage() async {
//     await _ensurePerms();
//     final img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
//     if (img != null) await _sendFile(File(img.path));
//   }
//
//   Future<void> _pickVideo() async {
//     await _ensurePerms();
//     final vid = await _picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(minutes: 2));
//     if (vid != null) await _sendFile(File(vid.path));
//   }
//
//   Future<void> _sendFile(File file) async {
//     try {
//       final bytes = await file.readAsBytes();
//       final b64 = base64Encode(bytes);
//       final fileName = p.basename(file.path);
//       final mime = lookupMimeType(file.path, headerBytes: bytes) ?? "application/octet-stream";
//       final dataUri = "data:$mime;base64,$b64";
//
//       final provider = Provider.of<TelegraphProvider>(context, listen: false);
//       final pendingId = "pending:${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(999999)}";
//       final kind = mime.startsWith('image/')
//           ? "image"
//           : (mime.startsWith('video/') ? "video" : (mime.startsWith('audio/') ? "audio" : "file"));
//
//       provider.messages.insert(0, {
//         "id": pendingId,
//         "text": "",
//         "is_out": true,
//         "time": _nowIso(),
//         "type": kind,
//         "local_path": file.path,
//         "uploading": true,
//         "progress": 0.0,
//         "pending": true,
//         "temp_id": null,
//         if (_replyToMsgId != null) "reply_to": _replyToMsgId,
//         if (_replyToMsgMap != null) "reply_preview": _replyPreviewText(_replyToMsgMap!),
//       });
//       _seenIds.add(pendingId);
//       Provider.of<TelegraphProvider>(context, listen: false).notifyListeners();
//
//       _socket?.add(jsonEncode({
//         "action": "send",
//         "file_name": fileName,
//         "file_base64": dataUri, // data: URI (spec supports raw or data:uri)
//         "mime_type": mime,
//         if (_replyToMsgId != null) "reply_to": _replyToMsgId,
//         // Backward compatibility:
//         "phone": widget.phone,
//         "chat_id": widget.chatId,
//         "access_hash": widget.accessHash,
//         "client_instance": _clientInstance,
//       }));
//       _clearReply();
//     } catch (e) {
//       debugPrint("⚠️ send file error: $e");
//     }
//   }
//
//   // ================================
//   // Mapping helpers
//   // ================================
//   Map<String, dynamic>? _mapServerMessage(dynamic data) {
//     if (data == null) return null;
//
//     final id = (data["id"] ?? data["msg_id"] ?? data["temp_id"])?.toString();
//     final text = (data["text"] ?? "") as String;
//     final isOut = data["is_out"] == true || (data["direction"]?.toString() == "out");
//     final date = (data["date"] ?? _nowIso()).toString();
//     final mediaType = (data["media_type"] ?? data["type"] ?? "text").toString();
//     final mediaLink = data["media_link"];
//     final replyTo = (data["reply_to"] is int) ? data["reply_to"] as int : null;
//
//     if (mediaType == "call_audio" || mediaType == "call_video") {
//       final call = (data["call"] ?? {}) as Map;
//       return {
//         "id": id,
//         "text": _formatCallTitle(call, mediaType),
//         "is_out": isOut,
//         "time": date,
//         "type": "call",
//         "call_status": call["status"],
//         "duration": call["duration"],
//         "direction": call["direction"], // incoming/outgoing
//         "pending": false,
//       };
//     }
//
//     // Normal text/file/image/video
//     return {
//       "id": id,
//       "text": text,
//       "is_out": isOut,
//       "time": date,
//       "type": _normalizeType(mediaType),
//       "url": _resolveUrl(mediaLink),
//       "pending": false,
//       if (replyTo != null) "reply_to": replyTo,
//     };
//   }
//
//   Map<String, dynamic>? _mapCallEvent(dynamic data) {
//     final id = data["id"];
//     final status = data["status"];
//     final direction = data["direction"];
//     final duration = data["duration"];
//     final isVideo = data["is_video"] == true;
//     final date = (data["date"] ?? _nowIso()).toString();
//
//     return {
//       "id": id?.toString(),
//       "text": isVideo ? "Video call" : "Voice call",
//       "is_out": (direction == "outgoing"),
//       "time": date,
//       "type": "call",
//       "call_status": status,
//       "duration": duration,
//       "direction": direction,
//       "pending": false,
//     };
//   }
//
//   String _normalizeType(String t) {
//     switch (t) {
//       case "image":
//       case "video":
//       case "audio":
//       case "voice":
//       case "sticker":
//       case "file":
//         return t;
//       default:
//         return "text";
//     }
//   }
//
//   String? _resolveUrl(dynamic url) {
//     if (url == null) return null;
//     final u = url.toString();
//     try {
//       final uri = Uri.parse(u);
//       if (uri.hasScheme && (uri.host == '127.0.0.1' || uri.host == 'localhost')) {
//         final base = Uri.parse(_apiBase);
//         return uri.replace(scheme: base.scheme, host: base.host, port: base.port).toString();
//       }
//       if (uri.hasScheme) return u;
//     } catch (_) {
//       // fallthrough
//     }
//     if (u.startsWith('/')) return '$_apiBase$u';
//     return '$_apiBase/$u';
//   }
//
//   String _formatCallTitle(Map call, String mediaType) {
//     final status = (call["status"] ?? "").toString();
//     final dur = call["duration"];
//     final sec = (dur is num) ? dur.toInt() : null;
//     final dir = (call["direction"] ?? "").toString(); // incoming/outgoing
//     final t = mediaType == "call_video" ? "Video call" : "Voice call";
//     final sd = (sec != null && sec > 0) ? " • ${_fmtDur(sec)}" : "";
//     final d = dir.isNotEmpty ? (dir == "incoming" ? "Incoming" : "Outgoing") : "";
//     return "$t • $status${sd}${d.isNotEmpty ? " • $d" : ""}";
//   }
//
//   String _fmtDur(int s) {
//     final h = s ~/ 3600;
//     final m = (s % 3600) ~/ 60;
//     final sec = s % 60;
//     if (h > 0) {
//       return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
//     }
//     return "${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
//   }
//
//   String _nowIso() => DateTime.now().toUtc().toIso8601String();
//
//   // ================================
//   // Reply helpers
//   // ================================
//   void _setReply(Map<String, dynamic> m) {
//     setState(() {
//       _replyToMsgMap = m;
//       // Try parse numeric id
//       final idStr = m["id"]?.toString();
//       _replyToMsgId = int.tryParse(idStr ?? "");
//     });
//   }
//
//   void _clearReply() {
//     setState(() {
//       _replyToMsgId = null;
//       _replyToMsgMap = null;
//     });
//   }
//
//   String _replyPreviewText(Map m) {
//     final t = (m["text"] ?? "").toString();
//     final kind = (m["type"] ?? "text").toString();
//     if (t.isNotEmpty) return t.length > 40 ? "${t.substring(0, 40)}…" : t;
//     return "[$kind]";
//   }
//
//   // ================================
//   // UI
//   // ================================
//   @override
//   Widget build(BuildContext context) {
//     final provider = Provider.of<TelegraphProvider>(context);
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFE5DDD5),
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF008069),
//         title: Row(children: [
//           const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, color: Colors.black)),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(widget.name, style: const TextStyle(color: Colors.white, fontSize: 18)),
//                 Text(
//                   _typing ? "typing..." : "online",
//                   style: const TextStyle(color: Colors.white70, fontSize: 12),
//                 ),
//               ],
//             ),
//           ),
//         ]),
//       ),
//       body: _loading
//           ? const Center(child: CircularProgressIndicator())
//           : Column(children: [
//         if (_replyToMsgMap != null)
//           Container(
//             color: const Color(0xFFeafaf5),
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//             child: Row(children: [
//               const Icon(Icons.reply, color: Colors.green),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: Text(_replyPreviewText(_replyToMsgMap!), maxLines: 1, overflow: TextOverflow.ellipsis),
//               ),
//               IconButton(onPressed: _clearReply, icon: const Icon(Icons.close, size: 18))
//             ]),
//           ),
//         Expanded(
//           child: ListView.builder(
//             controller: _scrollController,
//             reverse: true, // newest at top
//             itemCount: provider.messages.length,
//             itemBuilder: (context, i) {
//               final msg = provider.messages[i];
//               final isOut = msg["is_out"] == true;
//               final time = (msg["time"] ?? "") as String;
//
//               return GestureDetector(
//                 onLongPress: () => _showMsgMenu(msg),
//                 child: Align(
//                   alignment: isOut ? Alignment.centerRight : Alignment.centerLeft,
//                   child: Container(
//                     margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
//                     padding: const EdgeInsets.all(10),
//                     decoration: BoxDecoration(
//                       color: isOut ? Colors.green.shade400 : Colors.grey.shade300,
//                       borderRadius: BorderRadius.circular(14),
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.end,
//                       children: [
//                         _bubbleContent(msg, isOut),
//                         if (msg["uploading"] == true)
//                           Padding(
//                             padding: const EdgeInsets.only(top: 6),
//                             child: SizedBox(
//                               width: 160,
//                               child: LinearProgressIndicator(
//                                 value: ((msg["progress"] ?? 0.0) as num).clamp(0, 100) / 100.0,
//                                 minHeight: 4,
//                                 backgroundColor: Colors.white24,
//                               ),
//                             ),
//                           ),
//                         Padding(
//                           padding: const EdgeInsets.only(top: 4),
//                           child: Text(
//                             time,
//                             style: TextStyle(color: isOut ? Colors.white70 : Colors.grey[700], fontSize: 11),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//         Container(
//           color: Colors.white,
//           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//           child: Row(children: [
//             IconButton(icon: const Icon(Icons.attach_file, color: Colors.green), onPressed: _showAttachmentMenu),
//             Expanded(
//               child: TextField(
//                 controller: _msgCtrl,
//                 onChanged: (_) => _typingStart(),
//                 onEditingComplete: _typingStop,
//                 decoration: const InputDecoration(hintText: "Type a message", border: InputBorder.none),
//               ),
//             ),
//             IconButton(
//               icon: _sending
//                   ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
//                   : const Icon(Icons.send, color: Colors.green),
//               onPressed: _sending ? null : _sendText,
//             ),
//           ]),
//         ),
//       ]),
//     );
//   }
//
//   void _showAttachmentMenu() {
//     showModalBottomSheet(
//       context: context,
//       builder: (ctx) => SafeArea(
//         child: Wrap(children: [
//           ListTile(
//             leading: const Icon(Icons.photo, color: Colors.green),
//             title: const Text("Send Image"),
//             onTap: () {
//               Navigator.pop(ctx);
//               _pickImage();
//             },
//           ),
//           ListTile(
//             leading: const Icon(Icons.videocam, color: Colors.green),
//             title: const Text("Send Video"),
//             onTap: () {
//               Navigator.pop(ctx);
//               _pickVideo();
//             },
//           ),
//         ]),
//       ),
//     );
//   }
//
//   void _showMsgMenu(Map<String, dynamic> m) {
//     showModalBottomSheet(
//       context: context,
//       builder: (_) => SafeArea(
//         child: Column(mainAxisSize: MainAxisSize.min, children: [
//           ListTile(
//             leading: const Icon(Icons.reply),
//             title: const Text('Reply'),
//             onTap: () {
//               Navigator.pop(context);
//               _setReply(m);
//             },
//           ),
//           if ((m["text"] ?? "").toString().isNotEmpty)
//             ListTile(
//               leading: const Icon(Icons.copy),
//               title: const Text('Copy text'),
//               onTap: () async {
//                 await Clipboard.setData(ClipboardData(text: (m["text"] ?? "").toString()));
//                 if (mounted) Navigator.pop(context);
//                 if (mounted) {
//                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied')));
//                 }
//               },
//             ),
//         ]),
//       ),
//     );
//   }
//
//   // ================================
//   // Bubble content
//   // ================================
//   Widget _bubbleContent(Map<String, dynamic> msg, bool isOut) {
//     final type = (msg["type"] ?? "text") as String;
//     final text = (msg["text"] ?? "") as String;
//     final bool isDeleted = msg["is_deleted"] == true;
//
//     final textColor = isDeleted ? Colors.red : (isOut ? Colors.white : Colors.black87);
//
//     // reply preview inline (if any)
//     final replyPreview = msg["reply_preview"];
//     final replyChip = (replyPreview != null && replyPreview.toString().isNotEmpty)
//         ? Container(
//       margin: const EdgeInsets.only(bottom: 6),
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       decoration: BoxDecoration(
//         color: isOut ? Colors.white24 : Colors.black12,
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const Icon(Icons.reply, size: 14),
//           const SizedBox(width: 6),
//           Text(
//             replyPreview.toString(),
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//             style: TextStyle(fontSize: 12, color: isOut ? Colors.white : Colors.black87),
//           ),
//         ],
//       ),
//     )
//         : const SizedBox.shrink();
//
//     // CALL MESSAGE
//     if (type == "call" || type == "call_audio" || type == "call_video") {
//       final status = msg["call_status"]?.toString() ?? "";
//       final direction = msg["direction"]?.toString() ?? "";
//       final bool isVideo = type == "call_video";
//
//       IconData icon;
//       Color iconColor;
//       String label;
//
//       if (status == "missed") {
//         icon = isVideo ? Icons.videocam_off : Icons.call_missed;
//         iconColor = Colors.redAccent;
//         label = isVideo ? "Missed Video Call" : "Missed Voice Call";
//       } else if (status == "ended") {
//         icon = isVideo ? Icons.videocam : Icons.call_end;
//         iconColor = Colors.green;
//         label = isVideo ? "Video Call Ended" : "Voice Call Ended";
//       } else if (status == "busy") {
//         icon = isVideo ? Icons.videocam : Icons.call_end;
//         iconColor = Colors.orange;
//         label = isVideo ? "Video Call Busy" : "Voice Call Busy";
//       } else {
//         icon = isVideo ? Icons.videocam : Icons.phone;
//         iconColor = Colors.blueGrey;
//         label = isVideo ? "Video Call" : "Voice Call";
//       }
//
//       return Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           replyChip,
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//             decoration: BoxDecoration(
//               color: isOut ? Colors.white.withOpacity(0.1) : Colors.black12,
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(icon, color: iconColor, size: 20),
//                 const SizedBox(width: 6),
//                 Flexible(
//                   child: Text(
//                     "$label (${direction == 'incoming' ? 'Incoming' : 'Outgoing'})",
//                     style: TextStyle(
//                       color: textColor,
//                       fontWeight: FontWeight.w600,
//                       fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       );
//     }
//
//     // IMAGE
//     if (type == "image") {
//       final localPath = msg["local_path"];
//       final url = msg["url"];
//       const w = 220.0, h = 260.0;
//
//       Widget imageChild;
//       if (localPath != null) {
//         imageChild = Image.file(File(localPath), width: w, height: h, fit: BoxFit.cover);
//       } else if (url != null) {
//         imageChild = Image.network(_resolveUrl(url)!, width: w, height: h, fit: BoxFit.cover);
//       } else {
//         imageChild = Container(width: w, height: h, color: Colors.grey, child: const Icon(Icons.image));
//       }
//
//       return Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           replyChip,
//           ClipRRect(borderRadius: BorderRadius.circular(10), child: imageChild),
//           if (text.isNotEmpty) const SizedBox(height: 6),
//           if (text.isNotEmpty) Text(text, style: TextStyle(color: textColor)),
//         ],
//       );
//     }
//
//     // VIDEO (simple label; thumbnail/player can be added later)
//     if (type == "video") {
//       return Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           replyChip,
//           Row(mainAxisSize: MainAxisSize.min, children: [
//             const Icon(Icons.videocam, color: Colors.blue),
//             const SizedBox(width: 8),
//             Text("Video", style: TextStyle(color: textColor)),
//           ]),
//           if (text.isNotEmpty) const SizedBox(height: 6),
//           if (text.isNotEmpty) Text(text, style: TextStyle(color: textColor)),
//         ],
//       );
//     }
//
//     // AUDIO / VOICE
//     if (type == "audio" || type == "voice") {
//       return Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           replyChip,
//           Row(mainAxisSize: MainAxisSize.min, children: [
//             const Icon(Icons.audiotrack, color: Colors.orangeAccent),
//             const SizedBox(width: 8),
//             Text(type == "voice" ? "Voice message" : "Audio", style: TextStyle(color: textColor)),
//           ]),
//           if (text.isNotEmpty) const SizedBox(height: 6),
//           if (text.isNotEmpty) Text(text, style: TextStyle(color: textColor)),
//         ],
//       );
//     }
//
//     // TEXT
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         replyChip,
//         Text(
//           text,
//           style: TextStyle(
//             color: textColor,
//             fontSize: 15,
//             fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
//             fontWeight: isDeleted ? FontWeight.bold : FontWeight.normal,
//           ),
//         ),
//       ],
//     );
//   }
// }
