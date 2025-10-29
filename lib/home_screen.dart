

import 'dart:convert';
import 'package:ag_taligram/providers/telegraph_qg_provider.dart';
import 'package:ag_taligram/screens/auth_screen/phone_login_screen.dart';
import 'package:ag_taligram/screens/chant.dart';
import 'package:ag_taligram/screens/chat_screen.dart';
import 'package:ag_taligram/screens/group_add_screen.dart';
import 'package:ag_taligram/screens/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:translator/translator.dart';
import '../url.dart';

class TelegraphApp extends StatefulWidget {
  final Map<String, String>? userData;
  const TelegraphApp({super.key, this.userData});

  @override
  State<TelegraphApp> createState() => _TelegraphAppState();
}

class _TelegraphAppState extends State<TelegraphApp> {
  @override
  void initState() {
    super.initState();
    final p = Provider.of<TelegraphProvider>(context, listen: false);
    p.loadUser(widget.userData);
  }

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<TelegraphProvider>(context);

    return MaterialApp(
      title: 'Telegraph',
      debugShowCheckedModeBanner: false,
      themeMode: p.isDark ? ThemeMode.dark : ThemeMode.light,
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
      home: TelegraphHome(),
    );
  }
}

class TelegraphHome extends StatefulWidget {
  const TelegraphHome({super.key});

  @override
  State<TelegraphHome> createState() => _TelegraphHomeState();
}

class _TelegraphHomeState extends State<TelegraphHome>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final translator = GoogleTranslator();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<TelegraphProvider>(context);

    return Scaffold(
      drawer: TelegraphDrawer(),
      appBar: AppBar(
        title: Text(p.firstName.isNotEmpty ? p.firstName : "Telegraph"),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) =>  SearchScreen(phoneNumbar:p.phoneNumber)),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.chat_bubble_outline,color: Colors.white,),),
            Tab(icon: Icon(Icons.contacts_outlined,color: Colors.white,)),
            Tab(icon: Icon(Icons.call_outlined,color: Colors.white,)),
            Tab(icon: Icon(Icons.settings_outlined,color: Colors.white,)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChatsTab(p),
          _buildContactsTab(p),
          _buildCallsTab(p),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  Widget _buildChatsTab(TelegraphProvider p) {
    if (p.dialogs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: () async => p.fetchDialogs(p.phoneNumber),
      child: ListView.builder(
        itemCount: p.dialogs.length,
        itemBuilder: (context, i) {
          print('dfkdkfldkfkd 12345679581245-----');
          print(p.dialogs.length,);
          final d = p.dialogs[i];
          print(d["access_hash"],);
          final lastMsg = d["last_message"] ?? "";

          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(d["avatar"]),
            ),
            title: Text(
              d["name"],
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d["last_message"] ?? "",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "ID: ${d["id"] ?? 'N/A'}",  // 👈 ছোট করে user id দেখাবে
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
            trailing: d["unread_count"] > 0
                ? CircleAvatar(
              radius: 10,
              backgroundColor: Colors.red,
              child: Text(
                d["unread_count"].toString(),
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            )
                : null,
            onTap: () {
              final chatIdValue = d["id"];
              final accessHash = d["access_hash"];
              final isGroup = d["is_group"] == true;
              if (chatIdValue == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("⚠️ Chat ID missing for this user"),
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    phone: p.phoneNumber,
                    chatId: chatIdValue is int
                        ? chatIdValue
                        : int.tryParse(chatIdValue.toString()) ?? 0,
                    name: d["name"],
                    username: d["username"],
                    accessHash: isGroup
                        ? null // ✅ যদি group হয়, তাহলে null যাবে
                        : (accessHash is int
                        ? accessHash
                        : int.tryParse(accessHash.toString()) ?? 0),
                      // accessHash:accessHash is int
                      //     ? accessHash
                      //     : int.tryParse(accessHash.toString()) ?? 0,
                  ),
                ),
              );
            },
          );


        },
      ),
    );



  }

  Widget _buildContactsTab(TelegraphProvider p) => ListView(
    children: p.dialogs
        .map((d) => ListTile(
      leading: const Icon(Icons.person_outline),
      title: Text(d["name"]),
      subtitle: Text("@${d["username"]}"),
    ))
        .toList(),
  );

  Widget _buildCallsTab(TelegraphProvider p) => ListView(
    children: p.dialogs
        .map((d) => ListTile(
      leading: const Icon(Icons.call, color: Colors.green),
      title: Text(d["name"]),
      subtitle: Text("Last message: ${d["last_message"]}"
      ),
    ))
        .toList(),
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
          leading: Icon(Icons.color_lens_outlined), title: Text("Theme")),
    ],
  );
}

class TelegraphDrawer extends StatefulWidget {
  const TelegraphDrawer({super.key});

  @override
  State<TelegraphDrawer> createState() => _TelegraphDrawerState();
}

class _TelegraphDrawerState extends State<TelegraphDrawer> {
  bool showAccounts = false;
  bool _isSwitching = false; // 🔹 নতুন state: দ্রুত switch indicator

  final List<Map<String, String>> langs = [
    {"flag": "🇬🇧", "name": "English", "code": "en"},
    {"flag": "🇨🇳", "name": "中文", "code": "zh-cn"},
    {"flag": "🇧🇩", "name": "বাংলা", "code": "bn"},
    {"flag": "🇮🇳", "name": "हिन्दी", "code": "hi"},
  ];

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<TelegraphProvider>(context);

