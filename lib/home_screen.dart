
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:translator/translator.dart';
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
  String selectedLang = 'en';
  final translator = GoogleTranslator();
  List<Map<String, dynamic>> dialogs = [];

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadLang();
  }

  Future<void> _loadLang() async {
    final prefs = await SharedPreferences.getInstance();
    selectedLang = prefs.getString('lang') ?? 'en';
    setState(() {});
  }

  Future<void> _saveLang(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', code);
    setState(() => selectedLang = code);
  }

  Future<String> autoT(String text) async {
    if (selectedLang == 'en') return text;
    try {
      final t = await translator.translate(text, to: selectedLang);
      return t.text;
    } catch (_) {
      return text;
    }
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> accounts = [];

    final saved = prefs.getString('accounts');
    if (saved != null) {
      accounts = List<Map<String, dynamic>>.from(json.decode(saved));
    }

    if (widget.userData != null) {
      final newAcc = {
        "first_name": widget.userData!["first_name"] ?? "",
        "last_name": widget.userData!["last_name"] ?? "",
        "username": widget.userData!["username"] ?? "",
        "phone": widget.userData!["phone_number"] ?? "",
        "avatar": "assets/panda.jpg",
        "timestamp": DateTime.now().millisecondsSinceEpoch,
      };

      accounts.removeWhere((a) => a["phone"] == newAcc["phone"]);
      accounts.insert(0, newAcc);
      await prefs.setString('accounts', json.encode(accounts));

      firstName = newAcc["first_name"].toString();
      lastName = newAcc["last_name"].toString();
      username = newAcc["username"].toString();
      phoneNumber = newAcc["phone"].toString();
    } else if (accounts.isNotEmpty) {
      final acc = accounts.first;
      firstName = acc["first_name"];
      lastName = acc["last_name"];
      username = acc["username"];
      phoneNumber = acc["phone"];
    }

    setState(() {});
    if (phoneNumber.isNotEmpty) {
      await fetchDialogsFromServer(phoneNumber);
    }
  }

  /// ✅ Fetch Telegram dialogs dynamically
  Future<void> fetchDialogsFromServer(String phone) async {
    final String apiUrl = "http://192.168.0.247:8080/dialogs?phone=$phone";
    print("🌍 Fetching dialogs from: $apiUrl");

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data["dialogs"] != null && data["dialogs"] is List) {
          final List dialogsList = data["dialogs"];

          dialogs = dialogsList.map<Map<String, dynamic>>((d) {
            final username = d["username"] ?? "";
            final avatarUrl =
                "http://192.168.0.247:8080/avatar_redirect?phone=$phone&username=@$username";

            return {
              "id": d["id"],
              "name": d["name"] ?? "Unknown",
              "last_message": d["last_message"] ?? "",
              "unread_count": d["unread_count"] ?? 0,
              "is_group": d["is_group"] ?? false,
              "username": username,
              "avatar": avatarUrl,
            };
          }).toList();

          print("✅ Loaded ${dialogs.length} dialogs from server");
          setState(() {});
        } else {
          print("⚠️ No dialogs found in response");
        }
      } else {
        print("❌ Server error: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Exception while fetching dialogs: $e");
    }
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
        selectedLang: selectedLang,
        onLangChange: _saveLang,
        autoT: autoT,
        dialogs: dialogs,
        onRefresh: () => fetchDialogsFromServer(phoneNumber),
      ),
    );
  }
}

class TelegraphHome extends StatefulWidget {
  final bool isDark;
  final bool isChinese;
  final String selectedLang;
  final Function(String) onLangChange;
  final Future<String> Function(String) autoT;
  final VoidCallback onThemeToggle;
  final VoidCallback onLangToggle;
  final String firstName;
  final String lastName;
  final String username;
  final String phoneNumber;
  final List<Map<String, dynamic>> dialogs;
  final VoidCallback onRefresh;

  const TelegraphHome({
    super.key,
    required this.selectedLang,
    required this.onLangChange,
    required this.autoT,
    required this.isDark,
    required this.isChinese,
    required this.onThemeToggle,
    required this.onLangToggle,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.phoneNumber,
    required this.dialogs,
    required this.onRefresh,
  });

  @override
  State<TelegraphHome> createState() => _TelegraphHomeState();
}

