// // // import 'dart:convert';
// // // import 'dart:io';
// // // import 'package:ag_taligram/url.dart';
// // // import 'package:flutter/material.dart';
// // // import 'package:http/http.dart' as http;
// // // import 'package:image_picker/image_picker.dart';
// // // import 'package:permission_handler/permission_handler.dart';
// // // import 'package:provider/provider.dart';
// // // import '../providers/telegraph_qg_provider.dart';
// // //
// // // class ChatScreen extends StatefulWidget {
// // //   final String phone;
// // //   final int chatId;
// // //   final int accessHash;
// // //   final String name;
// // //   final String username;
// // //
// // //   const ChatScreen({
// // //     super.key,
// // //     required this.phone,
// // //     required this.chatId,
// // //     required this.accessHash,
// // //     required this.name,
// // //     required this.username,
// // //   });
// // //
// // //   @override
// // //   State<ChatScreen> createState() => _ChatScreenState();
// // // }
// // //
// // // class _ChatScreenState extends State<ChatScreen> {
// // //   final ScrollController _scrollController = ScrollController();
// // //   final TextEditingController _msgCtrl = TextEditingController();
// // //   final ImagePicker _picker = ImagePicker();
// // //
// // //   WebSocket? _socket;
// // //   bool _loading = true;
// // //   bool _sending = false;
// // //   List<File> _selectedImages = [];
// // //
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _fetchAndLoad(); // Load old messages
// // //     _connectWebSocket(); // Connect WS for real-time
// // //   }
// // //
// // //   @override
// // //   void dispose() {
// // //     _socket?.close();
// // //     super.dispose();
// // //   }
// // //
// // //   // ✅ Connect WebSocket
// // //   Future<void> _connectWebSocket() async {
// // //     try {
// // //       final wsUrl = 'ws://192.168.0.247:8080/chat_ws';
// // //       _socket = await WebSocket.connect(wsUrl);
// // //       print("✅ WebSocket Connected");
// // //
// // //       // 🔹 Send initialization (start listening for this chat)
// // //       final init = {
// // //         "phone": widget.phone,
// // //         "chat_id": widget.chatId,
// // //       };
// // //       _socket!.add(jsonEncode(init));
// // //
// // //       // 🔹 Listen for new messages
// // //       _socket!.listen((raw) {
// // //         try {
// // //           final decoded = jsonDecode(raw);
// // //           print("📩 WS RECEIVED → $decoded");
// // //
// // //           if (decoded["action"] == "new_message") {
// // //             // ✅ Incoming Telegram message
// // //             if (decoded["chat_id"].toString() ==
// // //                 widget.chatId.toString()) {
// // //               final provider =
// // //               Provider.of<TelegraphProvider>(context, listen: false);
// // //               provider.messages.insert(0, {
// // //                 "text": decoded["text"] ?? "",
// // //                 "is_out": false,
// // //                 "time": decoded["date"] ?? DateTime.now().toString(),
// // //               });
// // //               provider.notifyListeners();
// // //             }
// // //           } else if (decoded["status"] == "sent") {
// // //             print("✅ Message confirmed sent: ${decoded["text"]}");
// // //           } else if (decoded["status"] == "error") {
// // //             print("❌ WS Error: ${decoded["detail"]}");
// // //           }
// // //         } catch (e) {
// // //           print("⚠️ Decode error: $e");
// // //         }
// // //       }, onDone: () {
// // //         print("⚠️ WS closed. Reconnecting in 3s...");
// // //         Future.delayed(const Duration(seconds: 3), _connectWebSocket);
// // //       }, onError: (e) {
// // //         print("❌ WS error: $e");
// // //         Future.delayed(const Duration(seconds: 5), _connectWebSocket);
// // //       });
// // //     } catch (e) {
// // //       print("❌ WS connect failed: $e");
// // //       Future.delayed(const Duration(seconds: 5), _connectWebSocket);
// // //     }
// // //   }
// // //
// // //   // ✅ Fetch old messages
// // //   Future<void> _fetchAndLoad() async {
// // //     final provider = Provider.of<TelegraphProvider>(context, listen: false);
// // //     await provider.fetchMessages(
// // //         widget.phone, widget.chatId, widget.accessHash);
// // //     setState(() => _loading = false);
// // //   }
// // //
// // //   // ✅ Send message (via WebSocket → fallback HTTP)
// // //   Future<void> _sendMessage() async {
// // //     final text = _msgCtrl.text.trim();
// // //     if (text.isEmpty) return;
// // //
// // //     setState(() => _sending = true);
// // //     final provider = Provider.of<TelegraphProvider>(context, listen: false);
// // //
// // //     try {
// // //       if (_socket != null && _socket!.readyState == WebSocket.open) {
// // //         final msg = {
// // //           "action": "send",
// // //           "phone": widget.phone,
// // //           "chat_id": widget.chatId,
// // //           "access_hash": widget.accessHash,
// // //           "text": text,
// // //         };
// // //         _socket!.add(jsonEncode(msg));
// // //         print("📤 WS SENT → $msg");
// // //
// // //         // Show message instantly
// // //         provider.messages.insert(0, {
// // //           "text": text,
// // //           "is_out": true,
// // //           "time": DateTime.now().toString(),
// // //         });
// // //         provider.notifyListeners();
// // //         _msgCtrl.clear();
// // //       } else {
// // //         // HTTP fallback
// // //         final url = Uri.parse("$urlLocal/send");
// // //         final res = await http.post(url, body: {
// // //           "phone": widget.phone,
// // //           "to": widget.username,
// // //           "text": text,
// // //         });
// // //
// // //         if (res.statusCode == 200) {
// // //           provider.messages.insert(0, {
// // //             "text": text,
// // //             "is_out": true,
// // //             "time": DateTime.now().toString(),
// // //           });
// // //           provider.notifyListeners();
// // //           _msgCtrl.clear();
// // //         }
// // //       }
// // //     } catch (e) {
// // //       print("⚠️ Send error: $e");
// // //     } finally {
// // //       setState(() => _sending = false);
// // //     }
// // //   }
// // //
// // //   // 📸 Image picker logic
// // //   Future<void> _requestPermissions() async {
// // //     await [
// // //       Permission.camera,
// // //       Permission.photos,
// // //       Permission.storage,
// // //     ].request();
// // //   }
// // //
// // //   Future<void> _pickFromGallery() async {
// // //     await _requestPermissions();
// // //     final picked = await _picker.pickMultiImage(imageQuality: 80);
// // //     if (picked.isNotEmpty) {
// // //       setState(() => _selectedImages.addAll(picked.map((e) => File(e.path))));
// // //     }
// // //   }
// // //
// // //   Future<void> _pickFromCamera() async {
// // //     await _requestPermissions();
// // //     final picked =
// // //     await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
// // //     if (picked != null) {
// // //       setState(() => _selectedImages.add(File(picked.path)));
// // //     }
// // //   }
// // //
// // //   void _showSourceDialog() {
// // //     showModalBottomSheet(
// // //       context: context,
// // //       builder: (ctx) => SafeArea(
// // //         child: Wrap(
// // //           children: [
// // //             ListTile(
// // //               leading: const Icon(Icons.photo, color: Colors.green),
// // //               title: const Text("Gallery থেকে নিন"),
// // //               onTap: () {
// // //                 Navigator.pop(ctx);
// // //                 _pickFromGallery();
// // //               },
// // //             ),
// // //             ListTile(
// // //               leading: const Icon(Icons.camera_alt, color: Colors.green),
// // //               title: const Text("Camera দিয়ে তুলুন"),
// // //               onTap: () {
// // //                 Navigator.pop(ctx);
// // //                 _pickFromCamera();
// // //               },
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   // 🧱 UI build
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final provider = Provider.of<TelegraphProvider>(context);
// // //
// // //     return Scaffold(
// // //       backgroundColor: const Color(0xFFE5DDD5),
// // //       appBar: AppBar(
// // //         backgroundColor: const Color(0xFF008069),
// // //         title: Row(
// // //           children: [
// // //             const CircleAvatar(
// // //               backgroundColor: Colors.white,
// // //               child: Icon(Icons.person, color: Colors.black),
// // //             ),
// // //             const SizedBox(width: 10),
// // //             Text(widget.name,
// // //                 style: const TextStyle(color: Colors.white, fontSize: 18)),
// // //           ],
// // //         ),
// // //       ),
// // //       body: _loading
// // //           ? const Center(child: CircularProgressIndicator())
// // //           : Column(
// // //         children: [
// // //           if (_selectedImages.isNotEmpty)
// // //             Container(
// // //               height: 90,
// // //               padding: const EdgeInsets.symmetric(horizontal: 8),
// // //               child: ListView.builder(
// // //                 scrollDirection: Axis.horizontal,
// // //                 itemCount: _selectedImages.length,
// // //                 itemBuilder: (context, i) {
// // //                   final file = _selectedImages[i];
// // //                   return Stack(
// // //                     children: [
// // //                       Container(
// // //                         margin:
// // //                         const EdgeInsets.symmetric(horizontal: 4),
// // //                         child: ClipRRect(
// // //                           borderRadius: BorderRadius.circular(10),
// // //                           child: Image.file(
// // //                             file,
// // //                             width: 80,
// // //                             height: 80,
// // //                             fit: BoxFit.cover,
// // //                           ),
// // //                         ),
// // //                       ),
// // //                       Positioned(
// // //                         top: 2,
// // //                         right: 6,
// // //                         child: GestureDetector(
// // //                           onTap: () {
// // //                             setState(() {
// // //                               _selectedImages.removeAt(i);
// // //                             });
// // //                           },
// // //                           child: const CircleAvatar(
// // //                             radius: 10,
// // //                             backgroundColor: Colors.black54,
// // //                             child: Icon(Icons.close,
// // //                                 size: 14, color: Colors.white),
// // //                           ),
// // //                         ),
// // //                       ),
// // //                     ],
// // //                   );
// // //                 },
// // //               ),
// // //             ),
// // //
// // //           // 🔹 Messages list (real-time)
// // //           Expanded(
// // //             child: ListView.builder(
// // //               controller: _scrollController,
// // //               reverse: true,
// // //               itemCount: provider.messages.length,
// // //               itemBuilder: (context, i) {
// // //                 final msg = provider.messages[i];
// // //                 final isOut = msg["is_out"] == true;
// // //                 final text = msg["text"] ?? "";
// // //                 final time = msg["time"] ?? "";
// // //
// // //                 return Align(
// // //                   alignment: isOut
// // //                       ? Alignment.centerRight
// // //                       : Alignment.centerLeft,
// // //                   child: Container(
// // //                     margin: const EdgeInsets.symmetric(
// // //                         vertical: 4, horizontal: 8),
// // //                     padding: const EdgeInsets.all(10),
// // //                     decoration: BoxDecoration(
// // //                       color: isOut
// // //                           ? Colors.green.shade400
// // //                           : Colors.grey.shade300,
// // //                       borderRadius: BorderRadius.only(
// // //                         topLeft: const Radius.circular(14),
// // //                         topRight: const Radius.circular(14),
// // //                         bottomLeft: isOut
// // //                             ? const Radius.circular(14)
// // //                             : const Radius.circular(0),
// // //                         bottomRight: isOut
// // //                             ? const Radius.circular(0)
// // //                             : const Radius.circular(14),
// // //                       ),
// // //                     ),
// // //                     child: Column(
// // //                       crossAxisAlignment: CrossAxisAlignment.end,
// // //                       children: [
// // //                         if (text.isNotEmpty)
// // //                           Padding(
// // //                             padding:
// // //                             const EdgeInsets.symmetric(vertical: 4),
// // //                             child: Text(
// // //                               text,
// // //                               style: TextStyle(
// // //                                 color: isOut
// // //                                     ? Colors.white
// // //                                     : Colors.black87,
// // //                                 fontSize: 15,
// // //                               ),
// // //                             ),
// // //                           ),
// // //                         Text(
// // //                           time,
// // //                           style: TextStyle(
// // //                             color: isOut
// // //                                 ? Colors.white70
// // //                                 : Colors.grey[700],
// // //                             fontSize: 11,
// // //                           ),
// // //                         ),
// // //                       ],
// // //                     ),
// // //                   ),
// // //                 );
// // //               },
// // //             ),
// // //           ),
// // //
// // //           // 🔹 Message Input
// // //           Container(
// // //             color: Colors.white,
// // //             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
// // //             child: Row(
// // //               children: [
// // //                 IconButton(
// // //                   icon: const Icon(Icons.add, color: Colors.green),
// // //                   onPressed: _showSourceDialog,
// // //                 ),
// // //                 Expanded(
// // //                   child: TextField(
// // //                     controller: _msgCtrl,
// // //                     decoration: const InputDecoration(
// // //                       hintText: "Message",
// // //                       border: InputBorder.none,
// // //                     ),
// // //                   ),
// // //                 ),
// // //                 _sending
// // //                     ? const Padding(
// // //                   padding: EdgeInsets.all(8.0),
// // //                   child: CircularProgressIndicator(strokeWidth: 2),
// // //                 )
// // //                     : IconButton(
// // //                   icon: const Icon(Icons.send, color: Colors.green),
// // //                   onPressed: _sendMessage,
// // //                 ),
// // //               ],
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// // //
// // // import 'dart:convert';
// // // import 'dart:io';
// // // import 'package:ag_taligram/url.dart';
// // // import 'package:flutter/material.dart';
// // // import 'package:http/http.dart' as http;
// // // import 'package:image_picker/image_picker.dart';
// // // import 'package:mime/mime.dart';
// // // import 'package:path/path.dart' as p;
// // // import 'package:permission_handler/permission_handler.dart';
// // // import 'package:provider/provider.dart';
// // // import '../providers/telegraph_qg_provider.dart';
// // //
// // // class ChatScreen extends StatefulWidget {
// // //   final String phone;
// // //   final int chatId;
// // //   final int accessHash;
// // //   final String name;
// // //   final String username;
// // //
// // //   const ChatScreen({
// // //     super.key,
// // //     required this.phone,
// // //     required this.chatId,
// // //     required this.accessHash,
// // //     required this.name,
// // //     required this.username,
// // //   });
// // //
// // //   @override
// // //   State<ChatScreen> createState() => _ChatScreenState();
// // // }
// // //
// // // class _ChatScreenState extends State<ChatScreen> {
// // //   final ScrollController _scrollController = ScrollController();
// // //   final TextEditingController _msgCtrl = TextEditingController();
// // //   final ImagePicker _picker = ImagePicker();
// // //   WebSocket? _socket;
// // //
// // //   bool _loading = true;
// // //   bool _sending = false;
// // //   bool _typing = false;
// // //
// // //   // upload progress (maps to the last uploading message)
// // //   double _uploadProgress = 0.0;
// // //   int? _uploadingMsgIndex; // index in provider.messages
// // //
// // //   // optional: reply support (set this map from long-press)
// // //   Map<String, dynamic>? _replyToMsg;
// // //
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _fetchAndLoad();
// // //     _connectWebSocket();
// // //   }
// // //
// // //   @override
// // //   void dispose() {
// // //     _socket?.close();
// // //     super.dispose();
// // //   }
// // //
// // //   // ================================
// // //   // 🔌 WebSocket Connect
// // //   // ================================
// // //   Future<void> _connectWebSocket() async {
// // //     try {
// // //       // ⚠️ real device হলে LAN IP দাও
// // //       final wsUrl = 'ws://192.168.0.247:8080/chat_ws';
// // //       _socket = await WebSocket.connect(wsUrl);
// // //       debugPrint("✅ WS connected");
// // //
// // //       // INIT: backend-এর chat_ws যেমন চায়
// // //       final init = {
// // //         "phone": widget.phone,
// // //         "chat_id": widget.chatId,
// // //         "access_hash": widget.accessHash,
// // //       };
// // //       _socket!.add(jsonEncode(init));
// // //
// // //       _socket!.listen((raw) {
// // //         final provider = Provider.of<TelegraphProvider>(context, listen: false);
// // //         try {
// // //           final data = jsonDecode(raw);
// // //           // debugPrint("📩 WS IN → $data");
// // //
// // //           // --- upload progress (global)
// // //           if (data["action"] == "upload_progress") {
// // //             final prog = (data["progress"] ?? 0).toDouble();
// // //             setState(() => _uploadProgress = prog);
// // //             // tie to last uploading message
// // //             if (_uploadingMsgIndex != null &&
// // //                 _uploadingMsgIndex! < provider.messages.length) {
// // //               provider.messages[_uploadingMsgIndex!]["progress"] = prog;
// // //               provider.notifyListeners();
// // //             }
// // //             return;
// // //           }
// // //
// // //           // --- new incoming message from Telegram
// // //           if (data["action"] == "new_message") {
// // //             if (data["chat_id"].toString() == widget.chatId.toString()) {
// // //               final mediaType = data["media_type"]; // image / video / audio / file / null
// // //               final fileName  = data["file_name"];
// // //               final fileUrl   = data["file_url"];  // থাকলে ব্যবহার করব
// // //
// // //               provider.messages.insert(0, {
// // //                 "id": data["id"],
// // //                 "text": data["text"] ?? "",
// // //                 "is_out": false,
// // //                 "time": data["date"] ?? DateTime.now().toString(),
// // //                 "type": mediaType ?? (data["text"]?.isNotEmpty == true ? "text" : null),
// // //                 "file_name": fileName,
// // //                 "url": fileUrl,
// // //                 "progress": 100.0,
// // //                 "uploading": false,
// // //               });
// // //               provider.notifyListeners();
// // //             }
// // //             return;
// // //           }
// // //
// // //           // --- our own send confirmations
// // //           if (data["status"] == "sent_file" ||
// // //               data["status"] == "sent_video" ||
// // //               data["status"] == "sent_voice" ||
// // //               data["status"] == "sent_text") {
// // //             // clear upload UI
// // //             setState(() {
// // //               _uploadProgress = 100.0;
// // //             });
// // //             if (_uploadingMsgIndex != null &&
// // //                 _uploadingMsgIndex! < provider.messages.length) {
// // //               provider.messages[_uploadingMsgIndex!]["uploading"] = false;
// // //               provider.messages[_uploadingMsgIndex!]["progress"] = 100.0;
// // //               provider.notifyListeners();
// // //               _uploadingMsgIndex = null;
// // //             }
// // //             return;
// // //           }
// // //
// // //           if ((data["status"] ?? "").toString().contains("error")) {
// // //             debugPrint("❌ WS Error: ${data["detail"]}");
// // //           }
// // //         } catch (e) {
// // //           debugPrint("⚠️ WS decode error: $e");
// // //         }
// // //       }, onDone: () {
// // //         debugPrint("⚠️ WS closed. Reconnect in 3s...");
// // //         Future.delayed(const Duration(seconds: 3), _connectWebSocket);
// // //       }, onError: (err) {
// // //         debugPrint("❌ WS error: $err");
// // //         Future.delayed(const Duration(seconds: 5), _connectWebSocket);
// // //       });
// // //     } catch (e) {
// // //       debugPrint("❌ WS connect fail: $e");
// // //       Future.delayed(const Duration(seconds: 5), _connectWebSocket);
// // //     }
// // //   }
// // //
// // //   // ================================
// // //   // 📨 Load old messages
// // //   // ================================
// // //   Future<void> _fetchAndLoad() async {
// // //     final provider = Provider.of<TelegraphProvider>(context, listen: false);
// // //     await provider.fetchMessages(widget.phone, widget.chatId, widget.accessHash);
// // //     setState(() => _loading = false);
// // //   }
// // //
// // //   // ================================
// // //   // ✉️ Send text (with optional reply)
// // //   // ================================
// // //   Future<void> _sendText() async {
// // //     final text = _msgCtrl.text.trim();
// // //     if (text.isEmpty) return;
// // //
// // //     setState(() => _sending = true);
// // //     final provider = Provider.of<TelegraphProvider>(context, listen: false);
// // //
// // //     final payload = {
// // //       "action": "send",
// // //       "phone": widget.phone,
// // //       "chat_id": widget.chatId,
// // //       "access_hash": widget.accessHash,
// // //       "text": text,
// // //     };
// // //     if (_replyToMsg != null && _replyToMsg!["id"] != null) {
// // //       payload["reply_to"] = _replyToMsg!["id"];
// // //     }
// // //
// // //     try {
// // //       if (_socket?.readyState == WebSocket.open) {
// // //         _socket!.add(jsonEncode(payload));
// // //       } else {
// // //         // HTTP fallback
// // //         final url = Uri.parse("$urlLocal/send");
// // //         await http.post(url, body: {
// // //           "phone": widget.phone,
// // //           "to": widget.username,
// // //           "text": text,
// // //         });
// // //       }
// // //
// // //       provider.messages.insert(0, {
// // //         "text": text,
// // //         "is_out": true,
// // //         "time": DateTime.now().toString(),
// // //         "type": "text",
// // //         "uploading": false,
// // //         "progress": 100.0,
// // //       });
// // //       provider.notifyListeners();
// // //       _msgCtrl.clear();
// // //       setState(() => _replyToMsg = null);
// // //     } catch (e) {
// // //       debugPrint("⚠️ send text error: $e");
// // //     } finally {
// // //       setState(() => _sending = false);
// // //     }
// // //   }
// // //
// // //   // ================================
// // //   // 📤 Send file (image / video / audio)
// // //   // ================================
// // //   Future<void> _sendFile(File file, {String? caption}) async {
// // //     try {
// // //       final bytes = await file.readAsBytes();
// // //       final b64 = base64Encode(bytes);
// // //       final fileName = p.basename(file.path);
// // //       final mime = lookupMimeType(file.path) ?? "application/octet-stream";
// // //
// // //       final isImage = mime.startsWith('image/');
// // //       final isVideo = mime.startsWith('video/');
// // //       final isAudio = mime.startsWith('audio/');
// // //
// // //       final provider = Provider.of<TelegraphProvider>(context, listen: false);
// // //
// // //       // show immediately in list with local preview + 0% progress
// // //       provider.messages.insert(0, {
// // //         "text": caption ?? "",
// // //         "is_out": true,
// // //         "time": DateTime.now().toString(),
// // //         "type": isImage ? "image" : (isVideo ? "video" : (isAudio ? "audio" : "file")),
// // //         "local_path": file.path,
// // //         "file_name": fileName,
// // //         "mime": mime,
// // //         "uploading": true,
// // //         "progress": 0.0,
// // //       });
// // //       provider.notifyListeners();
// // //       _uploadingMsgIndex = 0; // just inserted at 0
// // //       setState(() {
// // //         _uploadProgress = 0.0;
// // //       });
// // //
// // //       final payload = {
// // //         "action": "send",
// // //         "phone": widget.phone,
// // //         "chat_id": widget.chatId,
// // //         "access_hash": widget.accessHash,
// // //         "file_name": fileName,
// // //         "file_base64": b64,
// // //         "mime_type": mime,
// // //         "text": caption ?? "",
// // //       };
// // //       if (_replyToMsg != null && _replyToMsg!["id"] != null) {
// // //         payload["reply_to"] = _replyToMsg!["id"];
// // //       }
// // //
// // //       if (_socket?.readyState == WebSocket.open) {
// // //         _socket!.add(jsonEncode(payload));
// // //       } else {
// // //         // চাইলে এখানে HTTP /upload fallback রাখতে পারো
// // //         debugPrint("WS not open; file not sent.");
// // //       }
// // //     } catch (e) {
// // //       debugPrint("⚠️ send file error: $e");
// // //     }
// // //   }
// // //
// // //   // ================================
// // //   // Typing events
// // //   // ================================
// // //   void _typingStart() {
// // //     if (_socket?.readyState == WebSocket.open) {
// // //       _socket!.add(jsonEncode({"action": "typing_start"}));
// // //     }
// // //   }
// // //
// // //   void _typingStop() {
// // //     if (_socket?.readyState == WebSocket.open) {
// // //       _socket!.add(jsonEncode({"action": "typing_stop"}));
// // //     }
// // //   }
// // //
// // //   // ================================
// // //   // File pickers
// // //   // ================================
// // //   Future<void> _ensurePerms() async {
// // //     await [Permission.camera, Permission.photos, Permission.storage].request();
// // //   }
// // //
// // //   Future<void> _pickImages() async {
// // //     await _ensurePerms();
// // //     final imgs = await _picker.pickMultiImage(imageQuality: 80);
// // //     for (final img in imgs) {
// // //       await _sendFile(File(img.path));
// // //     }
// // //   }
// // //
// // //   Future<void> _pickVideo() async {
// // //     await _ensurePerms();
// // //     final vid = await _picker.pickVideo(source: ImageSource.gallery);
// // //     if (vid != null) {
// // //       await _sendFile(File(vid.path));
// // //     }
// // //   }
// // //
// // //   void _showAttachmentMenu() {
// // //     showModalBottomSheet(
// // //       context: context,
// // //       builder: (ctx) => SafeArea(
// // //         child: Wrap(children: [
// // //           ListTile(
// // //             leading: const Icon(Icons.photo, color: Colors.green),
// // //             title: const Text("Send Image"),
// // //             onTap: () {
// // //               Navigator.pop(ctx);
// // //               _pickImages();
// // //             },
// // //           ),
// // //           ListTile(
// // //             leading: const Icon(Icons.videocam, color: Colors.green),
// // //             title: const Text("Send Video"),
// // //             onTap: () {
// // //               Navigator.pop(ctx);
// // //               _pickVideo();
// // //             },
// // //           ),
// // //         ]),
// // //       ),
// // //     );
// // //   }
// // //
// // //   // ================================
// // //   // UI helpers
// // //   // ================================
// // //   Widget _bubbleContent(Map<String, dynamic> msg, bool isOut) {
// // //     final type = (msg["type"] ?? "text").toString();
// // //     final text = msg["text"] ?? "";
// // //     final localPath = msg["local_path"];
// // //     final url = msg["url"];
// // //     final fileName = msg["file_name"];
// // //
// // //     // Image
// // //     if (type == "image") {
// // //       final w = 220.0;
// // //       final h = 260.0;
// // //       return Column(
// // //         crossAxisAlignment: CrossAxisAlignment.end,
// // //         children: [
// // //           ClipRRect(
// // //             borderRadius: BorderRadius.circular(10),
// // //             child: localPath != null
// // //                 ? Image.file(File(localPath), width: w, height: h, fit: BoxFit.cover)
// // //                 : (url != null
// // //                 ? Image.network(url, width: w, height: h, fit: BoxFit.cover)
// // //                 : Container(
// // //               width: w,
// // //               height: h,
// // //               color: Colors.black12,
// // //               child: const Icon(Icons.image, size: 48),
// // //             )),
// // //           ),
// // //           if (text.toString().isNotEmpty)
// // //             Padding(
// // //               padding: const EdgeInsets.only(top: 6),
// // //               child: Text(
// // //                 text,
// // //                 style: TextStyle(color: isOut ? Colors.white : Colors.black87),
// // //               ),
// // //             ),
// // //         ],
// // //       );
// // //     }
// // //
// // //     // Video
// // //     if (type == "video") {
// // //       return Column(
// // //         crossAxisAlignment: CrossAxisAlignment.start,
// // //         children: [
// // //           Container(
// // //             width: 240,
// // //             height: 150,
// // //             decoration: BoxDecoration(
// // //               color: Colors.black12,
// // //               borderRadius: BorderRadius.circular(10),
// // //             ),
// // //             child: Stack(
// // //               alignment: Alignment.center,
// // //               children: [
// // //                 if (localPath != null)
// // //                   const Icon(Icons.videocam, size: 48, color: Colors.black45)
// // //                 else if (url != null)
// // //                   const Icon(Icons.videocam, size: 48, color: Colors.black45)
// // //                 else
// // //                   const Icon(Icons.videocam_off, size: 48, color: Colors.black45),
// // //                 const Positioned(
// // //                   bottom: 8,
// // //                   child: Text("Video", style: TextStyle(color: Colors.black54)),
// // //                 ),
// // //               ],
// // //             ),
// // //           ),
// // //           if ((fileName ?? "").toString().isNotEmpty)
// // //             Padding(
// // //               padding: const EdgeInsets.only(top: 4),
// // //               child: Text(fileName, style: TextStyle(color: isOut ? Colors.white70 : Colors.black54, fontSize: 12)),
// // //             ),
// // //           if (text.toString().isNotEmpty)
// // //             Padding(
// // //               padding: const EdgeInsets.only(top: 4),
// // //               child: Text(text, style: TextStyle(color: isOut ? Colors.white : Colors.black87)),
// // //             ),
// // //         ],
// // //       );
// // //     }
// // //
// // //     // Audio / File (simple row)
// // //     if (type == "audio" || type == "file") {
// // //       return Row(
// // //         mainAxisSize: MainAxisSize.min,
// // //         children: [
// // //           Icon(type == "audio" ? Icons.audiotrack : Icons.insert_drive_file,
// // //               color: isOut ? Colors.white : Colors.black54),
// // //           const SizedBox(width: 8),
// // //           Text(fileName ?? 'file', style: TextStyle(color: isOut ? Colors.white : Colors.black87)),
// // //         ],
// // //       );
// // //     }
// // //
// // //     // Text
// // //     return Text(
// // //       text,
// // //       style: TextStyle(color: isOut ? Colors.white : Colors.black87, fontSize: 15),
// // //     );
// // //   }
// // //
// // //   // ================================
// // //   // UI
// // //   // ================================
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final provider = Provider.of<TelegraphProvider>(context);
// // //
// // //     return Scaffold(
// // //       backgroundColor: const Color(0xFFE5DDD5),
// // //       appBar: AppBar(
// // //         backgroundColor: const Color(0xFF008069),
// // //         title: Row(children: [
// // //           const CircleAvatar(
// // //             backgroundColor: Colors.white,
// // //             child: Icon(Icons.person, color: Colors.black),
// // //           ),
// // //           const SizedBox(width: 10),
// // //           Text(widget.name, style: const TextStyle(color: Colors.white, fontSize: 18)),
// // //           if (_typing)
// // //             const Padding(
// // //               padding: EdgeInsets.only(left: 8),
// // //               child: Text("typing...", style: TextStyle(color: Colors.white70, fontSize: 12)),
// // //             ),
// // //         ]),
// // //       ),
// // //       body: _loading
// // //           ? const Center(child: CircularProgressIndicator())
// // //           : Column(children: [
// // //         // reply banner (optional)
// // //         if (_replyToMsg != null)
// // //           Container(
// // //             color: Colors.teal.shade100,
// // //             padding: const EdgeInsets.all(8),
// // //             child: Row(children: [
// // //               Expanded(
// // //                 child: Text("↩️ Replying: ${_replyToMsg!["text"] ?? ""}",
// // //                     maxLines: 1, overflow: TextOverflow.ellipsis),
// // //               ),
// // //               IconButton(
// // //                 icon: const Icon(Icons.close),
// // //                 onPressed: () => setState(() => _replyToMsg = null),
// // //               )
// // //             ]),
// // //           ),
// // //
// // //         // 🔄 upload progress bar
// // //         if (_uploadProgress > 0 && _uploadProgress < 100)
// // //           Container(
// // //             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
// // //             child: Row(
// // //               children: [
// // //                 Expanded(
// // //                   child: LinearProgressIndicator(value: _uploadProgress / 100.0),
// // //                 ),
// // //                 const SizedBox(width: 10),
// // //                 Text("${_uploadProgress.toStringAsFixed(0)}%"),
// // //               ],
// // //             ),
// // //           ),
// // //
// // //         // messages list
// // //         Expanded(
// // //           child: ListView.builder(
// // //             controller: _scrollController,
// // //             reverse: true,
// // //             itemCount: provider.messages.length,
// // //             itemBuilder: (context, i) {
// // //               final msg = provider.messages[i];
// // //               final isOut = msg["is_out"] == true;
// // //               final time = msg["time"] ?? "";
// // //               final uploading = msg["uploading"] == true;
// // //               final progress = (msg["progress"] ?? 100.0).toDouble();
// // //
// // //               return GestureDetector(
// // //                 onLongPress: () => setState(() => _replyToMsg = msg), // enable reply
// // //                 child: Align(
// // //                   alignment: isOut ? Alignment.centerRight : Alignment.centerLeft,
// // //                   child: Container(
// // //                     margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
// // //                     padding: const EdgeInsets.all(10),
// // //                     decoration: BoxDecoration(
// // //                       color: isOut ? Colors.green.shade400 : Colors.grey.shade300,
// // //                       borderRadius: BorderRadius.only(
// // //                         topLeft: const Radius.circular(14),
// // //                         topRight: const Radius.circular(14),
// // //                         bottomLeft: isOut ? const Radius.circular(14) : const Radius.circular(0),
// // //                         bottomRight: isOut ? const Radius.circular(0) : const Radius.circular(14),
// // //                       ),
// // //                     ),
// // //                     child: Column(
// // //                       crossAxisAlignment: CrossAxisAlignment.end,
// // //                       children: [
// // //                         _bubbleContent(msg, isOut),
// // //
// // //                         if (uploading)
// // //                           Padding(
// // //                             padding: const EdgeInsets.only(top: 6),
// // //                             child: SizedBox(
// // //                               width: 160,
// // //                               child: Row(
// // //                                 children: [
// // //                                   Expanded(
// // //                                     child: LinearProgressIndicator(value: progress / 100.0),
// // //                                   ),
// // //                                   const SizedBox(width: 8),
// // //                                   Text("${progress.toStringAsFixed(0)}%",
// // //                                       style: TextStyle(
// // //                                         color: isOut ? Colors.white70 : Colors.black54,
// // //                                         fontSize: 11,
// // //                                       )),
// // //                                 ],
// // //                               ),
// // //                             ),
// // //                           ),
// // //
// // //                         Padding(
// // //                           padding: const EdgeInsets.only(top: 6),
// // //                           child: Text(
// // //                             time,
// // //                             style: TextStyle(
// // //                               color: isOut ? Colors.white70 : Colors.grey[700],
// // //                               fontSize: 11,
// // //                             ),
// // //                           ),
// // //                         ),
// // //                       ],
// // //                     ),
// // //                   ),
// // //                 ),
// // //               );
// // //             },
// // //           ),
// // //         ),
// // //
// // //         // input row
// // //         Container(
// // //           color: Colors.white,
// // //           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
// // //           child: Row(children: [
// // //             IconButton(
// // //               icon: const Icon(Icons.add, color: Colors.green),
// // //               onPressed: _showAttachmentMenu,
// // //             ),
// // //             Expanded(
// // //               child: TextField(
// // //                 controller: _msgCtrl,
// // //                 decoration: const InputDecoration(hintText: "Message", border: InputBorder.none),
// // //                 onChanged: (_) => _typingStart(),
// // //                 onEditingComplete: _typingStop,
// // //               ),
// // //             ),
// // //             _sending
// // //                 ? const Padding(
// // //               padding: EdgeInsets.all(8.0),
// // //               child: CircularProgressIndicator(strokeWidth: 2),
// // //             )
// // //                 : IconButton(
// // //               icon: const Icon(Icons.send, color: Colors.green),
// // //               onPressed: _sendText,
// // //             ),
// // //           ]),
// // //         ),
// // //       ]),
// // //     );
// // //   }
// // // }
// // //
// // //
// //
// //
// // import 'dart:async';
// // import 'dart:convert';
// // import 'dart:io';
// // import 'package:flutter/material.dart';
// // import 'package:image_picker/image_picker.dart';
// // import 'package:mime/mime.dart';
// // import 'package:path/path.dart' as p;
// // import 'package:permission_handler/permission_handler.dart';
// // import 'package:provider/provider.dart';
// // import '../providers/telegraph_qg_provider.dart';
// //
// // class ChatScreen extends StatefulWidget {
// //   final String phone;
// //   final int chatId;
// //   final int accessHash;
// //   final String name;
// //   final String username;
// //
// //   const ChatScreen({
// //     super.key,
// //     required this.phone,
// //     required this.chatId,
// //     required this.accessHash,
// //     required this.name,
// //     required this.username,
// //   });
// //
// //   @override
// //   State<ChatScreen> createState() => _ChatScreenState();
// // }
// //
// // class _ChatScreenState extends State<ChatScreen> {
// //   // ==== CONFIG ====
// //   static const String _wsUrl = 'ws://192.168.0.247:8080/chat_ws';
// //   static const String _apiBase = 'http://192.168.0.247:8080'; // <- change if needed
// //   static const Duration _wsPingEvery = Duration(seconds: 20);
// //
// //   final ScrollController _scrollController = ScrollController();
// //   final TextEditingController _msgCtrl = TextEditingController();
// //   final ImagePicker _picker = ImagePicker();
// //   WebSocket? _socket;
// //
// //   bool _loading = true;
// //   bool _sending = false;
// //   bool _typing = false;
// //   int? _uploadingMsgIndex;
// //
// //   // WS helpers
// //   Timer? _pingTimer;
// //   Timer? _reconnectTimer;
// //   int _reconnectAttempt = 0;
// //   final Set<String> _seenIds = {}; // for de-dupe (server IDs or temp ids)
// //   final String _clientInstance = DateTime.now().millisecondsSinceEpoch.toString();
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _fetchAndLoad();
// //     _connectWebSocket();
// //   }
// //
// //   @override
// //   void dispose() {
// //     _pingTimer?.cancel();
// //     _reconnectTimer?.cancel();
// //     _socket?.close();
// //     super.dispose();
// //   }
// //
// //   // ================================
// //   // 🔌 WebSocket Connect (self-healing)
// //   // ================================
// //   Future<void> _connectWebSocket() async {
// //     try {
// //       _reconnectTimer?.cancel();
// //       _socket = await WebSocket.connect(_wsUrl);
// //       _reconnectAttempt = 0;
// //       debugPrint("✅ WS Connected");
// //
// //       // Init frame (server expects this as first message)
// //       _socket!.add(jsonEncode({
// //         "phone": widget.phone,
// //         "chat_id": widget.chatId,
// //         "access_hash": widget.accessHash,
// //       }));
// //
// //       // Start server ping (keep-alive)
// //       _pingTimer?.cancel();
// //       _pingTimer = Timer.periodic(_wsPingEvery, (_) {
// //         if (_socket?.readyState == WebSocket.open) {
// //           _socket!.add(jsonEncode({"action": "ping"}));
// //         }
// //       });
// //
// //       _socket!.listen(
// //             (raw) => _handleWsFrame(raw),
// //         onDone: _scheduleReconnect,
// //         onError: (err) {
// //           debugPrint("⚠️ WS error: $err");
// //           _scheduleReconnect();
// //         },
// //         cancelOnError: true,
// //       );
// //     } catch (e) {
// //       debugPrint("⚠️ WS connect failed: $e");
// //       _scheduleReconnect();
// //     }
// //   }
// //
// //   void _scheduleReconnect([_]) {
// //     _pingTimer?.cancel();
// //     _reconnectAttempt++;
// //     final delay = Duration(seconds: _reconnectBackoffSeconds(_reconnectAttempt));
// //     debugPrint("↩️ Reconnect in ${delay.inSeconds}s (attempt $_reconnectAttempt)");
// //     _reconnectTimer?.cancel();
// //     _reconnectTimer = Timer(delay, _connectWebSocket);
// //   }
// //
// //   int _reconnectBackoffSeconds(int n) {
// //     final v = 1 << (n.clamp(0, 5)); // 1,2,4,8,16,32
// //     return v > 30 ? 30 : v;
// //   }
// //
// //   // ================================
// //   // 📨 Handle WS frames
// //   // ================================
// //   void _handleWsFrame(String raw) {
// //     if (!mounted) return;
// //     final provider = Provider.of<TelegraphProvider>(context, listen: false);
// //
// //     try {
// //       final data = jsonDecode(raw);
// //
// //       // Heartbeat or pong
// //       if (data["action"] == "_hb" || data["status"] == "pong") return;
// //
// //       // Typing events
// //       if (data["action"] == "typing") {
// //         setState(() => _typing = true);
// //         return;
// //       }
// //       if (data["action"] == "typing_stopped") {
// //         setState(() => _typing = false);
// //         return;
// //       }
// //
// //       // Upload progress for our last uploading bubble
// //       if (data["action"] == "upload_progress") {
// //         if (_uploadingMsgIndex != null &&
// //             _uploadingMsgIndex! < provider.messages.length) {
// //           provider.messages[_uploadingMsgIndex!]["progress"] = data["progress"];
// //           provider.notifyListeners();
// //         }
// //         return;
// //       }
// //
// //       // Listener ack
// //       if (data["status"] == "listening") return;
// //
// //       // SEED: initial messages pushed by server
// //       if (data["action"] == "seed" && data["messages"] is List) {
// //         final List<dynamic> arr = data["messages"];
// //         // server sends oldest → newest. Our ListView is reverse:true (newest at top),
// //         // so we'll add from last to first to keep newest at index 0.
// //         for (int i = arr.length - 1; i >= 0; i--) {
// //           final mapped = _mapServerMessage(arr[i]);
// //           if (mapped == null) continue;
// //           final id = mapped["id"]?.toString();
// //           if (id != null && _seenIds.contains(id)) continue;
// //           if (id != null) _seenIds.add(id);
// //           provider.messages.insert(0, mapped);
// //         }
// //         provider.notifyListeners();
// //         return;
// //       }
// //
// //       // PRIMARY MESSAGE (new_message OR generic with id)
// //       if (data["action"] == "new_message" || data.containsKey("id")) {
// //         final mapped = _mapServerMessage(data);
// //         if (mapped == null) return;
// //
// //         final id = mapped["id"]?.toString();
// //         // de-dupe: if we already have same server id, skip
// //         if (id != null && _seenIds.contains(id)) return;
// //         if (id != null) _seenIds.add(id);
// //
// //         // If it's our own pending text/file (no id), replace first pending bubble by text match
// //         final isOut = mapped["is_out"] == true;
// //         if (isOut) {
// //           final idx = provider.messages.indexWhere((m) {
// //             final bool pending = (m["pending"] == true) && (m["is_out"] == true);
// //             final sameText = (m["text"] ?? "") == (mapped["text"] ?? "");
// //             return pending && sameText;
// //           });
// //           if (idx != -1) {
// //             provider.messages[idx] = mapped;
// //             provider.notifyListeners();
// //             return;
// //           }
// //         }
// //
// //         provider.messages.insert(0, mapped);
// //         provider.notifyListeners();
// //         return;
// //       }
// //
// //       // (Older path) Explicit call_event
// //       if (data["action"] == "call_event") {
// //         final mapped = _mapCallEvent(data);
// //         if (mapped == null) return;
// //         final id = mapped["id"]?.toString();
// //         if (id != null && _seenIds.contains(id)) return;
// //         if (id != null) _seenIds.add(id);
// //         provider.messages.insert(0, mapped);
// //         provider.notifyListeners();
// //         return;
// //       }
// //     } catch (e) {
// //       debugPrint("⚠️ WS parse error: $e");
// //     }
// //   }
// //
// //   // ================================
// //   // 📨 Load messages (initial REST)
// //   // ================================
// //   Future<void> _fetchAndLoad() async {
// //     final provider = Provider.of<TelegraphProvider>(context, listen: false);
// //     await provider.fetchMessages(widget.phone, widget.chatId, widget.accessHash);
// //     // Provider-এর fetch যদি already normalize না করে থাকে, চাইলে এখানে normalize করতে পারেন।
// //     // ধরি আপনার provider আগের মতোই ঠিক ঢুকিয়ে দিচ্ছে।
// //     setState(() => _loading = false);
// //   }
// //
// //   // ================================
// //   // ✉️ Send text
// //   // ================================
// //   Future<void> _sendText() async {
// //     final text = _msgCtrl.text.trim();
// //     if (text.isEmpty) return;
// //
// //     setState(() => _sending = true);
// //     final provider = Provider.of<TelegraphProvider>(context, listen: false);
// //
// //     final payload = {
// //       "action": "send",
// //       "text": text,
// //       // সার্ভারের নতুন /chat_ws এ init-এ phone/chat_id/ah দেওয়া থাকে, "send"-এ আবার দিতে হয় না।
// //       // কিন্তু backward compatible রাখলাম:
// //       "phone": widget.phone,
// //       "chat_id": widget.chatId,
// //       "access_hash": widget.accessHash,
// //       "client_instance": _clientInstance,
// //     };
// //
// //     try {
// //       // optimistic pending bubble
// //       provider.messages.insert(0, {
// //         "id": "pending:${DateTime.now().microsecondsSinceEpoch}",
// //         "text": text,
// //         "is_out": true,
// //         "time": DateTime.now().toIso8601String(),
// //         "type": "text",
// //         "pending": true,
// //       });
// //       _seenIds.add(provider.messages.first["id"].toString());
// //       provider.notifyListeners();
// //
// //       _socket?.add(jsonEncode(payload));
// //       _msgCtrl.clear();
// //     } catch (e) {
// //       debugPrint("⚠️ send text error: $e");
// //     } finally {
// //       if (mounted) setState(() => _sending = false);
// //     }
// //   }
// //
// //   // ================================
// //   // Typing events
// //   // ================================
// //   Timer? _typingDebounce;
// //   void _typingStart() {
// //     _typingDebounce?.cancel();
// //     if (_socket?.readyState == WebSocket.open) {
// //       _socket!.add(jsonEncode({"action": "typing_start"}));
// //     }
// //     // stop typing if idle 2s
// //     _typingDebounce = Timer(const Duration(seconds: 2), _typingStop);
// //   }
// //
// //   void _typingStop() {
// //     if (_socket?.readyState == WebSocket.open) {
// //       _socket!.add(jsonEncode({"action": "typing_stop"}));
// //     }
// //   }
// //
// //   // ================================
// //   // Picker & Send File
// //   // ================================
// //   Future<void> _ensurePerms() async {
// //     await [Permission.camera, Permission.photos, Permission.storage].request();
// //   }
// //
// //   Future<void> _pickImage() async {
// //     await _ensurePerms();
// //     final img = await _picker.pickImage(source: ImageSource.gallery);
// //     if (img != null) await _sendFile(File(img.path));
// //   }
// //
// //   Future<void> _pickVideo() async {
// //     await _ensurePerms();
// //     final vid = await _picker.pickVideo(source: ImageSource.gallery);
// //     if (vid != null) await _sendFile(File(vid.path));
// //   }
// //
// //   Future<void> _sendFile(File file) async {
// //     try {
// //       final bytes = await file.readAsBytes();
// //       final b64 = base64Encode(bytes);
// //       final fileName = p.basename(file.path);
// //       final mime = lookupMimeType(file.path) ?? "application/octet-stream";
// //
// //       final provider = Provider.of<TelegraphProvider>(context, listen: false);
// //       provider.messages.insert(0, {
// //         "id": "pending:${DateTime.now().microsecondsSinceEpoch}",
// //         "text": "",
// //         "is_out": true,
// //         "time": DateTime.now().toIso8601String(),
// //         "type": mime.startsWith('image/') ? "image" : (mime.startsWith('video/') ? "video" : "file"),
// //         "local_path": file.path,
// //         "uploading": true,
// //         "progress": 0.0,
// //         "pending": true,
// //       });
// //       _uploadingMsgIndex = 0;
// //       _seenIds.add(provider.messages.first["id"].toString());
// //       provider.notifyListeners();
// //
// //       _socket?.add(jsonEncode({
// //         "action": "send",
// //         "file_name": fileName,
// //         "file_base64": b64,
// //         "mime_type": mime,
// //         // b/c older server versions used these in send:
// //         "phone": widget.phone,
// //         "chat_id": widget.chatId,
// //         "access_hash": widget.accessHash,
// //         "client_instance": _clientInstance,
// //       }));
// //     } catch (e) {
// //       debugPrint("⚠️ send file error: $e");
// //     }
// //   }
// //
// //   // ================================
// //   // Mapping helpers
// //   // ================================
// //   Map<String, dynamic>? _mapServerMessage(dynamic data) {
// //     if (data == null) return null;
// //
// //     final id = data["id"] ?? data["msg_id"] ?? data["temp_id"];
// //     final text = (data["text"] ?? "") as String;
// //     final isOut = data["is_out"] == true || (data["direction"]?.toString() == "out");
// //     final date = (data["date"] ?? DateTime.now().toIso8601String()).toString();
// //     final mediaType = (data["media_type"] ?? data["type"] ?? "text").toString();
// //     final mediaLink = data["media_link"];
// //
// //     if (mediaType == "call_audio" || mediaType == "call_video") {
// //       final call = data["call"] ?? {};
// //       return {
// //         "id": id?.toString(),
// //         "text": _formatCallTitle(call, mediaType),
// //         "is_out": isOut,
// //         "time": date,
// //         "type": "call",
// //         "call_status": call["status"],
// //         "duration": call["duration"],
// //         "direction": call["direction"], // incoming/outgoing
// //       };
// //     }
// //
// //     // Normal text/file/image/video
// //     return {
// //       "id": id?.toString(),
// //       "text": text,
// //       "is_out": isOut,
// //       "time": date,
// //       "type": _normalizeType(mediaType),
// //       "url": _resolveUrl(mediaLink),
// //       "pending": false,
// //     };
// //   }
// //
// //   Map<String, dynamic>? _mapCallEvent(dynamic data) {
// //     final id = data["id"];
// //     final status = data["status"];
// //     final direction = data["direction"];
// //     final duration = data["duration"];
// //     final isVideo = data["is_video"] == true;
// //     final date = (data["date"] ?? DateTime.now().toIso8601String()).toString();
// //
// //     return {
// //       "id": id?.toString(),
// //       "text": isVideo ? "Video call" : "Voice call",
// //       "is_out": (direction == "outgoing"),
// //       "time": date,
// //       "type": "call",
// //       "call_status": status,
// //       "duration": duration,
// //       "direction": direction,
// //     };
// //   }
// //
// //   String _normalizeType(String t) {
// //     switch (t) {
// //       case "image":
// //       case "video":
// //       case "audio":
// //       case "voice":
// //       case "sticker":
// //       case "file":
// //         return t;
// //       default:
// //         return "text";
// //     }
// //   }
// //
// //   String? _resolveUrl(dynamic url) {
// //     if (url == null) return null;
// //     final u = url.toString();
// //     if (u.startsWith('http://') || u.startsWith('https://')) return u;
// //     if (u.startsWith('/')) return '$_apiBase$u';
// //     return '$_apiBase/$u';
// //   }
// //
// //   String _formatCallTitle(Map call, String mediaType) {
// //     final status = (call["status"] ?? "").toString();
// //     final dur = call["duration"];
// //     final sec = (dur is num) ? dur.toInt() : null;
// //     final dir = (call["direction"] ?? "").toString(); // incoming/outgoing
// //     final t = mediaType == "call_video" ? "Video call" : "Voice call";
// //     final sd = (sec != null && sec > 0) ? " • ${_fmtDur(sec)}" : "";
// //     final d = dir.isNotEmpty ? (dir == "incoming" ? "Incoming" : "Outgoing") : "";
// //     return "$t • $status${sd}${d.isNotEmpty ? " • $d" : ""}";
// //     // Example: "Voice call • ended • 00:02:31 • Outgoing"
// //   }
// //
// //   String _fmtDur(int s) {
// //     final h = s ~/ 3600;
// //     final m = (s % 3600) ~/ 60;
// //     final sec = s % 60;
// //     if (h > 0) {
// //       return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
// //     }
// //     return "${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
// //   }
// //
// //   // ================================
// //   // Message Bubble
// //   // ================================
// //
// //   //
// //   // Widget _bubbleContent(Map<String, dynamic> msg, bool isOut) {
// //   //   final type = (msg["type"] ?? "text") as String;
// //   //   final text = (msg["text"] ?? "") as String;
// //   //   final bool isDeleted = msg["is_deleted"] == true;
// //   //
// //   //   // 🔴 deleted হলে টেক্সট লাল, না হলে আগের মতো
// //   //   final textColor = isDeleted
// //   //       ? Colors.red
// //   //       : (isOut ? Colors.white : Colors.black87);
// //   //
// //   //   // 📞 CALL MESSAGE
// //   //   if (type == "call") {
// //   //     final status = msg["call_status"]?.toString() ?? "";
// //   //     final direction = msg["direction"]?.toString() ?? "";
// //   //     IconData icon;
// //   //     Color color;
// //   //
// //   //     if (status == "missed") {
// //   //       icon = Icons.call_missed;
// //   //       color = Colors.red;
// //   //     } else if (status == "ended") {
// //   //       icon = Icons.call_end;
// //   //       color = Colors.green;
// //   //     } else if (status == "busy") {
// //   //       icon = Icons.call_end;
// //   //       color = Colors.orange;
// //   //     } else {
// //   //       icon = Icons.phone;
// //   //       color = Colors.blueGrey;
// //   //     }
// //   //
// //   //     return Row(
// //   //       mainAxisSize: MainAxisSize.min,
// //   //       children: [
// //   //         Icon(icon, color: color, size: 20),
// //   //         const SizedBox(width: 6),
// //   //         Flexible(
// //   //           child: Text(
// //   //             "$text (${direction == "incoming" ? "Incoming" : "Outgoing"})",
// //   //             style: TextStyle(
// //   //               color: textColor,
// //   //               fontWeight: FontWeight.w600,
// //   //             ),
// //   //           ),
// //   //         ),
// //   //       ],
// //   //     );
// //   //   }
// //   //
// //   //   // 🖼️ IMAGE
// //   //   if (type == "image") {
// //   //     final localPath = msg["local_path"];
// //   //     final url = msg["url"];
// //   //     const w = 220.0, h = 260.0;
// //   //
// //   //     Widget imageChild;
// //   //     if (localPath != null) {
// //   //       imageChild =
// //   //           Image.file(File(localPath), width: w, height: h, fit: BoxFit.cover);
// //   //     } else if (url != null) {
// //   //       imageChild = Image.network(_resolveUrl(url)!,
// //   //           width: w, height: h, fit: BoxFit.cover);
// //   //     } else {
// //   //       imageChild = Container(
// //   //         width: w,
// //   //         height: h,
// //   //         color: Colors.grey,
// //   //         child: const Icon(Icons.image),
// //   //       );
// //   //     }
// //   //
// //   //     return ClipRRect(
// //   //         borderRadius: BorderRadius.circular(10), child: imageChild);
// //   //   }
// //   //
// //   //   // 🎥 VIDEO
// //   //   if (type == "video") {
// //   //     return Row(
// //   //       mainAxisSize: MainAxisSize.min,
// //   //       children: [
// //   //         const Icon(Icons.videocam),
// //   //         const SizedBox(width: 8),
// //   //         Text("Video", style: TextStyle(color: textColor)),
// //   //       ],
// //   //     );
// //   //   }
// //   //
// //   //   // 🎧 AUDIO
// //   //   if (type == "audio" || type == "voice") {
// //   //     return Row(
// //   //       mainAxisSize: MainAxisSize.min,
// //   //       children: [
// //   //         const Icon(Icons.audiotrack),
// //   //         const SizedBox(width: 8),
// //   //         Text(
// //   //           type == "voice" ? "Voice message" : "Audio",
// //   //           style: TextStyle(color: textColor),
// //   //         ),
// //   //       ],
// //   //     );
// //   //   }
// //   //
// //   //   // 📝 Normal Text
// //   //   return Text(
// //   //     text,
// //   //     style: TextStyle(
// //   //       color: textColor,
// //   //       fontSize: 15,
// //   //       fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
// //   //       fontWeight: isDeleted ? FontWeight.bold : FontWeight.normal,
// //   //     ),
// //   //   );
// //   // }
// //
// //
// //
// //   Widget _bubbleContent(Map<String, dynamic> msg, bool isOut) {
// //     final type = (msg["type"] ?? "text") as String;
// //     final text = (msg["text"] ?? "") as String;
// //     final bool isDeleted = msg["is_deleted"] == true;
// //
// //     // 🔴 deleted হলে টেক্সট লাল, না হলে আগের মতো
// //     final textColor =
// //     isDeleted ? Colors.red : (isOut ? Colors.white : Colors.black87);
// //
// //     // ==========================================
// //     // 📞 CALL MESSAGE
// //     // ==========================================
// //     if (type == "call" || type == "call_audio" || type == "call_video") {
// //       final status = msg["call_status"]?.toString() ?? "";
// //       final direction = msg["direction"]?.toString() ?? "";
// //       final bool isVideo = type == "call_video";
// //
// //       IconData icon;
// //       Color iconColor;
// //       String label;
// //
// //       if (status == "missed") {
// //         icon = isVideo ? Icons.videocam_off : Icons.call_missed;
// //         iconColor = Colors.redAccent;
// //         label = isVideo ? "Missed Video Call" : "Missed Voice Call";
// //       } else if (status == "ended") {
// //         icon = isVideo ? Icons.videocam : Icons.call_end;
// //         iconColor = Colors.green;
// //         label = isVideo ? "Video Call Ended" : "Voice Call Ended";
// //       } else if (status == "busy") {
// //         icon = isVideo ? Icons.videocam : Icons.call_end;
// //         iconColor = Colors.orange;
// //         label = isVideo ? "Video Call Busy" : "Voice Call Busy";
// //       } else {
// //         icon = isVideo ? Icons.videocam : Icons.phone;
// //         iconColor = Colors.blueGrey;
// //         label = isVideo ? "Video Call" : "Voice Call";
// //       }
// //
// //       // 🎨 Make nice row design
// //       return Container(
// //         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
// //         decoration: BoxDecoration(
// //           color: isOut ? Colors.white.withOpacity(0.1) : Colors.black12,
// //           borderRadius: BorderRadius.circular(8),
// //         ),
// //         child: Row(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             Icon(icon, color: iconColor, size: 20),
// //             const SizedBox(width: 6),
// //             Flexible(
// //               child: Text(
// //                 "$label (${direction == "incoming" ? "Incoming" : "Outgoing"})",
// //                 style: TextStyle(
// //                   color: textColor,
// //                   fontWeight: FontWeight.w600,
// //                   fontStyle:
// //                   isDeleted ? FontStyle.italic : FontStyle.normal,
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ),
// //       );
// //     }
// //
// //     // ==========================================
// //     // 🖼️ IMAGE
// //     // ==========================================
// //     if (type == "image") {
// //       final localPath = msg["local_path"];
// //       final url = msg["url"];
// //       const w = 220.0, h = 260.0;
// //
// //       Widget imageChild;
// //       if (localPath != null) {
// //         imageChild = Image.file(File(localPath),
// //             width: w, height: h, fit: BoxFit.cover);
// //       } else if (url != null) {
// //         imageChild = Image.network(
// //           _resolveUrl(url)!,
// //           width: w,
// //           height: h,
// //           fit: BoxFit.cover,
// //         );
// //       } else {
// //         imageChild = Container(
// //           width: w,
// //           height: h,
// //           color: Colors.grey,
// //           child: const Icon(Icons.image),
// //         );
// //       }
// //
// //       return ClipRRect(
// //           borderRadius: BorderRadius.circular(10), child: imageChild);
// //     }
// //
// //     // ==========================================
// //     // 🎥 VIDEO
// //     // ==========================================
// //     if (type == "video") {
// //       return Row(
// //         mainAxisSize: MainAxisSize.min,
// //         children: [
// //           const Icon(Icons.videocam, color: Colors.blue),
// //           const SizedBox(width: 8),
// //           Text("Video", style: TextStyle(color: textColor)),
// //         ],
// //       );
// //     }
// //
// //     // ==========================================
// //     // 🎧 AUDIO
// //     // ==========================================
// //     if (type == "audio" || type == "voice") {
// //       return Row(
// //         mainAxisSize: MainAxisSize.min,
// //         children: [
// //           const Icon(Icons.audiotrack, color: Colors.orangeAccent),
// //           const SizedBox(width: 8),
// //           Text(
// //             type == "voice" ? "Voice message" : "Audio",
// //             style: TextStyle(color: textColor),
// //           ),
// //         ],
// //       );
// //     }
// //
// //     // ==========================================
// //     // 📝 Normal Text
// //     // ==========================================
// //     return Text(
// //       text,
// //       style: TextStyle(
// //         color: textColor,
// //         fontSize: 15,
// //         fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
// //         fontWeight: isDeleted ? FontWeight.bold : FontWeight.normal,
// //       ),
// //     );
// //   }
// //
// //
// //
// //   // Widget _bubbleContent(Map<String, dynamic> msg, bool isOut) {
// //   //   final type = (msg["type"] ?? "text") as String;
// //   //   final text = (msg["text"] ?? "") as String;
// //   //
// //   //   if (type == "call") {
// //   //     final status = msg["call_status"]?.toString() ?? "";
// //   //     final direction = msg["direction"]?.toString() ?? "";
// //   //     IconData icon;
// //   //     Color color;
// //   //
// //   //     if (status == "missed") {
// //   //       icon = Icons.call_missed;
// //   //       color = Colors.red;
// //   //     } else if (status == "ended") {
// //   //       icon = Icons.call_end;
// //   //       color = Colors.green;
// //   //     } else if (status == "busy") {
// //   //       icon = Icons.call_end;
// //   //       color = Colors.orange;
// //   //     } else {
// //   //       icon = Icons.phone;
// //   //       color = Colors.blueGrey;
// //   //     }
// //   //
// //   //     return Row(
// //   //       mainAxisSize: MainAxisSize.min,
// //   //       children: [
// //   //         Icon(icon, color: color, size: 20),
// //   //         const SizedBox(width: 6),
// //   //         Flexible(
// //   //           child: Text(
// //   //             "$text (${direction == "incoming" ? "Incoming" : "Outgoing"})",
// //   //             style: TextStyle(
// //   //               color: isOut ? Colors.white : Colors.black87,
// //   //               fontWeight: FontWeight.w600,
// //   //             ),
// //   //           ),
// //   //         ),
// //   //       ],
// //   //     );
// //   //   }
// //   //
// //   //   if (type == "image") {
// //   //     final localPath = msg["local_path"];
// //   //     final url = msg["url"];
// //   //     const w = 220.0, h = 260.0;
// //   //     final uploading = msg["uploading"] == true;
// //   //     final progress = (msg["progress"] ?? 0.0) as num;
// //   //
// //   //     Widget imageChild;
// //   //     if (localPath != null) {
// //   //       imageChild = Image.file(File(localPath), width: w, height: h, fit: BoxFit.cover);
// //   //     } else if (url != null) {
// //   //       imageChild = Image.network(_resolveUrl(url)!, width: w, height: h, fit: BoxFit.cover);
// //   //     } else {
// //   //       imageChild = Container(width: w, height: h, color: Colors.grey, child: const Icon(Icons.image));
// //   //     }
// //   //
// //   //     return Stack(
// //   //       children: [
// //   //         ClipRRect(borderRadius: BorderRadius.circular(10), child: imageChild),
// //   //         if (uploading)
// //   //           Positioned.fill(
// //   //             child: Container(
// //   //               alignment: Alignment.bottomCenter,
// //   //               decoration: BoxDecoration(
// //   //                 color: Colors.black.withOpacity(0.1),
// //   //                 borderRadius: BorderRadius.circular(10),
// //   //               ),
// //   //               child: Padding(
// //   //                 padding: const EdgeInsets.all(8.0),
// //   //                 child: LinearProgressIndicator(
// //   //                   value: progress.clamp(0, 100) / 100.0,
// //   //                   minHeight: 5,
// //   //                 ),
// //   //               ),
// //   //             ),
// //   //           ),
// //   //       ],
// //   //     );
// //   //   }
// //   //
// //   //   if (type == "video") {
// //   //     return Row(
// //   //       mainAxisSize: MainAxisSize.min,
// //   //       children: [
// //   //         const Icon(Icons.videocam),
// //   //         const SizedBox(width: 8),
// //   //         Text("Video", style: TextStyle(color: isOut ? Colors.white : Colors.black87)),
// //   //       ],
// //   //     );
// //   //   }
// //   //
// //   //   if (type == "audio" || type == "voice") {
// //   //     return Row(
// //   //       mainAxisSize: MainAxisSize.min,
// //   //       children: [
// //   //         const Icon(Icons.audiotrack),
// //   //         const SizedBox(width: 8),
// //   //         Text(type == "voice" ? "Voice message" : "Audio",
// //   //             style: TextStyle(color: isOut ? Colors.white : Colors.black87)),
// //   //       ],
// //   //     );
// //   //   }
// //   //
// //   //   // text / file / sticker (basic)
// //   //   return Text(text, style: TextStyle(color: isOut ? Colors.white : Colors.black87, fontSize: 15));
// //   // }
// //
// //   // ================================
// //   // UI
// //   // ================================
// //   @override
// //   Widget build(BuildContext context) {
// //     final provider = Provider.of<TelegraphProvider>(context);
// //
// //     return Scaffold(
// //       backgroundColor: const Color(0xFFE5DDD5),
// //       appBar: AppBar(
// //         backgroundColor: const Color(0xFF008069),
// //         title: Row(children: [
// //           const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, color: Colors.black)),
// //           const SizedBox(width: 10),
// //           Text(widget.name, style: const TextStyle(color: Colors.white, fontSize: 18)),
// //           if (_typing)
// //             const Padding(
// //               padding: EdgeInsets.only(left: 8),
// //               child: Text("typing...", style: TextStyle(color: Colors.white70, fontSize: 12)),
// //             ),
// //         ]),
// //       ),
// //       body: _loading
// //           ? const Center(child: CircularProgressIndicator())
// //           : Column(children: [
// //         Expanded(
// //           child: ListView.builder(
// //             controller: _scrollController,
// //             reverse: true, // newest at top
// //             itemCount: provider.messages.length,
// //             itemBuilder: (context, i) {
// //               final msg = provider.messages[i];
// //               final isOut = msg["is_out"] == true;
// //               final time = (msg["time"] ?? "") as String;
// //
// //               return Align(
// //                 alignment: isOut ? Alignment.centerRight : Alignment.centerLeft,
// //                 child: Container(
// //                   margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
// //                   padding: const EdgeInsets.all(10),
// //                   decoration: BoxDecoration(
// //                     color: isOut ? Colors.green.shade400 : Colors.grey.shade300,
// //                     borderRadius: BorderRadius.circular(14),
// //                   ),
// //                   child: Column(
// //                     crossAxisAlignment: CrossAxisAlignment.end,
// //                     children: [
// //                       _bubbleContent(msg, isOut),
// //                       Padding(
// //                         padding: const EdgeInsets.only(top: 4),
// //                         child: Text(
// //                           time,
// //                           style: TextStyle(color: isOut ? Colors.white70 : Colors.grey[700], fontSize: 11),
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //               );
// //             },
// //           ),
// //         ),
// //         Container(
// //           color: Colors.white,
// //           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
// //           child: Row(children: [
// //             IconButton(icon: const Icon(Icons.attach_file, color: Colors.green), onPressed: _showAttachmentMenu),
// //             Expanded(
// //               child: TextField(
// //                 controller: _msgCtrl,
// //                 onChanged: (v) => _typingStart(),
// //                 onEditingComplete: _typingStop,
// //                 decoration: const InputDecoration(hintText: "Type a message", border: InputBorder.none),
// //               ),
// //             ),
// //             IconButton(
// //               icon: _sending
// //                   ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
// //                   : const Icon(Icons.send, color: Colors.green),
// //               onPressed: _sending ? null : _sendText,
// //             ),
// //           ]),
// //         ),
// //       ]),
// //     );
// //   }
// //
// //   void _showAttachmentMenu() {
// //     showModalBottomSheet(
// //       context: context,
// //       builder: (ctx) => SafeArea(
// //         child: Wrap(children: [
// //           ListTile(
// //             leading: const Icon(Icons.photo, color: Colors.green),
// //             title: const Text("Send Image"),
// //             onTap: () {
// //               Navigator.pop(ctx);
// //               _pickImage();
// //             },
// //           ),
// //           ListTile(
// //             leading: const Icon(Icons.videocam, color: Colors.green),
// //             title: const Text("Send Video"),
// //             onTap: () {
// //               Navigator.pop(ctx);
// //               _pickVideo();
// //             },
// //           ),
// //         ]),
// //       ),
// //     );
// //   }
// // }
// //
// //
// // // import 'dart:convert';
// // // import 'dart:io';
// // // import 'package:flutter/material.dart';
// // // import 'package:image_picker/image_picker.dart';
// // // import 'package:mime/mime.dart';
// // // import 'package:path/path.dart' as p;
// // // import 'package:permission_handler/permission_handler.dart';
// // // import 'package:provider/provider.dart';
// // // import '../providers/telegraph_qg_provider.dart';
// // //
// // // class ChatScreen extends StatefulWidget {
// // //   final String phone;
// // //   final int chatId;
// // //   final int accessHash;
// // //   final String name;
// // //   final String username;
// // //
// // //   const ChatScreen({
// // //     super.key,
// // //     required this.phone,
// // //     required this.chatId,
// // //     required this.accessHash,
// // //     required this.name,
// // //     required this.username,
// // //   });
// // //
// // //   @override
// // //   State<ChatScreen> createState() => _ChatScreenState();
// // // }
// // //
// // // class _ChatScreenState extends State<ChatScreen> {
// // //   final ScrollController _scrollController = ScrollController();
// // //   final TextEditingController _msgCtrl = TextEditingController();
// // //   final ImagePicker _picker = ImagePicker();
// // //   WebSocket? _socket;
// // //
// // //   bool _loading = true;
// // //   bool _sending = false;
// // //   bool _typing = false;
// // //   int? _uploadingMsgIndex;
// // //
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _fetchAndLoad();
// // //     _connectWebSocket();
// // //   }
// // //
// // //   @override
// // //   void dispose() {
// // //     _socket?.close();
// // //     super.dispose();
// // //   }
// // //
// // //   // ================================
// // //   // 🔌 WebSocket Connect
// // //   // ================================
// // //   Future<void> _connectWebSocket() async {
// // //     try {
// // //       _socket = await WebSocket.connect('ws://192.168.0.247:8080/chat_ws');
// // //       debugPrint("✅ WS Connected");
// // //
// // //       _socket!.add(jsonEncode({
// // //         "phone": widget.phone,
// // //         "chat_id": widget.chatId,
// // //         "access_hash": widget.accessHash,
// // //       }));
// // //
// // //       _socket!.listen((raw) {
// // //         if (!mounted) return;
// // //         final provider = Provider.of<TelegraphProvider>(context, listen: false);
// // //
// // //         try {
// // //           final data = jsonDecode(raw);
// // //
// // //           // Ignore heartbeat
// // //           if (data["action"] == "_hb") return;
// // //
// // //           // Typing events
// // //           if (data["action"] == "typing") {
// // //             setState(() => _typing = true);
// // //             return;
// // //           }
// // //           if (data["action"] == "typing_stopped") {
// // //             setState(() => _typing = false);
// // //             return;
// // //           }
// // //
// // //           // Upload progress
// // //           if (data["action"] == "upload_progress") {
// // //             if (_uploadingMsgIndex != null &&
// // //                 _uploadingMsgIndex! < provider.messages.length) {
// // //               provider.messages[_uploadingMsgIndex!]["progress"] = data["progress"];
// // //               provider.notifyListeners();
// // //             }
// // //             return;
// // //           }
// // //
// // //           // Status/listening
// // //           if (data["status"] == "listening") return;
// // //
// // //           // Primary message
// // //           if (data.containsKey("id")) {
// // //             final mediaType = data["media_type"] ?? "text";
// // //             provider.messages.insert(0, {
// // //               "id": data["id"],
// // //               "text": data["text"] ?? "",
// // //               "is_out": data["is_out"] ?? false,
// // //               "time": data["date"] ?? DateTime.now().toString(),
// // //               "type": mediaType,
// // //               "url": data["media_link"],
// // //             });
// // //             provider.notifyListeners();
// // //           }
// // //         } catch (e) {
// // //           debugPrint("⚠️ WS parse error: $e");
// // //         }
// // //       }, onDone: () {
// // //         Future.delayed(const Duration(seconds: 3), _connectWebSocket);
// // //       }, onError: (err) {
// // //         Future.delayed(const Duration(seconds: 5), _connectWebSocket);
// // //       });
// // //     } catch (e) {
// // //       Future.delayed(const Duration(seconds: 5), _connectWebSocket);
// // //     }
// // //   }
// // //
// // //   // ================================
// // //   // 📨 Load messages
// // //   // ================================
// // //   Future<void> _fetchAndLoad() async {
// // //     final provider = Provider.of<TelegraphProvider>(context, listen: false);
// // //     await provider.fetchMessages(widget.phone, widget.chatId, widget.accessHash);
// // //     setState(() => _loading = false);
// // //   }
// // //
// // //   // ================================
// // //   // ✉️ Send text
// // //   // ================================
// // //   Future<void> _sendText() async {
// // //     final text = _msgCtrl.text.trim();
// // //     if (text.isEmpty) return;
// // //
// // //     setState(() => _sending = true);
// // //     final provider = Provider.of<TelegraphProvider>(context, listen: false);
// // //
// // //     final payload = {
// // //       "action": "send",
// // //       "phone": widget.phone,
// // //       "chat_id": widget.chatId,
// // //       "access_hash": widget.accessHash,
// // //       "text": text,
// // //     };
// // //
// // //     try {
// // //       _socket?.add(jsonEncode(payload));
// // //       provider.messages.insert(0, {
// // //         "text": text,
// // //         "is_out": true,
// // //         "time": DateTime.now().toString(),
// // //         "type": "text",
// // //       });
// // //       provider.notifyListeners();
// // //       _msgCtrl.clear();
// // //     } catch (e) {
// // //       debugPrint("⚠️ send text error: $e");
// // //     } finally {
// // //       setState(() => _sending = false);
// // //     }
// // //   }
// // //
// // //   // ================================
// // //   // Typing events
// // //   // ================================
// // //   void _typingStart() {
// // //     if (_socket?.readyState == WebSocket.open) {
// // //       _socket!.add(jsonEncode({
// // //         "action": "typing_start",
// // //         "phone": widget.phone,
// // //         "chat_id": widget.chatId
// // //       }));
// // //     }
// // //   }
// // //
// // //   void _typingStop() {
// // //     if (_socket?.readyState == WebSocket.open) {
// // //       _socket!.add(jsonEncode({
// // //         "action": "typing_stop",
// // //         "phone": widget.phone,
// // //         "chat_id": widget.chatId
// // //       }));
// // //     }
// // //   }
// // //
// // //   // ================================
// // //   // Picker & Send File
// // //   // ================================
// // //   Future<void> _ensurePerms() async {
// // //     await [Permission.camera, Permission.photos, Permission.storage].request();
// // //   }
// // //
// // //   Future<void> _pickImage() async {
// // //     await _ensurePerms();
// // //     final img = await _picker.pickImage(source: ImageSource.gallery);
// // //     if (img != null) await _sendFile(File(img.path));
// // //   }
// // //
// // //   Future<void> _pickVideo() async {
// // //     await _ensurePerms();
// // //     final vid = await _picker.pickVideo(source: ImageSource.gallery);
// // //     if (vid != null) await _sendFile(File(vid.path));
// // //   }
// // //
// // //   Future<void> _sendFile(File file) async {
// // //     try {
// // //       final bytes = await file.readAsBytes();
// // //       final b64 = base64Encode(bytes);
// // //       final fileName = p.basename(file.path);
// // //       final mime = lookupMimeType(file.path) ?? "application/octet-stream";
// // //
// // //       final provider = Provider.of<TelegraphProvider>(context, listen: false);
// // //       provider.messages.insert(0, {
// // //         "text": "",
// // //         "is_out": true,
// // //         "time": DateTime.now().toString(),
// // //         "type": mime.startsWith('image/') ? "image" : "file",
// // //         "local_path": file.path,
// // //         "uploading": true,
// // //         "progress": 0.0,
// // //       });
// // //       provider.notifyListeners();
// // //       _uploadingMsgIndex = 0;
// // //
// // //       _socket?.add(jsonEncode({
// // //         "action": "send",
// // //         "phone": widget.phone,
// // //         "chat_id": widget.chatId,
// // //         "access_hash": widget.accessHash,
// // //         "file_name": fileName,
// // //         "file_base64": b64,
// // //         "mime_type": mime,
// // //       }));
// // //     } catch (e) {
// // //       debugPrint("⚠️ send file error: $e");
// // //     }
// // //   }
// // //
// // //   void _showAttachmentMenu() {
// // //     showModalBottomSheet(
// // //       context: context,
// // //       builder: (ctx) => SafeArea(
// // //         child: Wrap(children: [
// // //           ListTile(
// // //             leading: const Icon(Icons.photo, color: Colors.green),
// // //             title: const Text("Send Image"),
// // //             onTap: () {
// // //               Navigator.pop(ctx);
// // //               _pickImage();
// // //             },
// // //           ),
// // //           ListTile(
// // //             leading: const Icon(Icons.videocam, color: Colors.green),
// // //             title: const Text("Send Video"),
// // //             onTap: () {
// // //               Navigator.pop(ctx);
// // //               _pickVideo();
// // //             },
// // //           ),
// // //         ]),
// // //       ),
// // //     );
// // //   }
// // //
// // //   // ================================
// // //   // Message Bubble
// // //   // ================================
// // //
// // //   Widget _bubbleContent(Map<String, dynamic> msg, bool isOut) {
// // //     final type = msg["type"] ?? "text";
// // //     final text = msg["text"] ?? "";
// // //
// // //     if (type == "call") {
// // //       final status = msg["call_status"] ?? "";
// // //       final direction = msg["direction"] ?? "";
// // //       IconData icon;
// // //       Color color;
// // //
// // //       if (status == "missed") {
// // //         icon = Icons.call_missed;
// // //         color = Colors.red;
// // //       } else if (status == "ended") {
// // //         icon = Icons.call_end;
// // //         color = Colors.green;
// // //       } else if (status == "busy") {
// // //         icon = Icons.call_end;
// // //         color = Colors.orange;
// // //       } else {
// // //         icon = Icons.phone;
// // //         color = Colors.blueGrey;
// // //       }
// // //
// // //       return Row(
// // //         mainAxisSize: MainAxisSize.min,
// // //         children: [
// // //           Icon(icon, color: color, size: 20),
// // //           const SizedBox(width: 6),
// // //           Text(
// // //             "$text (${direction == "incoming" ? "Incoming" : "Outgoing"})",
// // //             style: TextStyle(
// // //               color: isOut ? Colors.white : Colors.black87,
// // //               fontWeight: FontWeight.w500,
// // //             ),
// // //           ),
// // //         ],
// // //       );
// // //     }
// // //
// // //     if (type == "image") {
// // //       final localPath = msg["local_path"];
// // //       final url = msg["url"];
// // //       final w = 220.0, h = 260.0;
// // //       return ClipRRect(
// // //         borderRadius: BorderRadius.circular(10),
// // //         child: localPath != null
// // //             ? Image.file(File(localPath), width: w, height: h, fit: BoxFit.cover)
// // //             : (url != null
// // //             ? Image.network(url, width: w, height: h, fit: BoxFit.cover)
// // //             : Container(
// // //           width: w,
// // //           height: h,
// // //           color: Colors.grey,
// // //           child: const Icon(Icons.image),
// // //         )),
// // //       );
// // //     }
// // //
// // //     return Text(
// // //       text,
// // //       style: TextStyle(color: isOut ? Colors.white : Colors.black87, fontSize: 15),
// // //     );
// // //   }
// // //   // Widget _bubbleContent(Map<String, dynamic> msg, bool isOut) {
// // //   //   final type = msg["type"] ?? "text";
// // //   //   final text = msg["text"] ?? "";
// // //   //
// // //   //   if (type == "image") {
// // //   //     final localPath = msg["local_path"];
// // //   //     final url = msg["url"];
// // //   //     return ClipRRect(
// // //   //       borderRadius: BorderRadius.circular(10),
// // //   //       child: localPath != null
// // //   //           ? Image.file(File(localPath), width: 220, height: 260, fit: BoxFit.cover)
// // //   //           : (url != null
// // //   //           ? Image.network(url, width: 220, height: 260, fit: BoxFit.cover)
// // //   //           : Container(width: 220, height: 260, color: Colors.grey, child: const Icon(Icons.image))),
// // //   //     );
// // //   //   }
// // //   //
// // //   //   return Text(
// // //   //     text,
// // //   //     style: TextStyle(color: isOut ? Colors.white : Colors.black87, fontSize: 15),
// // //   //   );
// // //   // }
// // //
// // //   // ================================
// // //   // UI
// // //   // ================================
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final provider = Provider.of<TelegraphProvider>(context);
// // //
// // //     return Scaffold(
// // //       backgroundColor: const Color(0xFFE5DDD5),
// // //       appBar: AppBar(
// // //         backgroundColor: const Color(0xFF008069),
// // //         title: Row(children: [
// // //           const CircleAvatar(
// // //               backgroundColor: Colors.white,
// // //               child: Icon(Icons.person, color: Colors.black)),
// // //           const SizedBox(width: 10),
// // //           Text(widget.name, style: const TextStyle(color: Colors.white, fontSize: 18)),
// // //           if (_typing)
// // //             const Padding(
// // //               padding: EdgeInsets.only(left: 8),
// // //               child: Text("typing...", style: TextStyle(color: Colors.white70, fontSize: 12)),
// // //             ),
// // //         ]),
// // //       ),
// // //       body: _loading
// // //           ? const Center(child: CircularProgressIndicator())
// // //           : Column(children: [
// // //         Expanded(
// // //           child: ListView.builder(
// // //             controller: _scrollController,
// // //             reverse: true,
// // //             itemCount: provider.messages.length,
// // //             itemBuilder: (context, i) {
// // //               final msg = provider.messages[i];
// // //               final isOut = msg["is_out"] == true;
// // //               final time = msg["time"] ?? "";
// // //
// // //               return Align(
// // //                 alignment: isOut ? Alignment.centerRight : Alignment.centerLeft,
// // //                 child: Container(
// // //                   margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
// // //                   padding: const EdgeInsets.all(10),
// // //                   decoration: BoxDecoration(
// // //                     color: isOut ? Colors.green.shade400 : Colors.grey.shade300,
// // //                     borderRadius: BorderRadius.circular(14),
// // //                   ),
// // //                   child: Column(
// // //                     crossAxisAlignment: CrossAxisAlignment.end,
// // //                     children: [
// // //                       _bubbleContent(msg, isOut),
// // //                       Padding(
// // //                         padding: const EdgeInsets.only(top: 4),
// // //                         child: Text(time,
// // //                             style: TextStyle(color: isOut ? Colors.white70 : Colors.grey[700], fontSize: 11)),
// // //                       ),
// // //                     ],
// // //                   ),
// // //                 ),
// // //               );
// // //             },
// // //           ),
// // //         ),
// // //         Container(
// // //           color: Colors.white,
// // //           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
// // //           child: Row(children: [
// // //             IconButton(
// // //               icon: const Icon(Icons.attach_file, color: Colors.green),
// // //               onPressed: _showAttachmentMenu,
// // //             ),
// // //             Expanded(
// // //               child: TextField(
// // //                 controller: _msgCtrl,
// // //                 onChanged: (v) => _typingStart(),
// // //                 onEditingComplete: _typingStop,
// // //                 decoration: const InputDecoration(
// // //                   hintText: "Type a message",
// // //                   border: InputBorder.none,
// // //                 ),
// // //               ),
// // //             ),
// // //             IconButton(
// // //               icon: _sending
// // //                   ? const CircularProgressIndicator()
// // //                   : const Icon(Icons.send, color: Colors.green),
// // //               onPressed: _sendText,
// // //             ),
// // //           ]),
// // //         ),
// // //       ]),
// // //     );
// // //   }
// // // }
// //
// //
//
// //
// // import 'dart:async';
// // import 'dart:convert';
// // import 'dart:io';
// // import 'dart:math';
// //
// // import 'package:flutter/material.dart';
// // import 'package:image_picker/image_picker.dart';
// // import 'package:mime/mime.dart';
// //
// // class ChatScreen extends StatefulWidget {
// //   final String phone;      // e.g. "+88017..." (server normalize করবে)
// //   final int chatId;
// //   final int? accessHash;   // optional
// //   final String name;
// //   final String username;
// //
// //   const ChatScreen({
// //     super.key,
// //     required this.phone,
// //     required this.chatId,
// //     required this.accessHash,
// //     required this.name,
// //     required this.username,
// //   });
// //
// //   @override
// //   State<ChatScreen> createState() => _ChatScreenState();
// // }
// //
// // // ================================
// // // ✅ CHANGE THESE IF NEEDED
// // // ================================
// // const String _API_BASE = 'http://192.168.0.247:8080';
// // const String _WS_URL   = 'ws://192.168.0.247:8080/chat_ws';
// //
// // class _ChatScreenState extends State<ChatScreen> {
// //   // ---- Transport
// //   WebSocket? _ws;
// //   bool _connecting = false;
// //   int _reconnectAttempt = 0;
// //   Timer? _pingTimer;
// //   Timer? _reconnectTimer;
// //
// //   // ---- Typing
// //   bool _typing = false;
// //   Timer? _typingUiTtl;           // auto off if server silent
// //   Timer? _typingSendDebounce;    // client-side debounce
// //
// //   // ---- UI + Data
// //   final TextEditingController _textCtrl = TextEditingController();
// //   final ScrollController _scrollCtrl = ScrollController();
// //   final ImagePicker _picker = ImagePicker();
// //
// //   final List<Msg> _messages = [];                  // oldest → newest
// //   final Map<int, Msg> _byId = {};                  // msg_id → Msg
// //   final Map<String, int> _pendingIndexByTemp = {}; // temp_id → index
// //   final Set<String> _seenIds = {};                 // for de-dupe
// //
// //   bool _loading = true;
// //   bool _sending = false;
// //   bool _manuallyClosed = false;
// //
// //   // utils
// //   String get _clientInstance => 'ci-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1<<32)}';
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _fetchInitial();
// //     _connectWs();
// //   }
// //
// //   @override
// //   void dispose() {
// //     _manuallyClosed = true;
// //     _pingTimer?.cancel();
// //     _reconnectTimer?.cancel();
// //     _typingUiTtl?.cancel();
// //     _typingSendDebounce?.cancel();
// //     _ws?.close();
// //     _textCtrl.dispose();
// //     _scrollCtrl.dispose();
// //     super.dispose();
// //   }
// //
// //   // ================================
// //   // REST: load initial history (Mongo-first)
// //   // ================================
// //   Future<void> _fetchInitial() async {
// //     try {
// //       // order=asc দিলে server উল্টো (desc) রিটার্ন করে; যেটাই আসুক আমরা শেষে sort করে নেব
// //       final uri = Uri.parse(
// //         '$_API_BASE/messages'
// //             '?phone=+${Uri.encodeQueryComponent(widget.phone)}'
// //             '&chat_id=${widget.chatId}'
// //             '${widget.accessHash != null ? '&access_hash=${widget.accessHash}' : ''}'
// //
// //       );
// //       print(uri);
// //       print('kkk11234565855552');
// //
// //       final http = HttpClient();
// //       final req = await http.getUrl(uri);
// //       final res = await req.close();
// //       final body = await res.transform(utf8.decoder).join();
// //       final jsonBody = jsonDecode(body) as Map<String, dynamic>;
// //       final List arr = (jsonBody['messages'] as List?) ?? const [];
// //
// //       // server order-এর উপর নির্ভর না করে normalize করে ফেলি (oldest→newest)
// //       final List<Msg> temp = [];
// //       for (final it in arr) {
// //         final msg = Msg.fromApiMap(it as Map<String, dynamic>, widget.phone, widget.chatId);
// //         temp.add(msg);
// //       }
// //       temp.sort((a, b) => a.date.compareTo(b.date));
// //
// //       // index & seen
// //       _messages.clear();
// //       _byId.clear();
// //       _seenIds.clear();
// //       for (final m in temp) {
// //         _messages.add(m);
// //         if (m.id != null) {
// //           _byId[m.id!] = m;
// //           _seenIds.add('id:${m.id}');
// //         }
// //       }
// //       setState(() => _loading = false);
// //       _scrollToBottomSoon();
// //     } catch (e) {
// //       debugPrint('REST fetch error: $e');
// //       setState(() => _loading = false);
// //     }
// //   }
// //
// //   // ================================
// //   // WebSocket connect + keepalive + reconnect
// //   // ================================
// //   Future<void> _connectWs() async {
// //     if (_connecting) return;
// //     _connecting = true;
// //
// //     try {
// //       _ws = await WebSocket.connect(_WS_URL);
// //       _reconnectAttempt = 0;
// //
// //       // handshake: MUST be 1st frame
// //       _ws!.add(jsonEncode({
// //         'phone': widget.phone,
// //         'chat_id': widget.chatId,
// //         if (widget.accessHash != null) 'access_hash': widget.accessHash,
// //       }));
// //
// //       // keep-alive ping
// //       _pingTimer?.cancel();
// //       _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
// //         if (_ws?.readyState == WebSocket.open) {
// //           _ws!.add(jsonEncode({'action': 'ping'}));
// //         }
// //       });
// //
// //       _ws!.listen(
// //             (dynamic raw) => _onWsFrame(raw),
// //         onDone: _scheduleReconnect,
// //         onError: (err) {
// //           debugPrint('WS error: $err');
// //           _scheduleReconnect();
// //         },
// //         cancelOnError: true,
// //       );
// //     } catch (e) {
// //       _scheduleReconnect();
// //     } finally {
// //       _connecting = false;
// //     }
// //   }
// //
// //   void _scheduleReconnect([_]) {
// //     if (_manuallyClosed) return;
// //     _pingTimer?.cancel();
// //     _reconnectAttempt++;
// //     final delay = Duration(seconds: min(30, 1 << _reconnectAttempt));
// //     _reconnectTimer?.cancel();
// //     _reconnectTimer = Timer(delay, _connectWs);
// //   }
// //
// //   // ================================
// //   // WS frame handler (bytes or string)
// //   // ================================
// //   void _onWsFrame(dynamic raw) {
// //     if (!mounted) return;
// //     String s;
// //     if (raw is String) {
// //       s = raw;
// //     } else if (raw is List<int>) {
// //       s = utf8.decode(raw);
// //     } else {
// //       return;
// //     }
// //
// //     Map<String, dynamic> m;
// //     try {
// //       m = jsonDecode(s) as Map<String, dynamic>;
// //     } catch (_) {
// //       return;
// //     }
// //
// //     if (m['action'] == '_hb' || m['status'] == 'pong') return;
// //
// //     // errors
// //     if (m['status'] == 'error') {
// //       _toast('WS error: ${m['detail'] ?? ''}');
// //       return;
// //     }
// //
// //     switch (m['action']) {
// //       case 'seed':
// //         _handleSeed((m['messages'] as List?) ?? const []);
// //         return;
// //
// //       case 'typing':
// //         setState(() => _typing = true);
// //         _typingUiTtl?.cancel();
// //         _typingUiTtl = Timer(const Duration(seconds: 6), () {
// //           if (mounted) setState(() => _typing = false);
// //         });
// //         return;
// //
// //       case 'typing_stopped':
// //         _typingUiTtl?.cancel();
// //         setState(() => _typing = false);
// //         return;
// //
// //       case 'upload_progress':
// //         _handleUploadProgress(m);
// //         return;
// //
// //       case 'send_queued':
// //         _handleSendQueued(m);
// //         return;
// //
// //       case 'send_done':
// //         _handleSendDone(m);
// //         return;
// //
// //       case 'send_failed':
// //         _handleSendFailed(m);
// //         return;
// //
// //       case 'new_message':
// //       // fall-through to default mapping
// //         break;
// //     }
// //
// //     // generic new message / any payload with id/msg_id/temp_id
// //     if (m.containsKey('id') || m.containsKey('msg_id') || m.containsKey('temp_id')) {
// //       final msg = Msg.fromWsMap(m, widget.phone, widget.chatId);
// //       _insertOrUpdate(msg, fromRealtime: true);
// //     }
// //   }
// //
// //   // ---- seed
// //   void _handleSeed(List arr) {
// //     bool changed = false;
// //     for (final it in arr) {
// //       final msg = Msg.fromWsMap(it as Map<String, dynamic>, widget.phone, widget.chatId);
// //       // seed typically newest-last; we’ll insert & resort
// //       changed |= _insertOrUpdate(msg);
// //     }
// //     if (changed) {
// //       _messages.sort((a, b) => a.date.compareTo(b.date));
// //       setState(() {});
// //       _scrollToBottomSoon();
// //     }
// //   }
// //
// //   // ---- upload progress
// //   void _handleUploadProgress(Map<String, dynamic> m) {
// //     final tempId = m['temp_id']?.toString();
// //     final prog = (m['progress'] is num) ? (m['progress'] as num).toDouble() : null;
// //     if (tempId == null || prog == null) return;
// //
// //     final idx = _pendingIndexByTemp[tempId];
// //     if (idx != null && idx >= 0 && idx < _messages.length) {
// //       _messages[idx].uploadProgress = prog.clamp(0, 100);
// //       setState(() {});
// //     }
// //   }
// //
// //   // ---- send_queued: bind pending → temp_id
// //   void _handleSendQueued(Map<String, dynamic> m) {
// //     final tempId = m['temp_id']?.toString();
// //     final mediaType = (m['media_type'] ?? 'text').toString();
// //     if (tempId == null) return;
// //
// //     // find first pending bubble without temp_id
// //     final i = _messages.indexWhere((x) => x.pending && (x.tempId == null));
// //     if (i != -1) {
// //       _messages[i].tempId = tempId;
// //       _pendingIndexByTemp[tempId] = i;
// //       _messages[i].mediaType = mediaType;
// //       setState(() {});
// //     }
// //   }
// //
// //   // ---- send_done: finalize
// //   void _handleSendDone(Map<String, dynamic> m) {
// //     final tempId = m['temp_id']?.toString();
// //     final msgId = (m['msg_id'] is int) ? m['msg_id'] as int : int.tryParse(m['msg_id']?.toString() ?? '');
// //     if (tempId == null) return;
// //
// //     final i = _pendingIndexByTemp[tempId] ?? _messages.indexWhere((x) => x.tempId == tempId);
// //     if (i != -1) {
// //       final item = _messages[i];
// //       item.id = msgId ?? item.id;
// //       item.pending = false;
// //       item.existsOnTelegram = true;
// //       item.uploading = false;
// //       item.uploadProgress = 100;
// //       if (item.id != null) {
// //         _byId[item.id!] = item;
// //         _seenIds.add('id:${item.id}');
// //       }
// //       _pendingIndexByTemp.remove(tempId);
// //       setState(() {});
// //       _scrollToBottomSoon();
// //     }
// //   }
// //
// //   void _handleSendFailed(Map<String, dynamic> m) {
// //     final tempId = m['temp_id']?.toString();
// //     final i = tempId == null ? -1 : (_pendingIndexByTemp[tempId] ?? _messages.indexWhere((x) => x.tempId == tempId));
// //     if (i != -1) {
// //       final item = _messages[i];
// //       item.pending = false;
// //       item.failed = true;
// //       item.uploading = false;
// //       setState(() {});
// //     }
// //     _toast('Send failed: ${m['detail'] ?? ''}');
// //   }
// //
// //   // ================================
// //   // Insert / Update (by msg_id or temp_id)
// //   // ================================
// //   bool _insertOrUpdate(Msg m, {bool fromRealtime = false}) {
// //     // attach media_link fallback if needed
// //     if (m.needsMediaUrlFallback) {
// //       m.mediaLink = _buildMediaUrlFallback(m);
// //     }
// //
// //     if (m.id != null) {
// //       final exist = _byId[m.id!];
// //       if (exist != null) {
// //         exist.mergeFrom(m);
// //         return true;
// //       }
// //       // de-dupe by final id
// //       if (_seenIds.contains('id:${m.id}')) return false;
// //       _seenIds.add('id:${m.id}');
// //       _byId[m.id!] = m;
// //       _messages.add(m);
// //       if (fromRealtime) _scrollToBottomSoon();
// //       return true;
// //     }
// //
// //     if (m.tempId != null) {
// //       // update pending
// //       final i = _pendingIndexByTemp[m.tempId!] ?? _messages.indexWhere((x) => x.tempId == m.tempId);
// //       if (i != -1) {
// //         _messages[i].mergeFrom(m);
// //         return true;
// //       }
// //       // brand new queued (rare)
// //       _pendingIndexByTemp[m.tempId!] = _messages.length;
// //       _messages.add(m);
// //       if (fromRealtime) _scrollToBottomSoon();
// //       return true;
// //     }
// //
// //     // no id/temp → just append (shouldn't happen normally)
// //     _messages.add(m);
// //     return true;
// //   }
// //
// //   String _buildMediaUrlFallback(Msg m) {
// //     // ডকে লেখা: media_fs_id থাকলে /message_media থেকে serve হবে।
// //     // সাধারণ fallback pattern (server ইমপ্লিমেন্ট অনুযায়ী adjust করতে পারো):
// //     // /message_media?phone=...&chat_id=...&msg_id=...
// //     return '$_API_BASE/message_media'
// //         '?phone=${Uri.encodeQueryComponent(widget.phone)}'
// //         '&chat_id=${m.chatId}'
// //         '&msg_id=${m.id ?? 0}';
// //   }
// //
// //   // ================================
// //   // Actions - send / typing / image
// //   // ================================
// //   void _sendTypingStart() {
// //     _typingSendDebounce?.cancel();
// //     if (_ws?.readyState == WebSocket.open) {
// //       _ws!.add(jsonEncode({'action': 'typing_start'}));
// //     }
// //     _typingSendDebounce = Timer(const Duration(seconds: 2), _sendTypingStop);
// //   }
// //
// //   void _sendTypingStop() {
// //     if (_ws?.readyState == WebSocket.open) {
// //       _ws!.add(jsonEncode({'action': 'typing_stop'}));
// //     }
// //   }
// //
// //   Future<void> _sendText() async {
// //     final t = _textCtrl.text.trim();
// //     if (t.isEmpty) return;
// //
// //     setState(() => _sending = true);
// //
// //     // optimistic pending
// //     final pending = Msg.pendingText(
// //       text: t,
// //       isOut: true,
// //       username: widget.username,
// //     );
// //     _messages.add(pending);
// //     _scrollToBottomSoon();
// //     setState(() {});
// //
// //     final payload = {
// //       'action': 'send',
// //       'text': t,
// //       // কিছু সার্ভার older build-এ এগুলো চাইতে পারে
// //       'phone': widget.phone,
// //       'chat_id': widget.chatId,
// //       if (widget.accessHash != null) 'access_hash': widget.accessHash,
// //       'client_instance': _clientInstance,
// //       'client_tmp': pending.localClientTmp,
// //     };
// //
// //     try {
// //       _ws?.add(jsonEncode(payload));
// //       _textCtrl.clear();
// //     } catch (e) {
// //       pending.failed = true;
// //       pending.pending = false;
// //       setState(() {});
// //       _toast('Send error: $e');
// //     } finally {
// //       if (mounted) setState(() => _sending = false);
// //     }
// //   }
// //
// //   Future<void> _sendImage() async {
// //     try {
// //       final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 92);
// //       if (picked == null) return;
// //
// //       final bytes = await picked.readAsBytes();
// //       final b64 = base64Encode(bytes);
// //       final mime = lookupMimeType(picked.name) ?? 'image/jpeg';
// //
// //       final pending = Msg.pendingMedia(
// //         mediaType: 'image',
// //         caption: '',
// //         isOut: true,
// //         username: widget.username,
// //       );
// //       _messages.add(pending);
// //       _scrollToBottomSoon();
// //       setState(() {});
// //
// //       final payload = {
// //         'action': 'send',
// //         'text': '', // caption optional
// //         'file_base64': b64,        // raw base64 OK (server data:URI ও নেয়)
// //         'file_name': picked.name,
// //         'mime_type': mime,
// //         'phone': widget.phone,
// //         'chat_id': widget.chatId,
// //         if (widget.accessHash != null) 'access_hash': widget.accessHash,
// //         'client_instance': _clientInstance,
// //         'client_tmp': pending.localClientTmp,
// //       };
// //
// //       _ws?.add(jsonEncode(payload));
// //     } catch (e) {
// //       _toast('Image send error: $e');
// //     }
// //   }
// //
// //   // ================================
// //   // UI helpers
// //   // ================================
// //   void _toast(String msg) {
// //     if (!mounted) return;
// //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
// //   }
// //
// //   void _scrollToBottomSoon() {
// //     WidgetsBinding.instance.addPostFrameCallback((_) {
// //       if (!_scrollCtrl.hasClients) return;
// //       _scrollCtrl.animateTo(
// //         _scrollCtrl.position.maxScrollExtent + 80,
// //         duration: const Duration(milliseconds: 220),
// //         curve: Curves.easeOut,
// //       );
// //     });
// //   }
// //
// //   // ================================
// //   // BUILD
// //   // ================================
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         titleSpacing: 0,
// //         title: Row(
// //           children: [
// //             const CircleAvatar(child: Icon(Icons.person)),
// //             const SizedBox(width: 8),
// //             Expanded(
// //               child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
// //                 Text(widget.name, style: const TextStyle(fontWeight: FontWeight.w600)),
// //                 Text(_typing ? 'typing…' : 'online', style: Theme.of(context).textTheme.bodySmall),
// //               ]),
// //             ),
// //           ],
// //         ),
// //         actions: [
// //           IconButton(
// //             icon: const Icon(Icons.refresh),
// //             onPressed: () {
// //               _ws?.close();
// //               _connectWs();
// //             },
// //           ),
// //         ],
// //       ),
// //       body: Column(
// //         children: [
// //           Expanded(
// //             child: _loading
// //                 ? const Center(child: CircularProgressIndicator())
// //                 : ListView.builder(
// //               controller: _scrollCtrl,
// //               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
// //               itemCount: _messages.length,
// //               itemBuilder: (_, i) {
// //                 final m = _messages[i];
// //                 return _MessageBubble(
// //                   key: ValueKey('msg-${m.id ?? m.tempId ?? i}'),
// //                   msg: m,
// //                   findById: (id) => _byId[id],
// //                 );
// //               },
// //             ),
// //           ),
// //           _composer(),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Widget _composer() {
// //     final canSend = _textCtrl.text.trim().isNotEmpty && !_sending;
// //
// //     return SafeArea(
// //       top: false,
// //       child: Container(
// //         color: const Color(0xFFF7F7F7),
// //         padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
// //         child: Row(
// //           children: [
// //             IconButton(onPressed: _sendImage, icon: const Icon(Icons.attach_file)),
// //             Expanded(
// //               child: TextField(
// //                 controller: _textCtrl,
// //                 minLines: 1,
// //                 maxLines: 5,
// //                 onChanged: (_) => _sendTypingStart(),
// //                 decoration: const InputDecoration(isDense: true, hintText: 'Message', border: OutlineInputBorder()),
// //               ),
// //             ),
// //             const SizedBox(width: 8),
// //             SizedBox(
// //               width: 40,
// //               height: 40,
// //               child: Material(
// //                 color: canSend ? const Color(0xFF2AABEE) : const Color(0xFFB3E5FC),
// //                 shape: const CircleBorder(),
// //                 child: InkWell(
// //                   customBorder: const CircleBorder(),
// //                   onTap: canSend ? _sendText : null,
// //                   child: Center(
// //                     child: _sending
// //                         ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
// //                         : IconButton(onPressed: _sending ? null : _sendText, icon: const Icon(Icons.send)),
// //                   ),
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// // // ================================
// // // MODEL
// // // ================================
// // class Msg {
// //   int? id;                  // msg_id (final)
// //   String? tempId;           // send_queued
// //   final String? localClientTmp; // local optimistic tag
// //   String text;
// //   DateTime date;
// //   bool isOut;
// //   int? replyTo;
// //   String mediaType;         // text|image|video|audio|voice|sticker|file|call_audio|call_video
// //   String? mediaLink;
// //   bool deletedOnTelegram;
// //   bool existsOnTelegram;
// //
// //   // UI meta
// //   bool pending;
// //   bool failed;
// //   bool uploading;
// //   double uploadProgress;
// //
// //   final int chatId;         // for fallback url
// //
// //   Msg({
// //     required this.id,
// //     required this.tempId,
// //     required this.localClientTmp,
// //     required this.text,
// //     required this.date,
// //     required this.isOut,
// //     required this.replyTo,
// //     required this.mediaType,
// //     required this.mediaLink,
// //     required this.deletedOnTelegram,
// //     required this.existsOnTelegram,
// //     required this.pending,
// //     required this.failed,
// //     required this.uploading,
// //     required this.uploadProgress,
// //     required this.chatId,
// //   });
// //
// //   bool get needsMediaUrlFallback =>
// //       mediaLink == null &&
// //           (mediaType == 'image' || mediaType == 'video' || mediaType == 'audio' || mediaType == 'voice' || mediaType == 'file') &&
// //           id != null;
// //
// //   // ---- REST (/messages)
// //   factory Msg.fromApiMap(Map<String, dynamic> m, String phone, int chatId) {
// //     final id = (m['msg_id'] is int) ? m['msg_id'] as int : int.tryParse(m['msg_id']?.toString() ?? '');
// //     final mediaType = (m['media_type'] ?? 'text').toString();
// //
// //     return Msg(
// //       id: id,
// //       tempId: null,
// //       localClientTmp: null,
// //       text: (m['text'] ?? '').toString(),
// //       date: _parseIso(m['date']),
// //       isOut: (m['is_out'] == true) || (m['direction']?.toString() == 'out'),
// //       replyTo: (m['reply_to'] is int) ? m['reply_to'] as int : null,
// //       mediaType: mediaType,
// //       mediaLink: null, // REST-এ সাধারনত media_link থাকে না; fallback ইউআরএল বানাবো
// //       deletedOnTelegram: m['deleted_on_telegram'] == true,
// //       existsOnTelegram: m['exists_on_telegram'] != false,
// //       pending: false,
// //       failed: false,
// //       uploading: false,
// //       uploadProgress: 0.0,
// //       chatId: chatId,
// //     );
// //   }
// //
// //   // ---- WS (seed/new_message/send_queued/send_done)
// //   factory Msg.fromWsMap(Map<String, dynamic> m, String phone, int chatId) {
// //     final id = (m['id'] is int) ? m['id'] as int
// //         : (m['msg_id'] is int ? m['msg_id'] as int : int.tryParse(m['id']?.toString() ?? ''));
// //     final tempId = m['temp_id']?.toString();
// //
// //     final mediaType = (m['media_type'] ?? 'text').toString();
// //     return Msg(
// //       id: id,
// //       tempId: tempId,
// //       localClientTmp: null,
// //       text: (m['text'] ?? '').toString(),
// //       date: _parseIso(m['date']),
// //       isOut: (m['is_out'] == true) || (m['direction']?.toString() == 'out'),
// //       replyTo: (m['reply_to'] is int) ? m['reply_to'] as int : null,
// //       mediaType: mediaType,
// //       mediaLink: (m['media_link']?.toString()),
// //       deletedOnTelegram: m['deleted_on_telegram'] == true,
// //       existsOnTelegram: m['exists_on_telegram'] != false,
// //       pending: false,
// //       failed: false,
// //       uploading: false,
// //       uploadProgress: 0.0,
// //       chatId: chatId,
// //     );
// //   }
// //
// //   // ---- Optimistic pending creators
// //   factory Msg.pendingText({required String text, required bool isOut, required String username}) {
// //     final tmp = 'local-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1<<32)}';
// //     return Msg(
// //       id: null,
// //       tempId: null, // send_queued এ বসবে
// //       localClientTmp: tmp,
// //       text: text,
// //       date: DateTime.now().toUtc(),
// //       isOut: isOut,
// //       replyTo: null,
// //       mediaType: 'text',
// //       mediaLink: null,
// //       deletedOnTelegram: false,
// //       existsOnTelegram: false,
// //       pending: true,
// //       failed: false,
// //       uploading: false,
// //       uploadProgress: 0.0,
// //       chatId: 0,
// //     );
// //   }
// //
// //   factory Msg.pendingMedia({required String mediaType, required String caption, required bool isOut, required String username}) {
// //     final tmp = 'local-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1<<32)}';
// //     return Msg(
// //       id: null,
// //       tempId: null,
// //       localClientTmp: tmp,
// //       text: caption,
// //       date: DateTime.now().toUtc(),
// //       isOut: isOut,
// //       replyTo: null,
// //       mediaType: mediaType,
// //       mediaLink: null,
// //       deletedOnTelegram: false,
// //       existsOnTelegram: false,
// //       pending: true,
// //       failed: false,
// //       uploading: true,
// //       uploadProgress: 0.0,
// //       chatId: 0,
// //     );
// //   }
// //
// //   void mergeFrom(Msg other) {
// //     id = other.id ?? id;
// //     tempId = other.tempId ?? tempId;
// //     text = other.text.isNotEmpty ? other.text : text;
// //     date = other.date;
// //     isOut = other.isOut;
// //     replyTo = other.replyTo ?? replyTo;
// //     mediaType = other.mediaType.isNotEmpty ? other.mediaType : mediaType;
// //     mediaLink = other.mediaLink ?? mediaLink;
// //     deletedOnTelegram = other.deletedOnTelegram;
// //     existsOnTelegram = other.existsOnTelegram;
// //     pending = other.pending;
// //     failed = other.failed;
// //     uploading = other.uploading;
// //     uploadProgress = other.uploadProgress != 0.0 ? other.uploadProgress : uploadProgress;
// //   }
// // }
// //
// // // ================================
// // // BUBBLE
// // // ================================
// // class _MessageBubble extends StatelessWidget {
// //   final Msg msg;
// //   final Msg? Function(int id) findById;
// //
// //   const _MessageBubble({super.key, required this.msg, required this.findById});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final isOut = msg.isOut;
// //     return Padding(
// //       padding: const EdgeInsets.symmetric(vertical: 4),
// //       child: Row(
// //         mainAxisAlignment: isOut ? MainAxisAlignment.end : MainAxisAlignment.start,
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           if (!isOut) const SizedBox(width: 36),
// //           _bubbleCore(context),
// //           if (isOut) const SizedBox(width: 36),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Widget _bubbleCore(BuildContext context) {
// //     final ghost = (msg.existsOnTelegram == false) || msg.pending;
// //     final color = msg.failed
// //         ? Colors.red.shade200
// //         : (msg.isOut ? Colors.blue.shade100 : Colors.grey.shade200);
// //
// //     return ConstrainedBox(
// //       constraints: const BoxConstraints(maxWidth: 320),
// //       child: Container(
// //         padding: const EdgeInsets.all(10),
// //         decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
// //         child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
// //           if (msg.replyTo != null)
// //             _ReplyPreview(
// //               id: msg.replyTo!,
// //               text: findById(msg.replyTo!)?.text ?? '',
// //               mediaType: findById(msg.replyTo!)?.mediaType ?? 'text',
// //             ),
// //           _body(context, ghost),
// //           const SizedBox(height: 6),
// //           Row(mainAxisSize: MainAxisSize.min, children: [
// //             Text(_fmtTime(msg.date), style: const TextStyle(fontSize: 10, color: Colors.black54)),
// //             const SizedBox(width: 6),
// //             if (msg.pending) const Icon(Icons.schedule, size: 12, color: Colors.black45),
// //             if (msg.failed) const Icon(Icons.error_outline, size: 12, color: Colors.redAccent),
// //           ]),
// //         ]),
// //       ),
// //     );
// //   }
// //
// //   Widget _body(BuildContext context, bool ghost) {
// //     final t = msg.mediaType;
// //     if (t == 'text') {
// //       return SelectableText(
// //         msg.text.isEmpty ? '[empty]' : msg.text,
// //         style: TextStyle(
// //           fontSize: 15,
// //           fontStyle: ghost ? FontStyle.italic : FontStyle.normal,
// //           color: ghost ? Colors.black54 : Colors.black87,
// //         ),
// //       );
// //     }
// //     if (t == 'image') {
// //       final url = msg.mediaLink;
// //       if (url == null || url.isEmpty) {
// //         return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
// //           _progressBarIfUploading(),
// //           const Text('[image uploading…]'),
// //         ]);
// //       }
// //       return ClipRRect(
// //         borderRadius: BorderRadius.circular(10),
// //         child: Stack(
// //           children: [
// //             Image.network(url, width: 240, height: 180, fit: BoxFit.cover),
// //             if (ghost) Positioned.fill(child: ColoredBox(color: Colors.white.withOpacity(0.25))),
// //             if (msg.uploading) Positioned.fill(child: Align(alignment: Alignment.bottomCenter, child: _progressBarIfUploading())),
// //           ],
// //         ),
// //       );
// //     }
// //     if (t == 'video' || t == 'audio' || t == 'voice' || t == 'file' || t == 'sticker') {
// //       return Row(mainAxisSize: MainAxisSize.min, children: [
// //         const Icon(Icons.attach_file),
// //         const SizedBox(width: 6),
// //         Text('[$t] tap to open'),
// //         if (msg.uploading) ...[
// //           const SizedBox(width: 10),
// //           _progressBarIfUploading(),
// //         ],
// //       ]);
// //     }
// //     if (t == 'call_audio' || t == 'call_video') {
// //       final label = t == 'call_video' ? 'Video call' : 'Voice call';
// //       return Row(mainAxisSize: MainAxisSize.min, children: [
// //         Icon(t == 'call_video' ? Icons.videocam : Icons.call),
// //         const SizedBox(width: 6),
// //         Text(label),
// //       ]);
// //     }
// //     return Text('[${msg.mediaType}] ${msg.text}');
// //   }
// //
// //   Widget _progressBarIfUploading() {
// //     return Column(
// //       mainAxisSize: MainAxisSize.min,
// //       children: [
// //         SizedBox(
// //           width: 160,
// //           child: LinearProgressIndicator(
// //             value: (msg.uploadProgress > 0 && msg.uploadProgress <= 100) ? msg.uploadProgress / 100.0 : null,
// //           ),
// //         ),
// //         const SizedBox(height: 4),
// //         Text('${msg.uploadProgress.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 10)),
// //       ],
// //     );
// //   }
// //
// //   String _fmtTime(DateTime dt) {
// //     final h = dt.toLocal().hour.toString().padLeft(2, '0');
// //     final m = dt.toLocal().minute.toString().padLeft(2, '0');
// //     return '$h:$m';
// //   }
// // }
// //
// // class _ReplyPreview extends StatelessWidget {
// //   final int id;
// //   final String text;
// //   final String mediaType;
// //   const _ReplyPreview({required this.id, required this.text, required this.mediaType});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final isText = mediaType == 'text';
// //     final label = isText ? (text.isEmpty ? '[text]' : text) : '[$mediaType]';
// //     return Container(
// //       padding: const EdgeInsets.all(8),
// //       margin: const EdgeInsets.only(bottom: 6),
// //       decoration: BoxDecoration(
// //         color: Colors.white.withOpacity(0.6),
// //         borderRadius: BorderRadius.circular(8),
// //         border: Border.all(color: Colors.black12),
// //       ),
// //       child: Row(mainAxisSize: MainAxisSize.min, children: [
// //         const Icon(Icons.subdirectory_arrow_right, size: 16, color: Colors.black54),
// //         const SizedBox(width: 6),
// //         Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.black87)),
// //         const SizedBox(width: 6),
// //         Text('#$id', style: const TextStyle(fontSize: 11, color: Colors.black45)),
// //       ]),
// //     );
// //   }
// // }
// //
// // // ================================
// // // Utils
// // // ================================
// // DateTime _parseIso(dynamic v) {
// //   if (v is String) { try { return DateTime.parse(v).toUtc(); } catch (_) {} }
// //   return DateTime.now().toUtc();
// // }
//
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
//
// class ChatScreen extends StatefulWidget {
//   final String phone;      // e.g. "+88017..." (server will normalize)
//   final int chatId;
//   final int? accessHash;   // optional
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
// // ================================
// // ✅ CHANGE THESE IF NEEDED
// // ================================
// const String _API_BASE = 'http://192.168.0.247:8080';
// const String _WS_URL   = 'ws://192.168.0.247:8080/chat_ws';
//
// class _ChatScreenState extends State<ChatScreen> {
//   // ---- Transport
//   WebSocket? _ws;
//   bool _connecting = false;
//   int _reconnectAttempt = 0;
//   Timer? _pingTimer;
//   Timer? _reconnectTimer;
//
//   // ---- Typing
//   bool _typing = false;
//   Timer? _typingUiTtl;           // auto off if server silent
//   Timer? _typingSendDebounce;    // client-side debounce
//
//   // ---- UI + Data
//   final TextEditingController _textCtrl = TextEditingController();
//   final ScrollController _scrollCtrl = ScrollController();
//   final ImagePicker _picker = ImagePicker();
//
//   final List<Msg> _messages = [];                  // oldest → newest
//   final Map<int, Msg> _byId = {};                  // msg_id → Msg
//   final Map<String, int> _pendingIndexByTemp = {}; // temp_id → index
//   final Set<String> _seenIds = {};                 // for de-dupe
//
//   bool _loading = true;
//   bool _sending = false;
//   bool _manuallyClosed = false;
//
//   // utils
//   String get _clientInstance => 'ci-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1<<32)}';
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchInitial();
//     _connectWs();
//   }
//
//   @override
//   void dispose() {
//     _manuallyClosed = true;
//     _pingTimer?.cancel();
//     _reconnectTimer?.cancel();
//     _typingUiTtl?.cancel();
//     _typingSendDebounce?.cancel();
//     _ws?.close();
//     _textCtrl.dispose();
//     _scrollCtrl.dispose();
//     super.dispose();
//   }
//
//   // ================================
//   // REST: load initial history (Mongo-first)
//   // ================================
//   Future<void> _fetchInitial() async {
//     try {
//       final uri = Uri.parse(
//         '$_API_BASE/messages'
//             '?phone=${Uri.encodeQueryComponent(widget.phone)}' // ✅ no extra '+'; pass as-is
//             '&chat_id=${widget.chatId}'
//             '${widget.accessHash != null ? '&access_hash=${widget.accessHash}' : ''}'
//       );
//
//       final http = HttpClient();
//       final req = await http.getUrl(uri);
//       final res = await req.close();
//       final body = await res.transform(utf8.decoder).join();
//       final jsonBody = jsonDecode(body) as Map<String, dynamic>;
//       final List arr = (jsonBody['messages'] as List?) ?? const [];
//
//       // Normalize to oldest→newest and use _insertOrUpdate so media fallback applies
//       _messages.clear();
//       _byId.clear();
//       _seenIds.clear();
//
//       final List<Msg> temp = [];
//       for (final it in arr) {
//         final msg = Msg.fromApiMap(it as Map<String, dynamic>, widget.phone, widget.chatId);
//         temp.add(msg);
//       }
//       temp.sort((a, b) => a.date.compareTo(b.date));
//
//       for (final m in temp) {
//         _insertOrUpdate(m); // ensures mediaLink fallback is set
//       }
//
//       setState(() => _loading = false);
//       _scrollToBottomSoon();
//     } catch (e) {
//       debugPrint('REST fetch error: $e');
//       setState(() => _loading = false);
//     }
//   }
//
//   // ================================
//   // WebSocket connect + keepalive + reconnect
//   // ================================
//   Future<void> _connectWs() async {
//     if (_connecting) return;
//     _connecting = true;
//
//     try {
//       _ws = await WebSocket.connect(_WS_URL);
//       _reconnectAttempt = 0;
//
//       // handshake: MUST be 1st frame
//       _ws!.add(jsonEncode({
//         'phone': widget.phone,
//         'chat_id': widget.chatId,
//         if (widget.accessHash != null) 'access_hash': widget.accessHash,
//         'client_instance': _clientInstance, // ⭐ important for some servers
//       }));
//
//       // keep-alive ping
//       _pingTimer?.cancel();
//       _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
//         if (_ws?.readyState == WebSocket.open) {
//           _ws!.add(jsonEncode({'action': 'ping'}));
//         }
//       });
//
//       _ws!.listen(
//             (dynamic raw) => _onWsFrame(raw),
//         onDone: _scheduleReconnect,
//         onError: (err) {
//           debugPrint('WS error: $err');
//           _scheduleReconnect();
//         },
//         cancelOnError: true,
//       );
//     } catch (e) {
//       _scheduleReconnect();
//     } finally {
//       _connecting = false;
//     }
//   }
//
//   void _scheduleReconnect([_]) {
//     if (_manuallyClosed) return;
//     _pingTimer?.cancel();
//     _reconnectAttempt++;
//     final delay = Duration(seconds: min(30, 1 << _reconnectAttempt));
//     _reconnectTimer?.cancel();
//     _reconnectTimer = Timer(delay, _connectWs);
//   }
//
//   // ================================
//   // WS frame handler (bytes or string)
//   // ================================
//   void _onWsFrame(dynamic raw) {
//     if (!mounted) return;
//     String s;
//     if (raw is String) {
//       s = raw;
//     } else if (raw is List<int>) {
//       s = utf8.decode(raw);
//     } else {
//       return;
//     }
//
//     Map<String, dynamic> m;
//     try {
//       m = jsonDecode(s) as Map<String, dynamic>;
//     } catch (_) {
//       return;
//     }
//
//     if (m['action'] == '_hb' || m['status'] == 'pong') return;
//
//     // errors
//     if (m['status'] == 'error') {
//       _toast('WS error: ${m['detail'] ?? ''}');
//       return;
//     }
//
//     switch (m['action']) {
//       case 'seed':
//         _handleSeed((m['messages'] as List?) ?? const []);
//         return;
//
//       case 'typing':
//         setState(() => _typing = true);
//         _typingUiTtl?.cancel();
//         _typingUiTtl = Timer(const Duration(seconds: 6), () {
//           if (mounted) setState(() => _typing = false);
//         });
//         return;
//
//       case 'typing_stopped':
//         _typingUiTtl?.cancel();
//         setState(() => _typing = false);
//         return;
//
//       case 'upload_progress':
//         _handleUploadProgress(m);
//         return;
//
//       case 'send_queued':
//         _handleSendQueued(m);
//         return;
//
//       case 'send_done':
//         _handleSendDone(m);
//         return;
//
//       case 'send_failed':
//         _handleSendFailed(m);
//         return;
//
//       case 'new_message': {
//         // ⭐ nested-safe extraction (message/data/payload/messages or root)
//         final list = _extractMessageMaps(m);
//         final changed = _ingestAll(list, fromRealtime: true);
//         if (changed) {
//           setState(() {});
//           _scrollToBottomSoon();
//         }
//         return;
//       }
//     }
//
//     // generic fallback: root-level shape with id/msg_id/temp_id
//     if (m.containsKey('id') || m.containsKey('msg_id') || m.containsKey('temp_id')) {
//       final msg = Msg.fromWsMap(m, widget.phone, widget.chatId);
//       final changed = _insertOrUpdate(msg, fromRealtime: true);
//       if (changed) {
//         setState(() {});
//         _scrollToBottomSoon();
//       }
//     }
//   }
//
//   // ⭐ nested new_message extractors
//   List<Map<String, dynamic>> _extractMessageMaps(Map<String, dynamic> m) {
//     final List<Map<String, dynamic>> out = [];
//     final candidates = [m['message'], m['data'], m['payload'], m['messages']];
//
//     for (final cand in candidates) {
//       if (cand is Map<String, dynamic>) {
//         out.add(cand);
//       } else if (cand is List) {
//         for (final it in cand) {
//           if (it is Map<String, dynamic>) out.add(it);
//         }
//       }
//     }
//
//     // If still empty, try root if it looks like a message
//     if (out.isEmpty && (m.containsKey('id') || m.containsKey('msg_id') || m.containsKey('temp_id'))) {
//       out.add(m);
//     }
//     return out;
//   }
//
//   bool _ingestAll(List<Map<String, dynamic>> list, {bool fromRealtime = false}) {
//     bool changed = false;
//     for (final mm in list) {
//       final msg = Msg.fromWsMap(mm, widget.phone, widget.chatId);
//       changed |= _insertOrUpdate(msg, fromRealtime: fromRealtime);
//     }
//     return changed;
//   }
//
//   // ---- seed
//   void _handleSeed(List arr) {
//     bool changed = false;
//     for (final it in arr) {
//       final msg = Msg.fromWsMap(it as Map<String, dynamic>, widget.phone, widget.chatId);
//       // seed typically newest-last; we’ll insert & resort
//       changed |= _insertOrUpdate(msg);
//     }
//     if (changed) {
//       _messages.sort((a, b) => a.date.compareTo(b.date));
//       setState(() {});
//       _scrollToBottomSoon();
//     }
//   }
//
//   // ---- upload progress
//   void _handleUploadProgress(Map<String, dynamic> m) {
//     final tempId = m['temp_id']?.toString();
//     final prog = (m['progress'] is num) ? (m['progress'] as num).toDouble() : null;
//     if (tempId == null || prog == null) return;
//
//     final idx = _pendingIndexByTemp[tempId];
//     if (idx != null && idx >= 0 && idx < _messages.length) {
//       _messages[idx].uploadProgress = prog.clamp(0, 100);
//       setState(() {});
//     }
//   }
//
//   // ---- send_queued: bind pending → temp_id
//   void _handleSendQueued(Map<String, dynamic> m) {
//     final tempId = m['temp_id']?.toString();
//     final mediaType = (m['media_type'] ?? 'text').toString();
//     if (tempId == null) return;
//
//     // find first pending bubble without temp_id
//     final i = _messages.indexWhere((x) => x.pending && (x.tempId == null));
//     if (i != -1) {
//       _messages[i].tempId = tempId;
//       _pendingIndexByTemp[tempId] = i;
//       _messages[i].mediaType = mediaType;
//       setState(() {});
//     }
//   }
//
//   // ---- send_done: finalize
//   void _handleSendDone(Map<String, dynamic> m) {
//     final tempId = m['temp_id']?.toString();
//     final msgId = (m['msg_id'] is int) ? m['msg_id'] as int : int.tryParse(m['msg_id']?.toString() ?? '');
//     if (tempId == null) return;
//
//     final i = _pendingIndexByTemp[tempId] ?? _messages.indexWhere((x) => x.tempId == tempId);
//     if (i != -1) {
//       final item = _messages[i];
//       item.id = msgId ?? item.id;
//       item.pending = false;
//       item.existsOnTelegram = true;
//       item.uploading = false;
//       item.uploadProgress = 100;
//       if (item.id != null) {
//         _byId[item.id!] = item;
//         _seenIds.add('id:${item.id}');
//       }
//       _pendingIndexByTemp.remove(tempId);
//       setState(() {});
//       _scrollToBottomSoon();
//     }
//   }
//
//   void _handleSendFailed(Map<String, dynamic> m) {
//     final tempId = m['temp_id']?.toString();
//     final i = tempId == null ? -1 : (_pendingIndexByTemp[tempId] ?? _messages.indexWhere((x) => x.tempId == tempId));
//     if (i != -1) {
//       final item = _messages[i];
//       item.pending = false;
//       item.failed = true;
//       item.uploading = false;
//       setState(() {});
//     }
//     _toast('Send failed: ${m['detail'] ?? ''}');
//   }
//
//   // ================================
//   // Insert / Update (by msg_id or temp_id)
//   // ================================
//   bool _insertOrUpdate(Msg m, {bool fromRealtime = false}) {
//     // attach media_link fallback if needed
//     if (m.needsMediaUrlFallback) {
//       m.mediaLink = _buildMediaUrlFallback(m);
//     }
//
//     if (m.id != null) {
//       final exist = _byId[m.id!];
//       if (exist != null) {
//         exist.mergeFrom(m);
//         return true;
//       }
//       // de-dupe by final id
//       if (_seenIds.contains('id:${m.id}')) return false;
//       _seenIds.add('id:${m.id}');
//       _byId[m.id!] = m;
//       _messages.add(m);
//       if (fromRealtime) _scrollToBottomSoon();
//       return true;
//     }
//
//     if (m.tempId != null) {
//       // update pending
//       final i = _pendingIndexByTemp[m.tempId!] ?? _messages.indexWhere((x) => x.tempId == m.tempId);
//       if (i != -1) {
//         _messages[i].mergeFrom(m);
//         return true;
//       }
//       // brand new queued (rare)
//       _pendingIndexByTemp[m.tempId!] = _messages.length;
//       _messages.add(m);
//       if (fromRealtime) _scrollToBottomSoon();
//       return true;
//     }
//
//     // no id/temp → just append (shouldn't happen normally)
//     _messages.add(m);
//     return true;
//   }
//
//   String _buildMediaUrlFallback(Msg m) {
//     // When media_fs_id exists on server, /message_media should serve it.
//     // Generic fallback pattern (tune if your server differs):
//     // /message_media?phone=...&chat_id=...&msg_id=...
//     return '$_API_BASE/message_media'
//         '?phone=${Uri.encodeQueryComponent(widget.phone)}'
//         '&chat_id=${m.chatId}'
//         '&msg_id=${m.id ?? 0}';
//   }
//
//   // ================================
//   // Actions - send / typing / image
//   // ================================
//   void _sendTypingStart() {
//     _typingSendDebounce?.cancel();
//     if (_ws?.readyState == WebSocket.open) {
//       _ws!.add(jsonEncode({
//         'action': 'typing_start',
//         'phone': widget.phone,
//         'chat_id': widget.chatId,
//       }));
//     }
//     _typingSendDebounce = Timer(const Duration(seconds: 2), _sendTypingStop);
//   }
//
//   void _sendTypingStop() {
//     if (_ws?.readyState == WebSocket.open) {
//       _ws!.add(jsonEncode({
//         'action': 'typing_stop',
//         'phone': widget.phone,
//         'chat_id': widget.chatId,
//       }));
//     }
//   }
//
//   Future<void> _sendText() async {
//     final t = _textCtrl.text.trim();
//     if (t.isEmpty) return;
//
//     setState(() => _sending = true);
//
//     // optimistic pending
//     final pending = Msg.pendingText(
//       text: t,
//       isOut: true,
//       username: widget.username,
//     );
//     _messages.add(pending);
//     _scrollToBottomSoon();
//     setState(() {});
//
//     final payload = {
//       'action': 'send',
//       'text': t,
//       'phone': widget.phone,
//       'chat_id': widget.chatId,
//       if (widget.accessHash != null) 'access_hash': widget.accessHash,
//       'client_instance': _clientInstance,
//       'client_tmp': pending.localClientTmp,
//     };
//
//     try {
//       _ws?.add(jsonEncode(payload));
//       _textCtrl.clear();
//     } catch (e) {
//       pending.failed = true;
//       pending.pending = false;
//       setState(() {});
//       _toast('Send error: $e');
//     } finally {
//       if (mounted) setState(() => _sending = false);
//     }
//   }
//
//   Future<void> _sendImage() async {
//     try {
//       final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 92);
//       if (picked == null) return;
//
//       final bytes = await picked.readAsBytes();
//       final b64 = base64Encode(bytes);
//       final mime = lookupMimeType(picked.name) ?? 'image/jpeg';
//
//       final pending = Msg.pendingMedia(
//         mediaType: 'image',
//         caption: '',
//         isOut: true,
//         username: widget.username,
//       );
//       _messages.add(pending);
//       _scrollToBottomSoon();
//       setState(() {});
//
//       final payload = {
//         'action': 'send',
//         'text': '',
//         'file_base64': b64,        // raw base64 OK (server accepts data:URI too)
//         'file_name': picked.name,
//         'mime_type': mime,
//         'phone': widget.phone,
//         'chat_id': widget.chatId,
//         if (widget.accessHash != null) 'access_hash': widget.accessHash,
//         'client_instance': _clientInstance,
//         'client_tmp': pending.localClientTmp,
//       };
//
//       _ws?.add(jsonEncode(payload));
//     } catch (e) {
//       _toast('Image send error: $e');
//     }
//   }
//
//   // ================================
//   // UI helpers
//   // ================================
//   void _toast(String msg) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
//   }
//
//   void _scrollToBottomSoon() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (!_scrollCtrl.hasClients) return;
//       _scrollCtrl.animateTo(
//         _scrollCtrl.position.maxScrollExtent + 80,
//         duration: const Duration(milliseconds: 220),
//         curve: Curves.easeOut,
//       );
//     });
//   }
//
//   // ================================
//   // BUILD
//   // ================================
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         titleSpacing: 0,
//         title: Row(
//           children: [
//             const CircleAvatar(child: Icon(Icons.person)),
//             const SizedBox(width: 8),
//             Expanded(
//               child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
//                 Text(widget.name, style: const TextStyle(fontWeight: FontWeight.w600)),
//                 Text(_typing ? 'typing…' : 'online', style: Theme.of(context).textTheme.bodySmall),
//               ]),
//             ),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: () {
//               _ws?.close();
//               _connectWs();
//             },
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: _loading
//                 ? const Center(child: CircularProgressIndicator())
//                 : ListView.builder(
//               controller: _scrollCtrl,
//               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//               itemCount: _messages.length,
//               itemBuilder: (_, i) {
//                 final m = _messages[i];
//                 return _MessageBubble(
//                   key: ValueKey('msg-${m.id ?? m.tempId ?? i}'),
//                   msg: m,
//                   findById: (id) => _byId[id],
//                 );
//               },
//             ),
//           ),
//           _composer(),
//         ],
//       ),
//     );
//   }
//
//   Widget _composer() {
//     final canSend = _textCtrl.text.trim().isNotEmpty && !_sending;
//
//     return SafeArea(
//       top: false,
//       child: Container(
//         color: const Color(0xFFF7F7F7),
//         padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
//         child: Row(
//           children: [
//             IconButton(onPressed: _sendImage, icon: const Icon(Icons.attach_file)),
//             Expanded(
//               child: TextField(
//                 controller: _textCtrl,
//                 minLines: 1,
//                 maxLines: 5,
//                 onChanged: (_) => _sendTypingStart(),
//                 onEditingComplete: _sendTypingStop,
//                 decoration: const InputDecoration(isDense: true, hintText: 'Message', border: OutlineInputBorder()),
//               ),
//             ),
//             const SizedBox(width: 8),
//             SizedBox(
//               width: 40,
//               height: 40,
//               child: Material(
//                 color: canSend ? const Color(0xFF2AABEE) : const Color(0xFFB3E5FC),
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
//                         valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                       ),
//                     )
//                         : IconButton(onPressed: _sending ? null : _sendText, icon: const Icon(Icons.send)),
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
// // ================================
// // MODEL
// // ================================
// class Msg {
//   int? id;                  // msg_id (final)
//   String? tempId;           // send_queued
//   final String? localClientTmp; // local optimistic tag
//   String text;
//   DateTime date;
//   bool isOut;
//   int? replyTo;
//   String mediaType;         // text|image|video|audio|voice|sticker|file|call_audio|call_video
//   String? mediaLink;
//   bool deletedOnTelegram;
//   bool existsOnTelegram;
//
//   // UI meta
//   bool pending;
//   bool failed;
//   bool uploading;
//   double uploadProgress;
//
//   final int chatId;         // for fallback url
//
//   Msg({
//     required this.id,
//     required this.tempId,
//     required this.localClientTmp,
//     required this.text,
//     required this.date,
//     required this.isOut,
//     required this.replyTo,
//     required this.mediaType,
//     required this.mediaLink,
//     required this.deletedOnTelegram,
//     required this.existsOnTelegram,
//     required this.pending,
//     required this.failed,
//     required this.uploading,
//     required this.uploadProgress,
//     required this.chatId,
//   });
//
//   bool get needsMediaUrlFallback =>
//       mediaLink == null &&
//           (mediaType == 'image' || mediaType == 'video' || mediaType == 'audio' || mediaType == 'voice' || mediaType == 'file') &&
//           id != null;
//
//   // ---- REST (/messages)
//   factory Msg.fromApiMap(Map<String, dynamic> m, String phone, int chatId) {
//     final id = (m['msg_id'] is int) ? m['msg_id'] as int : int.tryParse(m['msg_id']?.toString() ?? '');
//     final mediaType = (m['media_type'] ?? 'text').toString();
//
//     return Msg(
//       id: id,
//       tempId: null,
//       localClientTmp: null,
//       text: (m['text'] ?? '').toString(),
//       date: _parseIso(m['date']),
//       isOut: (m['is_out'] == true) || (m['direction']?.toString() == 'out'),
//       replyTo: (m['reply_to'] is int) ? m['reply_to'] as int : null,
//       mediaType: mediaType,
//       mediaLink: null, // REST usually doesn't include media_link; we build fallback
//       deletedOnTelegram: m['deleted_on_telegram'] == true,
//       existsOnTelegram: m['exists_on_telegram'] != false,
//       pending: false,
//       failed: false,
//       uploading: false,
//       uploadProgress: 0.0,
//       chatId: chatId,
//     );
//   }
//
//   // ---- WS (seed/new_message/send_queued/send_done)
//   factory Msg.fromWsMap(Map<String, dynamic> m, String phone, int chatId) {
//     final id = (m['id'] is int)
//         ? m['id'] as int
//         : (m['msg_id'] is int ? m['msg_id'] as int : int.tryParse(m['id']?.toString() ?? ''));
//     final tempId = m['temp_id']?.toString();
//
//     final mediaType = (m['media_type'] ?? 'text').toString();
//     return Msg(
//       id: id,
//       tempId: tempId,
//       localClientTmp: null,
//       text: (m['text'] ?? '').toString(),
//       date: _parseIso(m['date']),
//       isOut: (m['is_out'] == true) || (m['direction']?.toString() == 'out'),
//       replyTo: (m['reply_to'] is int) ? m['reply_to'] as int : null,
//       mediaType: mediaType,
//       mediaLink: (m['media_link']?.toString()),
//       deletedOnTelegram: m['deleted_on_telegram'] == true,
//       existsOnTelegram: m['exists_on_telegram'] != false,
//       pending: false,
//       failed: false,
//       uploading: false,
//       uploadProgress: 0.0,
//       chatId: chatId,
//     );
//   }
//
//   // ---- Optimistic pending creators
//   factory Msg.pendingText({required String text, required bool isOut, required String username}) {
//     final tmp = 'local-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1<<32)}';
//     return Msg(
//       id: null,
//       tempId: null, // send_queued will fill
//       localClientTmp: tmp,
//       text: text,
//       date: DateTime.now().toUtc(),
//       isOut: isOut,
//       replyTo: null,
//       mediaType: 'text',
//       mediaLink: null,
//       deletedOnTelegram: false,
//       existsOnTelegram: false,
//       pending: true,
//       failed: false,
//       uploading: false,
//       uploadProgress: 0.0,
//       chatId: 0,
//     );
//   }
//
//   factory Msg.pendingMedia({required String mediaType, required String caption, required bool isOut, required String username}) {
//     final tmp = 'local-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1<<32)}';
//     return Msg(
//       id: null,
//       tempId: null,
//       localClientTmp: tmp,
//       text: caption,
//       date: DateTime.now().toUtc(),
//       isOut: isOut,
//       replyTo: null,
//       mediaType: mediaType,
//       mediaLink: null,
//       deletedOnTelegram: false,
//       existsOnTelegram: false,
//       pending: true,
//       failed: false,
//       uploading: true,
//       uploadProgress: 0.0,
//       chatId: 0,
//     );
//   }
//
//   void mergeFrom(Msg other) {
//     id = other.id ?? id;
//     tempId = other.tempId ?? tempId;
//     text = other.text.isNotEmpty ? other.text : text;
//     date = other.date;
//     isOut = other.isOut;
//     replyTo = other.replyTo ?? replyTo;
//     mediaType = other.mediaType.isNotEmpty ? other.mediaType : mediaType;
//     mediaLink = other.mediaLink ?? mediaLink;
//     deletedOnTelegram = other.deletedOnTelegram;
//     existsOnTelegram = other.existsOnTelegram;
//     pending = other.pending;
//     failed = other.failed;
//     uploading = other.uploading;
//     uploadProgress = other.uploadProgress != 0.0 ? other.uploadProgress : uploadProgress;
//   }
// }
//
// // ================================
// // BUBBLE
// // ================================
// class _MessageBubble extends StatelessWidget {
//   final Msg msg;
//   final Msg? Function(int id) findById;
//
//   const _MessageBubble({super.key, required this.msg, required this.findById});
//
//   @override
//   Widget build(BuildContext context) {
//     final isOut = msg.isOut;
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         mainAxisAlignment: isOut ? MainAxisAlignment.end : MainAxisAlignment.start,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           if (!isOut) const SizedBox(width: 36),
//           _bubbleCore(context),
//           if (isOut) const SizedBox(width: 36),
//         ],
//       ),
//     );
//   }
//
//   Widget _bubbleCore(BuildContext context) {
//     final ghost = (msg.existsOnTelegram == false) || msg.pending;
//     final color = msg.failed
//         ? Colors.red.shade200
//         : (msg.isOut ? Colors.blue.shade100 : Colors.grey.shade200);
//
//     return ConstrainedBox(
//       constraints: const BoxConstraints(maxWidth: 320),
//       child: Container(
//         padding: const EdgeInsets.all(10),
//         decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
//         child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//           if (msg.replyTo != null)
//             _ReplyPreview(
//               id: msg.replyTo!,
//               text: findById(msg.replyTo!)?.text ?? '',
//               mediaType: findById(msg.replyTo!)?.mediaType ?? 'text',
//             ),
//           _body(context, ghost),
//           const SizedBox(height: 6),
//           Row(mainAxisSize: MainAxisSize.min, children: [
//             Text(_fmtTime(msg.date), style: const TextStyle(fontSize: 10, color: Colors.black54)),
//             const SizedBox(width: 6),
//             if (msg.pending) const Icon(Icons.schedule, size: 12, color: Colors.black45),
//             if (msg.failed) const Icon(Icons.error_outline, size: 12, color: Colors.redAccent),
//           ]),
//         ]),
//       ),
//     );
//   }
//
//   Widget _body(BuildContext context, bool ghost) {
//     final t = msg.mediaType;
//     if (t == 'text') {
//       return SelectableText(
//         msg.text.isEmpty ? '[empty]' : msg.text,
//         style: TextStyle(
//           fontSize: 15,
//           fontStyle: ghost ? FontStyle.italic : FontStyle.normal,
//           color: ghost ? Colors.red : Colors.black87,
//         ),
//       );
//     }
//     if (t == 'image') {
//       final url = msg.mediaLink;
//       if (url == null || url.isEmpty) {
//         return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//           _progressBarIfUploading(),
//           const Text('[image uploading…]'),
//         ]);
//       }
//       return ClipRRect(
//         borderRadius: BorderRadius.circular(10),
//         child: Stack(
//           children: [
//             Image.network(url, width: 240, height: 180, fit: BoxFit.cover),
//             if (ghost) Positioned.fill(child: ColoredBox(color: Colors.white.withOpacity(0.25))),
//             if (msg.uploading) Positioned.fill(child: Align(alignment: Alignment.bottomCenter, child: _progressBarIfUploading())),
//           ],
//         ),
//       );
//     }
//     if (t == 'video' || t == 'audio' || t == 'voice' || t == 'file' || t == 'sticker') {
//       return Row(mainAxisSize: MainAxisSize.min, children: [
//         const Icon(Icons.attach_file),
//         const SizedBox(width: 6),
//         Text('[$t] tap to open'),
//         if (msg.uploading) ...[
//           const SizedBox(width: 10),
//           _progressBarIfUploading(),
//         ],
//       ]);
//     }
//     if (t == 'call_audio' || t == 'call_video') {
//       final label = t == 'call_video' ? 'Video call' : 'Voice call';
//       return Row(mainAxisSize: MainAxisSize.min, children: [
//         Icon(t == 'call_video' ? Icons.videocam : Icons.call),
//         const SizedBox(width: 6),
//         Text(label),
//       ]);
//     }
//     return Text('[${msg.mediaType}] ${msg.text}');
//   }
//
//   Widget _progressBarIfUploading() {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         SizedBox(
//           width: 160,
//           child: LinearProgressIndicator(
//             value: (msg.uploadProgress > 0 && msg.uploadProgress <= 100) ? msg.uploadProgress / 100.0 : null,
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text('${msg.uploadProgress.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 10)),
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
//   const _ReplyPreview({required this.id, required this.text, required this.mediaType});
//
//   @override
//   Widget build(BuildContext context) {
//     final isText = mediaType == 'text';
//     final label = isText ? (text.isEmpty ? '[text]' : text) : '[$mediaType]';
//     return Container(
//       padding: const EdgeInsets.all(8),
//       margin: const EdgeInsets.only(bottom: 6),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.6),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: Colors.black12),
//       ),
//       child: Row(mainAxisSize: MainAxisSize.min, children: [
//         const Icon(Icons.subdirectory_arrow_right, size: 16, color: Colors.black54),
//         const SizedBox(width: 6),
//         Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.black87)),
//         const SizedBox(width: 6),
//         Text('#$id', style: const TextStyle(fontSize: 11, color: Colors.black45)),
//       ]),
//     );
//   }
// }
//
// // ================================
// // Utils
// // ================================
// DateTime _parseIso(dynamic v) {
//   if (v is int) {
//     if (v > 1000000000000) return DateTime.fromMillisecondsSinceEpoch(v, isUtc: true);
//     if (v > 1000000000)    return DateTime.fromMillisecondsSinceEpoch(v * 1000, isUtc: true);
//   }
//   if (v is String) {
//     try { return DateTime.parse(v).toUtc(); } catch (_) {}
//     final n = int.tryParse(v);
//     if (n != null) {
//       if (n > 1000000000000) return DateTime.fromMillisecondsSinceEpoch(n, isUtc: true);
//       if (n > 1000000000)    return DateTime.fromMillisecondsSinceEpoch(n * 1000, isUtc: true);
//     }
//   }
//   return DateTime.now().toUtc();
// }
//
//
// // import 'dart:async';
// // import 'dart:convert';
// // import 'dart:io';
// // import 'dart:math';
// //
// // import 'package:flutter/material.dart';
// // import 'package:image_picker/image_picker.dart';
// // import 'package:mime/mime.dart';
// //
// // class ChatScreen extends StatefulWidget {
// //   final String phone;      // e.g. "+88017..." (server will normalize)
// //   final int chatId;
// //   final int? accessHash;   // optional
// //   final String name;
// //   final String username;
// //
// //   const ChatScreen({
// //     super.key,
// //     required this.phone,
// //     required this.chatId,
// //     required this.accessHash,
// //     required this.name,
// //     required this.username,
// //   });
// //
// //   @override
// //   State<ChatScreen> createState() => _ChatScreenState();
// // }
// //
// // // ================================
// // // ✅ CHANGE THESE IF NEEDED
// // // ================================
// // const String _API_BASE = 'http://192.168.0.247:8080';
// // const String _WS_URL   = 'ws://192.168.0.247:8080/chat_ws';
// //
// // class _ChatScreenState extends State<ChatScreen> {
// //   // ---- Transport
// //   WebSocket? _ws;
// //   bool _connecting = false;
// //   int _reconnectAttempt = 0;
// //   Timer? _pingTimer;
// //   Timer? _reconnectTimer;
// //
// //   // ---- Typing
// //   bool _typing = false;
// //   Timer? _typingUiTtl;           // auto off if server silent
// //   Timer? _typingSendDebounce;    // client-side debounce
// //
// //   // ---- UI + Data
// //   final TextEditingController _textCtrl = TextEditingController();
// //   final ScrollController _scrollCtrl = ScrollController();
// //   final ImagePicker _picker = ImagePicker();
// //
// //   final List<Msg> _messages = [];                  // oldest → newest
// //   final Map<int, Msg> _byId = {};                  // msg_id → Msg
// //   final Map<String, int> _pendingIndexByTemp = {}; // temp_id → index
// //   final Set<String> _seenIds = {};                 // for de-dupe
// //
// //   bool _loading = true;
// //   bool _sending = false;
// //   bool _manuallyClosed = false;
// //   // ⭐ nested shape থেকে 1 বা একাধিক message map বের করার helper
// //   List<Map<String, dynamic>> _extractMessageMaps(Map<String, dynamic> m) {
// //     final List<Map<String, dynamic>> out = [];
// //
// //     // common single-item wrappers
// //     final msg = (m['message'] ?? m['data'] ?? m['payload']);
// //     if (msg is Map<String, dynamic>) {
// //       out.add(msg);
// //     } else if (msg is List) {
// //       for (final it in msg) {
// //         if (it is Map<String, dynamic>) out.add(it);
// //       }
// //     }
// //
// //     // কিছু server সরাসরি root-এও field দেয়; সেক্ষেত্রে root-কেও ট্রাই করি
// //     if (out.isEmpty) {
// //       out.add(m);
// //     }
// //     return out;
// //   }
// //
// // // ⭐ bulk ingest
// //   bool _ingestAll(List<Map<String, dynamic>> list, {bool fromRealtime = false}) {
// //     bool changed = false;
// //     for (final mm in list) {
// //       final msg = Msg.fromWsMap(mm, widget.phone, widget.chatId);
// //       changed |= _insertOrUpdate(msg, fromRealtime: fromRealtime);
// //     }
// //     return changed;
// //   }
// //
// //
// //   // utils
// //   String get _clientInstance => 'ci-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1<<32)}';
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _fetchInitial();
// //     _connectWs();
// //   }
// //
// //   @override
// //   void dispose() {
// //     _manuallyClosed = true;
// //     _pingTimer?.cancel();
// //     _reconnectTimer?.cancel();
// //     _typingUiTtl?.cancel();
// //     _typingSendDebounce?.cancel();
// //     _ws?.close();
// //     _textCtrl.dispose();
// //     _scrollCtrl.dispose();
// //     super.dispose();
// //   }
// //
// //   // ================================
// //   // REST: load initial history (Mongo-first)
// //   // ================================
// //   Future<void> _fetchInitial() async {
// //     try {
// //       // order=asc দিলে server উল্টো (desc) রিটার্ন করে; যেটাই আসুক আমরা শেষে sort করে নেব
// //       final uri = Uri.parse(
// //         '$_API_BASE/messages'
// //             '?phone=+${Uri.encodeQueryComponent(widget.phone)}' // ✅ no manual '+'
// //             '&chat_id=${widget.chatId}'
// //             '${widget.accessHash != null ? '&access_hash=${widget.accessHash}' : ''}'
// //
// //       );
// //       print(uri);
// //
// //       final http = HttpClient();
// //       final req = await http.getUrl(uri);
// //       final res = await req.close();
// //       final body = await res.transform(utf8.decoder).join();
// //       final jsonBody = jsonDecode(body) as Map<String, dynamic>;
// //       final List arr = (jsonBody['messages'] as List?) ?? const [];
// //
// //       // Normalize to oldest→newest and use _insertOrUpdate so media fallback applies
// //       _messages.clear();
// //       _byId.clear();
// //       _seenIds.clear();
// //
// //       final List<Msg> temp = [];
// //       for (final it in arr) {
// //         final msg = Msg.fromApiMap(it as Map<String, dynamic>, widget.phone, widget.chatId);
// //         temp.add(msg);
// //       }
// //       temp.sort((a, b) => a.date.compareTo(b.date));
// //
// //       for (final m in temp) {
// //         _insertOrUpdate(m); // ✅ ensures mediaLink fallback is set
// //       }
// //
// //       setState(() => _loading = false);
// //       _scrollToBottomSoon();
// //     } catch (e) {
// //       debugPrint('REST fetch error: $e');
// //       setState(() => _loading = false);
// //     }
// //   }
// //
// //   // ================================
// //   // WebSocket connect + keepalive + reconnect
// //   // ================================
// //   Future<void> _connectWs() async {
// //     if (_connecting) return;
// //     _connecting = true;
// //
// //     try {
// //       _ws = await WebSocket.connect(_WS_URL);
// //       _reconnectAttempt = 0;
// //
// //       // handshake: MUST be 1st frame
// //       _ws!.add(jsonEncode({
// //         'phone': widget.phone,
// //         'chat_id': widget.chatId,
// //         if (widget.accessHash != null) 'access_hash': widget.accessHash,
// //         'client_instance': _clientInstance, // ⭐ added
// //       }));
// //       // keep-alive ping
// //       _pingTimer?.cancel();
// //       _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
// //         if (_ws?.readyState == WebSocket.open) {
// //           _ws!.add(jsonEncode({'action': 'ping'}));
// //         }
// //       });
// //
// //       _ws!.listen(
// //             (dynamic raw) => _onWsFrame(raw),
// //         onDone: _scheduleReconnect,
// //         onError: (err) {
// //           debugPrint('WS error: $err');
// //           _scheduleReconnect();
// //         },
// //         cancelOnError: true,
// //       );
// //     } catch (e) {
// //       _scheduleReconnect();
// //     } finally {
// //       _connecting = false;
// //     }
// //   }
// //
// //   void _scheduleReconnect([_]) {
// //     if (_manuallyClosed) return;
// //     _pingTimer?.cancel();
// //     _reconnectAttempt++;
// //     final delay = Duration(seconds: min(30, 1 << _reconnectAttempt));
// //     _reconnectTimer?.cancel();
// //     _reconnectTimer = Timer(delay, _connectWs);
// //   }
// //
// //   // ================================
// //   // WS frame handler (bytes or string)
// //   // ================================
// //   void _onWsFrame(dynamic raw) {
// //     if (!mounted) return;
// //     String s;
// //     if (raw is String) {
// //       s = raw;
// //     } else if (raw is List<int>) {
// //       s = utf8.decode(raw);
// //     } else {
// //       return;
// //     }
// //
// //     Map<String, dynamic> m;
// //     try {
// //       m = jsonDecode(s) as Map<String, dynamic>;
// //     } catch (_) {
// //       return;
// //     }
// //
// //     if (m['action'] == '_hb' || m['status'] == 'pong') return;
// //
// //     // errors
// //     if (m['status'] == 'error') {
// //       _toast('WS error: ${m['detail'] ?? ''}');
// //       return;
// //     }
// //
// //     switch (m['action']) {
// //       case 'seed':
// //         _handleSeed((m['messages'] as List?) ?? const []);
// //         return;
// //
// //       case 'typing':
// //         setState(() => _typing = true);
// //         _typingUiTtl?.cancel();
// //         _typingUiTtl = Timer(const Duration(seconds: 6), () {
// //           if (mounted) setState(() => _typing = false);
// //         });
// //         return;
// //
// //       case 'typing_stopped':
// //         _typingUiTtl?.cancel();
// //         setState(() => _typing = false);
// //         return;
// //
// //       case 'upload_progress':
// //         _handleUploadProgress(m);
// //         return;
// //
// //       case 'send_queued':
// //         _handleSendQueued(m);
// //         return;
// //
// //       case 'send_done':
// //         _handleSendDone(m);
// //         return;
// //
// //       case 'send_failed':
// //         _handleSendFailed(m);
// //         return;
// //
// //       case 'new_message': {
// //         final list = _extractMessageMaps(m);        // ⭐ nested-safe
// //         final changed = _ingestAll(list, fromRealtime: true);
// //         if (changed) {
// //           setState(() {});
// //           _scrollToBottomSoon();
// //         }
// //         return;
// //       }
// //       // fall-through to default mapping
// //         break;
// //     }
// //
// //     // generic new message / any payload with id/msg_id/temp_id
// //     if (m.containsKey('id') || m.containsKey('msg_id') || m.containsKey('temp_id')) {
// //       final msg = Msg.fromWsMap(m, widget.phone, widget.chatId);
// //       final changed = _insertOrUpdate(msg, fromRealtime: true);
// //       if (changed) {
// //         setState(() {});           // ✅ ensure UI refresh
// //         _scrollToBottomSoon();
// //       }
// //     }
// //   }
// //
// //   // ---- seed
// //   void _handleSeed(List arr) {
// //     bool changed = false;
// //     for (final it in arr) {
// //       final msg = Msg.fromWsMap(it as Map<String, dynamic>, widget.phone, widget.chatId);
// //       // seed typically newest-last; we’ll insert & resort
// //       changed |= _insertOrUpdate(msg);
// //     }
// //     if (changed) {
// //       _messages.sort((a, b) => a.date.compareTo(b.date));
// //       setState(() {});
// //       _scrollToBottomSoon();
// //     }
// //   }
// //
// //   // ---- upload progress
// //   void _handleUploadProgress(Map<String, dynamic> m) {
// //     final tempId = m['temp_id']?.toString();
// //     final prog = (m['progress'] is num) ? (m['progress'] as num).toDouble() : null;
// //     if (tempId == null || prog == null) return;
// //
// //     final idx = _pendingIndexByTemp[tempId];
// //     if (idx != null && idx >= 0 && idx < _messages.length) {
// //       _messages[idx].uploadProgress = prog.clamp(0, 100);
// //       setState(() {});
// //     }
// //   }
// //
// //   // ---- send_queued: bind pending → temp_id
// //   void _handleSendQueued(Map<String, dynamic> m) {
// //     final tempId = m['temp_id']?.toString();
// //     final mediaType = (m['media_type'] ?? 'text').toString();
// //     if (tempId == null) return;
// //
// //     // find first pending bubble without temp_id
// //     final i = _messages.indexWhere((x) => x.pending && (x.tempId == null));
// //     if (i != -1) {
// //       _messages[i].tempId = tempId;
// //       _pendingIndexByTemp[tempId] = i;
// //       _messages[i].mediaType = mediaType;
// //       setState(() {});
// //     }
// //   }
// //
// //   // ---- send_done: finalize
// //   void _handleSendDone(Map<String, dynamic> m) {
// //     final tempId = m['temp_id']?.toString();
// //     final msgId = (m['msg_id'] is int) ? m['msg_id'] as int : int.tryParse(m['msg_id']?.toString() ?? '');
// //     if (tempId == null) return;
// //
// //     final i = _pendingIndexByTemp[tempId] ?? _messages.indexWhere((x) => x.tempId == tempId);
// //     if (i != -1) {
// //       final item = _messages[i];
// //       item.id = msgId ?? item.id;
// //       item.pending = false;
// //       item.existsOnTelegram = true;
// //       item.uploading = false;
// //       item.uploadProgress = 100;
// //       if (item.id != null) {
// //         _byId[item.id!] = item;
// //         _seenIds.add('id:${item.id}');
// //       }
// //       _pendingIndexByTemp.remove(tempId);
// //       setState(() {});
// //       _scrollToBottomSoon();
// //     }
// //   }
// //
// //   void _handleSendFailed(Map<String, dynamic> m) {
// //     final tempId = m['temp_id']?.toString();
// //     final i = tempId == null ? -1 : (_pendingIndexByTemp[tempId] ?? _messages.indexWhere((x) => x.tempId == tempId));
// //     if (i != -1) {
// //       final item = _messages[i];
// //       item.pending = false;
// //       item.failed = true;
// //       item.uploading = false;
// //       setState(() {});
// //     }
// //     _toast('Send failed: ${m['detail'] ?? ''}');
// //   }
// //
// //   // ================================
// //   // Insert / Update (by msg_id or temp_id)
// //   // ================================
// //   bool _insertOrUpdate(Msg m, {bool fromRealtime = false}) {
// //     // attach media_link fallback if needed
// //     if (m.needsMediaUrlFallback) {
// //       m.mediaLink = _buildMediaUrlFallback(m);
// //     }
// //
// //     if (m.id != null) {
// //       final exist = _byId[m.id!];
// //       if (exist != null) {
// //         exist.mergeFrom(m);
// //         return true;
// //       }
// //       // de-dupe by final id
// //       if (_seenIds.contains('id:${m.id}')) return false;
// //       _seenIds.add('id:${m.id}');
// //       _byId[m.id!] = m;
// //       _messages.add(m);
// //       if (fromRealtime) _scrollToBottomSoon();
// //       return true;
// //     }
// //
// //     if (m.tempId != null) {
// //       // update pending
// //       final i = _pendingIndexByTemp[m.tempId!] ?? _messages.indexWhere((x) => x.tempId == m.tempId);
// //       if (i != -1) {
// //         _messages[i].mergeFrom(m);
// //         return true;
// //       }
// //       // brand new queued (rare)
// //       _pendingIndexByTemp[m.tempId!] = _messages.length;
// //       _messages.add(m);
// //       if (fromRealtime) _scrollToBottomSoon();
// //       return true;
// //     }
// //
// //     // no id/temp → just append (shouldn't happen normally)
// //     _messages.add(m);
// //     return true;
// //   }
// //
// //   String _buildMediaUrlFallback(Msg m) {
// //     // When media_fs_id exists on server, /message_media should serve it.
// //     // Generic fallback pattern (tune if your server differs):
// //     // /message_media?phone=...&chat_id=...&msg_id=...
// //     return '$_API_BASE/message_media'
// //         '?phone=${Uri.encodeQueryComponent(widget.phone)}'
// //         '&chat_id=${m.chatId}'
// //         '&msg_id=${m.id ?? 0}';
// //   }
// //
// //   // ================================
// //   // Actions - send / typing / image
// //   // ================================
// //   void _sendTypingStart() {
// //     _typingSendDebounce?.cancel();
// //     if (_ws?.readyState == WebSocket.open) {
// //       _ws!.add(jsonEncode({
// //         'action': 'typing_start',
// //         // some server builds require these
// //         'phone': widget.phone,
// //         'chat_id': widget.chatId,
// //       }));
// //     }
// //     _typingSendDebounce = Timer(const Duration(seconds: 2), _sendTypingStop);
// //   }
// //
// //   void _sendTypingStop() {
// //     if (_ws?.readyState == WebSocket.open) {
// //       _ws!.add(jsonEncode({
// //         'action': 'typing_stop',
// //         'phone': widget.phone,
// //         'chat_id': widget.chatId,
// //       }));
// //     }
// //   }
// //
// //   Future<void> _sendText() async {
// //     final t = _textCtrl.text.trim();
// //     if (t.isEmpty) return;
// //
// //     setState(() => _sending = true);
// //
// //     // optimistic pending
// //     final pending = Msg.pendingText(
// //       text: t,
// //       isOut: true,
// //       username: widget.username,
// //     );
// //     _messages.add(pending);
// //     _scrollToBottomSoon();
// //     setState(() {});
// //
// //     final payload = {
// //       'action': 'send',
// //       'text': t,
// //       // কিছু সার্ভার older build-এ এগুলো চাইতে পারে
// //       'phone': widget.phone,
// //       'chat_id': widget.chatId,
// //       if (widget.accessHash != null) 'access_hash': widget.accessHash,
// //       'client_instance': _clientInstance,
// //       'client_tmp': pending.localClientTmp,
// //     };
// //
// //     try {
// //       _ws?.add(jsonEncode(payload));
// //       _textCtrl.clear();
// //     } catch (e) {
// //       pending.failed = true;
// //       pending.pending = false;
// //       setState(() {});
// //       _toast('Send error: $e');
// //     } finally {
// //       if (mounted) setState(() => _sending = false);
// //     }
// //   }
// //
// //   Future<void> _sendImage() async {
// //     try {
// //       final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 92);
// //       if (picked == null) return;
// //
// //       final bytes = await picked.readAsBytes();
// //       final b64 = base64Encode(bytes);
// //       final mime = lookupMimeType(picked.name) ?? 'image/jpeg';
// //
// //       final pending = Msg.pendingMedia(
// //         mediaType: 'image',
// //         caption: '',
// //         isOut: true,
// //         username: widget.username,
// //       );
// //       _messages.add(pending);
// //       _scrollToBottomSoon();
// //       setState(() {});
// //
// //       final payload = {
// //         'action': 'send',
// //         'text': '', // caption optional
// //         'file_base64': b64,        // raw base64 OK (server accepts data:URI too)
// //         'file_name': picked.name,
// //         'mime_type': mime,
// //         'phone': widget.phone,
// //         'chat_id': widget.chatId,
// //         if (widget.accessHash != null) 'access_hash': widget.accessHash,
// //         'client_instance': _clientInstance,
// //         'client_tmp': pending.localClientTmp,
// //       };
// //
// //       _ws?.add(jsonEncode(payload));
// //     } catch (e) {
// //       _toast('Image send error: $e');
// //     }
// //   }
// //
// //   // ================================
// //   // UI helpers
// //   // ================================
// //   void _toast(String msg) {
// //     if (!mounted) return;
// //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
// //   }
// //
// //   void _scrollToBottomSoon() {
// //     WidgetsBinding.instance.addPostFrameCallback((_) {
// //       if (!_scrollCtrl.hasClients) return;
// //       _scrollCtrl.animateTo(
// //         _scrollCtrl.position.maxScrollExtent + 80,
// //         duration: const Duration(milliseconds: 220),
// //         curve: Curves.easeOut,
// //       );
// //     });
// //   }
// //
// //   // ================================
// //   // BUILD
// //   // ================================
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         titleSpacing: 0,
// //         title: Row(
// //           children: [
// //             const CircleAvatar(child: Icon(Icons.person)),
// //             const SizedBox(width: 8),
// //             Expanded(
// //               child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
// //                 Text(widget.name, style: const TextStyle(fontWeight: FontWeight.w600)),
// //                 Text(_typing ? 'typing…' : 'online', style: Theme.of(context).textTheme.bodySmall),
// //               ]),
// //             ),
// //           ],
// //         ),
// //         actions: [
// //           IconButton(
// //             icon: const Icon(Icons.refresh),
// //             onPressed: () {
// //               _ws?.close();
// //               _connectWs();
// //             },
// //           ),
// //         ],
// //       ),
// //       body: Column(
// //         children: [
// //           Expanded(
// //             child: _loading
// //                 ? const Center(child: CircularProgressIndicator())
// //                 : ListView.builder(
// //               controller: _scrollCtrl,
// //               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
// //               itemCount: _messages.length,
// //               itemBuilder: (_, i) {
// //                 final m = _messages[i];
// //                 return _MessageBubble(
// //                   key: ValueKey('msg-${m.id ?? m.tempId ?? i}') ,
// //                   msg: m,
// //                   findById: (id) => _byId[id],
// //                 );
// //               },
// //             ),
// //           ),
// //           _composer(),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Widget _composer() {
// //     final canSend = _textCtrl.text.trim().isNotEmpty && !_sending;
// //
// //     return SafeArea(
// //       top: false,
// //       child: Container(
// //         color: const Color(0xFFF7F7F7),
// //         padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
// //         child: Row(
// //           children: [
// //             IconButton(onPressed: _sendImage, icon: const Icon(Icons.attach_file)),
// //             Expanded(
// //               child: TextField(
// //                 controller: _textCtrl,
// //                 minLines: 1,
// //                 maxLines: 5,
// //                 onChanged: (_) => _sendTypingStart(),
// //                 onEditingComplete: _sendTypingStop,
// //                 decoration: const InputDecoration(isDense: true, hintText: 'Message', border: OutlineInputBorder()),
// //               ),
// //             ),
// //             const SizedBox(width: 8),
// //             SizedBox(
// //               width: 40,
// //               height: 40,
// //               child: Material(
// //                 color: canSend ? const Color(0xFF2AABEE) : const Color(0xFFB3E5FC),
// //                 shape: const CircleBorder(),
// //                 child: InkWell(
// //                   customBorder: const CircleBorder(),
// //                   onTap: canSend ? _sendText : null,
// //                   child: Center(
// //                     child: _sending
// //                         ? const SizedBox(
// //                       width: 18,
// //                       height: 18,
// //                       child: CircularProgressIndicator(
// //                         strokeWidth: 2,
// //                         valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
// //                       ),
// //                     )
// //                         :  IconButton(onPressed: _sending ? null : _sendText, icon: const Icon(Icons.send)),// simplified
// //                   ),
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// // // ================================
// // // MODEL
// // // ================================
// // class Msg {
// //   int? id;                  // msg_id (final)
// //   String? tempId;           // send_queued
// //   final String? localClientTmp; // local optimistic tag
// //   String text;
// //   DateTime date;
// //   bool isOut;
// //   int? replyTo;
// //   String mediaType;         // text|image|video|audio|voice|sticker|file|call_audio|call_video
// //   String? mediaLink;
// //   bool deletedOnTelegram;
// //   bool existsOnTelegram;
// //
// //   // UI meta
// //   bool pending;
// //   bool failed;
// //   bool uploading;
// //   double uploadProgress;
// //
// //   final int chatId;         // for fallback url
// //
// //   Msg({
// //     required this.id,
// //     required this.tempId,
// //     required this.localClientTmp,
// //     required this.text,
// //     required this.date,
// //     required this.isOut,
// //     required this.replyTo,
// //     required this.mediaType,
// //     required this.mediaLink,
// //     required this.deletedOnTelegram,
// //     required this.existsOnTelegram,
// //     required this.pending,
// //     required this.failed,
// //     required this.uploading,
// //     required this.uploadProgress,
// //     required this.chatId,
// //   });
// //
// //   bool get needsMediaUrlFallback =>
// //       mediaLink == null &&
// //           (mediaType == 'image' || mediaType == 'video' || mediaType == 'audio' || mediaType == 'voice' || mediaType == 'file') &&
// //           id != null;
// //
// //   // ---- REST (/messages)
// //   factory Msg.fromApiMap(Map<String, dynamic> m, String phone, int chatId) {
// //     final id = (m['msg_id'] is int) ? m['msg_id'] as int : int.tryParse(m['msg_id']?.toString() ?? '');
// //     final mediaType = (m['media_type'] ?? 'text').toString();
// //
// //     return Msg(
// //       id: id,
// //       tempId: null,
// //       localClientTmp: null,
// //       text: (m['text'] ?? '').toString(),
// //       date: _parseIso(m['date']),
// //       isOut: (m['is_out'] == true) || (m['direction']?.toString() == 'out'),
// //       replyTo: (m['reply_to'] is int) ? m['reply_to'] as int : null,
// //       mediaType: mediaType,
// //       mediaLink: null, // REST-এ সাধারনত media_link থাকে না; fallback ইউআরএল বানাবো
// //       deletedOnTelegram: m['deleted_on_telegram'] == true,
// //       existsOnTelegram: m['exists_on_telegram'] != false,
// //       pending: false,
// //       failed: false,
// //       uploading: false,
// //       uploadProgress: 0.0,
// //       chatId: chatId,
// //     );
// //   }
// //
// //   // ---- WS (seed/new_message/send_queued/send_done)
// //   factory Msg.fromWsMap(Map<String, dynamic> m, String phone, int chatId) {
// //     final id = (m['id'] is int)
// //         ? m['id'] as int
// //         : (m['msg_id'] is int ? m['msg_id'] as int : int.tryParse(m['id']?.toString() ?? ''));
// //     final tempId = m['temp_id']?.toString();
// //
// //     final mediaType = (m['media_type'] ?? 'text').toString();
// //     return Msg(
// //       id: id,
// //       tempId: tempId,
// //       localClientTmp: null,
// //       text: (m['text'] ?? '').toString(),
// //       date: _parseIso(m['date']),
// //       isOut: (m['is_out'] == true) || (m['direction']?.toString() == 'out'),
// //       replyTo: (m['reply_to'] is int) ? m['reply_to'] as int : null,
// //       mediaType: mediaType,
// //       mediaLink: (m['media_link']?.toString()),
// //       deletedOnTelegram: m['deleted_on_telegram'] == true,
// //       existsOnTelegram: m['exists_on_telegram'] != false,
// //       pending: false,
// //       failed: false,
// //       uploading: false,
// //       uploadProgress: 0.0,
// //       chatId: chatId,
// //     );
// //   }
// //
// //   // ---- Optimistic pending creators
// //   factory Msg.pendingText({required String text, required bool isOut, required String username}) {
// //     final tmp = 'local-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1<<32)}';
// //     return Msg(
// //       id: null,
// //       tempId: null, // send_queued এ বসবে
// //       localClientTmp: tmp,
// //       text: text,
// //       date: DateTime.now().toUtc(),
// //       isOut: isOut,
// //       replyTo: null,
// //       mediaType: 'text',
// //       mediaLink: null,
// //       deletedOnTelegram: false,
// //       existsOnTelegram: false,
// //       pending: true,
// //       failed: false,
// //       uploading: false,
// //       uploadProgress: 0.0,
// //       chatId: 0,
// //     );
// //   }
// //
// //   factory Msg.pendingMedia({required String mediaType, required String caption, required bool isOut, required String username}) {
// //     final tmp = 'local-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1<<32)}';
// //     return Msg(
// //       id: null,
// //       tempId: null,
// //       localClientTmp: tmp,
// //       text: caption,
// //       date: DateTime.now().toUtc(),
// //       isOut: isOut,
// //       replyTo: null,
// //       mediaType: mediaType,
// //       mediaLink: null,
// //       deletedOnTelegram: false,
// //       existsOnTelegram: false,
// //       pending: true,
// //       failed: false,
// //       uploading: true,
// //       uploadProgress: 0.0,
// //       chatId: 0,
// //     );
// //   }
// //
// //   void mergeFrom(Msg other) {
// //     id = other.id ?? id;
// //     tempId = other.tempId ?? tempId;
// //     text = other.text.isNotEmpty ? other.text : text;
// //     date = other.date;
// //     isOut = other.isOut;
// //     replyTo = other.replyTo ?? replyTo;
// //     mediaType = other.mediaType.isNotEmpty ? other.mediaType : mediaType;
// //     mediaLink = other.mediaLink ?? mediaLink;
// //     deletedOnTelegram = other.deletedOnTelegram;
// //     existsOnTelegram = other.existsOnTelegram;
// //     pending = other.pending;
// //     failed = other.failed;
// //     uploading = other.uploading;
// //     uploadProgress = other.uploadProgress != 0.0 ? other.uploadProgress : uploadProgress;
// //   }
// // }
// //
// // // ================================
// // // BUBBLE
// // // ================================
// // class _MessageBubble extends StatelessWidget {
// //   final Msg msg;
// //   final Msg? Function(int id) findById;
// //
// //   const _MessageBubble({super.key, required this.msg, required this.findById});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final isOut = msg.isOut;
// //     return Padding(
// //       padding: const EdgeInsets.symmetric(vertical: 4),
// //       child: Row(
// //         mainAxisAlignment: isOut ? MainAxisAlignment.end : MainAxisAlignment.start,
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           if (!isOut) const SizedBox(width: 36),
// //           _bubbleCore(context),
// //           if (isOut) const SizedBox(width: 36),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Widget _bubbleCore(BuildContext context) {
// //     final ghost = (msg.existsOnTelegram == false) || msg.pending;
// //     final color = msg.failed
// //         ? Colors.red.shade200
// //         : (msg.isOut ? Colors.blue.shade100 : Colors.grey.shade200);
// //
// //     return ConstrainedBox(
// //       constraints: const BoxConstraints(maxWidth: 320),
// //       child: Container(
// //         padding: const EdgeInsets.all(10),
// //         decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
// //         child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
// //           if (msg.replyTo != null)
// //             _ReplyPreview(
// //               id: msg.replyTo!,
// //               text: findById(msg.replyTo!)?.text ?? '',
// //               mediaType: findById(msg.replyTo!)?.mediaType ?? 'text',
// //             ),
// //           _body(context, ghost),
// //           const SizedBox(height: 6),
// //           Row(mainAxisSize: MainAxisSize.min, children: [
// //             Text(_fmtTime(msg.date), style: const TextStyle(fontSize: 10, color: Colors.black54)),
// //             const SizedBox(width: 6),
// //             if (msg.pending) const Icon(Icons.schedule, size: 12, color: Colors.black45),
// //             if (msg.failed) const Icon(Icons.error_outline, size: 12, color: Colors.redAccent),
// //           ]),
// //         ]),
// //       ),
// //     );
// //   }
// //
// //   Widget _body(BuildContext context, bool ghost) {
// //     final t = msg.mediaType;
// //     if (t == 'text') {
// //       return SelectableText(
// //         msg.text.isEmpty ? '[empty]' : msg.text,
// //         style: TextStyle(
// //           fontSize: 15,
// //           fontStyle: ghost ? FontStyle.italic : FontStyle.normal,
// //           color: ghost ? Colors.red : Colors.black87,
// //         ),
// //       );
// //     }
// //     if (t == 'image') {
// //       final url = msg.mediaLink;
// //       if (url == null || url.isEmpty) {
// //         return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
// //           _progressBarIfUploading(),
// //           const Text('[image uploading…]'),
// //         ]);
// //       }
// //       return ClipRRect(
// //         borderRadius: BorderRadius.circular(10),
// //         child: Stack(
// //           children: [
// //             Image.network(url, width: 240, height: 180, fit: BoxFit.cover),
// //             if (ghost) Positioned.fill(child: ColoredBox(color: Colors.white.withOpacity(0.25))),
// //             if (msg.uploading) Positioned.fill(child: Align(alignment: Alignment.bottomCenter, child: _progressBarIfUploading())),
// //           ],
// //         ),
// //       );
// //     }
// //     if (t == 'video' || t == 'audio' || t == 'voice' || t == 'file' || t == 'sticker') {
// //       return Row(mainAxisSize: MainAxisSize.min, children: [
// //         const Icon(Icons.attach_file),
// //         const SizedBox(width: 6),
// //         Text('[$t] tap to open'),
// //         if (msg.uploading) ...[
// //           const SizedBox(width: 10),
// //           _progressBarIfUploading(),
// //         ],
// //       ]);
// //     }
// //     if (t == 'call_audio' || t == 'call_video') {
// //       final label = t == 'call_video' ? 'Video call' : 'Voice call';
// //       return Row(mainAxisSize: MainAxisSize.min, children: [
// //         Icon(t == 'call_video' ? Icons.videocam : Icons.call),
// //         const SizedBox(width: 6),
// //         Text(label),
// //       ]);
// //     }
// //     return Text('[${msg.mediaType}] ${msg.text}');
// //   }
// //
// //   Widget _progressBarIfUploading() {
// //     return Column(
// //       mainAxisSize: MainAxisSize.min,
// //       children: [
// //         SizedBox(
// //           width: 160,
// //           child: LinearProgressIndicator(
// //             value: (msg.uploadProgress > 0 && msg.uploadProgress <= 100) ? msg.uploadProgress / 100.0 : null,
// //           ),
// //         ),
// //         const SizedBox(height: 4),
// //         Text('${msg.uploadProgress.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 10)),
// //       ],
// //     );
// //   }
// //
// //   String _fmtTime(DateTime dt) {
// //     final h = dt.toLocal().hour.toString().padLeft(2, '0');
// //     final m = dt.toLocal().minute.toString().padLeft(2, '0');
// //     return '$h:$m';
// //   }
// // }
// //
// // class _ReplyPreview extends StatelessWidget {
// //   final int id;
// //   final String text;
// //   final String mediaType;
// //   const _ReplyPreview({required this.id, required this.text, required this.mediaType});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final isText = mediaType == 'text';
// //     final label = isText ? (text.isEmpty ? '[text]' : text) : '[$mediaType]';
// //     return Container(
// //       padding: const EdgeInsets.all(8),
// //       margin: const EdgeInsets.only(bottom: 6),
// //       decoration: BoxDecoration(
// //         color: Colors.white.withOpacity(0.6),
// //         borderRadius: BorderRadius.circular(8),
// //         border: Border.all(color: Colors.black12),
// //       ),
// //       child: Row(mainAxisSize: MainAxisSize.min, children: [
// //         const Icon(Icons.subdirectory_arrow_right, size: 16, color: Colors.black54),
// //         const SizedBox(width: 6),
// //         Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.black87)),
// //         const SizedBox(width: 6),
// //         Text('#$id', style: const TextStyle(fontSize: 11, color: Colors.black45)),
// //       ]),
// //     );
// //   }
// // }
// //
// // // ================================
// // // Utils
// // // ================================
// // DateTime _parseIso(dynamic v) {
// //   if (v is String) { try { return DateTime.parse(v).toUtc(); } catch (_) {} }
// //   return DateTime.now().toUtc();
// // }