    return Drawer(
      width: 300,
      child: Stack(
        children: [
          // 🔹 মূল Drawer UI
          Container(
            color: p.isDark ? Colors.black : Colors.white,
            child: Column(
              children: [
                // HEADER
                Container(
                  color: p.isDark ? Colors.grey[900] : Colors.red,
                  padding: const EdgeInsets.only(top: 40, left: 10, right: 10, bottom: 10),
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
                            p.firstName.isNotEmpty ? p.firstName : "User",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                            icon: const Icon(Icons.brightness_6_outlined,
                                color: Colors.white),
                            onPressed: p.toggleTheme),
                      ]),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => setState(() => showAccounts = !showAccounts),
                        child: const Row(
                          children: [
                            Icon(Icons.person_outline, color: Colors.white),
                            SizedBox(width: 8),
                            Text("My Accounts",
                                style: TextStyle(color: Colors.white)),
                            Spacer(),
                            Icon(Icons.keyboard_arrow_down, color: Colors.white),
                          ],
                        ),
                      ),

                      // 🔽 ACCOUNTS
                      if (showAccounts)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          margin: const EdgeInsets.only(top: 8),
                          constraints: const BoxConstraints(maxHeight: 230),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: p.accounts.length + 1,
                            itemBuilder: (context, index) {
                              if (index == p.accounts.length) {
                                return ListTile(
                                  leading: const Icon(Icons.add, color: Colors.black),
                                  title: const Text("Add Account",
                                      style: TextStyle(color: Colors.black)),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                        const PhoneLoginScreen()),
                                  ),
                                );
                              }

                              final acc = p.accounts[index];
                              return ListTile(
                                leading: const CircleAvatar(
                                  radius: 16,
                                  backgroundImage: AssetImage('assets/panda.jpg'),
                                ),
                                title: Text(
                                  "${acc['first_name'] ?? ''} ${acc['last_name'] ?? ''}",
                                  style: const TextStyle(color: Colors.black),
                                ),
                                subtitle: Text(
                                  "+${acc['phone'] ?? ''}",
                                  style: const TextStyle(
                                      color: Colors.black54, fontSize: 12),
                                ),

                                trailing: IconButton(
                                  icon: const Icon(Icons.logout,
                                      color: Colors.redAccent, size: 20),
                                  onPressed: () => p.logoutAccount(index, context),
                                  tooltip: "Logout this account",
                                ),
                                // ✅ ইনস্ট্যান্ট অ্যাকাউন্ট চেঞ্জ
                                onTap: () async {
                                  Navigator.pop(context);
                                  setState(() => _isSwitching = true);

                                  await p.loadUser({
                                    "first_name": acc["first_name"],
                                    "last_name": acc["last_name"],
                                    "username": acc["username"],
                                    "phone_number": acc["phone"],
                                  });

                                  // 🔥 Home rebuild করার জন্য micro delay
                                  Future.delayed(const Duration(milliseconds: 100), () {
                                    if (mounted) {
                                      setState(() => _isSwitching = false);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("✅ Account switched instantly"),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),

                // 🌍 LANGUAGE SWITCH
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    dropdownColor: Colors.white,
                    icon: const Icon(Icons.language),
                    value: p.selectedLang,
                    items: langs
                        .map((lang) => DropdownMenuItem<String>(
                      value: lang['code'],
                      child: Row(
                        children: [
                          Text(lang['flag']!,
                              style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 8),
                          Text(lang['name']!,
                              style: const TextStyle(color: Colors.black)),
                        ],
                      ),
                    ))
                        .toList(),
                    onChanged: (code) async {
                      if (code != null) {
                        Navigator.pop(context);
                        setState(() => _isSwitching = true);
                        await p.saveLang(code);
                        // smooth refresh
                        Future.delayed(const Duration(milliseconds: 150), () {
                          if (mounted) {
                            setState(() => _isSwitching = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("🌐 Language changed instantly"),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }
                        });
                      }
                    },
                  ),
                ),

                // BODY MENU
                Expanded(
                  child: ListView(children:  [
                    ListTile(leading: Icon(Icons.person), title: Text("My Profile")),
                    ListTile(
                        leading: Icon(Icons.star_border),
                        title: Text("Special Features")),
                    ListTile(
                      leading: const Icon(Icons.chat_bubble_outline),
                      title: const Text("New Chat"),
                      onTap: () {
                        final p = Provider.of<TelegraphProvider>(context, listen: false);

                        // ensure + prefix
                        final activePhone = p.phoneNumber.startsWith('+')
                            ? p.phoneNumber
                            : '+${p.phoneNumber}';

                        if (activePhone.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No active account phone')),
                          );
                          return;
                        }

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CreateGropu(phoneNumber: activePhone),
                          ),
                        );
                      },
                    ),

                    // ListTile(
                    //     leading: Icon(Icons.chat_bubble_outline),
                    //     title: Text("New Chat"),
                    //
                    // ),
                    Divider(),
                    ListTile(leading: Icon(Icons.contacts), title: Text("Contacts")),
                    ListTile(leading: Icon(Icons.call), title: Text("Calls")),
                    ListTile(
                        leading: Icon(Icons.settings), title: Text("Settings")),
                    ListTile(
                        leading: Icon(Icons.color_lens_outlined),
                        title: Text("Theme Settings")),
                    ListTile(
                        leading: Icon(Icons.group_add_outlined),
                        title: Text("Invite Friends")),
                    Divider(),
                    ListTile(
                        leading: Icon(Icons.logout, color: Colors.red),
                        title: Text("Logout All",
                            style: TextStyle(color: Colors.red))),
                  ]),
                ),
              ],
            ),
          ),

          // 🔹 Loader overlay (দেখাবে যখন switching চলবে)
          if (_isSwitching)
            Container(
              color: Colors.black.withOpacity(0.2),
              alignment: Alignment.center,
              child: const CircularProgressIndicator(color: Colors.red),
            ),
        ],
      ),
    );
  }
}

