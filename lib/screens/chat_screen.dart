import 'dart:convert';
import 'dart:io';
import 'package:ag_taligram/url.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
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
  List<File> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    _fetchAndLoad(); // Load old messages
    _connectWebSocket(); // Connect WS for real-time
  }

  @override
  void dispose() {
    _socket?.close();
    super.dispose();
  }

  // ✅ Connect WebSocket
  Future<void> _connectWebSocket() async {
    try {
      final wsUrl = 'ws://192.168.0.247:8080/chat_ws';
      _socket = await WebSocket.connect(wsUrl);
      print("✅ WebSocket Connected");

      // 🔹 Send initialization (start listening for this chat)
      final init = {
        "phone": widget.phone,
        "chat_id": widget.chatId,
      };
      _socket!.add(jsonEncode(init));

      // 🔹 Listen for new messages
      _socket!.listen((raw) {
        try {
          final decoded = jsonDecode(raw);
          print("📩 WS RECEIVED → $decoded");

          if (decoded["action"] == "new_message") {
            // ✅ Incoming Telegram message
            if (decoded["chat_id"].toString() ==
                widget.chatId.toString()) {
              final provider =
              Provider.of<TelegraphProvider>(context, listen: false);
              provider.messages.insert(0, {
                "text": decoded["text"] ?? "",
                "is_out": false,
                "time": decoded["date"] ?? DateTime.now().toString(),
              });
              provider.notifyListeners();
            }
          } else if (decoded["status"] == "sent") {
            print("✅ Message confirmed sent: ${decoded["text"]}");
          } else if (decoded["status"] == "error") {
            print("❌ WS Error: ${decoded["detail"]}");
          }
        } catch (e) {
          print("⚠️ Decode error: $e");
        }
      }, onDone: () {
        print("⚠️ WS closed. Reconnecting in 3s...");
        Future.delayed(const Duration(seconds: 3), _connectWebSocket);
      }, onError: (e) {
        print("❌ WS error: $e");
        Future.delayed(const Duration(seconds: 5), _connectWebSocket);
      });
    } catch (e) {
      print("❌ WS connect failed: $e");
      Future.delayed(const Duration(seconds: 5), _connectWebSocket);
    }
  }

  // ✅ Fetch old messages
  Future<void> _fetchAndLoad() async {
    final provider = Provider.of<TelegraphProvider>(context, listen: false);
    await provider.fetchMessages(
        widget.phone, widget.chatId, widget.accessHash);
    setState(() => _loading = false);
  }

  // ✅ Send message (via WebSocket → fallback HTTP)
  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    final provider = Provider.of<TelegraphProvider>(context, listen: false);

    try {
      if (_socket != null && _socket!.readyState == WebSocket.open) {
        final msg = {
          "action": "send",
          "phone": widget.phone,
          "chat_id": widget.chatId,
          "access_hash": widget.accessHash,
          "text": text,
        };
        _socket!.add(jsonEncode(msg));
        print("📤 WS SENT → $msg");

        // Show message instantly
        provider.messages.insert(0, {
          "text": text,
          "is_out": true,
          "time": DateTime.now().toString(),
        });
        provider.notifyListeners();
        _msgCtrl.clear();
      } else {
        // HTTP fallback
        final url = Uri.parse("$urlLocal/send");
        final res = await http.post(url, body: {
          "phone": widget.phone,
          "to": widget.username,
          "text": text,
        });

        if (res.statusCode == 200) {
          provider.messages.insert(0, {
            "text": text,
            "is_out": true,
            "time": DateTime.now().toString(),
          });
          provider.notifyListeners();
          _msgCtrl.clear();
        }
      }
    } catch (e) {
      print("⚠️ Send error: $e");
    } finally {
      setState(() => _sending = false);
    }
  }

  // 📸 Image picker logic
  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.photos,
      Permission.storage,
    ].request();
  }

  Future<void> _pickFromGallery() async {
    await _requestPermissions();
    final picked = await _picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      setState(() => _selectedImages.addAll(picked.map((e) => File(e.path))));
    }
  }

  Future<void> _pickFromCamera() async {
    await _requestPermissions();
    final picked =
    await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (picked != null) {
      setState(() => _selectedImages.add(File(picked.path)));
    }
  }

  void _showSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo, color: Colors.green),
              title: const Text("Gallery থেকে নিন"),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text("Camera দিয়ে তুলুন"),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromCamera();
              },
            ),
          ],
        ),
      ),
    );
  }

  // 🧱 UI build
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TelegraphProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFE5DDD5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF008069),
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.black),
            ),
            const SizedBox(width: 10),
            Text(widget.name,
                style: const TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          if (_selectedImages.isNotEmpty)
            Container(
              height: 90,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                itemBuilder: (context, i) {
                  final file = _selectedImages[i];
                  return Stack(
                    children: [
                      Container(
                        margin:
                        const EdgeInsets.symmetric(horizontal: 4),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            file,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 6,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImages.removeAt(i);
                            });
                          },
                          child: const CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.black54,
                            child: Icon(Icons.close,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

          // 🔹 Messages list (real-time)
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              itemCount: provider.messages.length,
              itemBuilder: (context, i) {
                final msg = provider.messages[i];
                final isOut = msg["is_out"] == true;
                final text = msg["text"] ?? "";
                final time = msg["time"] ?? "";

                return Align(
                  alignment: isOut
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        vertical: 4, horizontal: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isOut
                          ? Colors.green.shade400
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(14),
                        topRight: const Radius.circular(14),
                        bottomLeft: isOut
                            ? const Radius.circular(14)
                            : const Radius.circular(0),
                        bottomRight: isOut
                            ? const Radius.circular(0)
                            : const Radius.circular(14),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (text.isNotEmpty)
                          Padding(
                            padding:
                            const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              text,
                              style: TextStyle(
                                color: isOut
                                    ? Colors.white
                                    : Colors.black87,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        Text(
                          time,
                          style: TextStyle(
                            color: isOut
                                ? Colors.white70
                                : Colors.grey[700],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 🔹 Message Input
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.green),
                  onPressed: _showSourceDialog,
                ),
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    decoration: const InputDecoration(
                      hintText: "Message",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                _sending
                    ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : IconButton(
                  icon: const Icon(Icons.send, color: Colors.green),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
