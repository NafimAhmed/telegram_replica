//
//
// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'dart:math';
//
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:mime/mime.dart';
// import 'package:url_launcher/url_launcher.dart';
//
// import '../url.dart';
//
// class ChatScreen extends StatefulWidget {// e.g., http://192.168.0.247:8080 or https://api.example.com
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
//   // Helpers
//   String get _wsUrl {
//     final base = urlLocal.trim();
//     final uri = Uri.parse(base);
//     final isHttps = uri.scheme == 'https';
//     final scheme = isHttps ? 'wss' : 'ws';
//     final path = uri.path.endsWith('/') ? '${uri.path}chat_ws' : '${uri.path}/chat_ws';
//     final wsUri = Uri(scheme: scheme, host: uri.host, port: uri.hasPort ? uri.port : null, path: path);
//     return wsUri.toString();
//   }
//
//   String rewriteMediaLink(String? link) {
//     if (link == null || link.isEmpty) return '';
//     final api = Uri.parse(urlLocal);
//     Uri uri;
//     try { uri = Uri.parse(link); } catch (_) { return link; }
//
//     final isLocal = (uri.host == '127.0.0.1') || (uri.host == 'localhost');
//     if (!isLocal) return link; // already absolute external
//
//     // Rewrite to apiBase host/scheme/port, preserve path+query
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
//   @override
//   void initState() {
//     super.initState();
//     _connect();
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
//   Future<void> _connect() async {
//     if (_connecting) return;
//     _connecting = true;
//     _manuallyClosed = false;
//
//     try {
//       setState(() { _listening = false; });
//       _ws = await WebSocket.connect(_wsUrl);
//       _reconnectAttempt = 0;
//
//       // Send INIT as first frame
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
//             // Most servers send text frames; handle just in case
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
//       _send({ 'action': 'ping' });
//     });
//   }
//
//   void _startTypingSweeper() {
//     _typingTtlSweeper?.cancel();
//     _typingTtlSweeper = Timer.periodic(const Duration(seconds: 2), (_) {
//       final now = DateTime.now().toUtc();
//       final expired = _typingTtl.entries.where((e) => e.value.isBefore(now)).map((e) => e.key).toList();
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
//     try { m = json.decode(s) as Map<String, dynamic>; } catch (_) { return; }
//
//     // Status frames
//     if (m['status'] == 'listening') {
//       setState(() { _listening = true; });
//       return;
//     }
//     if (m['status'] == 'pong') return;
//     if (m['status'] == 'error') {
//       final detail = m['detail']?.toString() ?? 'error';
//       _showSnack('Error: $detail');
//       if (detail.contains('not authorized')) {
//         // No auto-reconnect loop here; user must login separately.
//       }
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
//         }
//         _seedArrived = true;
//         _scrollToBottom();
//         setState(() {});
//         break;
//       case 'new_message':
//         final msg = ChatMessage.fromJson(m);
//         _insertOrUpdate(msg);
//         _scrollAfterIncoming();
//         setState(() {});
//         break;
//       case 'send_queued':
//         final tempId = m['temp_id']?.toString() ?? _makeTempId();
//         final msg = ChatMessage(
//           id: null,
//           tempId: tempId,
//           text: (m['text'] ?? '').toString(),
//           date: _parseIso(m['date']) ?? DateTime.now().toUtc(),
//           isOut: true,
//           senderId: null,
//           senderName: widget.username,
//           replyTo: null,
//           mediaType: (m['media_type'] ?? 'text').toString(),
//           mediaLink: null,
//           call: null,
//           deletedOnTelegram: false,
//           existsOnTelegram: false,
//           uploadProgress: 0.0,
//           status: MessageStatus.pending,
//         );
//         _messages.add(msg);
//         _byTemp[tempId] = msg;
//         _scrollToBottom();
//         setState(() {});
//         break;
//       case 'upload_progress':
//         final tempId = m['temp_id']?.toString();
//         final p = (m['progress'] is num) ? (m['progress'] as num).toDouble() : null;
//         if (tempId != null && p != null) {
//           final item = _byTemp[tempId];
//           if (item != null) {
//             item.uploadProgress = p;
//             setState(() {});
//           }
//         }
//         break;
//       case 'send_done':
//         final tempId = m['temp_id']?.toString();
//         final msgId = m['msg_id'];
//         if (tempId != null && msgId is int) {
//           final item = _byTemp[tempId];
//           if (item != null) {
//             item.id = msgId;
//             item.existsOnTelegram = true;
//             item.status = MessageStatus.sent;
//             _byId[msgId] = item;
//             setState(() {});
//           }
//         }
//         break;
//       case 'send_failed':
//         final tempId = m['temp_id']?.toString();
//         if (tempId != null) {
//           final item = _byTemp[tempId];
//           if (item != null) {
//             item.status = MessageStatus.failed;
//             setState(() {});
//             _showSnack('Send failed: ${m['detail'] ?? ''}');
//           }
//         }
//         break;
//       case 'typing':
//         final sender = (m['sender_id'] is int) ? m['sender_id'] as int : null;
//         if (sender != null) {
//           _typingUserIds.add(sender);
//           _typingTtl[sender] = DateTime.now().toUtc().add(const Duration(seconds: 6));
//           setState(() {});
//         }
//         break;
//       case 'typing_stopped':
//         final sender = (m['sender_id'] is int) ? m['sender_id'] as int : null;
//         if (sender != null) {
//           _typingUserIds.remove(sender);
//           _typingTtl.remove(sender);
//           setState(() {});
//         }
//         break;
//       case '_hb':
//       // server heartbeat; ignore
//         break;
//       default:
//       // ignore
//     }
//   }
//
//   void _insertOrUpdate(ChatMessage msg) {
//     // Rewrite media link if local
//     msg.mediaLink = rewriteMediaLink(msg.mediaLink);
//
//     if (msg.id != null) {
//       final existing = _byId[msg.id!];
//       if (existing != null) {
//         existing.mergeFrom(msg);
//       } else {
//         _byId[msg.id!] = msg;
//         _messages.add(msg);
//       }
//     } else if (msg.tempId != null) {
//       final existing = _byTemp[msg.tempId!];
//       if (existing != null) {
//         existing.mergeFrom(msg);
//       } else {
//         _byTemp[msg.tempId!] = msg;
//         _messages.add(msg);
//       }
//     } else {
//       _messages.add(msg);
//     }
//     _messages.sort((a, b) => a.date.compareTo(b.date));
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
//     final atBottom = _scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 120;
//     if (atBottom) _scrollToBottom();
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
//     try { w.add(json.encode(payload)); } catch (_) {}
//   }
//
//   // ===== Actions =====
//   void _sendTypingStart() {
//     _typingDebounce?.cancel();
//     _typingDebounce = Timer(const Duration(milliseconds: 200), () {
//       _send({ 'action': 'typing_start' });
//     });
//   }
//
//   Future<void> _sendText() async {
//     if (_ws == null) return;
//     final text = _textCtrl.text.trim();
//     if (text.isEmpty) return;
//
//     setState(() { _sending = true; });
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
//     setState(() { _sending = false; });
//   }
//
//   Future<void> _sendImage() async {
//     final picker = ImagePicker();
//     final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 92);
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
//     setState(() { _replyToMsgId = null; _replyPreviewText = null; });
//   }
//
//   String _makeTempId() => 'local-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1<<32)}';
//
//   // ===== UI =====
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//
//     return Scaffold(
//       appBar: AppBar(
//         titleSpacing: 0,
//         title: Row(
//           children: [
//             CircleAvatar(child: Text(widget.name.isNotEmpty ? widget.name.characters.first : 'U')),
//             const SizedBox(width: 8),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text(widget.name, style: const TextStyle(fontWeight: FontWeight.w600)),
//                   Text(_subtitleText(), style: theme.textTheme.bodySmall),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         actions: [
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
//               padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
//               itemCount: _messages.length + 1,
//               itemBuilder: (_, i) {
//                 if (i == _messages.length) {
//                   return _buildTypingRow();
//                 }
//                 final m = _messages[i];
//                 return _MessageBubble(
//                   key: ValueKey('msg-${m.id ?? m.tempId ?? i}'),
//                   msg: m,
//                   onLongPress: () {
//                     setState(() {
//                       _replyToMsgId = m.id; // Only real msg_id supported by server
//                       _replyPreviewText = m.previewText();
//                     });
//                   },
//                   onTapMedia: () async {
//                     final url = m.mediaLink;
//                     if (url == null || url.isEmpty) return;
//                     final uri = Uri.parse(url);
//                     if (await canLaunchUrl(uri)) {
//                       await launchUrl(uri, mode: LaunchMode.externalApplication);
//                     }
//                   },
//                 );
//               },
//             ),
//           ),
//           _buildComposer(),
//         ],
//       ),
//     );
//   }
//
//   String _subtitleText() {
//     if (!_listening) return 'connecting…';
//     if (!_seedArrived) return 'loading history…';
//     if (_typingUserIds.isNotEmpty) return 'typing…';
//     return 'online';
//   }
//
//   Widget _buildTypingRow() {
//     if (_typingUserIds.isEmpty) return const SizedBox.shrink();
//     return Padding(
//       padding: const EdgeInsets.only(left: 12, bottom: 8),
//       child: Text('typing…', style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic)),
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
//             onPressed: _clearReply,
//             icon: const Icon(Icons.close, size: 18),
//           )
//         ],
//       ),
//     );
//   }
//
//   Widget _buildComposer() {
//     return SafeArea(
//       top: false,
//       child: Padding(
//         padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
//         child: Row(
//           children: [
//             IconButton(
//               tooltip: 'Image',
//               onPressed: _sendImage,
//               icon: const Icon(Icons.image),
//             ),
//             Expanded(
//               child: TextField(
//                 controller: _textCtrl,
//                 minLines: 1,
//                 maxLines: 5,
//                 onChanged: (_) => _sendTypingStart(),
//                 decoration: const InputDecoration(
//                   hintText: 'Message',
//                   isDense: true,
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 8),
//             IconButton(
//               onPressed: _sending ? null : _sendText,
//               icon: const Icon(Icons.send),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// DateTime _parseIso(dynamic v) {
//   if (v is String) {
//     try { return DateTime.parse(v).toUtc(); } catch (_) {}
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
//   });
//
//   factory ChatMessage.fromJson(Map<String, dynamic> m) {
//     return ChatMessage(
//       id: (m['id'] is int) ? m['id'] as int : int.tryParse(m['id']?.toString() ?? ''),
//       tempId: m['temp_id']?.toString(),
//       text: (m['text'] ?? '').toString(),
//       senderId: (m['sender_id'] is int) ? m['sender_id'] as int : null,
//       senderName: (m['sender_name'] ?? '').toString(),
//       date: _parseIso(m['date']),
//       isOut: (m['is_out'] == true),
//       replyTo: (m['reply_to'] is int) ? m['reply_to'] as int : null,
//       mediaType: m['media_type']?.toString(),
//       mediaLink: m['media_link']?.toString(),
//       call: (m['call'] is Map) ? CallInfo.fromJson(m['call'] as Map<String, dynamic>) : null,
//       deletedOnTelegram: m['deleted_on_telegram'] == true,
//       existsOnTelegram: m['exists_on_telegram'] != false, // default true when msg_id exists
//       uploadProgress: 0.0,
//       status: MessageStatus.sent,
//     );
//   }
//
//   void mergeFrom(ChatMessage other) {
//     id = other.id ?? id;
//     tempId = other.tempId ?? tempId;
//     text = other.text.isNotEmpty ? other.text : text;
//     senderId = other.senderId ?? senderId;
//     senderName = other.senderName.isNotEmpty ? other.senderName : senderName;
//     date = other.date; // keep latest
//     isOut = other.isOut;
//     replyTo = other.replyTo ?? replyTo;
//     mediaType = other.mediaType ?? mediaType;
//     mediaLink = other.mediaLink ?? mediaLink;
//     call = other.call ?? call;
//     deletedOnTelegram = other.deletedOnTelegram;
//     existsOnTelegram = other.existsOnTelegram;
//     uploadProgress = other.uploadProgress != 0.0 ? other.uploadProgress : uploadProgress;
//     status = other.status;
//   }
//
//   String previewText() {
//     if ((mediaType ?? 'text') != 'text' && (text.isEmpty)) {
//       return '[${mediaType ?? 'media'}]';
//     }
//     return text;
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
//   final VoidCallback? onLongPress;
//   final VoidCallback? onTapMedia;
//
//   const _MessageBubble({super.key, required this.msg, this.onLongPress, this.onTapMedia});
//
//   @override
//   Widget build(BuildContext context) {
//     final align = msg.isOut ? CrossAxisAlignment.end : CrossAxisAlignment.start;
//     final bubbleColor = msg.isOut ? Colors.blue.shade100 : Colors.grey.shade200;
//     final textColor = Colors.black87;
//
//     final bubble = ConstrainedBox(
//       constraints: const BoxConstraints(maxWidth: 320),
//       child: Container(
//         padding: const EdgeInsets.all(10),
//         decoration: BoxDecoration(
//           color: bubbleColor,
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             if (!msg.isOut && msg.senderName.isNotEmpty)
//               Padding(
//                 padding: const EdgeInsets.only(bottom: 4),
//                 child: Text(msg.senderName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
//               ),
//             _buildBody(context),
//             const SizedBox(height: 6),
//             Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(_fmtTime(msg.date), style: const TextStyle(fontSize: 10, color: Colors.black54)),
//                 const SizedBox(width: 6),
//                 if (msg.status == MessageStatus.pending)
//                   const Icon(Icons.schedule, size: 12, color: Colors.black45)
//                 else if (msg.status == MessageStatus.failed)
//                   const Icon(Icons.error_outline, size: 12, color: Colors.redAccent)
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         mainAxisAlignment: msg.isOut ? MainAxisAlignment.end : MainAxisAlignment.start,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           if (!msg.isOut) const SizedBox(width: 36),
//           GestureDetector(onLongPress: onLongPress, child: bubble),
//           if (msg.isOut) const SizedBox(width: 36),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildBody(BuildContext context) {
//     final mt = (msg.mediaType ?? 'text');
//     final List<Widget> children = [];
//
//     if (msg.replyTo != null)
//       children.add(
//         Container(
//           padding: const EdgeInsets.all(8),
//           margin: const EdgeInsets.only(bottom: 6),
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(0.6),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Text('Reply to #${msg.replyTo}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
//         ),
//       );
//
//     if (mt == 'text') {
//       if (msg.text.isNotEmpty) {
//         children.add(SelectableText(msg.text, style: const TextStyle(fontSize: 15)));
//       } else {
//         children.add(const Text('[empty]', style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic)));
//       }
//     } else if (mt == 'image') {
//       if ((msg.mediaLink ?? '').isNotEmpty) {
//         children.add(
//           GestureDetector(
//             onTap: onTapMedia,
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(10),
//               child: Image.network(
//                 msg.mediaLink!,
//                 fit: BoxFit.cover,
//                 loadingBuilder: (context, child, progress) {
//                   if (progress == null) return child;
//                   final v = progress.expectedTotalBytes == null
//                       ? null
//                       : progress.cumulativeBytesLoaded / (progress.expectedTotalBytes!);
//                   return SizedBox(
//                     height: 180,
//                     width: 240,
//                     child: Center(child: CircularProgressIndicator(value: v)),
//                   );
//                 },
//                 errorBuilder: (_, __, ___) => Container(
//                   color: Colors.black12,
//                   height: 180,
//                   width: 240,
//                   alignment: Alignment.center,
//                   child: const Icon(Icons.broken_image),
//                 ),
//               ),
//             ),
//           ),
//         );
//       } else {
//         // pending upload
//         children.add(_uploadProgressBar());
//       }
//       if (msg.text.isNotEmpty) {
//         children.add(const SizedBox(height: 6));
//         children.add(Text(msg.text));
//       }
//     } else if (mt.startsWith('call_') && msg.call != null) {
//       children.add(
//         _CallChip(call: msg.call!),
//       );
//     } else {
//       // generic file/video/audio/voice/sticker placeholder
//       children.add(
//         InkWell(
//           onTap: onTapMedia,
//           child: Row(children: [
//             const Icon(Icons.attach_file),
//             const SizedBox(width: 8),
//             Expanded(child: Text('[${mt}] tap to open', overflow: TextOverflow.ellipsis)),
//           ]),
//         ),
//       );
//       if (msg.text.isNotEmpty) {
//         children.add(const SizedBox(height: 6));
//         children.add(Text(msg.text));
//       }
//       if (msg.status == MessageStatus.pending) {
//         children.add(const SizedBox(height: 6));
//         children.add(_uploadProgressBar());
//       }
//     }
//
//     return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
//   }
//
//   Widget _uploadProgressBar() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         LinearProgressIndicator(value: (msg.uploadProgress > 0 && msg.uploadProgress <= 100) ? msg.uploadProgress / 100.0 : null),
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
// class _CallChip extends StatelessWidget {
//   final CallInfo call;
//   const _CallChip({required this.call});
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
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 18),
//           const SizedBox(width: 8),
//           Text(text.toString()),
//         ],
//       ),
//     );
//   }
//
//   String _fmt(int s) {
//     final m = (s ~/ 60).toString().padLeft(2, '0');
//     final ss = (s % 60).toString().padLeft(2, '0');
//     return '$m:$ss';
//   }
// }
// ChatScreen.dart — WebSocket client for ws(s)://<HOST>/chat_ws
// Added (without breaking your existing logic):
// 1) exists_on_telegram == false → ghost style (text: italic+fade, image: grayscale+fade)
// 2) Rich reply preview (shows replied message content/type)
// 3) Swipe‑to‑reply (drag right) + Long‑press menu (Reply / Copy text / Copy media link)
// Keeps: INIT, seed/new_message, send text & image, typing, ping, upload progress, send_done, urlLocal

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Clipboard
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:url_launcher/url_launcher.dart';

