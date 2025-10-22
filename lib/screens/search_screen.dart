//
//
// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import '../url.dart';
// import 'chat_screen.dart';
//
// class SearchScreen extends StatefulWidget {
//   final String phoneNumbar;
//
//   const SearchScreen({super.key, required this.phoneNumbar});
//
//   @override
//   State<SearchScreen> createState() => _SearchScreenState();
// }
//
// class _SearchScreenState extends State<SearchScreen> {
//   final TextEditingController _searchCtrl = TextEditingController();
//   final List<Map<String, dynamic>> _results = [];
//   bool _loading = false;
//
//   Timer? _debounce; // ✅ টাইপিং delay control
//
//   @override
//   void dispose() {
//     _debounce?.cancel();
//     _searchCtrl.dispose();
//     super.dispose();
//   }
//
//   // 🔍 Debounced live search
//   void _onSearchChanged(String text) {
//     _debounce?.cancel();
//     if (text.trim().isEmpty) {
//       setState(() {
//         _results.clear();
//       });
//       return;
//     }
//
//     // 300 ms delay after user stops typing
//     _debounce = Timer(const Duration(milliseconds: 400), () {
//       _searchUsers(text.trim());
//     });
//   }
//
//   // 🔹 Actual API call
//   Future<void> _searchUsers(String query) async {
//     if (query.isEmpty) return;
//     setState(() => _loading = true);
//
//     try {
//       final uri = Uri.parse(
//           '$urlLocal/search_people?q=$query&phone=${widget.phoneNumbar}');
//       debugPrint("📡 Request: $uri");
//       final res = await http.get(uri);
//
//       if (res.statusCode == 200) {
//         final data = jsonDecode(res.body);
//         final List<dynamic> arr = data["results"] ?? [];
//         setState(() {
//           _results
//             ..clear()
//             ..addAll(arr.map((e) => Map<String, dynamic>.from(e)));
//         });
//       } else {
//         setState(() => _results.clear());
//       }
//     } catch (e) {
//       debugPrint("⚠️ Search error: $e");
//       setState(() => _results.clear());
//     } finally {
//       setState(() => _loading = false);
//     }
//   }
//
//   // 🔹 Open chat
//   void _openChat(Map<String, dynamic> user) {
//     final myPhone = widget.phoneNumbar;
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => ChatScreen(
//           phone: myPhone,
//           chatId: user["chat_id"],
//           accessHash: user["access_hash"],
//           name: user["name"] ?? "Unknown",
//           username: user["username"] ?? "",
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF17212B),
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF17212B),
//         titleSpacing: 0,
//         elevation: 0,
//         title: Row(
//           children: [
//             // IconButton(
//             //   icon: const Icon(Icons.arrow_back, color: Colors.white),
//             //   onPressed: () => Navigator.pop(context),
//             // ),
//             Expanded(
//               child: TextField(
//                 controller: _searchCtrl,
//                 style: const TextStyle(color: Colors.white),
//                 decoration: const InputDecoration(
//                   hintText: 'Search',
//                   hintStyle: TextStyle(color: Colors.white70),
//                   border: InputBorder.none,
//                 ),
//                 onChanged: _onSearchChanged, // ✅ live typing search
//               ),
//             ),
//             if (_loading)
//               const Padding(
//                 padding: EdgeInsets.only(right: 10),
//                 child: SizedBox(
//                   width: 20,
//                   height: 20,
//                   child: CircularProgressIndicator(
//                     strokeWidth: 2,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//
//       // Body auto updates when _results changes
//       body: _results.isEmpty
//           ? const Center(
//         child: Text(
//           "Search for users...",
//           style: TextStyle(color: Colors.white54),
//         ),
//       )
//           : ListView.builder(
//         itemCount: _results.length,
//         itemBuilder: (context, index) {
//           final user = _results[index];
//           final name = user["name"] ?? "Unknown";
//           final username = user["username"] ?? "";
//           return InkWell(
//             onTap: () => _openChat(user),
//             child: Container(
//               color: Colors.transparent,
//               padding:
//               const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
//               child: Row(
//                 children: [
//                   // Avatar
//                   CircleAvatar(
//                     radius: 26,
//                     backgroundColor: Colors.blueGrey.shade600,
//                     child: Text(
//                       name.isNotEmpty ? name[0].toUpperCase() : "?",
//                       style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 22,
//                           fontWeight: FontWeight.bold),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   // Name and username
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           name,
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 17,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         const SizedBox(height: 3),
//                         Text(
//                           "@$username",
//                           style: const TextStyle(
//                             color: Colors.white54,
//                             fontSize: 13,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   // Message icon
//                   IconButton(
//                     icon: const Icon(Icons.message,
//                         color: Colors.lightBlueAccent),
//                     onPressed: () => _openChat(user),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../url.dart';
import 'chat_screen.dart';

