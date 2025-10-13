//
//
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:provider/provider.dart';
// import '../providers/telegraph_qg_provider.dart';
//
// class ChatScreen extends StatefulWidget {
//   final String phone;
//   final int chatId;
//   final String name;
//
//   const ChatScreen({
//     super.key,
//     required this.phone,
//     required this.chatId,
//     required this.name,
//   });
//
//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }
//
// class _ChatScreenState extends State<ChatScreen> {
//   final ScrollController _scrollController = ScrollController();
//   bool _loading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchAndLoad();
//   }
//
//   Future<void> _fetchAndLoad() async {
//     final provider = Provider.of<TelegraphProvider>(context, listen: false);
//     await provider.fetchMessages(widget.phone, widget.chatId);
//     setState(() => _loading = false);
//   }
//
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
//           Expanded(
//             child: ListView.builder(
//               controller: _scrollController,
//               reverse: true,
//               itemCount: provider.messages.length,
//               itemBuilder: (context, i) {
//                 final msg = provider.messages[i];
//                 final bool isOut = msg["is_out"] == true;
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
//                         Text(
//                           text,
//                           style: TextStyle(
//                             color: isOut
//                                 ? Colors.white
//                                 : Colors.black87,
//                             fontSize: 15,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
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
//           Container(
//             color: Colors.white,
//             padding:
//             const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//             child: Row(
//               children: [
//                 const Icon(Icons.emoji_emotions_outlined,
//                     color: Colors.green),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: TextField(
//                     decoration: const InputDecoration(
//                       hintText: "Message",
//                       border: InputBorder.none,
//                     ),
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.send, color: Colors.green),
//                   onPressed: () {},
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
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../providers/telegraph_qg_provider.dart';

class ChatScreen extends StatefulWidget {
  final String phone;
  final int chatId;
  final String name;

  const ChatScreen({
    super.key,
    required this.phone,
    required this.chatId,
    required this.name,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _msgCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool _loading = true;
  bool _sending = false;
  List<File> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    _fetchAndLoad();
  }

  Future<void> _fetchAndLoad() async {
    final provider = Provider.of<TelegraphProvider>(context, listen: false);
    await provider.fetchMessages(widget.phone, widget.chatId);
    setState(() => _loading = false);
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.photos,
      Permission.storage,
    ].request();
  }

  // ✅ Pick multiple images from gallery
  Future<void> _pickFromGallery() async {
    await _requestPermissions();
    final picked = await _picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(picked.map((e) => File(e.path)));
      });
    }
  }

  // ✅ Take photo from camera
  Future<void> _pickFromCamera() async {
    await _requestPermissions();
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        _selectedImages.add(File(picked.path));
      });
    }
  }

  // ✅ Send message + images
  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty && _selectedImages.isEmpty) return;

    setState(() => _sending = true);
    final provider = Provider.of<TelegraphProvider>(context, listen: false);
    final url = Uri.parse("${provider.baseUrl}/send_message");

    try {
      var req = http.MultipartRequest('POST', url)
        ..fields['phone'] = widget.phone
        ..fields['chat_id'] = widget.chatId.toString()
        ..fields['text'] = text;

      // add all selected images
      for (var img in _selectedImages) {
        req.files.add(await http.MultipartFile.fromPath('file', img.path));
      }

      final res = await req.send();
      final body = await res.stream.bytesToString();
      print("📩 Send Response: $body");

      if (res.statusCode == 200) {
        _msgCtrl.clear();
        setState(() => _selectedImages.clear());
        await _fetchAndLoad();
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Failed: $body")));
      }
    } catch (e) {
      print("❌ Send error: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _sending = false);
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
          // 🔹 small thumbnails preview (selected images)
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

          // 🔹 message list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              itemCount: provider.messages.length,
              itemBuilder: (context, i) {
                final msg = provider.messages[i];
                final bool isOut = msg["is_out"] == true;
                final text = msg["text"] ?? "";
                final time = msg["time"] ?? "";
                final fileUrl = msg["file"] ?? "";

                final bool isImage = fileUrl.toString().endsWith(".jpg") ||
                    fileUrl.toString().endsWith(".png") ||
                    fileUrl.toString().endsWith(".jpeg");

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
                        if (isImage)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              fileUrl,
                              width: 180,
                              fit: BoxFit.cover,
                            ),
                          ),
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

          // 🔹 bottom input bar
          Container(
            color: Colors.white,
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                //  InkWell(
                //      onTap: (){
                //        // Navigator.pop(context);
                //        _pickFromGallery();
                //      },
                //      child: Icon(Icons.photo, color: Colors.green)),
                // SizedBox(width: 5,),
                // InkWell(
                //     onTap: (){
                //       // Navigator.pop(context);
                //       _pickFromCamera();
                //     },
                //     child: Icon(Icons.camera_alt, color: Colors.green)),
                // SizedBox(width: 5,),
                IconButton(
                  icon: const Icon(Icons.add,
                      color: Colors.green),
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
                  child:
                  CircularProgressIndicator(strokeWidth: 2),
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