import '../url.dart';

class ChatScreen extends StatefulWidget {
  final String phone;
  final int chatId;
  final int? accessHash; // optional
  final String name;
  final String username;

  const ChatScreen({
    super.key,
    required this.phone,
    required this.chatId,
    required this.accessHash,
    required this.name,
    required this.username,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // WebSocket
  WebSocket? _ws;
  bool _connecting = false;
  bool _manuallyClosed = false;
  int _reconnectAttempt = 0;

  // Heartbeat / typing
  Timer? _pingTimer;
  Timer? _typingDebounce;
  final Set<int> _typingUserIds = <int>{};
  Timer? _typingTtlSweeper;
  final Map<int, DateTime> _typingTtl = {}; // senderId -> expiry

  // UI
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _seedArrived = false;
  bool _listening = false;
  bool _sending = false;

  // Reply context
  int? _replyToMsgId;
  String? _replyPreviewText;

  // Messages (oldest → newest)
  final List<ChatMessage> _messages = [];
  final Map<int, ChatMessage> _byId = {};
  final Map<String, ChatMessage> _byTemp = {};

  // ===== URL helpers =====
  String get _wsUrl {
    final base = urlLocal.trim();
    final uri = Uri.parse(base);
    final isHttps = uri.scheme == 'https';
    final scheme = isHttps ? 'wss' : 'ws';
    final path = uri.path.endsWith('/') ? '${uri.path}chat_ws' : '${uri.path}/chat_ws';
    final wsUri = Uri(scheme: scheme, host: uri.host, port: uri.hasPort ? uri.port : null, path: path);
    return wsUri.toString();
  }

  String rewriteMediaLink(String? link) {
    if (link == null || link.isEmpty) return '';
    final api = Uri.parse(urlLocal);
    Uri uri;
    try { uri = Uri.parse(link); } catch (_) { return link; }

    final isLocal = (uri.host == '127.0.0.1') || (uri.host == 'localhost');
    if (!isLocal) return link; // already absolute external

    final newUri = Uri(
      scheme: api.scheme,
      host: api.host,
      port: api.hasPort ? api.port : null,
      path: uri.path,
      query: uri.query,
    );
    return newUri.toString();
  }

  @override
  void initState() {
    super.initState();
    _connect();
  }

  @override
  void dispose() {
    _manuallyClosed = true;
    _pingTimer?.cancel();
    _typingDebounce?.cancel();
    _typingTtlSweeper?.cancel();
    _ws?.close();
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (_connecting) return;
    _connecting = true;
    _manuallyClosed = false;

    try {
      setState(() { _listening = false; });
      _ws = await WebSocket.connect(_wsUrl);
      _reconnectAttempt = 0;

      // INIT as first frame
      final initPayload = {
        'phone': widget.phone,
        'chat_id': widget.chatId,
        if (widget.accessHash != null) 'access_hash': widget.accessHash,
      };
      _send(initPayload);

      _startPing();
      _startTypingSweeper();

      _ws!.listen(
            (dynamic data) {
          if (data is String) {
            _handleFrameString(data);
          } else if (data is List<int>) {
            _handleFrameString(utf8.decode(data));
          }
        },
        cancelOnError: true,
        onDone: _onSocketDone,
        onError: (err) { _onSocketDone(); },
      );
    } catch (e) {
      _scheduleReconnect();
    } finally {
      _connecting = false;
    }
  }

  void _onSocketDone() {
    _pingTimer?.cancel();
    _typingTtlSweeper?.cancel();
    if (!_manuallyClosed) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_manuallyClosed) return;
    _reconnectAttempt++;
    final delay = min(30, pow(2, _reconnectAttempt).toInt()); // 2,4,8,16,30
    Future.delayed(Duration(seconds: delay), () {
      if (mounted && !_manuallyClosed) _connect();
    });
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      _send({ 'action': 'ping' });
    });
  }

  void _startTypingSweeper() {
    _typingTtlSweeper?.cancel();
    _typingTtlSweeper = Timer.periodic(const Duration(seconds: 2), (_) {
      final now = DateTime.now().toUtc();
      final expired = _typingTtl.entries.where((e) => e.value.isBefore(now)).map((e) => e.key).toList();
      if (expired.isNotEmpty) {
        for (final id in expired) {
          _typingTtl.remove(id);
          _typingUserIds.remove(id);
        }
        if (mounted) setState(() {});
      }
    });
  }

  void _handleFrameString(String s) {
    Map<String, dynamic> m;
    try { m = json.decode(s) as Map<String, dynamic>; } catch (_) { return; }

    // Status frames
    if (m['status'] == 'listening') {
      setState(() { _listening = true; });
      return;
    }
    if (m['status'] == 'pong') return;
    if (m['status'] == 'error') {
      final detail = m['detail']?.toString() ?? 'error';
      _showSnack('Error: $detail');
      return;
    }

    final action = m['action'];
    switch (action) {
      case 'seed':
        final arr = (m['messages'] as List?) ?? [];
        for (final it in arr) {
          final msg = ChatMessage.fromJson(it as Map<String, dynamic>);
          _insertOrUpdate(msg);
        }
        _seedArrived = true;
        _scrollToBottom();
        setState(() {});
        break;
      case 'new_message':
        final msg = ChatMessage.fromJson(m);
        _insertOrUpdate(msg);
        _scrollAfterIncoming();
        setState(() {});
        break;
      case 'send_queued':
        final tempId = m['temp_id']?.toString() ?? _makeTempId();
        final msg = ChatMessage(
          id: null,
          tempId: tempId,
          text: (m['text'] ?? '').toString(),
          date: _parseIso(m['date']) ?? DateTime.now().toUtc(),
          isOut: true,
          senderId: null,
          senderName: widget.username,
          replyTo: null,
          mediaType: (m['media_type'] ?? 'text').toString(),
          mediaLink: null,
          call: null,
          deletedOnTelegram: false,
          existsOnTelegram: false,
          uploadProgress: 0.0,
          status: MessageStatus.pending,
        );
        _messages.add(msg);
        _byTemp[tempId] = msg;
        _scrollToBottom();
        setState(() {});
        break;
      case 'upload_progress':
        final tempId = m['temp_id']?.toString();
        final p = (m['progress'] is num) ? (m['progress'] as num).toDouble() : null;
        if (tempId != null && p != null) {
          final item = _byTemp[tempId];
          if (item != null) { item.uploadProgress = p; setState(() {}); }
        }
        break;
      case 'send_done':
        final tempId = m['temp_id']?.toString();
        final msgId = m['msg_id'];
        if (tempId != null && msgId is int) {
          final item = _byTemp[tempId];
          if (item != null) {
            item.id = msgId;
            item.existsOnTelegram = true;
            item.status = MessageStatus.sent;
            _byId[msgId] = item;
            setState(() {});
          }
        }
        break;
      case 'send_failed':
        final tempId = m['temp_id']?.toString();
        if (tempId != null) {
          final item = _byTemp[tempId];
          if (item != null) { item.status = MessageStatus.failed; setState(() {}); _showSnack('Send failed: ${m['detail'] ?? ''}'); }
        }
        break;
      case 'typing':
        final sender = (m['sender_id'] is int) ? m['sender_id'] as int : null;
        if (sender != null) {
          _typingUserIds.add(sender);
          _typingTtl[sender] = DateTime.now().toUtc().add(const Duration(seconds: 6));
          setState(() {});
        }
        break;
      case 'typing_stopped':
        final sender = (m['sender_id'] is int) ? m['sender_id'] as int : null;
        if (sender != null) {
          _typingUserIds.remove(sender);
          _typingTtl.remove(sender);
          setState(() {});
        }
        break;
      case '_hb':
        break;
      default:
      // ignore
    }
  }

  void _insertOrUpdate(ChatMessage msg) {
    msg.mediaLink = rewriteMediaLink(msg.mediaLink);

    if (msg.id != null) {
      final existing = _byId[msg.id!];
      if (existing != null) {
        existing.mergeFrom(msg);
      } else {
        _byId[msg.id!] = msg;
        _messages.add(msg);
      }
    } else if (msg.tempId != null) {
      final existing = _byTemp[msg.tempId!];
      if (existing != null) {
        existing.mergeFrom(msg);
      } else {
        _byTemp[msg.tempId!] = msg;
        _messages.add(msg);
      }
    } else {
      _messages.add(msg);
    }
    _messages.sort((a, b) => a.date.compareTo(b.date));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _scrollAfterIncoming() {
    if (!_scrollCtrl.hasClients) return;
    final atBottom = _scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 120;
    if (atBottom) _scrollToBottom();
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _send(Map<String, dynamic> payload) {
    final w = _ws;
    if (w == null) return;
    try { w.add(json.encode(payload)); } catch (_) {}
  }

  // ===== helpers for reply/copy =====
  ChatMessage? _findById(int id) => _byId[id];

  void _onReply(ChatMessage m) {
    if (m.id == null) { _showSnack('Reply needs a real msg_id'); return; }
    setState(() { _replyToMsgId = m.id; _replyPreviewText = m.previewText(); });
  }

  Future<void> _copyText(String t) async {
    if (t.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: t));
    _showSnack('Copied');
  }

  Future<void> _copyLink(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    _showSnack('Link copied');
  }

  void _showMsgMenu(ChatMessage m) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        final items = <Widget>[
          ListTile(
            leading: const Icon(Icons.reply),
            title: const Text('Reply'),
            onTap: () { Navigator.pop(context); _onReply(m); },
          ),
        ];
        if ((m.text).trim().isNotEmpty) {
          items.add(ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('Copy text'),
            onTap: () { Navigator.pop(context); _copyText(m.text); },
          ));
        }
        if ((m.mediaLink ?? '').isNotEmpty) {
          items.add(ListTile(
            leading: const Icon(Icons.link),
            title: const Text('Copy media link'),
            onTap: () { Navigator.pop(context); _copyLink(m.mediaLink!); },
          ));
        }
        return SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: items));
      },
    );
  }

  // ===== Actions =====
  void _sendTypingStart() {
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(milliseconds: 200), () {
      _send({ 'action': 'typing_start' });
    });
  }

  Future<void> _sendText() async {
    if (_ws == null) return;
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() { _sending = true; });

    final payload = <String, dynamic>{
      'action': 'send',
      'text': text,
      if (_replyToMsgId != null) 'reply_to': _replyToMsgId,
    };
    _send(payload);

    _textCtrl.clear();
    _clearReply();
    setState(() { _sending = false; });
  }

  Future<void> _sendImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 92);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final b64 = base64Encode(bytes);
    final mime = lookupMimeType(picked.name) ?? 'image/jpeg';

    final dataUri = 'data:$mime;base64,$b64';
    final payload = <String, dynamic>{
      'action': 'send',
      'text': '',
      'file_base64': dataUri,
      'file_name': picked.name,
      'mime_type': mime,
      if (_replyToMsgId != null) 'reply_to': _replyToMsgId,
    };
    _send(payload);
    _clearReply();
  }

  void _clearReply() {
    setState(() { _replyToMsgId = null; _replyPreviewText = null; });
  }

  String _makeTempId() => 'local-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1<<32)}';

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(child: Text(widget.name.isNotEmpty ? widget.name.characters.first : 'U')),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(_subtitleText(), style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () { _ws?.close(); _connect(); },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_replyToMsgId != null) _buildReplyBar(),
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              itemCount: _messages.length + 1,
              itemBuilder: (_, i) {
                if (i == _messages.length) { return _buildTypingRow(); }
                final m = _messages[i];
                return _MessageBubble(
                  key: ValueKey('msg-${m.id ?? m.tempId ?? i}'),
                  msg: m,
                  findById: _findById,
                  onSwipeReply: () => _onReply(m),
                  onLongPress: () => _showMsgMenu(m),
                  onTapMedia: () async {
                    final url = m.mediaLink; if (url == null || url.isEmpty) return;
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) { await launchUrl(uri, mode: LaunchMode.externalApplication); }
                  },
                );
              },
            ),
          ),
          _buildComposer(),
        ],
      ),
    );
  }

  String _subtitleText() {
    if (!_listening) return 'connecting…';
    if (!_seedArrived) return 'loading history…';
    if (_typingUserIds.isNotEmpty) return 'typing…';
    return 'online';
  }

  Widget _buildTypingRow() {
    if (_typingUserIds.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text('typing…', style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic)),
    );
  }

  Widget _buildReplyBar() {
    return Container(
      width: double.infinity,
      color: Colors.grey.shade200,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      child: Row(
        children: [
          const Icon(Icons.reply, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _replyPreviewText ?? 'Replying…',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(onPressed: _clearReply, icon: const Icon(Icons.close, size: 18))
        ],
      ),
    );
  }

  Widget _buildComposer() {
    final canSend = _textCtrl.text.trim().isNotEmpty && !_sending;

    return SafeArea(
      top: false,
      child: Container(
        color: const Color(0xFFF7F7F7), // Telegram-like bottom bar
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        child: Row(
          children: [
            // Telegram-style attach (paperclip). Still calls _sendImage().
            IconButton(
              tooltip: 'Attach',
              onPressed: _sendImage,
              icon: const Icon(Icons.attach_file),
            ),

            // Rounded, filled input like Telegram
            Expanded(
              child: TextField(
              controller: _textCtrl,
              minLines: 1,
              maxLines: 4,
              onChanged: (_) => _sendTypingStart(),
              decoration: const InputDecoration(hintText: 'Message', isDense: true, border: OutlineInputBorder()),
            ),

              // Container(
              //   decoration: BoxDecoration(
              //     color: Colors.white,
              //     borderRadius: BorderRadius.circular(24),
              //     boxShadow: const [
              //       BoxShadow(color: Colors.black12, blurRadius: 1, offset: Offset(0, 1)),
              //     ],
              //   ),
              //   padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              //   child: TextField(
              //     controller: _textCtrl,
              //     minLines: 1,
              //     maxLines: 5,
              //     onChanged: (_) {
              //       _sendTypingStart();
              //       // update send button enabled/disabled instantly
              //       if (mounted) setState(() {});
              //     },
              //     style: const TextStyle(fontSize: 16),
              //     decoration: const InputDecoration(
              //       hintText: 'Message',
              //       isCollapsed: true,
              //       border: InputBorder.none,
              //     ),
              //   ),
              // ),
            ),

            const SizedBox(width: 8),

            // Telegram-style circular Send button
            SizedBox(
              width: 40,
              height: 40,
              child: Material(
                color: canSend ? const Color(0xFF2AABEE) : const Color(0xFFB3E5FC),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: canSend ? _sendText : null,
                  child: Center(
                    child: _sending
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                    )
                        :  IconButton(onPressed: _sending ? null : _sendText, icon: const Icon(Icons.send)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


// Widget _buildComposer() {
  //   return SafeArea(
  //     top: false,
  //     child:
  //     Padding(
  //       padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
  //       child: Row(
  //         children: [
  //           IconButton(tooltip: 'Image', onPressed: _sendImage, icon: const Icon(Icons.image)),
  //           Expanded(
  //             child: TextField(
  //               controller: _textCtrl,
  //               minLines: 1,
  //               maxLines: 5,
  //               onChanged: (_) => _sendTypingStart(),
  //               decoration: const InputDecoration(hintText: 'Message', isDense: true, border: OutlineInputBorder()),
  //             ),
  //           ),
  //           const SizedBox(width: 8),
  //           IconButton(onPressed: _sending ? null : _sendText, icon: const Icon(Icons.send)),
  //         ],
  //       ),
  //     ),
  //   );
  // }
}

DateTime _parseIso(dynamic v) {
  if (v is String) { try { return DateTime.parse(v).toUtc(); } catch (_) {} }
  return DateTime.now().toUtc();
}

enum MessageStatus { pending, sent, failed }

class ChatMessage {
  int? id; // Telegram msg_id
  String? tempId; // local id for pending
  String text;
  int? senderId;
  String senderName;
  DateTime date;
  bool isOut;
  int? replyTo;
  String? mediaType; // text|image|video|audio|voice|sticker|file|call_audio|call_video
  String? mediaLink; // for non-text
  CallInfo? call;
  bool deletedOnTelegram;
  bool existsOnTelegram;
  double uploadProgress; // 0..100 for pending file uploads
  MessageStatus status;

  ChatMessage({
    required this.id,
    required this.tempId,
    required this.text,
    required this.date,
    required this.isOut,
    required this.senderId,
    required this.senderName,
    required this.replyTo,
    required this.mediaType,
    required this.mediaLink,
    required this.call,
    required this.deletedOnTelegram,
    required this.existsOnTelegram,
    required this.uploadProgress,
    this.status = MessageStatus.sent,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> m) {
    return ChatMessage(
      id: (m['id'] is int) ? m['id'] as int : int.tryParse(m['id']?.toString() ?? ''),
      tempId: m['temp_id']?.toString(),
      text: (m['text'] ?? '').toString(),
      senderId: (m['sender_id'] is int) ? m['sender_id'] as int : null,
      senderName: (m['sender_name'] ?? '').toString(),
      date: _parseIso(m['date']),
      isOut: (m['is_out'] == true),
      replyTo: (m['reply_to'] is int) ? m['reply_to'] as int : null,
      mediaType: m['media_type']?.toString(),
      mediaLink: m['media_link']?.toString(),
      call: (m['call'] is Map) ? CallInfo.fromJson(m['call'] as Map<String, dynamic>) : null,
      deletedOnTelegram: m['deleted_on_telegram'] == true,
      existsOnTelegram: m['exists_on_telegram'] != false, // default true when msg_id exists
      uploadProgress: 0.0,
      status: MessageStatus.sent,
    );
  }

  void mergeFrom(ChatMessage other) {
    id = other.id ?? id;
    tempId = other.tempId ?? tempId;
    text = other.text.isNotEmpty ? other.text : text;
    senderId = other.senderId ?? senderId;
    senderName = other.senderName.isNotEmpty ? other.senderName : senderName;
    date = other.date;
    isOut = other.isOut;
    replyTo = other.replyTo ?? replyTo;
    mediaType = other.mediaType ?? mediaType;
    mediaLink = other.mediaLink ?? mediaLink;
    call = other.call ?? call;
    deletedOnTelegram = other.deletedOnTelegram;
    existsOnTelegram = other.existsOnTelegram;
    uploadProgress = other.uploadProgress != 0.0 ? other.uploadProgress : uploadProgress;
    status = other.status;
  }

  String previewText() {
    if ((mediaType ?? 'text') != 'text' && (text.isEmpty)) {
      return '[${mediaType ?? 'media'}]';
    }
    return text;
  }
}

class CallInfo {
  final String status; // missed|busy|canceled|ended|accepted|ongoing|requested|unknown
  final int? duration; // seconds
  final bool isVideo;
  final String? reason; // raw TL name
  final String direction; // incoming|outgoing

  CallInfo({
    required this.status,
    required this.duration,
    required this.isVideo,
    required this.reason,
    required this.direction,
  });

  factory CallInfo.fromJson(Map<String, dynamic> m) {
    return CallInfo(
      status: (m['status'] ?? 'unknown').toString(),
      duration: (m['duration'] is int) ? m['duration'] as int : null,
      isVideo: m['is_video'] == true,
      reason: m['reason']?.toString(),
      direction: (m['direction'] ?? 'incoming').toString(),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage msg;
  final VoidCallback? onLongPress;
  final VoidCallback? onTapMedia;
  final ChatMessage? Function(int id) findById; // NEW
  final VoidCallback? onSwipeReply;             // NEW

  const _MessageBubble({
    super.key,
    required this.msg,
    this.onLongPress,
    this.onTapMedia,
    required this.findById,
    this.onSwipeReply,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: msg.isOut ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!msg.isOut) const SizedBox(width: 36),
          GestureDetector(
            onLongPress: onLongPress,
            onHorizontalDragEnd: (details) {
              if ((details.primaryVelocity ?? 0) > 150) { // swipe → reply
                if (onSwipeReply != null) onSwipeReply!();
              }
            },
            child: _buildBubbleWithGhosting(context),
          ),
          if (msg.isOut) const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _buildBubbleWithGhosting(BuildContext context) {
    final ghost = (msg.existsOnTelegram == false) || (msg.status == MessageStatus.pending);
    final base = _bubbleCore(context);

    // text/call → overall opacity
    if ((msg.mediaType ?? 'text') == 'text' || (msg.mediaType ?? '').startsWith('call_')) {
      return Opacity(opacity: ghost ? 0.65 : 1.0, child: base);
    }
    return base; // image/file handled in body
  }

  Widget _bubbleCore(BuildContext context) {
    final bubbleColor = msg.isOut ? Colors.blue.shade100 : Colors.grey.shade200;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: bubbleColor, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!msg.isOut && msg.senderName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(msg.senderName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            _buildBody(context),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_fmtTime(msg.date), style: const TextStyle(fontSize: 10, color: Colors.black54)),
                const SizedBox(width: 6),
                if (msg.status == MessageStatus.pending)
                  const Icon(Icons.schedule, size: 12, color: Colors.black45)
                else if (msg.status == MessageStatus.failed)
                  const Icon(Icons.error_outline, size: 12, color: Colors.redAccent)
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final mt = (msg.mediaType ?? 'text');
    final List<Widget> children = [];

    // Reply preview (real content)
    if (msg.replyTo != null) {
      final ref = findById(msg.replyTo!);
      children.add(_ReplyPreview(id: msg.replyTo!, text: ref?.previewText() ?? '', mediaType: ref?.mediaType ?? 'text'));
    }

    if (mt == 'text') {
      final ghost = (msg.existsOnTelegram == false) || (msg.status == MessageStatus.pending);
      if (msg.text.isNotEmpty) {
        children.add(SelectableText(
          msg.text,
          style: TextStyle(
            fontSize: 15,
            fontStyle: ghost ? FontStyle.italic : FontStyle.normal,
            color: ghost ? Colors.black54 : Colors.black87,
          ),
        ));
      } else {
        children.add(const Text('[empty]', style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic)));
      }
    } else if (mt == 'image') {
      final ghost = (msg.existsOnTelegram == false) || (msg.status == MessageStatus.pending);
      if ((msg.mediaLink ?? '').isNotEmpty) {
        Widget img = Image.network(
          msg.mediaLink!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            final v = progress.expectedTotalBytes == null ? null : progress.cumulativeBytesLoaded / (progress.expectedTotalBytes!);
            return SizedBox(height: 180, width: 240, child: Center(child: CircularProgressIndicator(value: v)));
          },
          errorBuilder: (_, __, ___) => Container(
            color: Colors.black12,
            height: 180,
            width: 240,
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image),
          ),
        );
        if (ghost) {
          img = Opacity(
            opacity: 0.65,
            child: const ColorFiltered(
              colorFilter: ColorFilter.matrix(<double>[
                0.2126, 0.7152, 0.0722, 0, 0,
                0.2126, 0.7152, 0.0722, 0, 0,
                0.2126, 0.7152, 0.0722, 0, 0,
                0,      0,      0,      1, 0,
              ]),
              child: SizedBox.shrink(),
            ),
          );
          // wrap real image inside ColorFiltered
          img = Opacity(
            opacity: 0.65,
            child: ColorFiltered(
              colorFilter: const ColorFilter.matrix(<double>[
                0.2126, 0.7152, 0.0722, 0, 0,
                0.2126, 0.7152, 0.0722, 0, 0,
                0.2126, 0.7152, 0.0722, 0, 0,
                0,      0,      0,      1, 0,
              ]),
              child: img,
            ),
          );
        }
        children.add(
          GestureDetector(
            onTap: onTapMedia,
            child: ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 240, child: img)),
          ),
        );
      } else {
        children.add(_uploadProgressBar());
      }
      if (msg.text.isNotEmpty) {
        children.add(const SizedBox(height: 6));
        children.add(Text(
          msg.text,
          style: TextStyle(
            fontStyle: (msg.existsOnTelegram == false) ? FontStyle.italic : FontStyle.normal,
            color: (msg.existsOnTelegram == false) ? Colors.black54 : null,
          ),
        ));
      }
    } else if (mt.startsWith('call_') && msg.call != null) {
      children.add(_CallChip(call: msg.call!));
    } else {
      // generic file/video/audio/voice/sticker
      children.add(
        InkWell(
          onTap: onTapMedia,
          child: Row(children: [
            const Icon(Icons.attach_file),
            const SizedBox(width: 8),
            Expanded(child: Text('[${mt}] tap to open', overflow: TextOverflow.ellipsis)),
          ]),
        ),
      );
      if (msg.text.isNotEmpty) {
        children.add(const SizedBox(height: 6));
        children.add(Text(msg.text));
      }
      if (msg.status == MessageStatus.pending) {
        children.add(const SizedBox(height: 6));
        children.add(_uploadProgressBar());
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  Widget _uploadProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(value: (msg.uploadProgress > 0 && msg.uploadProgress <= 100) ? msg.uploadProgress / 100.0 : null),
        const SizedBox(height: 4),
        Text('${msg.uploadProgress.toStringAsFixed(1)}%'),
      ],
    );
  }

  String _fmtTime(DateTime dt) {
    final h = dt.toLocal().hour.toString().padLeft(2, '0');
    final m = dt.toLocal().minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _ReplyPreview extends StatelessWidget {
  final int id;
  final String text;
  final String mediaType;
  const _ReplyPreview({required this.id, required this.text, required this.mediaType});

  @override
  Widget build(BuildContext context) {
    final isText = mediaType == 'text';
    final label = isText ? (text.isEmpty ? '[text]' : text) : '[${mediaType}]';
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(children: [
        const Icon(Icons.subdirectory_arrow_right, size: 16, color: Colors.black54),
        const SizedBox(width: 6),
        Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.black87))),
        const SizedBox(width: 6),
        Text('#$id', style: const TextStyle(fontSize: 11, color: Colors.black45)),
      ]),
    );
  }
}

class _CallChip extends StatelessWidget {
  final CallInfo call;
  const _CallChip({required this.call});

  @override
  Widget build(BuildContext context) {
    final isVideo = call.isVideo;
    final icon = isVideo ? Icons.videocam : Icons.call;
    final dur = call.duration != null ? _fmt(call.duration!) : null;
    final text = StringBuffer()..write(call.direction)..write(' ')..write(call.status);
    if (dur != null) text.write(' • $dur');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Text(text.toString()),
      ]),
    );
  }

  String _fmt(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$m:$ss';
  }
}