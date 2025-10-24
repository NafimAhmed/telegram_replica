// import 'dart:convert';
// import 'dart:io';
// import 'package:ag_taligram/url.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:image_picker/image_picker.dart';
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
//   final ScrollController _scrollController = ScrollController();
//   final TextEditingController _msgCtrl = TextEditingController();
//   final ImagePicker _picker = ImagePicker();
//
//   WebSocket? _socket;
//   bool _loading = true;
//   bool _sending = false;
//   List<File> _selectedImages = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchAndLoad(); // Load old messages
//     _connectWebSocket(); // Connect WS for real-time
//   }
//
//   @override
//   void dispose() {
//     _socket?.close();
//     super.dispose();
//   }
//
//   // ✅ Connect WebSocket
//   Future<void> _connectWebSocket() async {
//     try {
//       final wsUrl = 'ws://192.168.0.247:8080/chat_ws';
//       _socket = await WebSocket.connect(wsUrl);
//       print("✅ WebSocket Connected");
//
//       // 🔹 Send initialization (start listening for this chat)
//       final init = {
//         "phone": widget.phone,
//         "chat_id": widget.chatId,
//       };
//       _socket!.add(jsonEncode(init));
//
//       // 🔹 Listen for new messages
//       _socket!.listen((raw) {
//         try {
//           final decoded = jsonDecode(raw);
//           print("📩 WS RECEIVED → $decoded");
//
//           if (decoded["action"] == "new_message") {
//             // ✅ Incoming Telegram message
//             if (decoded["chat_id"].toString() ==
//                 widget.chatId.toString()) {
//               final provider =
//               Provider.of<TelegraphProvider>(context, listen: false);
//               provider.messages.insert(0, {
//                 "text": decoded["text"] ?? "",
//                 "is_out": false,
//                 "time": decoded["date"] ?? DateTime.now().toString(),
//               });
//               provider.notifyListeners();
//             }
//           } else if (decoded["status"] == "sent") {
//             print("✅ Message confirmed sent: ${decoded["text"]}");
//           } else if (decoded["status"] == "error") {
//             print("❌ WS Error: ${decoded["detail"]}");
//           }
//         } catch (e) {
//           print("⚠️ Decode error: $e");
//         }
//       }, onDone: () {
//         print("⚠️ WS closed. Reconnecting in 3s...");
//         Future.delayed(const Duration(seconds: 3), _connectWebSocket);
//       }, onError: (e) {
//         print("❌ WS error: $e");
//         Future.delayed(const Duration(seconds: 5), _connectWebSocket);
//       });
//     } catch (e) {
//       print("❌ WS connect failed: $e");
//       Future.delayed(const Duration(seconds: 5), _connectWebSocket);
//     }
//   }
//
//   // ✅ Fetch old messages
//   Future<void> _fetchAndLoad() async {
//     final provider = Provider.of<TelegraphProvider>(context, listen: false);
//     await provider.fetchMessages(
//         widget.phone, widget.chatId, widget.accessHash);
//     setState(() => _loading = false);
//   }
//
//   // ✅ Send message (via WebSocket → fallback HTTP)
//   Future<void> _sendMessage() async {
//     final text = _msgCtrl.text.trim();
//     if (text.isEmpty) return;
//
//     setState(() => _sending = true);
//     final provider = Provider.of<TelegraphProvider>(context, listen: false);
//
//     try {
//       if (_socket != null && _socket!.readyState == WebSocket.open) {
//         final msg = {
//           "action": "send",
//           "phone": widget.phone,
//           "chat_id": widget.chatId,
//           "access_hash": widget.accessHash,
//           "text": text,
//         };
//         _socket!.add(jsonEncode(msg));
//         print("📤 WS SENT → $msg");
//
//         // Show message instantly
//         provider.messages.insert(0, {
//           "text": text,
//           "is_out": true,
//           "time": DateTime.now().toString(),
//         });
//         provider.notifyListeners();
//         _msgCtrl.clear();
//       } else {
//         // HTTP fallback
//         final url = Uri.parse("$urlLocal/send");
//         final res = await http.post(url, body: {
//           "phone": widget.phone,
//           "to": widget.username,
//           "text": text,
//         });
//
//         if (res.statusCode == 200) {
//           provider.messages.insert(0, {
//             "text": text,
//             "is_out": true,
//             "time": DateTime.now().toString(),
//           });
//           provider.notifyListeners();
//           _msgCtrl.clear();
//         }
//       }
//     } catch (e) {
//       print("⚠️ Send error: $e");
//     } finally {
//       setState(() => _sending = false);
//     }
//   }
//
//   // 📸 Image picker logic
//   Future<void> _requestPermissions() async {
//     await [
//       Permission.camera,
//       Permission.photos,
//       Permission.storage,
//     ].request();
//   }
//
//   Future<void> _pickFromGallery() async {
//     await _requestPermissions();
//     final picked = await _picker.pickMultiImage(imageQuality: 80);
//     if (picked.isNotEmpty) {
//       setState(() => _selectedImages.addAll(picked.map((e) => File(e.path))));
//     }
//   }
//
//   Future<void> _pickFromCamera() async {
//     await _requestPermissions();
//     final picked =
//     await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
//     if (picked != null) {
//       setState(() => _selectedImages.add(File(picked.path)));
//     }
//   }
//
//   void _showSourceDialog() {
//     showModalBottomSheet(
//       context: context,
//       builder: (ctx) => SafeArea(
//         child: Wrap(
//           children: [
//             ListTile(
//               leading: const Icon(Icons.photo, color: Colors.green),
//               title: const Text("Gallery থেকে নিন"),
//               onTap: () {
//                 Navigator.pop(ctx);
//                 _pickFromGallery();
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.camera_alt, color: Colors.green),
//               title: const Text("Camera দিয়ে তুলুন"),
//               onTap: () {
//                 Navigator.pop(ctx);
//                 _pickFromCamera();
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // 🧱 UI build
//   @override
//   Widget build(BuildContext context) {
//     final provider = Provider.of<TelegraphProvider>(context);
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFE5DDD5),
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF008069),
//         title: Row(
//           children: [
//             const CircleAvatar(
//               backgroundColor: Colors.white,
//               child: Icon(Icons.person, color: Colors.black),
//             ),
//             const SizedBox(width: 10),
//             Text(widget.name,
//                 style: const TextStyle(color: Colors.white, fontSize: 18)),
//           ],
//         ),
//       ),
//       body: _loading
//           ? const Center(child: CircularProgressIndicator())
//           : Column(
//         children: [
//           if (_selectedImages.isNotEmpty)
//             Container(
//               height: 90,
//               padding: const EdgeInsets.symmetric(horizontal: 8),
//               child: ListView.builder(
//                 scrollDirection: Axis.horizontal,
//                 itemCount: _selectedImages.length,
//                 itemBuilder: (context, i) {
//                   final file = _selectedImages[i];
//                   return Stack(
//                     children: [
//                       Container(
//                         margin:
//                         const EdgeInsets.symmetric(horizontal: 4),
//                         child: ClipRRect(
//                           borderRadius: BorderRadius.circular(10),
//                           child: Image.file(
//                             file,
//                             width: 80,
//                             height: 80,
//                             fit: BoxFit.cover,
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         top: 2,
//                         right: 6,
//                         child: GestureDetector(
//                           onTap: () {
//                             setState(() {
//                               _selectedImages.removeAt(i);
//                             });
//                           },
//                           child: const CircleAvatar(
//                             radius: 10,
//                             backgroundColor: Colors.black54,
//                             child: Icon(Icons.close,
//                                 size: 14, color: Colors.white),
//                           ),
//                         ),
//                       ),
//                     ],
//                   );
//                 },
//               ),
//             ),
//
//           // 🔹 Messages list (real-time)
//           Expanded(
//             child: ListView.builder(
//               controller: _scrollController,
//               reverse: true,
//               itemCount: provider.messages.length,
//               itemBuilder: (context, i) {
//                 final msg = provider.messages[i];
//                 final isOut = msg["is_out"] == true;
//                 final text = msg["text"] ?? "";
//                 final time = msg["time"] ?? "";
//
//                 return Align(
//                   alignment: isOut
//                       ? Alignment.centerRight
//                       : Alignment.centerLeft,
//                   child: Container(
//                     margin: const EdgeInsets.symmetric(
//                         vertical: 4, horizontal: 8),
//                     padding: const EdgeInsets.all(10),
//                     decoration: BoxDecoration(
//                       color: isOut
//                           ? Colors.green.shade400
//                           : Colors.grey.shade300,
//                       borderRadius: BorderRadius.only(
//                         topLeft: const Radius.circular(14),
//                         topRight: const Radius.circular(14),
//                         bottomLeft: isOut
//                             ? const Radius.circular(14)
//                             : const Radius.circular(0),
//                         bottomRight: isOut
//                             ? const Radius.circular(0)
//                             : const Radius.circular(14),
//                       ),
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.end,
//                       children: [
//                         if (text.isNotEmpty)
//                           Padding(
//                             padding:
//                             const EdgeInsets.symmetric(vertical: 4),
//                             child: Text(
//                               text,
//                               style: TextStyle(
//                                 color: isOut
//                                     ? Colors.white
//                                     : Colors.black87,
//                                 fontSize: 15,
//                               ),
//                             ),
//                           ),
//                         Text(
//                           time,
//                           style: TextStyle(
//                             color: isOut
//                                 ? Colors.white70
//                                 : Colors.grey[700],
//                             fontSize: 11,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//
//           // 🔹 Message Input
//           Container(
//             color: Colors.white,
//             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//             child: Row(
//               children: [
//                 IconButton(
//                   icon: const Icon(Icons.add, color: Colors.green),
//                   onPressed: _showSourceDialog,
//                 ),
//                 Expanded(
//                   child: TextField(
//                     controller: _msgCtrl,
//                     decoration: const InputDecoration(
//                       hintText: "Message",
//                       border: InputBorder.none,
//                     ),
//                   ),
//                 ),
//                 _sending
//                     ? const Padding(
//                   padding: EdgeInsets.all(8.0),
//                   child: CircularProgressIndicator(strokeWidth: 2),
//                 )
//                     : IconButton(
//                   icon: const Icon(Icons.send, color: Colors.green),
//                   onPressed: _sendMessage,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }





















