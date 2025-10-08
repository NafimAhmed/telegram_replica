// import 'dart:convert';
//
// import 'package:ag_taligram/url.dart';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http;
// import 'main.dart'; // তোমার login/otp screen main.dart এখানে থাকবে
//
// class TelegraphApp extends StatefulWidget {
//   final Map<String, String>? userData; // <-- receive userData from OTP screen
//    TelegraphApp({super.key, this.userData});
//
//   @override
//   State<TelegraphApp> createState() => _TelegraphAppState();
// }
//
//
// class _TelegraphAppState extends State<TelegraphApp> {
//   String firstName = "";
//   String lastName = "";
//   String username = "";
//   String phoneNumber = "";
//   bool isDark = false;
//   bool isChinese = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadUser();
//   }
//
//   Future<void> _loadUser() async {
//     if (widget.userData != null) {
//       // Data direct আসছে OTP থেকে
//       setState(() {
//         firstName = widget.userData!['first_name'] ?? '';
//         lastName = widget.userData!['last_name'] ?? '';
//         username = widget.userData!['username'] ?? '';
//         phoneNumber = widget.userData!['phone_number'] ?? '';
//       });
//     } else {
//       // fallback — SharedPreferences থেকে load করবে
//       final prefs = await SharedPreferences.getInstance();
//       setState(() {
//         firstName = prefs.getString('first_name') ?? '';
//         lastName = prefs.getString('last_name') ?? '';
//         username = prefs.getString('username') ?? '';
//         phoneNumber = prefs.getString('phone_number') ?? '';
//       });
//     }
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Telegraph',
//       debugShowCheckedModeBanner: false,
//       themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
//       darkTheme: ThemeData.dark().copyWith(
//         scaffoldBackgroundColor: const Color(0xFF1E2429),
//         appBarTheme: const AppBarTheme(
//           backgroundColor: Color(0xFF2C343A),
//           foregroundColor: Colors.white,
//         ),
//         drawerTheme: const DrawerThemeData(backgroundColor: Color(0xFF2C343A)),
//       ),
//       theme: ThemeData(
//         primaryColor: Colors.green,
//         scaffoldBackgroundColor: Colors.white,
//         appBarTheme: const AppBarTheme(
//           color: Colors.green,
//           foregroundColor: Colors.white,
//           elevation: 0,
//         ),
//       ),
//       home: TelegraphHome(
//         isDark: isDark,
//         isChinese: isChinese,
//         onThemeToggle: () => setState(() => isDark = !isDark),
//         onLangToggle: () => setState(() => isChinese = !isChinese),
//         firstName: firstName,
//         lastName: lastName,
//         username: username,
//         phoneNumber: phoneNumber,
//       ),
//     );
//   }
// }
//
// class TelegraphHome extends StatefulWidget {
//   final bool isDark;
//   final bool isChinese;
//   final VoidCallback onThemeToggle;
//   final VoidCallback onLangToggle;
//   final String firstName;
//   final String lastName;
//   final String username;
//   final String phoneNumber;
//   const TelegraphHome({
//     super.key,
//     required this.isDark,
//     required this.isChinese,
//     required this.onThemeToggle,
//     required this.onLangToggle,
//     required this.firstName,
//     required this.lastName,
//     required this.username,
//     required this.phoneNumber,
//   });
//
//   @override
//   State<TelegraphHome> createState() => _TelegraphHomeState();
// }
//
// class _TelegraphHomeState extends State<TelegraphHome>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   final List<Map<String, String>> chats = [
//     {"name": "Graph AI Chat", "msg": "Chat with me!", "time": "Now"},
//     {"name": "UserInfoBot", "msg": "Verification needed", "time": "Mon"},
//     {"name": "BotFather", "msg": "Choose a bot from the list", "time": "Jun 12"},
//   ];
//
//   String t(String en, String zh) => widget.isChinese ? zh : en;
//
//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 4, vsync: this);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       drawer: TelegraphDrawer(
//         isDark: widget.isDark,
//         isChinese: widget.isChinese,
//         onThemeToggle: widget.onThemeToggle,
//         onLangToggle: widget.onLangToggle,
//         firstName: widget.firstName,
//         lastName: widget.lastName,
//         username: widget.username,
//         phoneNumber: widget.phoneNumber,
//       ),
//       appBar: AppBar(
//         title: Text(t(widget.firstName.isNotEmpty ? widget.firstName :"Telegraph", "电报")),
//         bottom: TabBar(
//           controller: _tabController,
//           indicatorColor: Colors.white,
//           indicatorWeight: 3,
//           tabs: const [
//             Tab(icon: Icon(Icons.chat_bubble_outline)),
//             Tab(icon: Icon(Icons.contacts_outlined)),
//             Tab(icon: Icon(Icons.call_outlined)),
//             Tab(icon: Icon(Icons.settings_outlined)),
//           ],
//         ),
//         actions: [
//           IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () {}),
//           IconButton(icon: const Icon(Icons.search), onPressed: () {}),
//         ],
//       ),
//       body: TabBarView(
//         controller: _tabController,
//         children: [
//           _buildChatsTab(),
//           _buildContactsTab(),
//           _buildCallsTab(),
//           _buildSettingsTab(),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         backgroundColor: Colors.red,
//         onPressed: () {},
//         child: const Icon(Icons.camera_alt_outlined),
//       ),
//     );
//   }
//
//   Widget _buildChatsTab() => ListView.builder(
//     itemCount: chats.length,
//     itemBuilder: (context, index) {
//       final chat = chats[index];
//       return ListTile(
//         leading: CircleAvatar(
//           backgroundColor: Colors.green,
//           child: Text(chat['name']![0],
//               style: const TextStyle(color: Colors.white)),
//         ),
//         title: Text(chat['name']!,
//             style: const TextStyle(fontWeight: FontWeight.w600)),
//         subtitle: Text(chat['msg']!,
//             maxLines: 1, overflow: TextOverflow.ellipsis),
//         trailing: Text(chat['time']!,
//             style: const TextStyle(color: Colors.grey, fontSize: 12)),
//       );
//     },
//   );
//
//   Widget _buildContactsTab() => ListView(
//     children: [
//       ListTile(
//           leading: const Icon(Icons.person_outline),
//           title: Text(t("Tamjid Dev", "谭吉德夫")),
//           subtitle: const Text("+880 1928478904")),
//       ListTile(
//           leading: const Icon(Icons.person_outline),
//           title: Text(t("Rakib Hasan", "拉基布")),
//           subtitle: const Text("+880 1710000000")),
//     ],
//   );
//
//   Widget _buildCallsTab() => ListView(
//     children: [
//       ListTile(
//           leading: const Icon(Icons.call_received, color: Colors.red),
//           title: Text(t("Missed Call – Rakib Hasan", "未接来电 – 拉基布")),
//           subtitle: Text(t("Yesterday 9:40 PM", "昨天 晚上9:40"))),
//       ListTile(
//           leading: const Icon(Icons.call_made, color: Colors.green),
//           title: Text(t("Outgoing Call – Tamjid Dev", "已拨电话 – 谭吉德夫")),
//           subtitle: Text(t("Today 10:12 AM", "今天 上午10:12"))),
//     ],
//   );
//
//   Widget _buildSettingsTab() => ListView(
//     children: [
//       ListTile(
//           leading: const Icon(Icons.settings),
//           title: Text(t("Account", "账户"))),
//       ListTile(
//           leading: const Icon(Icons.lock_outline),
//           title: Text(t("Privacy & Security", "隐私与安全"))),
//       ListTile(
//           leading: const Icon(Icons.notifications),
//           title: Text(t("Notifications", "通知"))),
//       ListTile(
//           leading: const Icon(Icons.color_lens_outlined),
//           title: Text(t("Theme", "主题"))),
//     ],
//   );
// }
//
// // =================== Drawer ===================
//
// class TelegraphDrawer extends StatefulWidget {
//   final bool isDark;
//   final bool isChinese;
//   final VoidCallback onThemeToggle;
//   final VoidCallback onLangToggle;
//   final String firstName;
//   final String lastName;
//   final String username;
//   final String phoneNumber;
//
//   const TelegraphDrawer({
//     super.key,
//     required this.isDark,
//     required this.isChinese,
//     required this.onThemeToggle,
//     required this.onLangToggle,
//     required this.firstName,
//     required this.lastName,
//     required this.username,
//     required this.phoneNumber,
//   });
//
//   @override
//   State<TelegraphDrawer> createState() => _TelegraphDrawerState();
// }
//
// class _TelegraphDrawerState extends State<TelegraphDrawer> {
//   bool showAccounts = false;
//   List<Map<String, String>> accounts = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _loadAccounts();
//   }
//
//   // 🔹 Load from SharedPreferences
//   Future<void> _loadAccounts() async {
//     final prefs = await SharedPreferences.getInstance();
//     final savedData = prefs.getString('accounts');
//
//     if (savedData != null) {
//       setState(() {
//         accounts = List<Map<String, String>>.from(json.decode(savedData));
//       });
//     } else {
//       accounts = [
//         {
//           "name": "Tamjid Dev",
//           "phone": "+8801928478904",
//           "avatar": "assets/panda.jpg"
//         }
//       ];
//       await prefs.setString('accounts', json.encode(accounts));
//     }
//   }
//
//   // 🔹 Save to SharedPreferences
//   Future<void> _saveAccounts() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('accounts', json.encode(accounts));
//   }
//
//   // 🔹 Add new account
//   Future<void> _addAccount() async {
//     setState(() {
//       accounts.add({
//         "name": "New User ${accounts.length + 1}",
//         "phone": "+8801XXXXXXXXX",
//         "avatar": "assets/panda.jpg"
//       });
//     });
//     await _saveAccounts();
//   }
//
//   // 🔹 Logout
//   Future<void> logout(BuildContext context) async {
//     final prefs = await SharedPreferences.getInstance();
//     final phone = prefs.getString('phone') ?? "";
//
//     try {
//       final url = Uri.parse("$urlLocal/logout");
//       final req = http.MultipartRequest('POST', url);
//       req.fields['phone'] = phone;
//       await req.send();
//     } catch (e) {
//       debugPrint("Logout API Error: $e");
//     }
//
//     await prefs.clear();
//
//     Navigator.pushAndRemoveUntil(
//       context,
//       MaterialPageRoute(builder: (_) => const PhoneLoginScreen()),
//           (route) => false,
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     String t(String en, String zh) => widget.isChinese ? zh : en;
//
//     return Drawer(
//       width: 300,
//       child: Container(
//         color: widget.isDark ? Colors.black : Colors.white,
//         child: Column(
//           children: [
//             // 🔹 HEADER
//             AnimatedContainer(
//               duration: const Duration(milliseconds: 300),
//               color: widget.isDark ? Colors.grey[900] : Colors.red,
//               padding: const EdgeInsets.only(top: 40, left: 10, right: 10, bottom: 10),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       CircleAvatar(
//                         radius: 28,
//                         backgroundColor: Colors.white,
//                         backgroundImage: const AssetImage('assets/panda.jpg'),
//                       ),
//                       const SizedBox(width: 12),
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             widget.firstName.isNotEmpty ? widget.firstName: "User",
//                             style: const TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold),
//                           ),
//                           Text(
//                             accounts.isNotEmpty ? accounts.first['phone']! : "",
//                             style: const TextStyle(
//                                 color: Colors.white70, fontSize: 13),
//                           ),
//                         ],
//                       ),
//                       const Spacer(),
//                       Column(
//                         children: [
//                           IconButton(
//                             icon: const Icon(Icons.brightness_6_outlined,
//                                 color: Colors.white),
//                             onPressed: widget.onThemeToggle,
//                           ),
//                           IconButton(
//                             icon: const Icon(Icons.translate_outlined,
//                                 color: Colors.white),
//                             onPressed: widget.onLangToggle,
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
//                   GestureDetector(
//                     onTap: () =>
//                         setState(() => showAccounts = !showAccounts),
//                     child: Row(
//                       children: [
//                         const Icon(Icons.person_outline, color: Colors.white),
//                         const SizedBox(width: 8),
//                         Text(
//                           t("My Accounts", "我的账户"),
//                           style: const TextStyle(color: Colors.white),
//                         ),
//                         const Spacer(),
//                         Icon(
//                           showAccounts
//                               ? Icons.keyboard_arrow_up
//                               : Icons.keyboard_arrow_down,
//                           color: Colors.white,
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//
//                   // 🔽 Accounts dropdown
//                   if (showAccounts)
//                     Container(
//                       constraints: const BoxConstraints(maxHeight: 180),
//                       child: ListView.builder(
//                         shrinkWrap: true,
//                         itemCount: accounts.length + 1,
//                         itemBuilder: (context, index) {
//                           if (index == accounts.length) {
//                             return ListTile(
//                               leading: const Icon(Icons.add,
//                                   color: Colors.white, size: 22),
//                               title: const Text(
//                                 "Add Account",
//                                 style: TextStyle(color: Colors.white),
//                               ),
//                               onTap: _addAccount,
//                             );
//                           }
//                           final acc = accounts[index];
//                           return ListTile(
//                             leading: CircleAvatar(
//                               radius: 16,
//                               backgroundImage:
//                               const AssetImage('assets/panda.jpg'),
//                             ),
//                             title: Text(
//                               acc["name"] ?? "",
//                               style: const TextStyle(color: Colors.white),
//                             ),
//                             subtitle: Text(
//                               acc["phone"] ?? "",
//                               style: const TextStyle(
//                                   color: Colors.white70, fontSize: 12),
//                             ),
//                             trailing: Container(
//                               padding: const EdgeInsets.symmetric(
//                                   horizontal: 8, vertical: 2),
//                               decoration: BoxDecoration(
//                                 color: Colors.white.withOpacity(0.2),
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               child: const Text("⚙️",
//                                   style: TextStyle(color: Colors.white)),
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//
//             // 🔹 BODY (Scrollable)
//             Expanded(
//               child: ListView(
//                 padding: EdgeInsets.zero,
//                 children: [
//                   ListTile(
//                       leading: const Icon(Icons.person),
//                       title: Text(t("My Profile", "我的资料"))),
//                   ListTile(
//                       leading: const Icon(Icons.star_border),
//                       title: Text(t("Special Features", "特色功能"))),
//                   ListTile(
//                       leading: const Icon(Icons.chat_bubble_outline),
//                       title: Text(t("New Chat", "新聊天"))),
//                   const Divider(),
//                   ListTile(
//                       leading: const Icon(Icons.contacts),
//                       title: Text(t("Contacts", "联系人"))),
//                   ListTile(
//                       leading: const Icon(Icons.history),
//                       title: Text(t("Contact Changes", "联系人变更"))),
//                   ListTile(
//                       leading: const Icon(Icons.call),
//                       title: Text(t("Calls", "通话"))),
//                   ListTile(
//                       leading: const Icon(Icons.search),
//                       title: Text(t("ID Finder", "ID查找"))),
//                   const Divider(),
//                   ListTile(
//                       leading: const Icon(Icons.settings),
//                       title: Text(t("Settings", "设置"))),
//                   ListTile(
//                       leading: const Icon(Icons.color_lens_outlined),
//                       title: Text(t("Theme Settings", "主题设置"))),
//                   ListTile(
//                       leading: const Icon(Icons.group_add_outlined),
//                       title: Text(t("Invite Friends", "邀请好友"))),
//                   const Divider(),
//                   ListTile(
//                     leading: const Icon(Icons.logout, color: Colors.red),
//                     title: Text(t("Logout", "退出登录"),
//                         style: const TextStyle(color: Colors.red)),
//                     onTap: () => logout(context),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'main.dart';
import 'url.dart';

class TelegraphApp extends StatefulWidget {
  final Map<String, String>? userData;
  const TelegraphApp({super.key, this.userData});

  @override
  State<TelegraphApp> createState() => _TelegraphAppState();
}

class _TelegraphAppState extends State<TelegraphApp> {
  String firstName = "";
  String lastName = "";
  String username = "";
  String phoneNumber = "";
  bool isDark = false;
  bool isChinese = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> accounts = [];

    final saved = prefs.getString('accounts');
    if (saved != null) {
      accounts = List<Map<String, dynamic>>.from(json.decode(saved));
    }

    // যদি userData আসে OTP থেকে, নতুনটাকে accounts list-এ যোগ করবে
    if (widget.userData != null) {
      final newAcc = {
        "first_name": widget.userData!["first_name"] ?? "",
        "last_name": widget.userData!["last_name"] ?? "",
        "username": widget.userData!["username"] ?? "",
        "phone": widget.userData!["phone_number"] ?? "",
        "avatar": "assets/panda.jpg",
        "timestamp": DateTime.now().millisecondsSinceEpoch,
      };

      // remove duplicate
      accounts.removeWhere((a) => a["phone"] == newAcc["phone"]);
      // insert on top
      accounts.insert(0, newAcc);
      await prefs.setString('accounts', json.encode(accounts));

      firstName = newAcc["first_name"].toString() ?? "";
      lastName = newAcc["last_name"].toString() ?? "";
      username = newAcc["username"].toString() ?? "";
      phoneNumber = newAcc["phone"].toString() ?? "";
    } else if (accounts.isNotEmpty) {
      // last logged in user
      final acc = accounts.first;
      firstName = acc["first_name"] ?? "";
      lastName = acc["last_name"] ?? "";
      username = acc["username"] ?? "";
      phoneNumber = acc["phone"] ?? "";
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Telegraph',
      debugShowCheckedModeBanner: false,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E2429),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2C343A),
          foregroundColor: Colors.white,
        ),
        drawerTheme: const DrawerThemeData(backgroundColor: Color(0xFF2C343A)),
      ),
      theme: ThemeData(
        primaryColor: Colors.green,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          color: Colors.green,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: TelegraphHome(
        isDark: isDark,
        isChinese: isChinese,
        onThemeToggle: () => setState(() => isDark = !isDark),
        onLangToggle: () => setState(() => isChinese = !isChinese),
        firstName: firstName,
        lastName: lastName,
        username: username,
        phoneNumber: phoneNumber,
      ),
    );
  }
}