class _TelegraphHomeState extends State<TelegraphHome>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
        selectedLang: widget.selectedLang,
        onLangChange: widget.onLangChange,
        autoT: widget.autoT,
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
          _buildChatsTab(), // ✅ এখন এখানে আসবে API থেকে ডেটা
          _buildContactsTab(),
          _buildCallsTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  /// ✅ এখানে এখন static না, Flask API data দেখাবে
  Widget _buildChatsTab() {
    final dialogs = widget.dialogs;

    if (dialogs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async => widget.onRefresh(),
      child: ListView.builder(
        itemCount: dialogs.length,
        itemBuilder: (context, i) {
          final d = dialogs[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(d["avatar"]),
            ),
            title: Text(
              d["name"],
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              d["last_message"],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: d["unread_count"] > 0
                ? CircleAvatar(
              radius: 10,
              backgroundColor: Colors.red,
              child: Text(
                d["unread_count"].toString(),
                style:
                const TextStyle(fontSize: 10, color: Colors.white),
              ),
            )
                : null,
          );
        },
      ),
    );
  }

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
          leading: Icon(Icons.lock_outline),
          title: Text("Privacy & Security")),
      ListTile(
          leading: Icon(Icons.notifications),
          title: Text("Notifications")),
      ListTile(
          leading: Icon(Icons.color_lens_outlined),
          title: Text("Theme")),
    ],
  );
}