class SearchScreen extends StatefulWidget {
  final String phoneNumbar;
  const SearchScreen({super.key, required this.phoneNumbar});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final List<Map<String, dynamic>> _results = [];
  Map<String, dynamic>? _lastUser; // ✅ Last searched user
  bool _loading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadLastUser(); // 🔹 load from local storage
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  // 🧠 Load recent user from local storage
  Future<void> _loadLastUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('last_user');
    if (userJson != null) {
      setState(() {
        _lastUser = jsonDecode(userJson);
      });
    }
  }

  // 💾 Save recent user locally
  Future<void> _saveLastUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_user', jsonEncode(user));
    setState(() => _lastUser = user);
  }

  // 🔍 Live search debounce
  void _onSearchChanged(String text) {
    _debounce?.cancel();
    if (text.trim().isEmpty) {
      setState(() => _results.clear());
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchUsers(text.trim());
    });
  }

  // 🔹 API call
  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) return;
    setState(() => _loading = true);

    try {
      final uri = Uri.parse(
          '$urlLocal/search_people?q=$query&phone=${widget.phoneNumbar}');
      debugPrint("📡 Request: $uri");

      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<dynamic> arr = data["results"] ?? [];

        setState(() {
          _results
            ..clear()
            ..addAll(arr.map((e) => Map<String, dynamic>.from(e)));
        });
      } else {
        setState(() => _results.clear());
      }
    } catch (e) {
      debugPrint("⚠️ Search error: $e");
      setState(() => _results.clear());
    } finally {
      setState(() => _loading = false);
    }
  }

  // 🔹 Open Chat + Save user
  void _openChat(Map<String, dynamic> user) async {
    await _saveLastUser(user); // ✅ save to local
    final myPhone = widget.phoneNumbar;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          phone: myPhone,
          chatId: user["chat_id"],
          accessHash: user["access_hash"],
          name: user["name"] ?? "Unknown",
          username: user["username"] ?? "",
        ),
      ),
    );
  }

  // 🎨 User Tile
  Widget _buildUserTile(Map<String, dynamic> user, {bool highlight = false}) {
    final name = user["name"] ?? "Unknown";
    final username = user["username"] ?? "";
    return InkWell(
      onTap: () => _openChat(user),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: highlight
              ? const Color(0xFF1E3346)
              : const Color(0xFF1A2633),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            if (highlight)
              BoxShadow(
                color: Colors.lightBlueAccent.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.blueAccent.shade400,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : "?",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text("@$username",
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.message_rounded,
                color: Colors.lightBlueAccent, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() => const Center(
    child: Text("Search for users...",
        style: TextStyle(color: Colors.white54)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1923),
      appBar: AppBar(
        backgroundColor:  Colors.green,
        elevation: 0,
        titleSpacing: 0,
        title: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color:  Colors.grey,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const SizedBox(width: 8),
              const Icon(Icons.search, color: Colors.black, size: 22),
              const SizedBox(width: 4),
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Search',
                    hintStyle: const TextStyle(color: Colors.black),
                    filled: true,
                    fillColor:  Colors.grey,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    // enabledBorder: OutlineInputBorder(
                    //   borderRadius: BorderRadius.circular(12),
                    //   borderSide: const BorderSide(color: Colors.white24, width: 1),
                    // ),
                    // focusedBorder: OutlineInputBorder(
                    //   borderRadius: BorderRadius.circular(12),
                    //   borderSide: const BorderSide(color: Colors.lightBlueAccent, width: 2),
                    // ),
                  ),
                  // decoration: const InputDecoration(
                  //   hintText: 'Search',
                  //   hintStyle: TextStyle(color: Colors.white54),
                  //   border: InputBorder.none,
                  // ),
                  onChanged: _onSearchChanged,
                ),
              ),
              if (_searchCtrl.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black, size: 20),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _results.clear());
                  },
                ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),

      // 🧠 Body
      body: _results.isEmpty
          ? (_lastUser != null
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding:
            EdgeInsets.only(left: 18, top: 20, bottom: 10),
            child: Text(
              "Recent Search",
              style: TextStyle(
                  color: Colors.white54,
                  fontSize: 15,
                  fontWeight: FontWeight.w500),
            ),
          ),
          _buildUserTile(_lastUser!, highlight: true),
        ],
      )
          : _buildEmpty())
          : ListView.builder(
        itemCount: _results.length,
        itemBuilder: (context, i) =>
            _buildUserTile(_results[i]),
      ),
    );
  }
}
