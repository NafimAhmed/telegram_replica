//String urlLocal="http://192.168.0.247:8080";
String urlLocal="http://156.245.198.71:5080";

//
// // chat_screen.dart
//
// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'dart:math';
//
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart'; // Clipboard
// import 'package:image_picker/image_picker.dart';
// import 'package:mime/mime.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:http/http.dart' as http; // ⬅️ delete POST used
// import 'package:provider/provider.dart'; // ✅ ADDED
// import 'package:translator/translator.dart'; // ✅ ADDED
// import 'package:ag_taligram/providers/telegraph_qg_provider.dart'; // ✅ ADDED
//
// import '../url.dart';
//
// class ChatScreen extends StatefulWidget {
//   final String phone;
//   final int chatId;
//   final int? accessHash; // optional
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
//   // WebSocket
//   WebSocket? _ws;
//   bool _connecting = false;
//   bool _manuallyClosed = false;
//   int _reconnectAttempt = 0;
//
//   // Heartbeat / typing
//   Timer? _pingTimer;
//   Timer? _typingDebounce;
//   final Set<int> _typingUserIds = <int>{};
//   Timer? _typingTtlSweeper;
//   final Map<int, DateTime> _typingTtl = {}; // senderId -> expiry
//
//   // UI
//   final TextEditingController _textCtrl = TextEditingController();
//   final ScrollController _scrollCtrl = ScrollController();
//   bool _seedArrived = false;
//   bool _listening = false;
//   bool _sending = false;
//
//   // Reply context
//   int? _replyToMsgId;
//   String? _replyPreviewText;
//
//   // Messages (oldest → newest)
//   final List<ChatMessage> _messages = [];
//   final Map<int, ChatMessage> _byId = {};
//   final Map<String, ChatMessage> _byTemp = {};
//
//   // Stable ordering sequence
//   int _seqCounter = 0; // increases on first insert of any message
//
//   // ===== Multi-select =====
//   bool _selectMode = false;
//   final Set<int> _selectedIds = <int>{};
//
//   // ===== Translation state (ADDED) =====
//   final GoogleTranslator _translator = GoogleTranslator();
//   String _currentLang = 'en';
//   bool _bulkTranslating = false;
//
//   int get _selectedCount => _selectedIds.length;
//
//   @override
//   void initState() {
//     super.initState();
//     _connect();
//   }
//
//   // ✅ react to Provider language change
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     final lang = context.watch<TelegraphProvider>().selectedLang;
//     if (_currentLang != lang) {
//       _currentLang = lang;
//       _translateRecent(lang);
//       setState(() {});
//     }
//   }
//
//   @override
//   void dispose() {
//     _manuallyClosed = true;
//     _pingTimer?.cancel();
//     _typingDebounce?.cancel();
//     _typingTtlSweeper?.cancel();
//     _ws?.close();
//     _textCtrl.dispose();
//     _scrollCtrl.dispose();
//     super.dispose();
//   }
//
//   // ===== URL helpers =====
//   String get _wsUrl {
//     final base = urlLocal.trim();
//     final uri = Uri.parse(base);
//     final isHttps = uri.scheme == 'https';
//     final scheme = isHttps ? 'wss' : 'ws';
//     final path =
//     uri.path.endsWith('/') ? '${uri.path}chat_ws' : '${uri.path}/chat_ws';
//     final wsUri = Uri(
//       scheme: scheme,
//       host: uri.host,
//       port: uri.hasPort ? uri.port : null,
//       path: path,
//     );
//     return wsUri.toString();
//   }
//
//   String rewriteMediaLink(String? link) {
//     if (link == null || link.isEmpty) return '';
//     final api = Uri.parse(urlLocal);
//     Uri uri;
//     try {
//       uri = Uri.parse(link);
//     } catch (_) {
//       return link;
//     }
//
//     final newUri = Uri(
//       scheme: api.scheme,
//       host: api.host,
//       port: api.hasPort ? api.port : null,
//       path: uri.path,
//       query: uri.query,
//     );
//     return newUri.toString();
//   }
//
//   // Fallback media URL builder (uses your API base, phone/chat/msg/access_hash)
//   String _buildMediaUrl(int msgId) {
//     final api = Uri.parse(urlLocal.trim());
//     final path = api.path.endsWith('/')
//         ? '${api.path}message_media'
//         : '${api.path}/message_media';
//
//     final qp = <String, String>{
//       'phone': widget.phone,
//       'chat_id': widget.chatId.toString(),
//       'msg_id': msgId.toString(),
//       if (widget.accessHash != null) 'access_hash': widget.accessHash.toString(),
//     };
//
//     return Uri(
//       scheme: api.scheme,
//       host: api.host,
//       port: api.hasPort ? api.port : null,
//       path: path,
//       queryParameters: qp,
//     ).toString();
//   }
//
//   Future<void> _connect() async {
//     if (_connecting) return;
//     _connecting = true;
//     _manuallyClosed = false;
//
//     try {
//       setState(() {
//         _listening = false;
//       });
//       _ws = await WebSocket.connect(_wsUrl);
//       _reconnectAttempt = 0;
//
//       // INIT as first frame
//       final initPayload = {
//         'phone': widget.phone,
//         'chat_id': widget.chatId,
//         if (widget.accessHash != null) 'access_hash': widget.accessHash,
//       };
//       _send(initPayload);
//
//       _startPing();
//       _startTypingSweeper();
//
//       _ws!.listen(
//             (dynamic data) {
//           if (data is String) {
//             _handleFrameString(data);
//           } else if (data is List<int>) {
//             _handleFrameString(utf8.decode(data));
//           }
//         },
//         cancelOnError: true,
//         onDone: _onSocketDone,
//         onError: (err) {
//           _onSocketDone();
//         },
//       );
//     } catch (e) {
//       _scheduleReconnect();
//     } finally {
//       _connecting = false;
//     }
//   }
//
//   void _onSocketDone() {
//     _pingTimer?.cancel();
//     _typingTtlSweeper?.cancel();
//     if (!_manuallyClosed) {
//       _scheduleReconnect();
//     }
//   }
//
//   void _scheduleReconnect() {
//     if (_manuallyClosed) return;
//     _reconnectAttempt++;
//     final delay = min(30, pow(2, _reconnectAttempt).toInt()); // 2,4,8,16,30
//     Future.delayed(Duration(seconds: delay), () {
//       if (mounted && !_manuallyClosed) _connect();
//     });
//   }
//
//   void _startPing() {
//     _pingTimer?.cancel();
//     _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
//       _send({'action': 'ping'});
//     });
//   }
//
//   void _startTypingSweeper() {
//     _typingTtlSweeper?.cancel();
//     _typingTtlSweeper = Timer.periodic(const Duration(seconds: 2), (_) {
//       final now = DateTime.now().toUtc();
//       final expired =
//       _typingTtl.entries.where((e) => e.value.isBefore(now)).map((e) => e.key).toList();
//       if (expired.isNotEmpty) {
//         for (final id in expired) {
//           _typingTtl.remove(id);
//           _typingUserIds.remove(id);
//         }
//         if (mounted) setState(() {});
//       }
//     });
//   }
//
//   void _handleFrameString(String s) {
//     Map<String, dynamic> m;
//     try {
//       m = json.decode(s) as Map<String, dynamic>;
//     } catch (_) {
//       return;
//     }
//
//     // Status frames
//     if (m['status'] == 'listening') {
//       setState(() {
//         _listening = true;
//       });
//       return;
//     }
//     if (m['status'] == 'pong') return;
//     if (m['status'] == 'error') {
//       final detail = m['detail']?.toString() ?? 'error';
//       _showSnack('Error: $detail');
//       return;
//     }
//
//     final action = m['action'];
//     switch (action) {
//       case 'seed':
//         final arr = (m['messages'] as List?) ?? [];
//         for (final it in arr) {
//           final msg = ChatMessage.fromJson(it as Map<String, dynamic>);
//           _insertOrUpdate(msg);
//           // ✅ translate per message (if needed)
//           _maybeTranslateOne(msg, context.read<TelegraphProvider>().selectedLang);
//         }
//         _seedArrived = true;
//         _scrollToBottom();
//         setState(() {});
//         break;
//
//       case 'new_message':
//         final msg = ChatMessage.fromJson(m);
//         _insertOrUpdate(msg);
//         // ✅ translate newly arrived message
//         _maybeTranslateOne(msg, context.read<TelegraphProvider>().selectedLang);
//         _scrollAfterIncoming();
//         setState(() {});
//         break;
//
//       case 'send_queued':
//         {
//           final tempId = m['temp_id']?.toString() ?? _makeTempId();
//           final msg = ChatMessage(
//             id: null,
//             tempId: tempId,
//             text: (m['text'] ?? '').toString(),
//             date: _parseIso(m['date']),
//             isOut: true,
//             senderId: null,
//             senderName: widget.username,
//             replyTo: (m['reply_to'] is int) ? m['reply_to'] as int : null,
//             mediaType: (m['media_type'] ?? 'text').toString(),
//             mediaLink: null,
//             call: null,
//             deletedOnTelegram: false,
//             existsOnTelegram: false,
//             uploadProgress: 0.0,
//             status: MessageStatus.pending,
//             arriveSeq: -1,
//           );
//           _insertOrUpdate(msg);
//           // ✅ translate user-typed message too
//           _maybeTranslateOne(msg, context.read<TelegraphProvider>().selectedLang);
//           _scrollToBottom();
//           setState(() {});
//           break;
//         }
//
//       case 'upload_progress':
//         {
//           final tempId = m['temp_id']?.toString();
//           final p =
//           (m['progress'] is num) ? (m['progress'] as num).toDouble() : null;
//           if (tempId != null && p != null) {
//             final item = _byTemp[tempId];
//             if (item != null) {
//               item.uploadProgress = p;
//               setState(() {});
//             }
//           }
//           break;
//         }
//
//       case 'send_done':
//         {
//           final tempId = m['temp_id']?.toString();
//           final rawId = m['msg_id'];
//           final msgId = (rawId is int) ? rawId : int.tryParse(rawId?.toString() ?? '');
//
//           if (tempId != null && msgId != null) {
//             final item = _byTemp[tempId];
//             if (item != null) {
//               // media_type: prefer server, else keep previous
//               final typ = (m['media_type'] ?? item.mediaType)?.toString();
//
//               // media_link: server → rewrite; else build fallback for non-text
//               String? link;
//               final rawLink = m['media_link']?.toString();
//               if (rawLink != null && rawLink.isNotEmpty) {
//                 link = rewriteMediaLink(rawLink);
//               } else if (typ != null && typ != 'text') {
//                 link = _buildMediaUrl(msgId);
//               }
//
//               // optional server date
//               final maybeDate = _parseIso(m['date']);
//
//               item.id = msgId;
//               item.mediaType = typ ?? item.mediaType;
//               if (link != null) item.mediaLink = link;
//               if (maybeDate != null) item.date = maybeDate;
//               item.existsOnTelegram = true;
//               item.status = MessageStatus.sent;
//               item.uploadProgress = 100.0;
//
//               // promote to byId, drop temp
//               _byId[msgId] = item;
//               _byTemp.remove(tempId);
//
//               // ✅ translate finalized message if needed
//               _maybeTranslateOne(item, context.read<TelegraphProvider>().selectedLang);
//
//               _sortMessages();
//               setState(() {});
//             }
//           }
//           break;
//         }
//
//       case 'send_failed':
//         {
//           final tempId2 = m['temp_id']?.toString();
//           if (tempId2 != null) {
//             final item = _byTemp[tempId2];
//             if (item != null) {
//               item.status = MessageStatus.failed;
//               setState(() {});
//               _showSnack('Send failed: ${m['detail'] ?? ''}');
//             }
//           }
//           break;
//         }
//
//       case 'typing':
//         {
//           final sender = (m['sender_id'] is int) ? m['sender_id'] as int : null;
//           if (sender != null) {
//             _typingUserIds.add(sender);
//             _typingTtl[sender] =
//                 DateTime.now().toUtc().add(const Duration(seconds: 6));
//             setState(() {});
//           }
//           break;
//         }
//
//       case 'typing_stopped':
//         {
//           final sender2 = (m['sender_id'] is int) ? m['sender_id'] as int : null;
//           if (sender2 != null) {
//             _typingUserIds.remove(sender2);
//             _typingTtl.remove(sender2);
//             setState(() {});
//           }
//           break;
//         }
//
//       case '_hb':
//         break;
//
//       default:
//       // ignore unknown
//     }
//   }
//
//   // ===== Translation helpers (ADDED) =====
//   void _maybeTranslateOne(ChatMessage m, String lang) {
//     if ((m.mediaType ?? 'text') != 'text') return;
//     final t = m.text.trim();
//     if (t.isEmpty) return;
//     if (lang.isEmpty || lang == 'en') return; // English shows original
//     if (m.i18n.containsKey(lang)) return;
//
//     _translator.translate(t, to: lang).then((tr) {
//       m.i18n[lang] = tr.text;
//       if (mounted) setState(() {});
//     }).catchError((_) {});
//   }
//
//   Future<void> _translateRecent(String lang) async {
//     if (lang.isEmpty || lang == 'en') return;
//     if (_bulkTranslating) return;
//     _bulkTranslating = true;
//     try {
//       final recent = _messages.reversed
//           .where((m) => (m.mediaType ?? 'text') == 'text' && m.text.trim().isNotEmpty)
//           .take(200)
//           .toList();
//       for (final m in recent) {
//         if (!m.i18n.containsKey(lang)) {
//           try {
//             final tr = await _translator.translate(m.text, to: lang);
//             m.i18n[lang] = tr.text;
//           } catch (_) {}
//         }
//       }
//       if (mounted) setState(() {});
//     } finally {
//       _bulkTranslating = false;
//     }
//   }
//
//   // ===== Stable ordering =====
//   void _sortMessages() {
//     _messages.sort((a, b) {
//       if (a.id != null && b.id != null) {
//         return a.id!.compareTo(b.id!);
//       }
//       final c = a.date.compareTo(b.date);
//       if (c != 0) return c;
//       return a.arriveSeq.compareTo(b.arriveSeq);
//     });
//   }
//
//   void _insertOrUpdate(ChatMessage msg) {
//     msg.mediaLink = rewriteMediaLink(msg.mediaLink);
//
//     if ((msg.mediaType ?? 'text') != 'text' &&
//         (msg.mediaLink == null || msg.mediaLink!.isEmpty) &&
//         msg.id != null) {
//       msg.mediaLink = _buildMediaUrl(msg.id!);
//     }
//
//     if (msg.id != null) {
//       final existing = _byId[msg.id!];
//       if (existing != null) {
//         existing.mergeFrom(msg);
//       } else {
//         if (msg.arriveSeq < 0) msg.arriveSeq = _seqCounter++;
//         _byId[msg.id!] = msg;
//         _messages.add(msg);
//       }
//     } else if (msg.tempId != null) {
//       final existing = _byTemp[msg.tempId!];
//       if (existing != null) {
//         existing.mergeFrom(msg);
//       } else {
//         if (msg.arriveSeq < 0) msg.arriveSeq = _seqCounter++;
//         _byTemp[msg.tempId!] = msg;
//         _messages.add(msg);
//       }
//     } else {
//       if (msg.arriveSeq < 0) msg.arriveSeq = _seqCounter++;
//       _messages.add(msg);
//     }
//
//     _sortMessages();
//   }
//
//   void _scrollToBottom() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (!_scrollCtrl.hasClients) return;
//       _scrollCtrl.animateTo(
//         _scrollCtrl.position.maxScrollExtent + 80,
//         duration: const Duration(milliseconds: 250),
//         curve: Curves.easeOut,
//       );
//     });
//   }
//
//   void _scrollAfterIncoming() {
//     if (!_scrollCtrl.hasClients) return;
//     final delta = _scrollCtrl.position.maxScrollExtent - _scrollCtrl.position.pixels;
//     if (delta <= 200) {
//       _scrollToBottom();
//     }
//   }
//
//   void _showSnack(String msg) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
//   }
//
//   void _send(Map<String, dynamic> payload) {
//     final w = _ws;
//     if (w == null) return;
//     try {
//       w.add(json.encode(payload));
//     } catch (_) {}
//   }
//
//   // ===== helpers for reply/copy =====
//   ChatMessage? _findById(int id) => _byId[id];
//
//   void _onReply(ChatMessage m) {
//     if (m.id == null) {
//       _showSnack('Reply needs a real msg_id');
//       return;
//     }
//     final lang = context.read<TelegraphProvider>().selectedLang;
//     final label = ((m.mediaType ?? 'text') == 'text')
//         ? (m.displayText(lang).isEmpty ? '[text]' : m.displayText(lang))
//         : '[${m.mediaType}]';
//
//     setState(() {
//       _replyToMsgId = m.id;
//       _replyPreviewText = label;
//     });
//   }
//
//   Future<void> _copyText(String t) async {
//     if (t.trim().isEmpty) return;
//     await Clipboard.setData(ClipboardData(text: t));
//     _showSnack('Copied');
//   }
//
//   Future<void> _copyLink(String url) async {
//     await Clipboard.setData(ClipboardData(text: url));
//     _showSnack('Link copied');
//   }
//
//   void _showMsgMenu(ChatMessage m) {
//     showModalBottomSheet(
//       context: context,
//       showDragHandle: true,
//       builder: (_) {
//         final items = <Widget>[
//           ListTile(
//             leading: const Icon(Icons.reply),
//             title: const Text('Reply'),
//             onTap: () {
//               Navigator.pop(context);
//               _onReply(m);
//             },
//           ),
//         ];
//         if ((m.text).trim().isNotEmpty) {
//           items.add(ListTile(
//             leading: const Icon(Icons.copy),
//             title: const Text('Copy text'),
//             onTap: () {
//               Navigator.pop(context);
//               _copyText(m.text);
//             },
//           ));
//         }
//         if ((m.mediaLink ?? '').isNotEmpty) {
//           items.add(ListTile(
//             leading: const Icon(Icons.link),
//             title: const Text('Copy media link'),
//             onTap: () {
//               Navigator.pop(context);
//               _copyLink(m.mediaLink!);
//             },
//           ));
//         }
//         return SafeArea(
//             child: Column(mainAxisSize: MainAxisSize.min, children: items));
//       },
//     );
//   }
//
//   // ===== Actions =====
//   void _sendTypingStart() {
//     _typingDebounce?.cancel();
//     _typingDebounce = Timer(const Duration(milliseconds: 200), () {
//       _send({'action': 'typing_start'});
//     });
//   }
//
//   Future<void> _sendText() async {
//     if (_ws == null) return;
//     final text = _textCtrl.text.trim();
//     if (text.isEmpty) return;
//
//     setState(() {
//       _sending = true;
//     });
//
//     final payload = <String, dynamic>{
//       'action': 'send',
//       'text': text,
//       if (_replyToMsgId != null) 'reply_to': _replyToMsgId,
//     };
//     _send(payload);
//
//     _textCtrl.clear();
//     _clearReply();
//     setState(() {
//       _sending = false;
//     });
//   }
//
//   Future<void> _sendImage() async {
//     final picker = ImagePicker();
//     final picked =
//     await picker.pickImage(source: ImageSource.gallery, imageQuality: 92);
//     if (picked == null) return;
//     final bytes = await picked.readAsBytes();
//     final b64 = base64Encode(bytes);
//     final mime = lookupMimeType(picked.name) ?? 'image/jpeg';
//
//     final dataUri = 'data:$mime;base64,$b64';
//     final payload = <String, dynamic>{
//       'action': 'send',
//       'text': '',
//       'file_base64': dataUri,
//       'file_name': picked.name,
//       'mime_type': mime,
//       if (_replyToMsgId != null) 'reply_to': _replyToMsgId,
//     };
//     _send(payload);
//     _clearReply();
//   }
//
//   void _clearReply() {
//     setState(() {
//       _replyToMsgId = null;
//       _replyPreviewText = null;
//     });
//   }
//
//   String _makeTempId() =>
//       'local-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1 << 32)}';
//
//   String _subtitleText() {
//     if (!_listening) return 'connecting…';
//     if (!_seedArrived) return 'loading history…';
//     if (_typingUserIds.isNotEmpty) return 'typing…';
//     return 'online';
//   }
//
//   String _initial(String s) {
//     final t = s.trim();
//     return t.isEmpty ? 'U' : t.substring(0, 1).toUpperCase();
//   }
//
//   // ============== DELETE API ==============
//   Future<void> _deleteSelected() async {
//     if (_selectedIds.isEmpty) return;
//
//     final ok = await showDialog<bool>(
//       context: context,
//       barrierDismissible: true,
//       builder: (ctx) => AlertDialog(
//         title: const Text('Delete messages?'),
//         content: Text(
//           'Selected: $_selectedCount',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(ctx).pop(false),
//             child: const Text('Cancel'),
//           ),
//           FilledButton(
//             onPressed: () => Navigator.of(ctx).pop(true),
//             child: const Text('Delete'),
//           ),
//         ],
//       ),
//     );
//
//     if (ok != true) return;
//     if (!mounted) return;
//
//     try {
//       final api = Uri.parse(urlLocal.trim());
//       final path = api.path.endsWith('/')
//           ? '${api.path}delete_messages'
//           : '${api.path}/delete_messages';
//
//       final url = Uri(
//         scheme: api.scheme,
//         host: api.host,
//         port: api.hasPort ? api.port : null,
//         path: path,
//       );
//
//       final body = <String, dynamic>{
//         'phone': widget.phone,
//         'chat_id': widget.chatId,
//         if (widget.accessHash != null) 'access_hash': widget.accessHash,
//         'msg_ids': _selectedIds.toList(),
//         'revoke': true,
//         'db_hard': true,
//         'delete_media': true,
//         'db_force': false,
//       };
//
//       final resp = await http.post(
//         url,
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode(body),
//       );
//       if (!mounted) return;
//
//       if (resp.statusCode >= 200 && resp.statusCode < 300) {
//         final deleted = <int>{};
//         try {
//           final mm = json.decode(resp.body);
//           final cand =
//           (mm['deleted'] ?? mm['deleted_ids'] ?? mm['data']) as dynamic;
//           if (cand is List) {
//             for (final e in cand) {
//               final v = (e is int) ? e : int.tryParse(e.toString());
//               if (v != null) deleted.add(v);
//             }
//           }
//         } catch (_) {}
//
//         final effective = deleted.isNotEmpty ? deleted : _selectedIds;
//
//         for (final id in effective) {
//           final item = _byId[id];
//           if (item != null) {
//             item.existsOnTelegram = false;
//             item.deletedOnTelegram = true;
//           }
//         }
//
//         if (!mounted) return;
//         setState(() {});
//         _showSnack('Deleted ${effective.length} message(s).');
//
//         if (!mounted) return;
//         _exitSelection();
//       } else {
//         _showSnack('Delete failed: ${resp.statusCode} ${resp.reasonPhrase}');
//       }
//     } catch (e) {
//       if (!mounted) return;
//       _showSnack('Delete error: $e');
//     }
//   }
//
//   // ===== Selection helpers =====
//   void _enterSelection(ChatMessage m) {
//     if (m.id == null) {
//       _showSnack('This message has no real msg_id yet.');
//       return;
//     }
//     setState(() {
//       _selectMode = true;
//       _selectedIds.add(m.id!);
//     });
//   }
//
//   void _toggleSelection(ChatMessage m) {
//     if (m.id == null) return;
//     setState(() {
//       if (_selectedIds.contains(m.id)) {
//         _selectedIds.remove(m.id);
//         if (_selectedIds.isEmpty) _selectMode = false;
//       } else {
//         _selectedIds.add(m.id!);
//       }
//     });
//   }
//
//   void _exitSelection() {
//     setState(() {
//       _selectMode = false;
//       _selectedIds.clear();
//     });
//   }
//
//   void _selectAllToggle() {
//     final allIds = <int>[];
//     for (final m in _messages) {
//       if (m.id != null) allIds.add(m.id!);
//     }
//     setState(() {
//       if (_selectedIds.length == allIds.length) {
//         _selectedIds.clear();
//         _selectMode = false;
//       } else {
//         _selectedIds
//           ..clear()
//           ..addAll(allIds);
//         _selectMode = true;
//       }
//     });
//   }
//
//   void _replySelected() {
//     if (_selectedIds.isEmpty) return;
//     int? target;
//     for (final m in _messages) {
//       if (m.id != null && _selectedIds.contains(m.id)) {
//         target = m.id;
//         break;
//       }
//     }
//     if (target != null) {
//       final ref = _byId[target]!;
//       _onReply(ref);
//       _exitSelection();
//       _showSnack('Replying to #$target');
//     }
//   }
//
//   Future<void> _forwardSelected() async {
//     if (_selectedIds.isEmpty) return;
//     final picked = _messages
//         .where((m) => m.id != null && _selectedIds.contains(m.id))
//         .map((m) => '[#${m.id}] ${m.previewText()}')
//         .join('\n');
//     await Clipboard.setData(ClipboardData(text: picked));
//     _showSnack('Copied ${_selectedIds.length} selected to clipboard');
//   }
//
//   // ===== UI =====
//   @override
//   Widget build(BuildContext context) {
//     final canSend = _textCtrl.text.trim().isNotEmpty && !_sending;
//     final lang = context.watch<TelegraphProvider>().selectedLang; // ✅ ADDED
//
//     return Scaffold(
//       appBar: AppBar(
//         leading: _selectMode
//             ? IconButton(
//           tooltip: 'Cancel',
//           icon: const Icon(Icons.close),
//           onPressed: _exitSelection,
//         )
//             : null,
//         titleSpacing: 0,
//         title: _selectMode
//             ? Text('$_selectedCount selected')
//             : Row(
//           children: [
//             CircleAvatar(child: Text(_initial(widget.name))),
//             const SizedBox(width: 8),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text(widget.name,
//                       style:
//                       const TextStyle(fontWeight: FontWeight.w600)),
//                   Text(_subtitleText(),
//                       style: const TextStyle(
//                           color: Colors.white, fontSize: 12)),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         actions: _selectMode
//             ? [
//           IconButton(
//             tooltip: 'Reply',
//             icon: const Icon(Icons.reply),
//             onPressed: _selectedIds.isEmpty ? null : _replySelected,
//           ),
//           IconButton(
//             tooltip: 'Forward',
//             icon: const Icon(Icons.forward),
//             onPressed: _selectedIds.isEmpty ? null : _forwardSelected,
//           ),
//           IconButton(
//             tooltip: 'Select all',
//             icon: const Icon(Icons.select_all),
//             onPressed: _selectAllToggle,
//           ),
//           IconButton(
//             tooltip: 'Delete',
//             icon: const Icon(Icons.delete_outline),
//             onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
//           ),
//         ]
//             : [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: () {
//               _ws?.close();
//               _connect();
//             },
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           if (_replyToMsgId != null) _buildReplyBar(),
//           Expanded(
//             child: ListView.builder(
//               controller: _scrollCtrl,
//               padding:
//               const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
//               itemCount: _messages.length + 1,
//               itemBuilder: (_, i) {
//                 if (i == _messages.length) {
//                   return _buildTypingRow();
//                 }
//                 final m = _messages[i];
//                 final isSelected =
//                     _selectMode && m.id != null && _selectedIds.contains(m.id!);
//
//                 return _MessageBubble(
//                   key: ValueKey('msg-${m.id ?? m.tempId ?? i}'),
//                   msg: m,
//                   lang: lang, // ✅ pass current language
//                   selectionMode: _selectMode,
//                   selected: isSelected,
//                   onSelectToggle: () => _toggleSelection(m),
//                   onLongPress: () => _enterSelection(m),
//                   onTapMedia: () async {
//                     if (_selectMode) {
//                       _toggleSelection(m);
//                       return;
//                     }
//                     final url = m.mediaLink;
//                     if (url == null || url.isEmpty) return;
//                     final uri = Uri.parse(url);
//                     if (await canLaunchUrl(uri)) {
//                       await launchUrl(uri,
//                           mode: LaunchMode.externalApplication);
//                     }
//                   },
//                   onSwipeReply: () => _onReply(m),
//                   findById: _findById,
//                 );
//               },
//             ),
//           ),
//           _buildComposer(canSend),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildTypingRow() {
//     if (_typingUserIds.isEmpty) return const SizedBox.shrink();
//     return Padding(
//       padding: const EdgeInsets.only(left: 12, bottom: 8),
//       child: Text('typing…',
//           style:
//           TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic)),
//     );
//   }
//
//   Widget _buildReplyBar() {
//     return Container(
//       width: double.infinity,
//       color: Colors.grey.shade200,
//       padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
//       child: Row(
//         children: [
//           const Icon(Icons.reply, size: 18),
//           const SizedBox(width: 6),
//           Expanded(
//             child: Text(
//               _replyPreviewText ?? 'Replying…',
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//           IconButton(
//               onPressed: _clearReply, icon: const Icon(Icons.close, size: 18))
//         ],
//       ),
//     );
//   }
//
//   Widget _buildComposer(bool canSend) {
//     return SafeArea(
//       top: false,
//       child: Container(
//         color: const Color(0xFFF7F7F7),
//         padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
//         child: Row(
//           children: [
//             IconButton(
//               tooltip: 'Attach',
//               onPressed: _sendImage,
//               icon: const Icon(Icons.attach_file),
//             ),
//             Expanded(
//               child: TextField(
//                 controller: _textCtrl,
//                 minLines: 1,
//                 maxLines: 4,
//                 onChanged: (_) {
//                   // _sendTypingStart();
//                   if (mounted) setState(() {}); // update send button state immediately
//                 },
//                 decoration: const InputDecoration(
//                   hintText: 'Message',
//                   isDense: true,
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 8),
//             SizedBox(
//               width: 40,
//               height: 40,
//               child: Material(
//                 color: canSend
//                     ? const Color(0xFF2AABEE)
//                     : const Color(0xFFB3E5FC),
//                 shape: const CircleBorder(),
//                 child: InkWell(
//                   customBorder: const CircleBorder(),
//                   onTap: canSend ? _sendText : null,
//                   child: Center(
//                     child: _sending
//                         ? const SizedBox(
//                       width: 18,
//                       height: 18,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 2,
//                         valueColor:
//                         AlwaysStoppedAnimation<Color>(Colors.white),
//                       ),
//                     )
//                         : const Icon(Icons.send, color: Colors.white),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // ===== Helpers outside widget =====
// DateTime _parseIso(dynamic v) {
//   if (v is String) {
//     try {
//       return DateTime.parse(v).toUtc();
//     } catch (_) {}
//   }
//   return DateTime.now().toUtc();
// }
//
// enum MessageStatus { pending, sent, failed }
//
// class ChatMessage {
//   int? id; // Telegram msg_id
//   String? tempId; // local id for pending
//   String text;
//   int? senderId;
//   String senderName;
//   DateTime date;
//   bool isOut;
//   int? replyTo;
//   String? mediaType; // text|image|video|audio|voice|sticker|file|call_audio|call_video
//   String? mediaLink; // for non-text
//   CallInfo? call;
//   bool deletedOnTelegram;
//   bool existsOnTelegram;
//   double uploadProgress; // 0..100 for pending file uploads
//   MessageStatus status;
//
//   // stable ordering fallback
//   int arriveSeq;
//
//   // ✅ ADDED: translation cache + toggle
//   Map<String, String> i18n = {}; // langCode -> translated text
//   bool showOriginal = false;
//
//   ChatMessage({
//     required this.id,
//     required this.tempId,
//     required this.text,
//     required this.date,
//     required this.isOut,
//     required this.senderId,
//     required this.senderName,
//     required this.replyTo,
//     required this.mediaType,
//     required this.mediaLink,
//     required this.call,
//     required this.deletedOnTelegram,
//     required this.existsOnTelegram,
//     required this.uploadProgress,
//     this.status = MessageStatus.sent,
//     this.arriveSeq = -1,
//   });
//
//   // normalize msg_id/photo and keep link if provided
//   factory ChatMessage.fromJson(Map<String, dynamic> m) {
//     final anyId = m['id'] ?? m['msg_id'];
//
//     String? t = m['media_type']?.toString();
//     if (t == 'photo') t = 'image'; // normalize
//
//     return ChatMessage(
//       id: (anyId is int) ? anyId : int.tryParse(anyId?.toString() ?? ''),
//       tempId: m['temp_id']?.toString(),
//       text: (m['text'] ?? '').toString(),
//       senderId: (m['sender_id'] is int) ? m['sender_id'] as int : null,
//       senderName: (m['sender_name'] ?? '').toString(),
//       date: _parseIso(m['date']),
//       isOut: (m['is_out'] == true),
//       replyTo: (m['reply_to'] is int) ? m['reply_to'] as int : null,
//       mediaType: t,
//       mediaLink: m['media_link']?.toString(),
//       call: (m['call'] is Map)
//           ? CallInfo.fromJson(m['call'] as Map<String, dynamic>)
//           : null,
//       deletedOnTelegram: m['deleted_on_telegram'] == true,
//       existsOnTelegram: m['exists_on_telegram'] != false,
//       uploadProgress: 0.0,
//       status: MessageStatus.sent,
//       arriveSeq: -1,
//     );
//   }
//
//   void mergeFrom(ChatMessage other) {
//     id = other.id ?? id;
//     tempId = other.tempId ?? tempId;
//     text = other.text.isNotEmpty ? other.text : text;
//     senderId = other.senderId ?? senderId;
//     senderName = other.senderName.isNotEmpty ? other.senderName : senderName;
//     date = other.date;
//     isOut = other.isOut;
//     replyTo = other.replyTo ?? replyTo;
//     mediaType = other.mediaType ?? mediaType;
//     mediaLink = other.mediaLink ?? mediaLink;
//     call = other.call ?? call;
//     deletedOnTelegram = other.deletedOnTelegram;
//     existsOnTelegram = other.existsOnTelegram;
//     uploadProgress =
//     other.uploadProgress != 0.0 ? other.uploadProgress : uploadProgress;
//     status = other.status;
//     // keep i18n cache
//   }
//
//   String previewText() {
//     if ((mediaType ?? 'text') != 'text' && (text.isEmpty)) {
//       return '[${mediaType ?? 'media'}]';
//     }
//     return text.isEmpty ? '[text]' : text;
//   }
//
//   // ✅ ADDED: which text to show for a given language
//   String displayText(String lang) {
//     if (showOriginal) return text;
//     if (lang.isEmpty || lang == 'en') return text;
//     return i18n[lang] ?? text;
//   }
// }
//
// class CallInfo {
//   final String status; // missed|busy|canceled|ended|accepted|ongoing|requested|unknown
//   final int? duration; // seconds
//   final bool isVideo;
//   final String? reason; // raw TL name
//   final String direction; // incoming|outgoing
//
//   CallInfo({
//     required this.status,
//     required this.duration,
//     required this.isVideo,
//     required this.reason,
//     required this.direction,
//   });
//
//   factory CallInfo.fromJson(Map<String, dynamic> m) {
//     return CallInfo(
//       status: (m['status'] ?? 'unknown').toString(),
//       duration: (m['duration'] is int) ? m['duration'] as int : null,
//       isVideo: m['is_video'] == true,
//       reason: m['reason']?.toString(),
//       direction: (m['direction'] ?? 'incoming').toString(),
//     );
//   }
// }
//
// class _MessageBubble extends StatelessWidget {
//   final ChatMessage msg;
//   final String lang; // ✅ ADDED
//   final VoidCallback? onLongPress;
//   final VoidCallback? onTapMedia;
//   final ChatMessage? Function(int id) findById;
//   final VoidCallback? onSwipeReply;
//
//   // selection support
//   final bool selectionMode;
//   final bool selected;
//   final VoidCallback? onSelectToggle;
//
//   const _MessageBubble({
//     super.key,
//     required this.msg,
//     required this.lang, // ✅ ADDED
//     this.onLongPress,
//     this.onTapMedia,
//     required this.findById,
//     this.onSwipeReply,
//     this.selectionMode = false,
//     this.selected = false,
//     this.onSelectToggle,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           if (selectionMode)
//             GestureDetector(
//               onTap: onSelectToggle,
//               child: Container(
//                 width: 28,
//                 height: 28,
//                 margin: const EdgeInsets.only(top: 6, left: 6, right: 6),
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: selected ? Colors.blue : Colors.transparent,
//                   border: Border.all(color: Colors.blue, width: 2),
//                 ),
//                 child: selected
//                     ? const Icon(Icons.check, size: 16, color: Colors.white)
//                     : const SizedBox.shrink(),
//               ),
//             )
//           else
//             const SizedBox(width: 12),
//
//           // bubble
//           Expanded(
//             child: Align(
//               alignment:
//               msg.isOut ? Alignment.centerRight : Alignment.centerLeft,
//               child: GestureDetector(
//                 onTap: selectionMode ? onSelectToggle : null,
//                 onLongPress: onLongPress,
//                 onHorizontalDragEnd: (details) {
//                   if ((details.primaryVelocity ?? 0) > 150) {
//                     if (onSwipeReply != null) onSwipeReply!();
//                   }
//                 },
//                 child: _buildBubbleWithGhosting(context),
//               ),
//             ),
//           ),
//
//           const SizedBox(width: 12),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildBubbleWithGhosting(BuildContext context) {
//     final ghost = (msg.existsOnTelegram == false) ||
//         (msg.status == MessageStatus.pending);
//     final base = _bubbleCore(context);
//
//     if ((msg.mediaType ?? 'text') == 'text' ||
//         (msg.mediaType ?? '').startsWith('call_')) {
//       return Opacity(opacity: ghost ? 0.65 : 1.0, child: base);
//     }
//     return base;
//   }
//
//   Widget _bubbleCore(BuildContext context) {
//     Color bubbleColor =
//     msg.isOut ? Colors.blue.shade100 : Colors.grey.shade200;
//     if (selectionMode && selected) {
//       bubbleColor = msg.isOut ? Colors.blue.shade200 : Colors.grey.shade300;
//     }
//
//     return ConstrainedBox(
//       constraints: const BoxConstraints(maxWidth: 320),
//       child: Container(
//         padding: const EdgeInsets.all(10),
//         decoration: BoxDecoration(
//           color: bubbleColor,
//           borderRadius: BorderRadius.circular(12),
//           border: selectionMode && selected
//               ? Border.all(color: Colors.blueAccent, width: 1)
//               : null,
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             if (!msg.isOut && msg.senderName.isNotEmpty)
//               Padding(
//                 padding: const EdgeInsets.only(bottom: 4),
//                 child: Text(msg.senderName,
//                     style: const TextStyle(
//                         fontSize: 12, fontWeight: FontWeight.w600)),
//               ),
//             _buildBody(context),
//             const SizedBox(height: 6),
//             Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(_fmtTime(msg.date),
//                     style:
//                     const TextStyle(fontSize: 10, color: Colors.black54)),
//                 const SizedBox(width: 6),
//                 if (msg.status == MessageStatus.pending)
//                   const Icon(Icons.schedule, size: 12, color: Colors.black45)
//                 else if (msg.status == MessageStatus.failed)
//                   const Icon(Icons.error_outline,
//                       size: 12, color: Colors.redAccent)
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildBody(BuildContext context) {
//     final mt = (msg.mediaType ?? 'text');
//     final List<Widget> children = [];
//
//     // Reply preview
//     if (msg.replyTo != null) {
//       final ref = findById(msg.replyTo!);
//       final rpType = ref?.mediaType ?? 'text';
//       final rpText = (ref == null)
//           ? '[unavailable]'
//           : (rpType == 'text'
//           ? (ref.displayText(lang).isEmpty ? '[text]' : ref.displayText(lang))
//           : '[${rpType}]');
//       children.add(
//           _ReplyPreview(id: msg.replyTo!, text: rpText, mediaType: rpType));
//     }
//
//     if (mt == 'text') {
//       final ghost = (msg.existsOnTelegram == false) ||
//           (msg.status == MessageStatus.pending);
//       final shown = msg.displayText(lang);
//       children.add(SelectableText(
//         shown.isNotEmpty ? shown : '[empty]',
//         style: TextStyle(
//           fontSize: 15,
//           fontStyle: ghost ? FontStyle.italic : FontStyle.normal,
//           color: ghost ? Colors.red : Colors.black87,
//         ),
//       ));
//     } else if (mt == 'image') {
//       final ghost = (msg.existsOnTelegram == false) ||
//           (msg.status == MessageStatus.pending);
//       if ((msg.mediaLink ?? '').isNotEmpty) {
//         Widget img = Image.network(
//           msg.mediaLink!,
//           fit: BoxFit.cover,
//           gaplessPlayback: true,
//           loadingBuilder: (context, child, progress) {
//             if (progress == null) return child;
//             final v = progress.expectedTotalBytes == null
//                 ? null
//                 : progress.cumulativeBytesLoaded /
//                 (progress.expectedTotalBytes!);
//             return SizedBox(
//                 height: 180,
//                 width: 240,
//                 child: Center(child: CircularProgressIndicator(value: v)));
//           },
//         );
//         if (ghost) {
//           img = Opacity(
//             opacity: 0.85,
//             child: ColorFiltered(
//               colorFilter: ColorFilter.mode(
//                   Colors.red.withOpacity(0.50), BlendMode.modulate),
//               child: img,
//             ),
//           );
//         }
//
//         children.add(
//           GestureDetector(
//             onTap: selectionMode ? onSelectToggle : onTapMedia,
//             child: ClipRRect(
//                 borderRadius: BorderRadius.circular(10),
//                 child: SizedBox(width: 240, child: img)),
//           ),
//         );
//       } else {
//         children.add(_uploadProgressBar());
//       }
//       final cap = msg.displayText(lang);
//       if (cap.isNotEmpty) {
//         children.add(const SizedBox(height: 6));
//         children.add(Text(
//           cap,
//           style: TextStyle(
//             fontStyle: (msg.existsOnTelegram == false)
//                 ? FontStyle.italic
//                 : FontStyle.normal,
//             color:
//             (msg.existsOnTelegram == false) ? Colors.black54 : null,
//           ),
//         ));
//       }
//     } else if (mt.startsWith('call_') && msg.call != null) {
//       children.add(_CallChip(call: msg.call!));
//     } else {
//       // generic file/video/audio/voice/sticker
//       children.add(
//         InkWell(
//           onTap: selectionMode ? onSelectToggle : onTapMedia,
//           child: Row(children: [
//             const Icon(Icons.attach_file),
//             const SizedBox(width: 8),
//             Expanded(
//                 child: Text('[${mt}] tap to open',
//                     overflow: TextOverflow.ellipsis)),
//           ]),
//         ),
//       );
//       final cap = msg.displayText(lang);
//       if (cap.isNotEmpty) {
//         children.add(const SizedBox(height: 6));
//         children.add(Text(cap));
//       }
//       if (msg.status == MessageStatus.pending) {
//         children.add(const SizedBox(height: 6));
//         children.add(_uploadProgressBar());
//       }
//     }
//
//     return Column(
//         crossAxisAlignment: CrossAxisAlignment.start, children: children);
//   }
//
//   Widget _uploadProgressBar() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         LinearProgressIndicator(
//           value: (msg.uploadProgress > 0 && msg.uploadProgress <= 100)
//               ? msg.uploadProgress / 100.0
//               : null,
//         ),
//         const SizedBox(height: 4),
//         Text('${msg.uploadProgress.toStringAsFixed(1)}%'),
//       ],
//     );
//   }
//
//   String _fmtTime(DateTime dt) {
//     final h = dt.toLocal().hour.toString().padLeft(2, '0');
//     final m = dt.toLocal().minute.toString().padLeft(2, '0');
//     return '$h:$m';
//   }
// }
//
// class _ReplyPreview extends StatelessWidget {
//   final int id;
//   final String text;
//   final String mediaType;
//   const _ReplyPreview(
//       {super.key, required this.id, required this.text, required this.mediaType});
//
//   @override
//   Widget build(BuildContext context) {
//     final isText = mediaType == 'text';
//     final label = isText ? (text.isEmpty ? '[text]' : text) : '[${mediaType}]';
//     return Container(
//       padding: const EdgeInsets.all(8),
//       margin: const EdgeInsets.only(bottom: 6),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.6),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: Colors.black12),
//       ),
//       child: Row(children: [
//         const Icon(Icons.subdirectory_arrow_right,
//             size: 16, color: Colors.black54),
//         const SizedBox(width: 6),
//         Expanded(
//             child: Text(label,
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//                 style: const TextStyle(fontSize: 12, color: Colors.black87))),
//         const SizedBox(width: 6),
//         Text('#$id',
//             style: const TextStyle(fontSize: 11, color: Colors.black45)),
//       ]),
//     );
//   }
// }
//
// class _CallChip extends StatelessWidget {
//   final CallInfo call;
//   const _CallChip({super.key, required this.call});
//
//   @override
//   Widget build(BuildContext context) {
//     final isVideo = call.isVideo;
//     final icon = isVideo ? Icons.videocam : Icons.call;
//     final dur = call.duration != null ? _fmt(call.duration!) : null;
//     final text = StringBuffer()
//       ..write(call.direction)
//       ..write(' ')
//       ..write(call.status);
//     if (dur != null) text.write(' • $dur');
//
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.7),
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: Colors.black12),
//       ),
//       child: Row(mainAxisSize: MainAxisSize.min, children: [
//         Icon(icon, size: 18),
//         const SizedBox(width: 8),
//         Text(text.toString()),
//       ]),
//     );
//   }
//
//   String _fmt(int s) {
//     final m = (s ~/ 60).toString().padLeft(2, '0');
//     final ss = (s % 60).toString().padLeft(2, '0');
//     return '$m:$ss';
//   }
// }