//
// import 'dart:convert';
// import 'dart:io';
// import 'package:ag_taligram/url.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
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
//   final ScrollController _scrollController = ScrollController();
//   final TextEditingController _msgCtrl = TextEditingController();
//   final ImagePicker _picker = ImagePicker();
//   WebSocket? _socket;
//
//   bool _loading = true;
//   bool _sending = false;
//   bool _typing = false;
//
//   // upload progress (maps to the last uploading message)
//   double _uploadProgress = 0.0;
//   int? _uploadingMsgIndex; // index in provider.messages
//
//   // optional: reply support (set this map from long-press)
//   Map<String, dynamic>? _replyToMsg;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchAndLoad();
//     _connectWebSocket();
//   }
//
//   @override
//   void dispose() {
//     _socket?.close();
//     super.dispose();
//   }
//
//   // ================================
//   // 🔌 WebSocket Connect
//   // ================================
//   Future<void> _connectWebSocket() async {
//     try {
//       // ⚠️ real device হলে LAN IP দাও
//       final wsUrl = 'ws://192.168.0.247:8080/chat_ws';
//       _socket = await WebSocket.connect(wsUrl);
//       debugPrint("✅ WS connected");
//
//       // INIT: backend-এর chat_ws যেমন চায়
//       final init = {
//         "phone": widget.phone,
//         "chat_id": widget.chatId,
//         "access_hash": widget.accessHash,
//       };
//       _socket!.add(jsonEncode(init));
//
//       _socket!.listen((raw) {
//         final provider = Provider.of<TelegraphProvider>(context, listen: false);
//         try {
//           final data = jsonDecode(raw);
//           // debugPrint("📩 WS IN → $data");
//
//           // --- upload progress (global)
//           if (data["action"] == "upload_progress") {
//             final prog = (data["progress"] ?? 0).toDouble();
//             setState(() => _uploadProgress = prog);
//             // tie to last uploading message
//             if (_uploadingMsgIndex != null &&
//                 _uploadingMsgIndex! < provider.messages.length) {
//               provider.messages[_uploadingMsgIndex!]["progress"] = prog;
//               provider.notifyListeners();
//             }
//             return;
//           }
//
//           // --- new incoming message from Telegram
//           if (data["action"] == "new_message") {
//             if (data["chat_id"].toString() == widget.chatId.toString()) {
//               final mediaType = data["media_type"]; // image / video / audio / file / null
//               final fileName  = data["file_name"];
//               final fileUrl   = data["file_url"];  // থাকলে ব্যবহার করব
//
//               provider.messages.insert(0, {
//                 "id": data["id"],
//                 "text": data["text"] ?? "",
//                 "is_out": false,
//                 "time": data["date"] ?? DateTime.now().toString(),
//                 "type": mediaType ?? (data["text"]?.isNotEmpty == true ? "text" : null),
//                 "file_name": fileName,
//                 "url": fileUrl,
//                 "progress": 100.0,
//                 "uploading": false,
//               });
//               provider.notifyListeners();
//             }
//             return;
//           }
//
//           // --- our own send confirmations
//           if (data["status"] == "sent_file" ||
//               data["status"] == "sent_video" ||
//               data["status"] == "sent_voice" ||
//               data["status"] == "sent_text") {
//             // clear upload UI
//             setState(() {
//               _uploadProgress = 100.0;
//             });
//             if (_uploadingMsgIndex != null &&
//                 _uploadingMsgIndex! < provider.messages.length) {
//               provider.messages[_uploadingMsgIndex!]["uploading"] = false;
//               provider.messages[_uploadingMsgIndex!]["progress"] = 100.0;
//               provider.notifyListeners();
//               _uploadingMsgIndex = null;
//             }
//             return;
//           }
//
//           if ((data["status"] ?? "").toString().contains("error")) {
//             debugPrint("❌ WS Error: ${data["detail"]}");
//           }
//         } catch (e) {
//           debugPrint("⚠️ WS decode error: $e");
//         }
//       }, onDone: () {
//         debugPrint("⚠️ WS closed. Reconnect in 3s...");
//         Future.delayed(const Duration(seconds: 3), _connectWebSocket);
//       }, onError: (err) {
//         debugPrint("❌ WS error: $err");
//         Future.delayed(const Duration(seconds: 5), _connectWebSocket);
//       });
//     } catch (e) {
//       debugPrint("❌ WS connect fail: $e");
//       Future.delayed(const Duration(seconds: 5), _connectWebSocket);
//     }
//   }
//
//   // ================================
//   // 📨 Load old messages
//   // ================================
//   Future<void> _fetchAndLoad() async {
//     final provider = Provider.of<TelegraphProvider>(context, listen: false);
//     await provider.fetchMessages(widget.phone, widget.chatId, widget.accessHash);
//     setState(() => _loading = false);
//   }
//
//   // ================================
//   // ✉️ Send text (with optional reply)
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
//       "phone": widget.phone,
//       "chat_id": widget.chatId,
//       "access_hash": widget.accessHash,
//       "text": text,
//     };
//     if (_replyToMsg != null && _replyToMsg!["id"] != null) {
//       payload["reply_to"] = _replyToMsg!["id"];
//     }
//
//     try {
//       if (_socket?.readyState == WebSocket.open) {
//         _socket!.add(jsonEncode(payload));
//       } else {
//         // HTTP fallback
//         final url = Uri.parse("$urlLocal/send");
//         await http.post(url, body: {
//           "phone": widget.phone,
//           "to": widget.username,
//           "text": text,
//         });
//       }
//
//       provider.messages.insert(0, {
//         "text": text,
//         "is_out": true,
//         "time": DateTime.now().toString(),
//         "type": "text",
//         "uploading": false,
//         "progress": 100.0,
//       });
//       provider.notifyListeners();
//       _msgCtrl.clear();
//       setState(() => _replyToMsg = null);
//     } catch (e) {
//       debugPrint("⚠️ send text error: $e");
//     } finally {
//       setState(() => _sending = false);
//     }
//   }
//
//   // ================================
//   // 📤 Send file (image / video / audio)
//   // ================================
//   Future<void> _sendFile(File file, {String? caption}) async {
//     try {
//       final bytes = await file.readAsBytes();
//       final b64 = base64Encode(bytes);
//       final fileName = p.basename(file.path);
//       final mime = lookupMimeType(file.path) ?? "application/octet-stream";
//
//       final isImage = mime.startsWith('image/');
//       final isVideo = mime.startsWith('video/');
//       final isAudio = mime.startsWith('audio/');
//
//       final provider = Provider.of<TelegraphProvider>(context, listen: false);
//
//       // show immediately in list with local preview + 0% progress
//       provider.messages.insert(0, {
//         "text": caption ?? "",
//         "is_out": true,
//         "time": DateTime.now().toString(),
//         "type": isImage ? "image" : (isVideo ? "video" : (isAudio ? "audio" : "file")),
//         "local_path": file.path,
//         "file_name": fileName,
//         "mime": mime,
//         "uploading": true,
//         "progress": 0.0,
//       });
//       provider.notifyListeners();
//       _uploadingMsgIndex = 0; // just inserted at 0
//       setState(() {
//         _uploadProgress = 0.0;
//       });
//
//       final payload = {
//         "action": "send",
//         "phone": widget.phone,
//         "chat_id": widget.chatId,
//         "access_hash": widget.accessHash,
//         "file_name": fileName,
//         "file_base64": b64,
//         "mime_type": mime,
//         "text": caption ?? "",
//       };
//       if (_replyToMsg != null && _replyToMsg!["id"] != null) {
//         payload["reply_to"] = _replyToMsg!["id"];
//       }
//
//       if (_socket?.readyState == WebSocket.open) {
//         _socket!.add(jsonEncode(payload));
//       } else {
//         // চাইলে এখানে HTTP /upload fallback রাখতে পারো
//         debugPrint("WS not open; file not sent.");
//       }
//     } catch (e) {
//       debugPrint("⚠️ send file error: $e");
//     }
//   }
//
//   // ================================
//   // Typing events
//   // ================================
//   void _typingStart() {
//     if (_socket?.readyState == WebSocket.open) {
//       _socket!.add(jsonEncode({"action": "typing_start"}));
//     }
//   }
//
//   void _typingStop() {
//     if (_socket?.readyState == WebSocket.open) {
//       _socket!.add(jsonEncode({"action": "typing_stop"}));
//     }
//   }
//
//   // ================================
//   // File pickers
//   // ================================
//   Future<void> _ensurePerms() async {
//     await [Permission.camera, Permission.photos, Permission.storage].request();
//   }
//
//   Future<void> _pickImages() async {
//     await _ensurePerms();
//     final imgs = await _picker.pickMultiImage(imageQuality: 80);
//     for (final img in imgs) {
//       await _sendFile(File(img.path));
//     }
//   }
//
//   Future<void> _pickVideo() async {
//     await _ensurePerms();
//     final vid = await _picker.pickVideo(source: ImageSource.gallery);
//     if (vid != null) {
//       await _sendFile(File(vid.path));
//     }
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
//               _pickImages();
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
//   // ================================
//   // UI helpers
//   // ================================
//   Widget _bubbleContent(Map<String, dynamic> msg, bool isOut) {
//     final type = (msg["type"] ?? "text").toString();
//     final text = msg["text"] ?? "";
//     final localPath = msg["local_path"];
//     final url = msg["url"];
//     final fileName = msg["file_name"];
//
//     // Image
//     if (type == "image") {
//       final w = 220.0;
//       final h = 260.0;
//       return Column(
//         crossAxisAlignment: CrossAxisAlignment.end,
//         children: [
//           ClipRRect(
//             borderRadius: BorderRadius.circular(10),
//             child: localPath != null
//                 ? Image.file(File(localPath), width: w, height: h, fit: BoxFit.cover)
//                 : (url != null
//                 ? Image.network(url, width: w, height: h, fit: BoxFit.cover)
//                 : Container(
//               width: w,
//               height: h,
//               color: Colors.black12,
//               child: const Icon(Icons.image, size: 48),
//             )),
//           ),
//           if (text.toString().isNotEmpty)
//             Padding(
//               padding: const EdgeInsets.only(top: 6),
//               child: Text(
//                 text,
//                 style: TextStyle(color: isOut ? Colors.white : Colors.black87),
//               ),
//             ),
//         ],
//       );
//     }
//
//     // Video
//     if (type == "video") {
//       return Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             width: 240,
//             height: 150,
//             decoration: BoxDecoration(
//               color: Colors.black12,
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Stack(
//               alignment: Alignment.center,
//               children: [
//                 if (localPath != null)
//                   const Icon(Icons.videocam, size: 48, color: Colors.black45)
//                 else if (url != null)
//                   const Icon(Icons.videocam, size: 48, color: Colors.black45)
//                 else
//                   const Icon(Icons.videocam_off, size: 48, color: Colors.black45),
//                 const Positioned(
//                   bottom: 8,
//                   child: Text("Video", style: TextStyle(color: Colors.black54)),
//                 ),
//               ],
//             ),
//           ),
//           if ((fileName ?? "").toString().isNotEmpty)
//             Padding(
//               padding: const EdgeInsets.only(top: 4),
//               child: Text(fileName, style: TextStyle(color: isOut ? Colors.white70 : Colors.black54, fontSize: 12)),
//             ),
//           if (text.toString().isNotEmpty)
//             Padding(
//               padding: const EdgeInsets.only(top: 4),
//               child: Text(text, style: TextStyle(color: isOut ? Colors.white : Colors.black87)),
//             ),
//         ],
//       );
//     }
//
//     // Audio / File (simple row)
//     if (type == "audio" || type == "file") {
//       return Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(type == "audio" ? Icons.audiotrack : Icons.insert_drive_file,
//               color: isOut ? Colors.white : Colors.black54),
//           const SizedBox(width: 8),
//           Text(fileName ?? 'file', style: TextStyle(color: isOut ? Colors.white : Colors.black87)),
//         ],
//       );
//     }
//
//     // Text
//     return Text(
//       text,
//       style: TextStyle(color: isOut ? Colors.white : Colors.black87, fontSize: 15),
//     );
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
//           const CircleAvatar(
//             backgroundColor: Colors.white,
//             child: Icon(Icons.person, color: Colors.black),
//           ),
//           const SizedBox(width: 10),
//           Text(widget.name, style: const TextStyle(color: Colors.white, fontSize: 18)),
//           if (_typing)
//             const Padding(
//               padding: EdgeInsets.only(left: 8),
//               child: Text("typing...", style: TextStyle(color: Colors.white70, fontSize: 12)),
//             ),
//         ]),
//       ),
//       body: _loading
//           ? const Center(child: CircularProgressIndicator())
//           : Column(children: [
//         // reply banner (optional)
//         if (_replyToMsg != null)
//           Container(
//             color: Colors.teal.shade100,
//             padding: const EdgeInsets.all(8),
//             child: Row(children: [
//               Expanded(
//                 child: Text("↩️ Replying: ${_replyToMsg!["text"] ?? ""}",
//                     maxLines: 1, overflow: TextOverflow.ellipsis),
//               ),
//               IconButton(
//                 icon: const Icon(Icons.close),
//                 onPressed: () => setState(() => _replyToMsg = null),
//               )
//             ]),
//           ),
//
//         // 🔄 upload progress bar
//         if (_uploadProgress > 0 && _uploadProgress < 100)
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: LinearProgressIndicator(value: _uploadProgress / 100.0),
//                 ),
//                 const SizedBox(width: 10),
//                 Text("${_uploadProgress.toStringAsFixed(0)}%"),
//               ],
//             ),
//           ),
//
//         // messages list
//         Expanded(
//           child: ListView.builder(
//             controller: _scrollController,
//             reverse: true,
//             itemCount: provider.messages.length,
//             itemBuilder: (context, i) {
//               final msg = provider.messages[i];
//               final isOut = msg["is_out"] == true;
//               final time = msg["time"] ?? "";
//               final uploading = msg["uploading"] == true;
//               final progress = (msg["progress"] ?? 100.0).toDouble();
//
//               return GestureDetector(
//                 onLongPress: () => setState(() => _replyToMsg = msg), // enable reply
//                 child: Align(
//                   alignment: isOut ? Alignment.centerRight : Alignment.centerLeft,
//                   child: Container(
//                     margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
//                     padding: const EdgeInsets.all(10),
//                     decoration: BoxDecoration(
//                       color: isOut ? Colors.green.shade400 : Colors.grey.shade300,
//                       borderRadius: BorderRadius.only(
//                         topLeft: const Radius.circular(14),
//                         topRight: const Radius.circular(14),
//                         bottomLeft: isOut ? const Radius.circular(14) : const Radius.circular(0),
//                         bottomRight: isOut ? const Radius.circular(0) : const Radius.circular(14),
//                       ),
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.end,
//                       children: [
//                         _bubbleContent(msg, isOut),
//
//                         if (uploading)
//                           Padding(
//                             padding: const EdgeInsets.only(top: 6),
//                             child: SizedBox(
//                               width: 160,
//                               child: Row(
//                                 children: [
//                                   Expanded(
//                                     child: LinearProgressIndicator(value: progress / 100.0),
//                                   ),
//                                   const SizedBox(width: 8),
//                                   Text("${progress.toStringAsFixed(0)}%",
//                                       style: TextStyle(
//                                         color: isOut ? Colors.white70 : Colors.black54,
//                                         fontSize: 11,
//                                       )),
//                                 ],
//                               ),
//                             ),
//                           ),
//
//                         Padding(
//                           padding: const EdgeInsets.only(top: 6),
//                           child: Text(
//                             time,
//                             style: TextStyle(
//                               color: isOut ? Colors.white70 : Colors.grey[700],
//                               fontSize: 11,
//                             ),
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
//
//         // input row
//         Container(
//           color: Colors.white,
//           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//           child: Row(children: [
//             IconButton(
//               icon: const Icon(Icons.add, color: Colors.green),
//               onPressed: _showAttachmentMenu,
//             ),
//             Expanded(
//               child: TextField(
//                 controller: _msgCtrl,
//                 decoration: const InputDecoration(hintText: "Message", border: InputBorder.none),
//                 onChanged: (_) => _typingStart(),
//                 onEditingComplete: _typingStop,
//               ),
//             ),
//             _sending
//                 ? const Padding(
//               padding: EdgeInsets.all(8.0),
//               child: CircularProgressIndicator(strokeWidth: 2),
//             )
//                 : IconButton(
//               icon: const Icon(Icons.send, color: Colors.green),
//               onPressed: _sendText,
//             ),
//           ]),
//         ),
//       ]),
//     );
//   }
// }
//
//


import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../providers/telegraph_qg_provider.dart';

class ChatScreen extends StatefulWidget {
  final String phone;
  final int chatId;
  final int accessHash;
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
  // ==== CONFIG ====
  static const String _wsUrl = 'ws://192.168.0.247:8080/chat_ws';
  static const String _apiBase = 'http://192.168.0.247:8080'; // <- change if needed
  static const Duration _wsPingEvery = Duration(seconds: 20);

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _msgCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  WebSocket? _socket;

  bool _loading = true;
  bool _sending = false;
  bool _typing = false;
  int? _uploadingMsgIndex;

  // WS helpers
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  final Set<String> _seenIds = {}; // for de-dupe (server IDs or temp ids)
  final String _clientInstance = DateTime.now().millisecondsSinceEpoch.toString();

  @override
  void initState() {
    super.initState();
    _fetchAndLoad();
    _connectWebSocket();
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _socket?.close();
    super.dispose();
  }

  // ================================
  // 🔌 WebSocket Connect (self-healing)
  // ================================
  Future<void> _connectWebSocket() async {
    try {
      _reconnectTimer?.cancel();
      _socket = await WebSocket.connect(_wsUrl);
      _reconnectAttempt = 0;
      debugPrint("✅ WS Connected");

      // Init frame (server expects this as first message)
      _socket!.add(jsonEncode({
        "phone": widget.phone,
        "chat_id": widget.chatId,
        "access_hash": widget.accessHash,
      }));

      // Start server ping (keep-alive)
      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(_wsPingEvery, (_) {
        if (_socket?.readyState == WebSocket.open) {
          _socket!.add(jsonEncode({"action": "ping"}));
        }
      });

      _socket!.listen(
            (raw) => _handleWsFrame(raw),
        onDone: _scheduleReconnect,
        onError: (err) {
          debugPrint("⚠️ WS error: $err");
          _scheduleReconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint("⚠️ WS connect failed: $e");
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect([_]) {
    _pingTimer?.cancel();
    _reconnectAttempt++;
    final delay = Duration(seconds: _reconnectBackoffSeconds(_reconnectAttempt));
    debugPrint("↩️ Reconnect in ${delay.inSeconds}s (attempt $_reconnectAttempt)");
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, _connectWebSocket);
  }

  int _reconnectBackoffSeconds(int n) {
    final v = 1 << (n.clamp(0, 5)); // 1,2,4,8,16,32
    return v > 30 ? 30 : v;
  }

  // ================================
  // 📨 Handle WS frames
  // ================================
  void _handleWsFrame(String raw) {
    if (!mounted) return;
    final provider = Provider.of<TelegraphProvider>(context, listen: false);

    try {
      final data = jsonDecode(raw);

      // Heartbeat or pong
      if (data["action"] == "_hb" || data["status"] == "pong") return;

      // Typing events
      if (data["action"] == "typing") {
        setState(() => _typing = true);
        return;
      }
      if (data["action"] == "typing_stopped") {
        setState(() => _typing = false);
        return;
      }

      // Upload progress for our last uploading bubble
      if (data["action"] == "upload_progress") {
        if (_uploadingMsgIndex != null &&
            _uploadingMsgIndex! < provider.messages.length) {
          provider.messages[_uploadingMsgIndex!]["progress"] = data["progress"];
          provider.notifyListeners();
        }
        return;
      }

      // Listener ack
      if (data["status"] == "listening") return;

      // SEED: initial messages pushed by server
      if (data["action"] == "seed" && data["messages"] is List) {
        final List<dynamic> arr = data["messages"];
        // server sends oldest → newest. Our ListView is reverse:true (newest at top),
        // so we'll add from last to first to keep newest at index 0.
        for (int i = arr.length - 1; i >= 0; i--) {
          final mapped = _mapServerMessage(arr[i]);
          if (mapped == null) continue;
          final id = mapped["id"]?.toString();
          if (id != null && _seenIds.contains(id)) continue;
          if (id != null) _seenIds.add(id);
          provider.messages.insert(0, mapped);
        }
        provider.notifyListeners();
        return;
      }

      // PRIMARY MESSAGE (new_message OR generic with id)
      if (data["action"] == "new_message" || data.containsKey("id")) {
        final mapped = _mapServerMessage(data);
        if (mapped == null) return;

        final id = mapped["id"]?.toString();
        // de-dupe: if we already have same server id, skip
        if (id != null && _seenIds.contains(id)) return;
        if (id != null) _seenIds.add(id);

        // If it's our own pending text/file (no id), replace first pending bubble by text match
        final isOut = mapped["is_out"] == true;
        if (isOut) {
          final idx = provider.messages.indexWhere((m) {
            final bool pending = (m["pending"] == true) && (m["is_out"] == true);
            final sameText = (m["text"] ?? "") == (mapped["text"] ?? "");
            return pending && sameText;
          });
          if (idx != -1) {
            provider.messages[idx] = mapped;
            provider.notifyListeners();
            return;
          }
        }

        provider.messages.insert(0, mapped);
        provider.notifyListeners();
        return;
      }

      // (Older path) Explicit call_event
      if (data["action"] == "call_event") {
        final mapped = _mapCallEvent(data);
        if (mapped == null) return;
        final id = mapped["id"]?.toString();
        if (id != null && _seenIds.contains(id)) return;
        if (id != null) _seenIds.add(id);
        provider.messages.insert(0, mapped);
        provider.notifyListeners();
        return;
      }
    } catch (e) {
      debugPrint("⚠️ WS parse error: $e");
    }
  }

  // ================================
  // 📨 Load messages (initial REST)
  // ================================
  Future<void> _fetchAndLoad() async {
    final provider = Provider.of<TelegraphProvider>(context, listen: false);
    await provider.fetchMessages(widget.phone, widget.chatId, widget.accessHash);
    // Provider-এর fetch যদি already normalize না করে থাকে, চাইলে এখানে normalize করতে পারেন।
    // ধরি আপনার provider আগের মতোই ঠিক ঢুকিয়ে দিচ্ছে।
    setState(() => _loading = false);
  }

  // ================================
  // ✉️ Send text
  // ================================
  Future<void> _sendText() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    final provider = Provider.of<TelegraphProvider>(context, listen: false);

    final payload = {
      "action": "send",
      "text": text,
      // সার্ভারের নতুন /chat_ws এ init-এ phone/chat_id/ah দেওয়া থাকে, "send"-এ আবার দিতে হয় না।
      // কিন্তু backward compatible রাখলাম:
      "phone": widget.phone,
      "chat_id": widget.chatId,
      "access_hash": widget.accessHash,
      "client_instance": _clientInstance,
    };

    try {
      // optimistic pending bubble
      provider.messages.insert(0, {
        "id": "pending:${DateTime.now().microsecondsSinceEpoch}",
        "text": text,
        "is_out": true,
        "time": DateTime.now().toIso8601String(),
        "type": "text",
        "pending": true,
      });
      _seenIds.add(provider.messages.first["id"].toString());
      provider.notifyListeners();

      _socket?.add(jsonEncode(payload));
      _msgCtrl.clear();
    } catch (e) {
      debugPrint("⚠️ send text error: $e");
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // ================================
  // Typing events
  // ================================
  Timer? _typingDebounce;
  void _typingStart() {
    _typingDebounce?.cancel();
    if (_socket?.readyState == WebSocket.open) {
      _socket!.add(jsonEncode({"action": "typing_start"}));
    }
    // stop typing if idle 2s
    _typingDebounce = Timer(const Duration(seconds: 2), _typingStop);
  }

  void _typingStop() {
    if (_socket?.readyState == WebSocket.open) {
      _socket!.add(jsonEncode({"action": "typing_stop"}));
    }
  }

  // ================================
  // Picker & Send File
  // ================================
  Future<void> _ensurePerms() async {
    await [Permission.camera, Permission.photos, Permission.storage].request();
  }

  Future<void> _pickImage() async {
    await _ensurePerms();
    final img = await _picker.pickImage(source: ImageSource.gallery);
    if (img != null) await _sendFile(File(img.path));
  }

  Future<void> _pickVideo() async {
    await _ensurePerms();
    final vid = await _picker.pickVideo(source: ImageSource.gallery);
    if (vid != null) await _sendFile(File(vid.path));
  }

  Future<void> _sendFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final b64 = base64Encode(bytes);
      final fileName = p.basename(file.path);
      final mime = lookupMimeType(file.path) ?? "application/octet-stream";

      final provider = Provider.of<TelegraphProvider>(context, listen: false);
      provider.messages.insert(0, {
        "id": "pending:${DateTime.now().microsecondsSinceEpoch}",
        "text": "",
        "is_out": true,
        "time": DateTime.now().toIso8601String(),
        "type": mime.startsWith('image/') ? "image" : (mime.startsWith('video/') ? "video" : "file"),
        "local_path": file.path,
        "uploading": true,
        "progress": 0.0,
        "pending": true,
      });
      _uploadingMsgIndex = 0;
      _seenIds.add(provider.messages.first["id"].toString());
      provider.notifyListeners();

      _socket?.add(jsonEncode({
        "action": "send",
        "file_name": fileName,
        "file_base64": b64,
        "mime_type": mime,
        // b/c older server versions used these in send:
        "phone": widget.phone,
        "chat_id": widget.chatId,
        "access_hash": widget.accessHash,
        "client_instance": _clientInstance,
      }));
    } catch (e) {
      debugPrint("⚠️ send file error: $e");
    }
  }

  // ================================
  // Mapping helpers
  // ================================
  Map<String, dynamic>? _mapServerMessage(dynamic data) {
    if (data == null) return null;

    final id = data["id"] ?? data["msg_id"] ?? data["temp_id"];
    final text = (data["text"] ?? "") as String;
    final isOut = data["is_out"] == true || (data["direction"]?.toString() == "out");
    final date = (data["date"] ?? DateTime.now().toIso8601String()).toString();
    final mediaType = (data["media_type"] ?? data["type"] ?? "text").toString();
    final mediaLink = data["media_link"];

    if (mediaType == "call_audio" || mediaType == "call_video") {
      final call = data["call"] ?? {};
      return {
        "id": id?.toString(),
        "text": _formatCallTitle(call, mediaType),
        "is_out": isOut,
        "time": date,
        "type": "call",
        "call_status": call["status"],
        "duration": call["duration"],
        "direction": call["direction"], // incoming/outgoing
      };
    }

    // Normal text/file/image/video
    return {
      "id": id?.toString(),
      "text": text,
      "is_out": isOut,
      "time": date,
      "type": _normalizeType(mediaType),
      "url": _resolveUrl(mediaLink),
      "pending": false,
    };
  }

  Map<String, dynamic>? _mapCallEvent(dynamic data) {
    final id = data["id"];
    final status = data["status"];
    final direction = data["direction"];
    final duration = data["duration"];
    final isVideo = data["is_video"] == true;
    final date = (data["date"] ?? DateTime.now().toIso8601String()).toString();

    return {
      "id": id?.toString(),
      "text": isVideo ? "Video call" : "Voice call",
      "is_out": (direction == "outgoing"),
      "time": date,
      "type": "call",
      "call_status": status,
      "duration": duration,
      "direction": direction,
    };
  }

  String _normalizeType(String t) {
    switch (t) {
      case "image":
      case "video":
      case "audio":
      case "voice":
      case "sticker":
      case "file":
        return t;
      default:
        return "text";
    }
  }

  String? _resolveUrl(dynamic url) {
    if (url == null) return null;
    final u = url.toString();
    if (u.startsWith('http://') || u.startsWith('https://')) return u;
    if (u.startsWith('/')) return '$_apiBase$u';
    return '$_apiBase/$u';
  }

  String _formatCallTitle(Map call, String mediaType) {
    final status = (call["status"] ?? "").toString();
    final dur = call["duration"];
    final sec = (dur is num) ? dur.toInt() : null;
    final dir = (call["direction"] ?? "").toString(); // incoming/outgoing
    final t = mediaType == "call_video" ? "Video call" : "Voice call";
    final sd = (sec != null && sec > 0) ? " • ${_fmtDur(sec)}" : "";
    final d = dir.isNotEmpty ? (dir == "incoming" ? "Incoming" : "Outgoing") : "";
    return "$t • $status${sd}${d.isNotEmpty ? " • $d" : ""}";
    // Example: "Voice call • ended • 00:02:31 • Outgoing"
  }

  String _fmtDur(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    if (h > 0) {
      return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
    }
    return "${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
  }

  // ================================
  // Message Bubble
  // ================================

  //
  // Widget _bubbleContent(Map<String, dynamic> msg, bool isOut) {
  //   final type = (msg["type"] ?? "text") as String;
  //   final text = (msg["text"] ?? "") as String;
  //   final bool isDeleted = msg["is_deleted"] == true;
  //
  //   // 🔴 deleted হলে টেক্সট লাল, না হলে আগের মতো
  //   final textColor = isDeleted
  //       ? Colors.red
  //       : (isOut ? Colors.white : Colors.black87);
  //
  //   // 📞 CALL MESSAGE
  //   if (type == "call") {
  //     final status = msg["call_status"]?.toString() ?? "";
  //     final direction = msg["direction"]?.toString() ?? "";
  //     IconData icon;
  //     Color color;
  //
  //     if (status == "missed") {
  //       icon = Icons.call_missed;
  //       color = Colors.red;
  //     } else if (status == "ended") {
  //       icon = Icons.call_end;
  //       color = Colors.green;
  //     } else if (status == "busy") {
  //       icon = Icons.call_end;
  //       color = Colors.orange;
  //     } else {
  //       icon = Icons.phone;
  //       color = Colors.blueGrey;
  //     }
  //
  //     return Row(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         Icon(icon, color: color, size: 20),
  //         const SizedBox(width: 6),
  //         Flexible(
  //           child: Text(
  //             "$text (${direction == "incoming" ? "Incoming" : "Outgoing"})",
  //             style: TextStyle(
  //               color: textColor,
  //               fontWeight: FontWeight.w600,
  //             ),
  //           ),
  //         ),
  //       ],
  //     );
  //   }
  //
  //   // 🖼️ IMAGE
  //   if (type == "image") {
  //     final localPath = msg["local_path"];
  //     final url = msg["url"];
  //     const w = 220.0, h = 260.0;
  //
  //     Widget imageChild;
  //     if (localPath != null) {
  //       imageChild =
  //           Image.file(File(localPath), width: w, height: h, fit: BoxFit.cover);
  //     } else if (url != null) {
  //       imageChild = Image.network(_resolveUrl(url)!,
  //           width: w, height: h, fit: BoxFit.cover);
  //     } else {
  //       imageChild = Container(
  //         width: w,
  //         height: h,
  //         color: Colors.grey,
  //         child: const Icon(Icons.image),
  //       );
  //     }
  //
  //     return ClipRRect(
  //         borderRadius: BorderRadius.circular(10), child: imageChild);
  //   }
  //
  //   // 🎥 VIDEO
  //   if (type == "video") {
  //     return Row(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         const Icon(Icons.videocam),
  //         const SizedBox(width: 8),
  //         Text("Video", style: TextStyle(color: textColor)),
  //       ],
  //     );
  //   }
  //
  //   // 🎧 AUDIO
  //   if (type == "audio" || type == "voice") {
  //     return Row(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         const Icon(Icons.audiotrack),
  //         const SizedBox(width: 8),
  //         Text(
  //           type == "voice" ? "Voice message" : "Audio",
  //           style: TextStyle(color: textColor),
  //         ),
  //       ],
  //     );
  //   }
  //
  //   // 📝 Normal Text
  //   return Text(
  //     text,
  //     style: TextStyle(
  //       color: textColor,
  //       fontSize: 15,
  //       fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
  //       fontWeight: isDeleted ? FontWeight.bold : FontWeight.normal,
  //     ),
  //   );
  // }



  Widget _bubbleContent(Map<String, dynamic> msg, bool isOut) {
    final type = (msg["type"] ?? "text") as String;
    final text = (msg["text"] ?? "") as String;
    final bool isDeleted = msg["is_deleted"] == true;

    // 🔴 deleted হলে টেক্সট লাল, না হলে আগের মতো
    final textColor =
    isDeleted ? Colors.red : (isOut ? Colors.white : Colors.black87);

    // ==========================================
    // 📞 CALL MESSAGE
    // ==========================================
    if (type == "call" || type == "call_audio" || type == "call_video") {
      final status = msg["call_status"]?.toString() ?? "";
      final direction = msg["direction"]?.toString() ?? "";
      final bool isVideo = type == "call_video";

      IconData icon;
      Color iconColor;
      String label;

      if (status == "missed") {
        icon = isVideo ? Icons.videocam_off : Icons.call_missed;
        iconColor = Colors.redAccent;
        label = isVideo ? "Missed Video Call" : "Missed Voice Call";
      } else if (status == "ended") {
        icon = isVideo ? Icons.videocam : Icons.call_end;
        iconColor = Colors.green;
        label = isVideo ? "Video Call Ended" : "Voice Call Ended";
      } else if (status == "busy") {
        icon = isVideo ? Icons.videocam : Icons.call_end;
        iconColor = Colors.orange;
        label = isVideo ? "Video Call Busy" : "Voice Call Busy";
      } else {
        icon = isVideo ? Icons.videocam : Icons.phone;
        iconColor = Colors.blueGrey;
        label = isVideo ? "Video Call" : "Voice Call";
      }

      // 🎨 Make nice row design
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isOut ? Colors.white.withOpacity(0.1) : Colors.black12,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                "$label (${direction == "incoming" ? "Incoming" : "Outgoing"})",
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontStyle:
                  isDeleted ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ==========================================
    // 🖼️ IMAGE
    // ==========================================
    if (type == "image") {
      final localPath = msg["local_path"];
      final url = msg["url"];
      const w = 220.0, h = 260.0;

      Widget imageChild;
      if (localPath != null) {
        imageChild = Image.file(File(localPath),
            width: w, height: h, fit: BoxFit.cover);
      } else if (url != null) {
        imageChild = Image.network(
          _resolveUrl(url)!,
          width: w,
          height: h,
          fit: BoxFit.cover,
        );
      } else {
        imageChild = Container(
          width: w,
          height: h,
          color: Colors.grey,
          child: const Icon(Icons.image),
        );
      }

      return ClipRRect(
          borderRadius: BorderRadius.circular(10), child: imageChild);
    }

    // ==========================================
    // 🎥 VIDEO
    // ==========================================
    if (type == "video") {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.videocam, color: Colors.blue),
          const SizedBox(width: 8),
          Text("Video", style: TextStyle(color: textColor)),
        ],
      );
    }

    // ==========================================
    // 🎧 AUDIO
    // ==========================================
    if (type == "audio" || type == "voice") {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.audiotrack, color: Colors.orangeAccent),
          const SizedBox(width: 8),
          Text(
            type == "voice" ? "Voice message" : "Audio",
            style: TextStyle(color: textColor),
          ),
        ],
      );
    }

    // ==========================================
    // 📝 Normal Text
    // ==========================================
    return Text(
      text,
      style: TextStyle(
        color: textColor,
        fontSize: 15,
        fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
        fontWeight: isDeleted ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }



  // Widget _bubbleContent(Map<String, dynamic> msg, bool isOut) {
  //   final type = (msg["type"] ?? "text") as String;
  //   final text = (msg["text"] ?? "") as String;
  //
  //   if (type == "call") {
  //     final status = msg["call_status"]?.toString() ?? "";
  //     final direction = msg["direction"]?.toString() ?? "";
  //     IconData icon;
  //     Color color;
  //
  //     if (status == "missed") {
  //       icon = Icons.call_missed;
  //       color = Colors.red;
  //     } else if (status == "ended") {
  //       icon = Icons.call_end;
  //       color = Colors.green;
  //     } else if (status == "busy") {
  //       icon = Icons.call_end;
  //       color = Colors.orange;
  //     } else {
  //       icon = Icons.phone;
  //       color = Colors.blueGrey;
  //     }
  //
  //     return Row(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         Icon(icon, color: color, size: 20),
  //         const SizedBox(width: 6),
  //         Flexible(
  //           child: Text(
  //             "$text (${direction == "incoming" ? "Incoming" : "Outgoing"})",
  //             style: TextStyle(
  //               color: isOut ? Colors.white : Colors.black87,
  //               fontWeight: FontWeight.w600,
  //             ),
  //           ),
  //         ),
  //       ],
  //     );
  //   }
  //
  //   if (type == "image") {
  //     final localPath = msg["local_path"];
  //     final url = msg["url"];
  //     const w = 220.0, h = 260.0;
  //     final uploading = msg["uploading"] == true;
  //     final progress = (msg["progress"] ?? 0.0) as num;
  //
  //     Widget imageChild;
  //     if (localPath != null) {
  //       imageChild = Image.file(File(localPath), width: w, height: h, fit: BoxFit.cover);
  //     } else if (url != null) {
  //       imageChild = Image.network(_resolveUrl(url)!, width: w, height: h, fit: BoxFit.cover);
  //     } else {
  //       imageChild = Container(width: w, height: h, color: Colors.grey, child: const Icon(Icons.image));
  //     }
  //
  //     return Stack(
  //       children: [
  //         ClipRRect(borderRadius: BorderRadius.circular(10), child: imageChild),
  //         if (uploading)
  //           Positioned.fill(
  //             child: Container(
  //               alignment: Alignment.bottomCenter,
  //               decoration: BoxDecoration(
  //                 color: Colors.black.withOpacity(0.1),
  //                 borderRadius: BorderRadius.circular(10),
  //               ),
  //               child: Padding(
  //                 padding: const EdgeInsets.all(8.0),
  //                 child: LinearProgressIndicator(
  //                   value: progress.clamp(0, 100) / 100.0,
  //                   minHeight: 5,
  //                 ),
  //               ),
  //             ),
  //           ),
  //       ],
  //     );
  //   }
  //
  //   if (type == "video") {
  //     return Row(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         const Icon(Icons.videocam),
  //         const SizedBox(width: 8),
  //         Text("Video", style: TextStyle(color: isOut ? Colors.white : Colors.black87)),
  //       ],
  //     );
  //   }
  //
  //   if (type == "audio" || type == "voice") {
  //     return Row(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         const Icon(Icons.audiotrack),
  //         const SizedBox(width: 8),
  //         Text(type == "voice" ? "Voice message" : "Audio",
  //             style: TextStyle(color: isOut ? Colors.white : Colors.black87)),
  //       ],
  //     );
  //   }
  //
  //   // text / file / sticker (basic)
  //   return Text(text, style: TextStyle(color: isOut ? Colors.white : Colors.black87, fontSize: 15));
  // }

  // ================================
  // UI
  // ================================
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TelegraphProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFE5DDD5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF008069),
        title: Row(children: [
          const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, color: Colors.black)),
          const SizedBox(width: 10),
          Text(widget.name, style: const TextStyle(color: Colors.white, fontSize: 18)),
          if (_typing)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text("typing...", style: TextStyle(color: Colors.white70, fontSize: 12)),
            ),
        ]),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            reverse: true, // newest at top
            itemCount: provider.messages.length,
            itemBuilder: (context, i) {
              final msg = provider.messages[i];
              final isOut = msg["is_out"] == true;
              final time = (msg["time"] ?? "") as String;

              return Align(
                alignment: isOut ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isOut ? Colors.green.shade400 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _bubbleContent(msg, isOut),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          time,
                          style: TextStyle(color: isOut ? Colors.white70 : Colors.grey[700], fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(children: [
            IconButton(icon: const Icon(Icons.attach_file, color: Colors.green), onPressed: _showAttachmentMenu),
            Expanded(
              child: TextField(
                controller: _msgCtrl,
                onChanged: (v) => _typingStart(),
                onEditingComplete: _typingStop,
                decoration: const InputDecoration(hintText: "Type a message", border: InputBorder.none),
              ),
            ),
            IconButton(
              icon: _sending
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send, color: Colors.green),
              onPressed: _sending ? null : _sendText,
            ),
          ]),
        ),
      ]),
    );
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.photo, color: Colors.green),
            title: const Text("Send Image"),
            onTap: () {
              Navigator.pop(ctx);
              _pickImage();
            },
          ),
          ListTile(
            leading: const Icon(Icons.videocam, color: Colors.green),
            title: const Text("Send Video"),
            onTap: () {
              Navigator.pop(ctx);
              _pickVideo();
            },
          ),
        ]),
      ),
    );
  }
}


// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
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
//   final ScrollController _scrollController = ScrollController();
//   final TextEditingController _msgCtrl = TextEditingController();
//   final ImagePicker _picker = ImagePicker();
//   WebSocket? _socket;
//
//   bool _loading = true;
//   bool _sending = false;
//   bool _typing = false;
//   int? _uploadingMsgIndex;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchAndLoad();
//     _connectWebSocket();
//   }
//
//   @override
//   void dispose() {
//     _socket?.close();
//     super.dispose();
//   }
//
//   // ================================
//   // 🔌 WebSocket Connect
//   // ================================
//   Future<void> _connectWebSocket() async {
//     try {
//       _socket = await WebSocket.connect('ws://192.168.0.247:8080/chat_ws');
//       debugPrint("✅ WS Connected");
//
//       _socket!.add(jsonEncode({
//         "phone": widget.phone,
//         "chat_id": widget.chatId,
//         "access_hash": widget.accessHash,
//       }));
//
//       _socket!.listen((raw) {
//         if (!mounted) return;
//         final provider = Provider.of<TelegraphProvider>(context, listen: false);
//
//         try {
//           final data = jsonDecode(raw);
//
//           // Ignore heartbeat
//           if (data["action"] == "_hb") return;
//
//           // Typing events
//           if (data["action"] == "typing") {
//             setState(() => _typing = true);
//             return;
//           }
//           if (data["action"] == "typing_stopped") {
//             setState(() => _typing = false);
//             return;
//           }
//
//           // Upload progress
//           if (data["action"] == "upload_progress") {
//             if (_uploadingMsgIndex != null &&
//                 _uploadingMsgIndex! < provider.messages.length) {
//               provider.messages[_uploadingMsgIndex!]["progress"] = data["progress"];
//               provider.notifyListeners();
//             }
//             return;
//           }
//
//           // Status/listening
//           if (data["status"] == "listening") return;
//
//           // Primary message
//           if (data.containsKey("id")) {
//             final mediaType = data["media_type"] ?? "text";
//             provider.messages.insert(0, {
//               "id": data["id"],
//               "text": data["text"] ?? "",
//               "is_out": data["is_out"] ?? false,
//               "time": data["date"] ?? DateTime.now().toString(),
//               "type": mediaType,
//               "url": data["media_link"],
//             });
//             provider.notifyListeners();
//           }
//         } catch (e) {
//           debugPrint("⚠️ WS parse error: $e");
//         }
//       }, onDone: () {
//         Future.delayed(const Duration(seconds: 3), _connectWebSocket);
//       }, onError: (err) {
//         Future.delayed(const Duration(seconds: 5), _connectWebSocket);
//       });
//     } catch (e) {
//       Future.delayed(const Duration(seconds: 5), _connectWebSocket);
//     }
//   }
//
//   // ================================
//   // 📨 Load messages
//   // ================================
//   Future<void> _fetchAndLoad() async {
//     final provider = Provider.of<TelegraphProvider>(context, listen: false);
//     await provider.fetchMessages(widget.phone, widget.chatId, widget.accessHash);
//     setState(() => _loading = false);
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
//       "phone": widget.phone,
//       "chat_id": widget.chatId,
//       "access_hash": widget.accessHash,
//       "text": text,
//     };
//
//     try {
//       _socket?.add(jsonEncode(payload));
//       provider.messages.insert(0, {
//         "text": text,
//         "is_out": true,
//         "time": DateTime.now().toString(),
//         "type": "text",
//       });
//       provider.notifyListeners();
//       _msgCtrl.clear();
//     } catch (e) {
//       debugPrint("⚠️ send text error: $e");
//     } finally {
//       setState(() => _sending = false);
//     }
//   }
//
//   // ================================
//   // Typing events
//   // ================================
//   void _typingStart() {
//     if (_socket?.readyState == WebSocket.open) {
//       _socket!.add(jsonEncode({
//         "action": "typing_start",
//         "phone": widget.phone,
//         "chat_id": widget.chatId
//       }));
//     }
//   }
//
//   void _typingStop() {
//     if (_socket?.readyState == WebSocket.open) {
//       _socket!.add(jsonEncode({
//         "action": "typing_stop",
//         "phone": widget.phone,
//         "chat_id": widget.chatId
//       }));
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
//     final img = await _picker.pickImage(source: ImageSource.gallery);
//     if (img != null) await _sendFile(File(img.path));
//   }
//
//   Future<void> _pickVideo() async {
//     await _ensurePerms();
//     final vid = await _picker.pickVideo(source: ImageSource.gallery);
//     if (vid != null) await _sendFile(File(vid.path));
//   }
//
//   Future<void> _sendFile(File file) async {
//     try {
//       final bytes = await file.readAsBytes();
//       final b64 = base64Encode(bytes);
//       final fileName = p.basename(file.path);
//       final mime = lookupMimeType(file.path) ?? "application/octet-stream";
//
//       final provider = Provider.of<TelegraphProvider>(context, listen: false);
//       provider.messages.insert(0, {
//         "text": "",
//         "is_out": true,
//         "time": DateTime.now().toString(),
//         "type": mime.startsWith('image/') ? "image" : "file",
//         "local_path": file.path,
//         "uploading": true,
//         "progress": 0.0,
//       });
//       provider.notifyListeners();
//       _uploadingMsgIndex = 0;
//
//       _socket?.add(jsonEncode({
//         "action": "send",
//         "phone": widget.phone,
//         "chat_id": widget.chatId,
//         "access_hash": widget.accessHash,
//         "file_name": fileName,
//         "file_base64": b64,
//         "mime_type": mime,
//       }));
//     } catch (e) {
//       debugPrint("⚠️ send file error: $e");
//     }
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
//   // ================================
//   // Message Bubble
//   // ================================
//
//   Widget _bubbleContent(Map<String, dynamic> msg, bool isOut) {
//     final type = msg["type"] ?? "text";
//     final text = msg["text"] ?? "";
//
//     if (type == "call") {
//       final status = msg["call_status"] ?? "";
//       final direction = msg["direction"] ?? "";
//       IconData icon;
//       Color color;
//
//       if (status == "missed") {
//         icon = Icons.call_missed;
//         color = Colors.red;
//       } else if (status == "ended") {
//         icon = Icons.call_end;
//         color = Colors.green;
//       } else if (status == "busy") {
//         icon = Icons.call_end;
//         color = Colors.orange;
//       } else {
//         icon = Icons.phone;
//         color = Colors.blueGrey;
//       }
//
//       return Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, color: color, size: 20),
//           const SizedBox(width: 6),
//           Text(
//             "$text (${direction == "incoming" ? "Incoming" : "Outgoing"})",
//             style: TextStyle(
//               color: isOut ? Colors.white : Colors.black87,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ],
//       );
//     }
//
//     if (type == "image") {
//       final localPath = msg["local_path"];
//       final url = msg["url"];
//       final w = 220.0, h = 260.0;
//       return ClipRRect(
//         borderRadius: BorderRadius.circular(10),
//         child: localPath != null
//             ? Image.file(File(localPath), width: w, height: h, fit: BoxFit.cover)
//             : (url != null
//             ? Image.network(url, width: w, height: h, fit: BoxFit.cover)
//             : Container(
//           width: w,
//           height: h,
//           color: Colors.grey,
//           child: const Icon(Icons.image),
//         )),
//       );
//     }
//
//     return Text(
//       text,
//       style: TextStyle(color: isOut ? Colors.white : Colors.black87, fontSize: 15),
//     );
//   }
//   // Widget _bubbleContent(Map<String, dynamic> msg, bool isOut) {
//   //   final type = msg["type"] ?? "text";
//   //   final text = msg["text"] ?? "";
//   //
//   //   if (type == "image") {
//   //     final localPath = msg["local_path"];
//   //     final url = msg["url"];
//   //     return ClipRRect(
//   //       borderRadius: BorderRadius.circular(10),
//   //       child: localPath != null
//   //           ? Image.file(File(localPath), width: 220, height: 260, fit: BoxFit.cover)
//   //           : (url != null
//   //           ? Image.network(url, width: 220, height: 260, fit: BoxFit.cover)
//   //           : Container(width: 220, height: 260, color: Colors.grey, child: const Icon(Icons.image))),
//   //     );
//   //   }
//   //
//   //   return Text(
//   //     text,
//   //     style: TextStyle(color: isOut ? Colors.white : Colors.black87, fontSize: 15),
//   //   );
//   // }
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
//           const CircleAvatar(
//               backgroundColor: Colors.white,
//               child: Icon(Icons.person, color: Colors.black)),
//           const SizedBox(width: 10),
//           Text(widget.name, style: const TextStyle(color: Colors.white, fontSize: 18)),
//           if (_typing)
//             const Padding(
//               padding: EdgeInsets.only(left: 8),
//               child: Text("typing...", style: TextStyle(color: Colors.white70, fontSize: 12)),
//             ),
//         ]),
//       ),
//       body: _loading
//           ? const Center(child: CircularProgressIndicator())
//           : Column(children: [
//         Expanded(
//           child: ListView.builder(
//             controller: _scrollController,
//             reverse: true,
//             itemCount: provider.messages.length,
//             itemBuilder: (context, i) {
//               final msg = provider.messages[i];
//               final isOut = msg["is_out"] == true;
//               final time = msg["time"] ?? "";
//
//               return Align(
//                 alignment: isOut ? Alignment.centerRight : Alignment.centerLeft,
//                 child: Container(
//                   margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
//                   padding: const EdgeInsets.all(10),
//                   decoration: BoxDecoration(
//                     color: isOut ? Colors.green.shade400 : Colors.grey.shade300,
//                     borderRadius: BorderRadius.circular(14),
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.end,
//                     children: [
//                       _bubbleContent(msg, isOut),
//                       Padding(
//                         padding: const EdgeInsets.only(top: 4),
//                         child: Text(time,
//                             style: TextStyle(color: isOut ? Colors.white70 : Colors.grey[700], fontSize: 11)),
//                       ),
//                     ],
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
//             IconButton(
//               icon: const Icon(Icons.attach_file, color: Colors.green),
//               onPressed: _showAttachmentMenu,
//             ),
//             Expanded(
//               child: TextField(
//                 controller: _msgCtrl,
//                 onChanged: (v) => _typingStart(),
//                 onEditingComplete: _typingStop,
//                 decoration: const InputDecoration(
//                   hintText: "Type a message",
//                   border: InputBorder.none,
//                 ),
//               ),
//             ),
//             IconButton(
//               icon: _sending
//                   ? const CircularProgressIndicator()
//                   : const Icon(Icons.send, color: Colors.green),
//               onPressed: _sendText,
//             ),
//           ]),
//         ),
//       ]),
//     );
//   }
// }