class TelegraphHome extends StatefulWidget {
  final bool isDark;
  final bool isChinese;
  final VoidCallback onThemeToggle;
  final VoidCallback onLangToggle;
  final String firstName;
  final String lastName;
  final String username;
  final String phoneNumber;

  const TelegraphHome({
    super.key,
    required this.isDark,
    required this.isChinese,
    required this.onThemeToggle,
    required this.onLangToggle,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.phoneNumber,
  });

  @override
  State<TelegraphHome> createState() => _TelegraphHomeState();
}

class _TelegraphHomeState extends State<TelegraphHome>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, String>> chats = [
    {"name": "Graph AI Chat", "msg": "Chat with me!", "time": "Now"},
    {"name": "UserInfoBot", "msg": "Verification needed", "time": "Mon"},
    {"name": "BotFather", "msg": "Choose a bot from the list", "time": "Jun 12"},
  ];

  String t(String en, String zh) => widget.isChinese ? zh : en;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: TelegraphDrawer(
        isDark: widget.isDark,
        isChinese: widget.isChinese,
        onThemeToggle: widget.onThemeToggle,
        onLangToggle: widget.onLangToggle,
      ),
      appBar: AppBar(
        title: Text(
          widget.firstName.isNotEmpty ? widget.firstName : "Telegraph",
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.chat_bubble_outline)),
            Tab(icon: Icon(Icons.contacts_outlined)),
            Tab(icon: Icon(Icons.call_outlined)),
            Tab(icon: Icon(Icons.settings_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChatsTab(),
          _buildContactsTab(),
          _buildCallsTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  Widget _buildChatsTab() => ListView.builder(
    itemCount: chats.length,
    itemBuilder: (context, i) => ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.green,
        child: Text(chats[i]['name']![0],
            style: const TextStyle(color: Colors.white)),
      ),
      title: Text(chats[i]['name']!,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(chats[i]['msg']!,
          maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text(chats[i]['time']!,
          style: const TextStyle(color: Colors.grey, fontSize: 12)),
    ),
  );

  Widget _buildContactsTab() => ListView(
    children: const [
      ListTile(
          leading: Icon(Icons.person_outline),
          title: Text("Tamjid Dev"),
          subtitle: Text("+880 1928478904")),
      ListTile(
          leading: Icon(Icons.person_outline),
          title: Text("Rakib Hasan"),
          subtitle: Text("+880 1710000000")),
    ],
  );

  Widget _buildCallsTab() => ListView(
    children: const [
      ListTile(
          leading: Icon(Icons.call_received, color: Colors.red),
          title: Text("Missed Call – Rakib Hasan"),
          subtitle: Text("Yesterday 9:40 PM")),
      ListTile(
          leading: Icon(Icons.call_made, color: Colors.green),
          title: Text("Outgoing Call – Tamjid Dev"),
          subtitle: Text("Today 10:12 AM")),
    ],
  );

  Widget _buildSettingsTab() => ListView(
    children: const [
      ListTile(leading: Icon(Icons.settings), title: Text("Account")),
      ListTile(
          leading: Icon(Icons.lock_outline), title: Text("Privacy & Security")),
      ListTile(
          leading: Icon(Icons.notifications), title: Text("Notifications")),
      ListTile(
          leading: Icon(Icons.color_lens_outlined), title: Text("Theme")),
    ],
  );
}

// ================= DRAWER =================

// ================= DRAWER =================
class TelegraphDrawer extends StatefulWidget {
  final bool isDark;
  final bool isChinese;
  final VoidCallback onThemeToggle;
  final VoidCallback onLangToggle;
  const TelegraphDrawer({
    super.key,
    required this.isDark,
    required this.isChinese,
    required this.onThemeToggle,
    required this.onLangToggle,
  });

  @override
  State<TelegraphDrawer> createState() => _TelegraphDrawerState();
}

class _TelegraphDrawerState extends State<TelegraphDrawer> {
  bool showAccounts = false;
  List<Map<String, dynamic>> accounts = [];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('accounts');
    if (saved != null) {
      setState(() {
        accounts = List<Map<String, dynamic>>.from(json.decode(saved));
      });
    }
  }

  Future<void> _saveAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accounts', json.encode(accounts));
  }

  Future<void> _logoutAccount(int index, BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    // remove this account
    final removed = accounts.removeAt(index);
    await _saveAccounts();

    if (accounts.isEmpty) {
      // সব শেষ — login screen-এ ফিরে যাবে
      await prefs.clear();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const PhoneLoginScreen()),
            (route) => false,
      );
      return;
    }

    // যদি এখনো account থাকে → পরেরটা active করে TelegraphApp খুলবে
    await prefs.setString('accounts', json.encode(accounts));

    final next = accounts.first;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TelegraphApp(
          userData: {
            "first_name": next["first_name"]?.toString() ?? "",
            "last_name": next["last_name"]?.toString() ?? "",
            "username": next["username"]?.toString() ?? "",
            "phone_number": next["phone"]?.toString() ?? "",
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 300,
      child: Container(
        color: widget.isDark ? Colors.black : Colors.white,
        child: Column(
          children: [
            // 🔹 Header
            Container(
              color: widget.isDark ? Colors.grey[900] : Colors.red,
              padding:
              const EdgeInsets.only(top: 40, left: 10, right: 10, bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const CircleAvatar(
                        radius: 28,
                        backgroundImage: AssetImage('assets/panda.jpg')),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        accounts.isNotEmpty
                            ? "${accounts.first['first_name'] ?? ''} ${accounts.first['last_name'] ?? ''}"
                            : "User",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                        icon: const Icon(Icons.brightness_6_outlined,
                            color: Colors.white),
                        onPressed: widget.onThemeToggle),
                    IconButton(
                        icon: const Icon(Icons.translate_outlined,
                            color: Colors.white),
                        onPressed: widget.onLangToggle),
                  ]),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => setState(() => showAccounts = !showAccounts),
                    child: Row(
                      children: const [
                        Icon(Icons.person_outline, color: Colors.white),
                        SizedBox(width: 8),
                        Text("My Accounts",
                            style: TextStyle(color: Colors.white)),
                        Spacer(),
                        Icon(Icons.keyboard_arrow_down, color: Colors.white),
                      ],
                    ),
                  ),

                  // 🔽 Accounts dropdown
                  if (showAccounts)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white, // dropdown background white
                        borderRadius: BorderRadius.circular(8),
                      ),
                      margin: const EdgeInsets.only(top: 8),
                      constraints: const BoxConstraints(maxHeight: 230),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: accounts.length + 1,
                        itemBuilder: (context, index) {
                          if (index == accounts.length) {
                            return ListTile(
                              leading:
                              const Icon(Icons.add, color: Colors.black),
                              title: const Text("Add Account",
                                  style: TextStyle(color: Colors.black)),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const PhoneLoginScreen()),
                              ),
                            );
                          }
                          final acc = accounts[index];
                          return ListTile(
                            leading: const CircleAvatar(
                              radius: 16,
                              backgroundImage:
                              AssetImage('assets/panda.jpg'),
                            ),
                            title: Text(
                              "${acc['first_name']?.toString() ?? ''} ${acc['last_name']?.toString() ?? ''}",
                              style: const TextStyle(color: Colors.black),
                            ),
                            subtitle: Text(
                              "+${acc['phone']?.toString() ?? ''}",
                              style: const TextStyle(
                                  color: Colors.black54, fontSize: 12),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.logout,
                                  color: Colors.redAccent, size: 20),
                              onPressed: () => _logoutAccount(index, context),
                              tooltip: "Logout this account",
                            ),
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TelegraphApp(
                                    userData: {
                                      "first_name":
                                      acc["first_name"]?.toString() ?? "",
                                      "last_name":
                                      acc["last_name"]?.toString() ?? "",
                                      "username":
                                      acc["username"]?.toString() ?? "",
                                      "phone_number":
                                      acc["phone"]?.toString() ?? "",
                                    },
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),

            // 🔹 Body
            Expanded(
              child: ListView(
                children: [

                                    ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(("My Profile"))),
                  ListTile(
                      leading: const Icon(Icons.star_border),
                      title: Text(("Special Features"))),
                  ListTile(
                      leading: const Icon(Icons.chat_bubble_outline),
                      title: Text(("New Chat"))),
                  const Divider(),
                  ListTile(
                      leading: const Icon(Icons.contacts),
                      title: Text(("Contacts"))),
                  ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(("Contact Changes"))),
                  ListTile(
                      leading: const Icon(Icons.call),
                      title: Text(("Calls"))),
                  ListTile(
                      leading: const Icon(Icons.search),
                      title: Text(("ID Finder"))),
                  const Divider(),
                  ListTile(
                      leading: const Icon(Icons.settings),
                      title: Text(("Settings"))),
                  ListTile(
                      leading: const Icon(Icons.color_lens_outlined),
                      title: Text(("Theme Settings"))),
                  ListTile(
                      leading: const Icon(Icons.group_add_outlined),
                      title: Text(("Invite Friends"))),
                  const Divider(),

                  const Divider(),
                  ListTile(
                      leading: const Icon(Icons.settings),
                      title: const Text("Settings")),
                  ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text("Logout All",
                          style: TextStyle(color: Colors.red)),
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.clear();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PhoneLoginScreen()),
                              (route) => false,
                        );
                      }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}



