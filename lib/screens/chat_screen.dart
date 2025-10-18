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






















import 'dart:convert';
import 'dart:io';
import 'package:ag_taligram/url.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _msgCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  WebSocket? _socket;

  bool _loading = true;
  bool _sending = false;
  bool _typing = false;

  // upload progress (maps to the last uploading message)
  double _uploadProgress = 0.0;
  int? _uploadingMsgIndex; // index in provider.messages

  // optional: reply support (set this map from long-press)
  Map<String, dynamic>? _replyToMsg;

  @override
  void initState() {
    super.initState();
    _fetchAndLoad();
    _connectWebSocket();
  }

  @override
  void dispose() {
    _socket?.close();
    super.dispose();
  }

  // ================================
  // 🔌 WebSocket Connect
  // ================================
  Future<void> _connectWebSocket() async {
    try {
      // ⚠️ real device হলে LAN IP দাও
      final wsUrl = 'ws://192.168.0.247:8080/chat_ws';
      _socket = await WebSocket.connect(wsUrl);
      debugPrint("✅ WS connected");

      // INIT: backend-এর chat_ws যেমন চায়
      final init = {
        "phone": widget.phone,
        "chat_id": widget.chatId,
        "access_hash": widget.accessHash,
      };
      _socket!.add(jsonEncode(init));

      _socket!.listen((raw) {
        final provider = Provider.of<TelegraphProvider>(context, listen: false);
        try {
          final data = jsonDecode(raw);
          // debugPrint("📩 WS IN → $data");

          // --- upload progress (global)
          if (data["action"] == "upload_progress") {
            final prog = (data["progress"] ?? 0).toDouble();
            setState(() => _uploadProgress = prog);
            // tie to last uploading message
            if (_uploadingMsgIndex != null &&
                _uploadingMsgIndex! < provider.messages.length) {
              provider.messages[_uploadingMsgIndex!]["progress"] = prog;
              provider.notifyListeners();
            }
            return;
          }

          // --- new incoming message from Telegram
          if (data["action"] == "new_message") {
            if (data["chat_id"].toString() == widget.chatId.toString()) {
              final mediaType = data["media_type"]; // image / video / audio / file / null
              final fileName  = data["file_name"];
              final fileUrl   = data["file_url"];  // থাকলে ব্যবহার করব

              provider.messages.insert(0, {
                "id": data["id"],
                "text": data["text"] ?? "",
                "is_out": false,
                "time": data["date"] ?? DateTime.now().toString(),
                "type": mediaType ?? (data["text"]?.isNotEmpty == true ? "text" : null),
                "file_name": fileName,
                "url": fileUrl,
                "progress": 100.0,
                "uploading": false,
              });
              provider.notifyListeners();
            }
            return;
          }

          // --- our own send confirmations
          if (data["status"] == "sent_file" ||
              data["status"] == "sent_video" ||
              data["status"] == "sent_voice" ||
              data["status"] == "sent_text") {
            // clear upload UI
            setState(() {
              _uploadProgress = 100.0;
            });
            if (_uploadingMsgIndex != null &&
                _uploadingMsgIndex! < provider.messages.length) {
              provider.messages[_uploadingMsgIndex!]["uploading"] = false;
              provider.messages[_uploadingMsgIndex!]["progress"] = 100.0;
              provider.notifyListeners();
              _uploadingMsgIndex = null;
            }
            return;
          }

          if ((data["status"] ?? "").toString().contains("error")) {
            debugPrint("❌ WS Error: ${data["detail"]}");
          }
        } catch (e) {
          debugPrint("⚠️ WS decode error: $e");
        }
      }, onDone: () {
        debugPrint("⚠️ WS closed. Reconnect in 3s...");
        Future.delayed(const Duration(seconds: 3), _connectWebSocket);
      }, onError: (err) {
        debugPrint("❌ WS error: $err");
        Future.delayed(const Duration(seconds: 5), _connectWebSocket);
      });
    } catch (e) {
      debugPrint("❌ WS connect fail: $e");
      Future.delayed(const Duration(seconds: 5), _connectWebSocket);
    }
  }

  // ================================
  // 📨 Load old messages
  // ================================
  Future<void> _fetchAndLoad() async {
    final provider = Provider.of<TelegraphProvider>(context, listen: false);
    await provider.fetchMessages(widget.phone, widget.chatId, widget.accessHash);
    setState(() => _loading = false);
  }

  // ================================
  // ✉️ Send text (with optional reply)
  // ================================
  Future<void> _sendText() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    final provider = Provider.of<TelegraphProvider>(context, listen: false);

    final payload = {
      "action": "send",
      "phone": widget.phone,
      "chat_id": widget.chatId,
      "access_hash": widget.accessHash,
      "text": text,
    };
    if (_replyToMsg != null && _replyToMsg!["id"] != null) {
      payload["reply_to"] = _replyToMsg!["id"];
    }

    try {
      if (_socket?.readyState == WebSocket.open) {
        _socket!.add(jsonEncode(payload));
      } else {
        // HTTP fallback
        final url = Uri.parse("$urlLocal/send");
        await http.post(url, body: {
          "phone": widget.phone,
          "to": widget.username,
          "text": text,
        });
      }

      provider.messages.insert(0, {
        "text": text,
        "is_out": true,
        "time": DateTime.now().toString(),
        "type": "text",
        "uploading": false,
        "progress": 100.0,
      });
      provider.notifyListeners();
      _msgCtrl.clear();
      setState(() => _replyToMsg = null);
    } catch (e) {
      debugPrint("⚠️ send text error: $e");
    } finally {
      setState(() => _sending = false);
    }
  }

  // ================================
  // 📤 Send file (image / video / audio)
  // ================================
  Future<void> _sendFile(File file, {String? caption}) async {
    try {
      final bytes = await file.readAsBytes();
      final b64 = base64Encode(bytes);
      final fileName = p.basename(file.path);
      final mime = lookupMimeType(file.path) ?? "application/octet-stream";

      final isImage = mime.startsWith('image/');
      final isVideo = mime.startsWith('video/');
      final isAudio = mime.startsWith('audio/');

      final provider = Provider.of<TelegraphProvider>(context, listen: false);

      // show immediately in list with local preview + 0% progress
      provider.messages.insert(0, {
        "text": caption ?? "",
        "is_out": true,
        "time": DateTime.now().toString(),
        "type": isImage ? "image" : (isVideo ? "video" : (isAudio ? "audio" : "file")),
        "local_path": file.path,
        "file_name": fileName,
        "mime": mime,
        "uploading": true,
        "progress": 0.0,
      });
      provider.notifyListeners();
      _uploadingMsgIndex = 0; // just inserted at 0
      setState(() {
        _uploadProgress = 0.0;
      });

      final payload = {
        "action": "send",
        "phone": widget.phone,
        "chat_id": widget.chatId,
        "access_hash": widget.accessHash,
        "file_name": fileName,
        "file_base64": b64,
        "mime_type": mime,
        "text": caption ?? "",
      };
      if (_replyToMsg != null && _replyToMsg!["id"] != null) {
        payload["reply_to"] = _replyToMsg!["id"];
      }

      if (_socket?.readyState == WebSocket.open) {
        _socket!.add(jsonEncode(payload));
      } else {
        // চাইলে এখানে HTTP /upload fallback রাখতে পারো
        debugPrint("WS not open; file not sent.");
      }
    } catch (e) {
      debugPrint("⚠️ send file error: $e");
    }
  }

  // ================================
  // Typing events
  // ================================
  void _typingStart() {
    if (_socket?.readyState == WebSocket.open) {
      _socket!.add(jsonEncode({"action": "typing_start"}));
    }
  }

  void _typingStop() {
    if (_socket?.readyState == WebSocket.open) {
      _socket!.add(jsonEncode({"action": "typing_stop"}));
    }
  }

  // ================================
  // File pickers
  // ================================
  Future<void> _ensurePerms() async {
    await [Permission.camera, Permission.photos, Permission.storage].request();
  }

  Future<void> _pickImages() async {
    await _ensurePerms();
    final imgs = await _picker.pickMultiImage(imageQuality: 80);
    for (final img in imgs) {
      await _sendFile(File(img.path));
    }
  }

  Future<void> _pickVideo() async {
    await _ensurePerms();
    final vid = await _picker.pickVideo(source: ImageSource.gallery);
    if (vid != null) {
      await _sendFile(File(vid.path));
    }
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
              _pickImages();
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

  // ================================
  // UI helpers
  // ================================
  Widget _bubbleContent(Map<String, dynamic> msg, bool isOut) {
    final type = (msg["type"] ?? "text").toString();
    final text = msg["text"] ?? "";
    final localPath = msg["local_path"];
    final url = msg["url"];
    final fileName = msg["file_name"];

    // Image
    if (type == "image") {
      final w = 220.0;
      final h = 260.0;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: localPath != null
                ? Image.file(File(localPath), width: w, height: h, fit: BoxFit.cover)
                : (url != null
                ? Image.network(url, width: w, height: h, fit: BoxFit.cover)
                : Container(
              width: w,
              height: h,
              color: Colors.black12,
              child: const Icon(Icons.image, size: 48),
            )),
          ),
          if (text.toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                text,
                style: TextStyle(color: isOut ? Colors.white : Colors.black87),
              ),
            ),
        ],
      );
    }

    // Video
    if (type == "video") {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 240,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (localPath != null)
                  const Icon(Icons.videocam, size: 48, color: Colors.black45)
                else if (url != null)
                  const Icon(Icons.videocam, size: 48, color: Colors.black45)
                else
                  const Icon(Icons.videocam_off, size: 48, color: Colors.black45),
                const Positioned(
                  bottom: 8,
                  child: Text("Video", style: TextStyle(color: Colors.black54)),
                ),
              ],
            ),
          ),
          if ((fileName ?? "").toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(fileName, style: TextStyle(color: isOut ? Colors.white70 : Colors.black54, fontSize: 12)),
            ),
          if (text.toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(text, style: TextStyle(color: isOut ? Colors.white : Colors.black87)),
            ),
        ],
      );
    }

    // Audio / File (simple row)
    if (type == "audio" || type == "file") {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(type == "audio" ? Icons.audiotrack : Icons.insert_drive_file,
              color: isOut ? Colors.white : Colors.black54),
          const SizedBox(width: 8),
          Text(fileName ?? 'file', style: TextStyle(color: isOut ? Colors.white : Colors.black87)),
        ],
      );
    }

    // Text
    return Text(
      text,
      style: TextStyle(color: isOut ? Colors.white : Colors.black87, fontSize: 15),
    );
  }

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
          const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: Colors.black),
          ),
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
        // reply banner (optional)
        if (_replyToMsg != null)
          Container(
            color: Colors.teal.shade100,
            padding: const EdgeInsets.all(8),
            child: Row(children: [
              Expanded(
                child: Text("↩️ Replying: ${_replyToMsg!["text"] ?? ""}",
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _replyToMsg = null),
              )
            ]),
          ),

        // 🔄 upload progress bar
        if (_uploadProgress > 0 && _uploadProgress < 100)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(value: _uploadProgress / 100.0),
                ),
                const SizedBox(width: 10),
                Text("${_uploadProgress.toStringAsFixed(0)}%"),
              ],
            ),
          ),

        // messages list
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            reverse: true,
            itemCount: provider.messages.length,
            itemBuilder: (context, i) {
              final msg = provider.messages[i];
              final isOut = msg["is_out"] == true;
              final time = msg["time"] ?? "";
              final uploading = msg["uploading"] == true;
              final progress = (msg["progress"] ?? 100.0).toDouble();

              return GestureDetector(
                onLongPress: () => setState(() => _replyToMsg = msg), // enable reply
                child: Align(
                  alignment: isOut ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isOut ? Colors.green.shade400 : Colors.grey.shade300,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(14),
                        topRight: const Radius.circular(14),
                        bottomLeft: isOut ? const Radius.circular(14) : const Radius.circular(0),
                        bottomRight: isOut ? const Radius.circular(0) : const Radius.circular(14),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _bubbleContent(msg, isOut),

                        if (uploading)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: SizedBox(
                              width: 160,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: LinearProgressIndicator(value: progress / 100.0),
                                  ),
                                  const SizedBox(width: 8),
                                  Text("${progress.toStringAsFixed(0)}%",
                                      style: TextStyle(
                                        color: isOut ? Colors.white70 : Colors.black54,
                                        fontSize: 11,
                                      )),
                                ],
                              ),
                            ),
                          ),

                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            time,
                            style: TextStyle(
                              color: isOut ? Colors.white70 : Colors.grey[700],
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // input row
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.green),
              onPressed: _showAttachmentMenu,
            ),
            Expanded(
              child: TextField(
                controller: _msgCtrl,
                decoration: const InputDecoration(hintText: "Message", border: InputBorder.none),
                onChanged: (_) => _typingStart(),
                onEditingComplete: _typingStop,
              ),
            ),
            _sending
                ? const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : IconButton(
              icon: const Icon(Icons.send, color: Colors.green),
              onPressed: _sendText,
            ),
          ]),
        ),
      ]),
    );
  }
}