//
//
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http;
// import 'package:translator/translator.dart';
// import 'main.dart';
// import 'url.dart';
//
// class TelegraphApp extends StatefulWidget {
//   final Map<String, String>? userData;
//   const TelegraphApp({super.key, this.userData});
//
//   @override
//   State<TelegraphApp> createState() => _TelegraphAppState();
// }
//
// class _TelegraphAppState extends State<TelegraphApp> {
//   String firstName = "";
//   String lastName = "";
//   String username = "";
//   String phoneNumber = "";
//   bool isDark = false;
//   bool isChinese = false;
//   String selectedLang = 'en';
//   final translator = GoogleTranslator();
//   List<Map<String, dynamic>> dialogs = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _loadUser();
//     _loadLang();
//   }
//
//   Future<void> _loadLang() async {
//     final prefs = await SharedPreferences.getInstance();
//     selectedLang = prefs.getString('lang') ?? 'en';
//     setState(() {});
//   }
//
//   Future<void> _saveLang(String code) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('lang', code);
//     setState(() => selectedLang = code);
//   }
//
//   Future<String> autoT(String text) async {
//     if (selectedLang == 'en') return text;
//     try {
//       final t = await translator.translate(text, to: selectedLang);
//       return t.text;
//     } catch (_) {
//       return text;
//     }
//   }
//
//   Future<void> _loadUser() async {
//     final prefs = await SharedPreferences.getInstance();
//     List<Map<String, dynamic>> accounts = [];
//
//     final saved = prefs.getString('accounts');
//     if (saved != null) {
//       accounts = List<Map<String, dynamic>>.from(json.decode(saved));
//     }
//
//     // যদি userData আসে OTP থেকে, নতুনটাকে accounts list-এ যোগ করবে
//     if (widget.userData != null) {
//       final newAcc = {
//         "first_name": widget.userData!["first_name"] ?? "",
//         "last_name": widget.userData!["last_name"] ?? "",
//         "username": widget.userData!["username"] ?? "",
//         "phone": widget.userData!["phone_number"] ?? "",
//         "avatar": "assets/panda.jpg",
//         "timestamp": DateTime.now().millisecondsSinceEpoch,
//       };
//
//       // remove duplicate
//       accounts.removeWhere((a) => a["phone"] == newAcc["phone"]);
//       // insert on top
//       accounts.insert(0, newAcc);
//       await prefs.setString('accounts', json.encode(accounts));
//
//       firstName = newAcc["first_name"].toString() ?? "";
//       lastName = newAcc["last_name"].toString() ?? "";
//       username = newAcc["username"].toString() ?? "";
//       phoneNumber = newAcc["phone"].toString() ?? "";
//     } else if (accounts.isNotEmpty) {
//       // last logged in user
//       final acc = accounts.first;
//       firstName = acc["first_name"] ?? "";
//       lastName = acc["last_name"] ?? "";
//       username = acc["username"] ?? "";
//       phoneNumber = acc["phone"] ?? "";
//     }
//
//     setState(() {});
//     if (phoneNumber.isNotEmpty) {
//       await fetchDialogsFromServer(phoneNumber);
//     }
//   }
//
//
//   /// ✅ Fetch Telegram dialogs dynamically
//   Future<void> fetchDialogsFromServer(String phone) async {
//     final String apiUrl = "http://192.168.0.247:8080/dialogs?phone=$phone";
//     print("🌍 Fetching dialogs from: $apiUrl");
//
//     try {
//       final response = await http.get(Uri.parse(apiUrl));
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//
//         if (data["dialogs"] != null && data["dialogs"] is List) {
//           final List dialogsList = data["dialogs"];
//
//           dialogs = dialogsList.map<Map<String, dynamic>>((d) {
//             final username = d["username"] ?? "";
//             final avatarUrl =
//                 "http://192.168.0.247:8080/avatar_redirect?phone=$phone&username=@$username";
//
//             return {
//               "id": d["id"],
//               "name": d["name"] ?? "Unknown",
//               "last_message": d["last_message"] ?? "",
//               "unread_count": d["unread_count"] ?? 0,
//               "is_group": d["is_group"] ?? false,
//               "username": username,
//               "avatar": avatarUrl,
//             };
//           }).toList();
//
//           print("✅ Loaded ${dialogs.length} dialogs from server");
//           setState(() {});
//         } else {
//           print("⚠️ No dialogs found in response");
//         }
//       } else {
//         print("❌ Server error: ${response.statusCode}");
//       }
//     } catch (e) {
//       print("❌ Exception while fetching dialogs: $e");
//     }
//   }
//
//
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
//         selectedLang: selectedLang,
//         onLangChange: _saveLang,
//         autoT: autoT,
//       ),
//     );
//   }
// }
//
// class TelegraphHome extends StatefulWidget {
//   final bool isDark;
//   final bool isChinese;
//   final String selectedLang;
//   final Function(String) onLangChange;
//   final Future<String> Function(String) autoT;
//   final VoidCallback onThemeToggle;
//   final VoidCallback onLangToggle;
//   final String firstName;
//   final String lastName;
//   final String username;
//   final String phoneNumber;
//
//   const TelegraphHome({
//     super.key,
//     required this.selectedLang,
//     required this.onLangChange,
//     required this.autoT,
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
//
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
//         selectedLang: widget.selectedLang,
//         onLangChange: widget.onLangChange,
//         autoT: widget.autoT,
//       ),
//       appBar: AppBar(
//         title: Text(
//           widget.firstName.isNotEmpty ? widget.username : "Telegraph",
//         ),
//         bottom: TabBar(
//           controller: _tabController,
//           indicatorColor: Colors.white,
//           tabs: const [
//             Tab(icon: Icon(Icons.chat_bubble_outline)),
//             Tab(icon: Icon(Icons.contacts_outlined)),
//             Tab(icon: Icon(Icons.call_outlined)),
//             Tab(icon: Icon(Icons.settings_outlined)),
//           ],
//         ),
//       ),
//       body:
//       TabBarView(
//         controller: _tabController,
//         children: [
//           _buildChatsTab(),
//           _buildContactsTab(),
//           _buildCallsTab(),
//           _buildSettingsTab(),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildChatsTab() => ListView.builder(
//     itemCount: chats.length,
//     itemBuilder: (context, i) => ListTile(
//       leading: CircleAvatar(
//         backgroundColor: Colors.green,
//         child: Text(chats[i]['name']![0],
//             style: const TextStyle(color: Colors.white)),
//       ),
//       title: Text(chats[i]['name']!,
//           style: const TextStyle(fontWeight: FontWeight.w600)),
//       subtitle: Text(chats[i]['msg']!,
//           maxLines: 1, overflow: TextOverflow.ellipsis),
//       trailing: Text(chats[i]['time']!,
//           style: const TextStyle(color: Colors.grey, fontSize: 12)),
//     ),
//   );
//
//   Widget _buildContactsTab() => ListView(
//     children: const [
//       ListTile(
//           leading: Icon(Icons.person_outline),
//           title: Text("Tamjid Dev"),
//           subtitle: Text("+880 1928478904")),
//       ListTile(
//           leading: Icon(Icons.person_outline),
//           title: Text("Rakib Hasan"),
//           subtitle: Text("+880 1710000000")),
//     ],
//   );
//
//   Widget _buildCallsTab() => ListView(
//     children: const [
//       ListTile(
//           leading: Icon(Icons.call_received, color: Colors.red),
//           title: Text("Missed Call – Rakib Hasan"),
//           subtitle: Text("Yesterday 9:40 PM")),
//       ListTile(
//           leading: Icon(Icons.call_made, color: Colors.green),
//           title: Text("Outgoing Call – Tamjid Dev"),
//           subtitle: Text("Today 10:12 AM")),
//     ],
//   );
//
//   Widget _buildSettingsTab() => ListView(
//     children: const [
//       ListTile(leading: Icon(Icons.settings), title: Text("Account")),
//       ListTile(
//           leading: Icon(Icons.lock_outline), title: Text("Privacy & Security")),
//       ListTile(
//           leading: Icon(Icons.notifications), title: Text("Notifications")),
//       ListTile(
//           leading: Icon(Icons.color_lens_outlined), title: Text("Theme")),
//     ],
//   );
// }

 //////// right code cilo ai ta
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http;
// import 'package:translator/translator.dart';
// import 'main.dart';
// import 'url.dart';
//
// class TelegraphApp extends StatefulWidget {
//   final Map<String, String>? userData;
//   const TelegraphApp({super.key, this.userData});
//
//   @override
//   State<TelegraphApp> createState() => _TelegraphAppState();
// }
//
// class _TelegraphAppState extends State<TelegraphApp> {
//   String firstName = "";
//   String lastName = "";
//   String username = "";
//   String phoneNumber = "";
//   bool isDark = false;
//   String selectedLang = 'en';
//   final translator = GoogleTranslator();
//   List<Map<String, dynamic>> dialogs = [];
//   List<Map<String, dynamic>> accounts = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _loadLang();
//     _loadUser();
//   }
//
//   Future<void> _loadLang() async {
//     final prefs = await SharedPreferences.getInstance();
//     selectedLang = prefs.getString('lang') ?? 'en';
//     setState(() {});
//   }
//
//   Future<void> _saveLang(String code) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('lang', code);
//     setState(() => selectedLang = code);
//   }
//
//   Future<void> _loadUser() async {
//     final prefs = await SharedPreferences.getInstance();
//     final saved = prefs.getString('accounts');
//     if (saved != null) accounts = List<Map<String, dynamic>>.from(json.decode(saved));
//
//     if (widget.userData != null) {
//       final newAcc = {
//         "first_name": widget.userData!["first_name"] ?? "",
//         "last_name": widget.userData!["last_name"] ?? "",
//         "username": widget.userData!["username"] ?? "",
//         "phone": widget.userData!["phone_number"] ?? "",
//         "avatar": "assets/panda.jpg",
//       };
//       accounts.removeWhere((a) => a["phone"] == newAcc["phone"]);
//       accounts.insert(0, newAcc);
//       await prefs.setString('accounts', json.encode(accounts));
//       firstName = newAcc["first_name"].toString();
//       username = newAcc["username"].toString();
//       phoneNumber = newAcc["phone"].toString();
//     } else if (accounts.isNotEmpty) {
//       final acc = accounts.first;
//       firstName = acc["first_name"];
//       username = acc["username"];
//       phoneNumber = acc["phone"];
//     }
//     setState(() {});
//     if (phoneNumber.isNotEmpty) await fetchDialogsFromServer(phoneNumber);
//   }
//
//   Future<void> fetchDialogsFromServer(String phone) async {
//     final url = "http://192.168.0.247:8080/dialogs?phone=$phone";
//     try {
//       final res = await http.get(Uri.parse(url));
//       if (res.statusCode == 200) {
//         final data = json.decode(res.body);
//         if (data["dialogs"] is List) {
//           dialogs = (data["dialogs"] as List).map<Map<String, dynamic>>((d) {
//             final user = d["username"] ?? "";
//             return {
//               "name": d["name"] ?? "Unknown",
//               "username": user,
//               "last_message": d["last_message"] ?? "",
//               "unread_count": d["unread_count"] ?? 0,
//               "avatar":
//               "http://192.168.0.247:8080/avatar_redirect?phone=$phone&username=@$user",
//             };
//           }).toList();
//         }
//       }
//     } catch (e) {
//       print("❌ Dialog fetch error: $e");
//     }
//     setState(() {});
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: "Telegraph",
//       debugShowCheckedModeBanner: false,
//       themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
//       darkTheme: ThemeData.dark(),
//       theme: ThemeData(primarySwatch: Colors.green),
//       home: TelegraphHome(
//         isDark: isDark,
//         onThemeToggle: () => setState(() => isDark = !isDark),
//         username: username,
//         phoneNumber: phoneNumber,
//         dialogs: dialogs,
//         accounts: accounts,
//         onRefresh: () => fetchDialogsFromServer(phoneNumber),
//         onAccountSwitch: (acc) async {
//           final prefs = await SharedPreferences.getInstance();
//           accounts.removeWhere((a) => a["phone"] == acc["phone"]);
//           accounts.insert(0, acc);
//           await prefs.setString('accounts', json.encode(accounts));
//           setState(() {
//             username = acc["username"];
//             phoneNumber = acc["phone"];
//           });
//           await fetchDialogsFromServer(phoneNumber);
//         },
//       ),
//     );
//   }
// }
//
// class TelegraphHome extends StatefulWidget {
//   final bool isDark;
//   final VoidCallback onThemeToggle;
//   final String username;
//   final String phoneNumber;
//   final List<Map<String, dynamic>> dialogs;
//   final List<Map<String, dynamic>> accounts;
//   final VoidCallback onRefresh;
//   final Function(Map<String, dynamic>) onAccountSwitch;
//
//   const TelegraphHome({
//     super.key,
//     required this.isDark,
//     required this.onThemeToggle,
//     required this.username,
//     required this.phoneNumber,
//     required this.dialogs,
//     required this.accounts,
//     required this.onRefresh,
//     required this.onAccountSwitch,
//   });
//
//   @override
//   State<TelegraphHome> createState() => _TelegraphHomeState();
// }
//
// class _TelegraphHomeState extends State<TelegraphHome>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   Map<String, dynamic>? selectedAccount;
//
//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 4, vsync: this);
//     if (widget.accounts.isNotEmpty) {
//       selectedAccount = widget.accounts.first;
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       drawer: Drawer(
//         child: Column(
//           children: [
//             const SizedBox(height: 30),
//             // ✅ Dropdown for account switcher
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: DropdownButton<Map<String, dynamic>>(
//                 isExpanded: true,
//                 value: selectedAccount,
//                 icon: const Icon(Icons.arrow_drop_down),
//                 items: widget.accounts
//                     .map((acc) => DropdownMenuItem(
//                   value: acc,
//                   child: Row(
//                     children: [
//                       const CircleAvatar(
//                           radius: 16,
//                           backgroundImage:
//                           AssetImage("assets/panda.jpg")),
//                       const SizedBox(width: 8),
//                       Expanded(
//                           child: Text(
//                             acc["username"] ?? "Unknown",
//                             overflow: TextOverflow.ellipsis,
//                           )),
//                     ],
//                   ),
//                 ))
//                     .toList(),
//                 onChanged: (acc) {
//                   if (acc != null) {
//                     setState(() => selectedAccount = acc);
//                     widget.onAccountSwitch(acc);
//                     Navigator.pop(context);
//                   }
//                 },
//               ),
//             ),
//             const Divider(),
//             ListTile(
//               leading: const Icon(Icons.refresh),
//               title: const Text("Refresh Data"),
//               onTap: () {
//                 Navigator.pop(context);
//                 widget.onRefresh();
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.dark_mode),
//               title: const Text("Toggle Theme"),
//               onTap: () {
//                 Navigator.pop(context);
//                 widget.onThemeToggle();
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.logout, color: Colors.red),
//               title: const Text("Logout"),
//               onTap: () {
//                 Navigator.pop(context);
//                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//                     content: Text("Logged out successfully ✅")));
//               },
//             ),
//             const Spacer(),
//             const Padding(
//               padding: EdgeInsets.all(8.0),
//               child: Text("Telegraph App ©2025",
//                   style: TextStyle(color: Colors.grey, fontSize: 12)),
//             ),
//           ],
//         ),
//       ),
//
//       appBar: AppBar(
//         title:
//         Text(widget.username.isNotEmpty ? widget.username : "Telegraph"),
//         actions: [
//           IconButton(icon: const Icon(Icons.refresh), onPressed: widget.onRefresh),
//         ],
//         bottom: TabBar(
//           controller: _tabController,
//           indicatorColor: Colors.green,
//           tabs: const [
//             Tab(icon: Icon(Icons.chat_bubble_outline)),
//             Tab(icon: Icon(Icons.contacts_outlined)),
//             Tab(icon: Icon(Icons.call_outlined)),
//             Tab(icon: Icon(Icons.settings_outlined)),
//           ],
//         ),
//       ),
//
//       body: TabBarView(
//         controller: _tabController,
//         children: [
//           _buildChatsTab(),
//           _buildContactsTab(),
//           _buildCallsTab(),
//           _buildSettingsTab(),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildChatsTab() {
//     final dialogs = widget.dialogs;
//     if (dialogs.isEmpty) {
//       return const Center(child: CircularProgressIndicator());
//     }
//     return ListView.builder(
//       itemCount: dialogs.length,
//       itemBuilder: (context, i) {
//         final d = dialogs[i];
//         return ListTile(
//           leading: CircleAvatar(backgroundImage: NetworkImage(d["avatar"])),
//           title: Text(d["name"], style: const TextStyle(fontWeight: FontWeight.w600)),
//           subtitle: Text(d["last_message"],
//               maxLines: 1, overflow: TextOverflow.ellipsis),
//           trailing: d["unread_count"] > 0
//               ? CircleAvatar(
//             radius: 10,
//             backgroundColor: Colors.red,
//             child: Text(d["unread_count"].toString(),
//                 style:
//                 const TextStyle(fontSize: 10, color: Colors.white)),
//           )
//               : null,
//         );
//       },
//     );
//   }
//
//   Widget _buildContactsTab() {
//     final dialogs = widget.dialogs;
//     return ListView(
//       children: dialogs
//           .map((d) => ListTile(
//         leading: const Icon(Icons.person_outline),
//         title: Text(d["name"]),
//         subtitle: Text("@${d["username"]}"),
//       ))
//           .toList(),
//     );
//   }
//
//   Widget _buildCallsTab() {
//     final dialogs = widget.dialogs;
//     return ListView(
//       children: dialogs
//           .map((d) => ListTile(
//         leading: const Icon(Icons.call, color: Colors.green),
//         title: Text(d["name"]),
//         subtitle: Text("Last message: ${d["last_message"]}"),
//       ))
//           .toList(),
//     );
//   }
//
//   Widget _buildSettingsTab() => ListView(
//     children: const [
//       ListTile(leading: Icon(Icons.settings), title: Text("Account")),
//       ListTile(
//           leading: Icon(Icons.lock_outline),
//           title: Text("Privacy & Security")),
//       ListTile(
//           leading: Icon(Icons.notifications),
//           title: Text("Notifications")),
//       ListTile(
//           leading: Icon(Icons.color_lens_outlined),
//           title: Text("Theme")),
//     ],
//   );
// }


