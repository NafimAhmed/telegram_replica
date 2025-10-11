// import 'dart:convert';
// import 'package:ag_taligram/url.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
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
//   List<Map<String, dynamic>> messages = [];
//   bool isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     fetchMessages();
//   }
//
//   Future<void> fetchMessages() async {
//     final url = Uri.parse(
//         "$urlLocal/messages?phone=${widget.phone}&chat_id=${widget.chatId}");
//     try {
//       final res = await http.get(url);
//       if (res.statusCode == 200) {
//         final data = json.decode(res.body);
//         if (data["messages"] is List) {
//           setState(() {
//             messages =
//             List<Map<String, dynamic>>.from(data["messages"].reversed); // latest bottom
//             isLoading = false;
//           });
//         }
//       }
//     } catch (e) {
//       print("⚠️ Message fetch error: $e");
//       setState(() => isLoading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Row(
//           children: [
//             CircleAvatar(child: Text(widget.name.isNotEmpty ? widget.name[0] : '?')),
//             const SizedBox(width: 10),
//             Text(widget.name),
//           ],
//         ),
//         backgroundColor: Colors.green,
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Column(
//         children: [
//           Expanded(
//             child: ListView.builder(
//               reverse: true,
//               padding: const EdgeInsets.all(8),
//               itemCount: messages.length,
//               itemBuilder: (context, index) {
//                 final msg = messages[index];
//                 final bool isOut = msg["is_out"] ?? false;
//                 final text = msg["text"] ?? "";
//                 final date = msg["date"]?.toString().substring(11, 16) ?? "";
//
//                 return Align(
//                   alignment:
//                   isOut ? Alignment.centerRight : Alignment.centerLeft,
//                   child: Container(
//                     margin: const EdgeInsets.symmetric(vertical: 4),
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 12, vertical: 8),
//                     constraints: const BoxConstraints(maxWidth: 280),
//                     decoration: BoxDecoration(
//                       color: isOut
//                           ? Colors.green.shade300
//                           : Colors.grey.shade200,
//                       borderRadius: BorderRadius.only(
//                         topLeft: const Radius.circular(12),
//                         topRight: const Radius.circular(12),
//                         bottomLeft: isOut
//                             ? const Radius.circular(12)
//                             : const Radius.circular(0),
//                         bottomRight: isOut
//                             ? const Radius.circular(0)
//                             : const Radius.circular(12),
//                       ),
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(text,
//                             style: TextStyle(
//                               color: isOut
//                                   ? Colors.white
//                                   : Colors.grey.shade900,
//                             )),
//                         const SizedBox(height: 4),
//                         Align(
//                           alignment: Alignment.bottomRight,
//                           child: Text(
//                             date,
//                             style: TextStyle(
//                               fontSize: 10,
//                               color: isOut
//                                   ? Colors.white70
//                                   : Colors.grey.shade600,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//           // Text input area
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//             color: Colors.white,
//             child: Row(
//               children: [
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
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatScreen extends StatefulWidget {
  final String phone;
  final int chatId;
  final String name;
  const ChatScreen({super.key, required this.phone, required this.chatId, required this.name});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List messages = [];
  bool loading = true;
  final String baseUrl = "http://192.168.0.247:8080";

  @override
  void initState() {
    super.initState();
    fetchMessages();
  }

  Future<void> fetchMessages() async {
    try {
      final url = Uri.parse("$baseUrl/messages?phone=${widget.phone}&chat_id=${widget.chatId}");
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          messages = data["messages"] ?? [];
          loading = false;
        });
      }
    } catch (e) {
      print("❌ Message fetch error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        reverse: true,
        itemCount: messages.length,
        itemBuilder: (context, i) {
          final m = messages[i];
          final bool isOut = m["is_out"] == true;
          return Align(
            alignment: isOut ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isOut ? Colors.green.shade400 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                m["text"] ?? "",
                style: TextStyle(
                  color: isOut ? Colors.white : Colors.black87,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