// class TelegraphDrawer extends StatefulWidget {
//   final bool isDark;
//   final bool isChinese;
//   final VoidCallback onThemeToggle;
//   final VoidCallback onLangToggle;
//   const TelegraphDrawer({
//     super.key,
//     required this.isDark,
//     required this.isChinese,
//     required this.onThemeToggle,
//     required this.onLangToggle,
//   });
//
//   @override
//   State<TelegraphDrawer> createState() => _TelegraphDrawerState();
// }
//
// class _TelegraphDrawerState extends State<TelegraphDrawer> {
//   bool showAccounts = false;
//   List<Map<String, dynamic>> accounts = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _loadAccounts();
//   }
//
//   Future<void> _loadAccounts() async {
//     final prefs = await SharedPreferences.getInstance();
//     final saved = prefs.getString('accounts');
//     if (saved != null) {
//       setState(() {
//         accounts = List<Map<String, dynamic>>.from(json.decode(saved));
//       });
//     }
//   }
//
//   Future<void> _logout(BuildContext context) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.clear();
//     Navigator.pushAndRemoveUntil(
//       context,
//       MaterialPageRoute(builder: (_) => const PhoneLoginScreen()),
//           (route) => false,
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Drawer(
//       width: 300,
//       child: Container(
//         color: widget.isDark ? Colors.black : Colors.white,
//         child: Column(
//           children: [
//             Container(
//               color: widget.isDark ? Colors.grey[900] : Colors.red,
//               padding:
//               const EdgeInsets.only(top: 40, left: 10, right: 10, bottom: 10),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(children: [
//                     const CircleAvatar(
//                         radius: 28, backgroundImage: AssetImage('assets/panda.jpg')),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Text(
//                         accounts.isNotEmpty
//                             ? "${accounts.first['first_name']} ${accounts.first['last_name']}"
//                             : "User",
//                         style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold),
//                       ),
//                     ),
//                     IconButton(
//                         icon: const Icon(Icons.brightness_6_outlined,
//                             color: Colors.white),
//                         onPressed: widget.onThemeToggle),
//                     IconButton(
//                         icon: const Icon(Icons.translate_outlined,
//                             color: Colors.white),
//                         onPressed: widget.onLangToggle),
//                   ]),
//                   const SizedBox(height: 8),
//                   GestureDetector(
//                     onTap: () => setState(() => showAccounts = !showAccounts),
//                     child: Row(
//                       children: const [
//                         Icon(Icons.person_outline, color: Colors.white),
//                         SizedBox(width: 8),
//                         Text("My Accounts",
//                             style: TextStyle(color: Colors.white)),
//                         Spacer(),
//                         Icon(Icons.keyboard_arrow_down, color: Colors.white),
//                       ],
//                     ),
//                   ),
//                   if (showAccounts)
//                     Container(
//                       constraints: const BoxConstraints(maxHeight: 220),
//                       margin: const EdgeInsets.only(top: 6),
//                       child: ListView.builder(
//                         shrinkWrap: true,
//                         itemCount: accounts.length + 1,
//                         itemBuilder: (context, index) {
//                           if (index == accounts.length) {
//                             return ListTile(
//                               leading:
//                               const Icon(Icons.add, color: Colors.white),
//                               title: const Text("Add Account",
//                                   style: TextStyle(color: Colors.white)),
//                               onTap: () => Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                     builder: (_) => const PhoneLoginScreen()),
//                               ),
//                             );
//                           }
//                           final acc = accounts[index];
//                           return ListTile(
//                             leading: const CircleAvatar(
//                                 radius: 16,
//                                 backgroundImage:
//                                 AssetImage('assets/panda.jpg')),
//                             title: Text(
//                               "${acc['first_name']} ${acc['last_name']}",
//                               style: const TextStyle(color: Colors.white),
//                             ),
//                             subtitle: Text(
//                               "+${acc['phone']}",
//                               style: const TextStyle(
//                                   color: Colors.white70, fontSize: 12),
//                             ),
//                             onTap: () {
//                               Navigator.pushReplacement(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (_) => TelegraphApp(
//                                     userData: {
//                                       "first_name": acc["first_name"],
//                                       "last_name": acc["last_name"],
//                                       "username": acc["username"],
//                                       "phone_number": acc["phone"],
//                                     },
//                                   ),
//                                 ),
//                               );
//                             },
//                           );
//                         },
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//             Expanded(
//               child: ListView(
//                 children: [
//                   const Divider(),
//                   ListTile(
//                       leading: const Icon(Icons.settings),
//                       title: const Text("Settings")),
//                   ListTile(
//                       leading: const Icon(Icons.logout, color: Colors.red),
//                       title: const Text("Logout",
//                           style: TextStyle(color: Colors.red)),
//                       onTap: () => _logout(context)),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