// ================= DRAWER =================
class TelegraphDrawer extends StatefulWidget {
  final bool isDark;
  final bool isChinese;
  final VoidCallback onThemeToggle;
  final VoidCallback onLangToggle;
  final String selectedLang;
  final Function(String) onLangChange;
  final Future<String> Function(String) autoT;
  const TelegraphDrawer({
    super.key,
    required this.isDark,
    required this.isChinese,
    required this.onThemeToggle,
    required this.onLangToggle,
    required this.selectedLang,
    required this.onLangChange,
    required this.autoT,
  });

  @override
  State<TelegraphDrawer> createState() => _TelegraphDrawerState();
}

class _TelegraphDrawerState extends State<TelegraphDrawer> {
  bool showAccounts = false;
  List<Map<String, dynamic>> accounts = [];

  final List<Map<String, String>> langs = [
    {"flag": "🇬🇧", "name": "English", "code": "en"},
    {"flag": "🇨🇳", "name": "中文", "code": "zh-cn"},
    {"flag": "🇧🇩", "name": "বাংলা", "code": "bn"},
    {"flag": "🇮🇳", "name": "हिन्दी", "code": "hi"},
  ];

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
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                dropdownColor: Colors.white,
                icon: Icon(Icons.language),
                // Text(
                //   langs.firstWhere((l) => l['code'] == widget.selectedLang,
                //       orElse: () => langs.first)['flag']!,
                //   style: const TextStyle(fontSize: 28),
                // ),
                value: widget.selectedLang,
                items: langs
                    .map((lang) => DropdownMenuItem<String>(
                  value: lang['code'],
                  child: Row(
                    children: [
                      Text(lang['flag']!, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      Text(lang['name']!,
                          style: const TextStyle(color: Colors.black)),
                    ],
                  ),
                ))
                    .toList(),
                onChanged: (code) {
                  if (code != null) {
                    widget.onLangChange(code);
                    setState(() {});
                  }
                },
              ),
            ),

            // 🔹 Body

            Expanded(
                child: FutureBuilder<List<String>>(
                    future: Future.wait([
                      widget.autoT("My Profile"),
                      widget.autoT("Special Features"),
                      widget.autoT("New Chat"),
                      widget.autoT("Contacts"),
                      widget.autoT("Calls"),
                      widget.autoT("Settings"),
                      widget.autoT("Theme Settings"),
                      widget.autoT("Invite Friends"),
                      widget.autoT("Logout All"),
                    ]),
                    builder: (context, snap) {
                      final t = snap.data ??
                          [
                            "My Profile",
                            "Special Features",
                            "New Chat",
                            "Contacts",
                            "Calls",
                            "Settings",
                            "Theme Settings",
                            "Invite Friends",
                            "Logout All"
                          ];
                      return ListView(children: [
                        ListTile(leading: const Icon(Icons.person), title: Text(t[0])),
                        ListTile(
                            leading: const Icon(Icons.star_border), title: Text(t[1])),
                        ListTile(
                            leading: const Icon(Icons.chat_bubble_outline),
                            title: Text(t[2])),
                        const Divider(),
                        ListTile(
                            leading: const Icon(Icons.contacts), title: Text(t[3])),
                        ListTile(leading: const Icon(Icons.call), title: Text(t[4])),
                        ListTile(
                            leading: const Icon(Icons.settings), title: Text(t[5])),
                        ListTile(
                            leading: const Icon(Icons.color_lens_outlined),
                            title: Text(t[6])),
                        ListTile(
                            leading: const Icon(Icons.group_add_outlined),
                            title: Text(t[7])),
                        const Divider(),
                        ListTile(
                            leading: const Icon(Icons.logout, color: Colors.red),
                            title: Text(t[8],
                                style: const TextStyle(color: Colors.red))),
                      ]);
                    }))
            // Expanded(
            //   child: ListView(
            //     children: [
            //
            //       ListTile(
            //           leading: const Icon(Icons.person),
            //           title: Text(("My Profile"))),
            //       ListTile(
            //           leading: const Icon(Icons.star_border),
            //           title: Text(("Special Features"))),
            //       ListTile(
            //           leading: const Icon(Icons.chat_bubble_outline),
            //           title: Text(("New Chat"))),
            //       const Divider(),
            //       ListTile(
            //           leading: const Icon(Icons.contacts),
            //           title: Text(("Contacts"))),
            //       ListTile(
            //           leading: const Icon(Icons.history),
            //           title: Text(("Contact Changes"))),
            //       ListTile(
            //           leading: const Icon(Icons.call),
            //           title: Text(("Calls"))),
            //       ListTile(
            //           leading: const Icon(Icons.search),
            //           title: Text(("ID Finder"))),
            //       const Divider(),
            //       ListTile(
            //           leading: const Icon(Icons.settings),
            //           title: Text(("Settings"))),
            //       ListTile(
            //           leading: const Icon(Icons.color_lens_outlined),
            //           title: Text(("Theme Settings"))),
            //       ListTile(
            //           leading: const Icon(Icons.group_add_outlined),
            //           title: Text(("Invite Friends"))),
            //       const Divider(),
            //
            //       const Divider(),
            //       ListTile(
            //           leading: const Icon(Icons.settings),
            //           title: const Text("Settings")),
            //       ListTile(
            //           leading: const Icon(Icons.logout, color: Colors.red),
            //           title: const Text("Logout All",
            //               style: TextStyle(color: Colors.red)),
            //           onTap: () async {
            //             final prefs = await SharedPreferences.getInstance();
            //             await prefs.clear();
            //             Navigator.pushAndRemoveUntil(
            //               context,
            //               MaterialPageRoute(
            //                   builder: (_) => const PhoneLoginScreen()),
            //                   (route) => false,
            //             );
            //           }),
            //     ],
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}


