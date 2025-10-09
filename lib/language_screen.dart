// import 'package:flutter/material.dart';
// import 'package:easy_localization/easy_localization.dart';
//
// class LanguageScreen extends StatefulWidget {
//   const LanguageScreen({super.key});
//
//   @override
//   State<LanguageScreen> createState() => _LanguageScreenState();
// }
//
// class _LanguageScreenState extends State<LanguageScreen> {
//   final TextEditingController _searchCtrl = TextEditingController();
//
//   final List<Map<String, dynamic>> languages = [
//     {'flag': '🇬🇧', 'name': 'English', 'native': 'English', 'locale': const Locale('en')},
//     {'flag': '🇨🇳', 'name': '简体中文', 'native': 'Chinese (Simplified)', 'locale': const Locale('zh')},
//     {'flag': '🇧🇩', 'name': 'বাংলা', 'native': 'Bangla', 'locale': const Locale('bn')},
//     {'flag': '🇮🇳', 'name': 'हिन्दी', 'native': 'Hindi', 'locale': const Locale('hi')},
//     {'flag': '🇪🇸', 'name': 'Español', 'native': 'Spanish', 'locale': const Locale('es')},
//     {'flag': '🇷🇺', 'name': 'Русский', 'native': 'Russian', 'locale': const Locale('ru')},
//     {'flag': '🇸🇦', 'name': 'العربية', 'native': 'Arabic', 'locale': const Locale('ar')},
//     {'flag': '🇹🇷', 'name': 'Türkçe', 'native': 'Turkish', 'locale': const Locale('tr')},
//     {'flag': '🇫🇷', 'name': 'Français', 'native': 'French', 'locale': const Locale('fr')},
//     {'flag': '🇩🇪', 'name': 'Deutsch', 'native': 'German', 'locale': const Locale('de')},
//     {'flag': '🇮🇹', 'name': 'Italiano', 'native': 'Italian', 'locale': const Locale('it')},
//     {'flag': '🇰🇷', 'name': '한국어', 'native': 'Korean', 'locale': const Locale('ko')},
//     {'flag': '🇯🇵', 'name': '日本語', 'native': 'Japanese', 'locale': const Locale('ja')},
//     {'flag': '🇮🇩', 'name': 'Bahasa Indonesia', 'native': 'Indonesian', 'locale': const Locale('id')},
//     {'flag': '🇺🇿', 'name': "Oʻzbekcha", 'native': 'Uzbek', 'locale': const Locale('uz')},
//     {'flag': '🇧🇷', 'name': 'Português (Brasil)', 'native': 'Portuguese (Brazil)', 'locale': const Locale('pt')}
//   ];
//
//   String searchQuery = '';
//
//   @override
//   Widget build(BuildContext context) {
//     final current = context.locale;
//
//     final filteredLanguages = languages.where((lang) {
//       final name = lang['name'].toString().toLowerCase();
//       final native = lang['native'].toString().toLowerCase();
//       return name.contains(searchQuery.toLowerCase()) ||
//           native.contains(searchQuery.toLowerCase());
//     }).toList();
//
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.green,
//         title: Text(tr('language')),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.search),
//             onPressed: () {
//               showSearch(
//                 context: context,
//                 delegate: _LanguageSearchDelegate(languages, current, context),
//               );
//             },
//           )
//         ],
//       ),
//       body: ListView.separated(
//         itemCount: filteredLanguages.length,
//         separatorBuilder: (context, i) => const Divider(height: 1),
//         itemBuilder: (context, i) {
//           final lang = filteredLanguages[i];
//           final locale = lang['locale'] as Locale;
//
//           return RadioListTile<Locale>(
//             value: locale,
//             groupValue: current,
//             activeColor: Colors.green,
//             onChanged: (val) {
//               context.setLocale(locale);
//               setState(() {});
//             },
//             title: Text(
//               "${lang['flag']} ${lang['name']}",
//               style: const TextStyle(fontSize: 16),
//             ),
//             subtitle: Text(
//               lang['native'],
//               style: const TextStyle(color: Colors.grey, fontSize: 13),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
//
// class _LanguageSearchDelegate extends SearchDelegate {
//   final List<Map<String, dynamic>> langs;
//   final Locale current;
//   final BuildContext ctx;
//   _LanguageSearchDelegate(this.langs, this.current, this.ctx);
//
//   @override
//   List<Widget>? buildActions(BuildContext context) =>
//       [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];
//
//   @override
//   Widget? buildLeading(BuildContext context) => IconButton(
//       icon: const Icon(Icons.arrow_back),
//       onPressed: () => close(context, ''));
//
//   @override
//   Widget buildResults(BuildContext context) => _buildList(context);
//
//   @override
//   Widget buildSuggestions(BuildContext context) => _buildList(context);
//
//   Widget _buildList(BuildContext context) {
//     final filtered = langs.where((l) {
//       final name = l['name'].toString().toLowerCase();
//       final native = l['native'].toString().toLowerCase();
//       return name.contains(query.toLowerCase()) ||
//           native.contains(query.toLowerCase());
//     }).toList();
//
//     return ListView.builder(
//       itemCount: filtered.length,
//       itemBuilder: (context, i) {
//         final lang = filtered[i];
//         return ListTile(
//           leading: Text(lang['flag'], style: const TextStyle(fontSize: 22)),
//           title: Text(lang['name']),
//           subtitle: Text(lang['native']),
//           trailing: lang['locale'] == context.locale
//               ? const Icon(Icons.check, color: Colors.green)
//               : null,
//           onTap: () {
//             ctx.setLocale(lang['locale']);
//             close(context, lang['name']);
//           },
//         );
//       },
//     );
//   }
// }







import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  String firstName = "", lastName = "", username = "", phoneNumber = "";
  bool isDark = false;
  String selectedLang = 'en';
  final translator = GoogleTranslator();

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
    if (saved != null) accounts = List<Map<String, dynamic>>.from(json.decode(saved));

    if (widget.userData != null) {
      final newAcc = {
        "first_name": widget.userData!["first_name"] ?? "",
        "last_name": widget.userData!["last_name"] ?? "",
        "username": widget.userData!["username"] ?? "",
        "phone": widget.userData!["phone_number"] ?? "",
        "avatar": "assets/panda.jpg",
      };
      accounts.removeWhere((a) => a["phone"] == newAcc["phone"]);
      accounts.insert(0, newAcc);
      await prefs.setString('accounts', json.encode(accounts));
      firstName = newAcc["first_name"] ?? "";
      lastName = newAcc["last_name"] ?? "";
      username = newAcc["username"] ?? "";
      phoneNumber = newAcc["phone"] ?? "";
    } else if (accounts.isNotEmpty) {
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
      debugShowCheckedModeBanner: false,
      title: 'Telegraph',
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E2429),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF2C343A)),
      ),
      theme: ThemeData(
        primaryColor: Colors.green,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(color: Colors.green, foregroundColor: Colors.white),
      ),
      home: TelegraphHome(
        isDark: isDark,
        onThemeToggle: () => setState(() => isDark = !isDark),
        firstName: firstName,
        lastName: lastName,
        username: username,
        phoneNumber: phoneNumber,
        selectedLang: selectedLang,
        onLangChange: _saveLang,
        autoT: autoT,
      ),
    );
  }
}

class TelegraphHome extends StatefulWidget {
  final bool isDark;
  final VoidCallback onThemeToggle;
  final String selectedLang;
  final Function(String) onLangChange;
  final Future<String> Function(String) autoT;
  final String firstName, lastName, username, phoneNumber;
  const TelegraphHome({
    super.key,
    required this.isDark,
    required this.onThemeToggle,
    required this.selectedLang,
    required this.onLangChange,
    required this.autoT,
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
        onThemeToggle: widget.onThemeToggle,
        selectedLang: widget.selectedLang,
        onLangChange: widget.onLangChange,
        autoT: widget.autoT,
      ),
      appBar: AppBar(
        title: Text(widget.firstName.isNotEmpty ? widget.firstName : "Telegraph"),
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
        child:
        Text(chats[i]['name']![0], style: const TextStyle(color: Colors.white)),
      ),
      title: Text(chats[i]['name']!,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(chats[i]['msg']!,
          maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text(chats[i]['time']!,
          style: const TextStyle(color: Colors.grey, fontSize: 12)),
    ),
  );

  Widget _buildContactsTab() => ListView(children: const [
    ListTile(
        leading: Icon(Icons.person_outline),
        title: Text("Tamjid Dev"),
        subtitle: Text("+880 1928478904")),
    ListTile(
        leading: Icon(Icons.person_outline),
        title: Text("Rakib Hasan"),
        subtitle: Text("+880 1710000000")),
  ]);

  Widget _buildCallsTab() => ListView(children: const [
    ListTile(
        leading: Icon(Icons.call_received, color: Colors.red),
        title: Text("Missed Call – Rakib Hasan"),
        subtitle: Text("Yesterday 9:40 PM")),
    ListTile(
        leading: Icon(Icons.call_made, color: Colors.green),
        title: Text("Outgoing Call – Tamjid Dev"),
        subtitle: Text("Today 10:12 AM")),
  ]);

  Widget _buildSettingsTab() => ListView(children: const [
    ListTile(leading: Icon(Icons.settings), title: Text("Account")),
    ListTile(
        leading: Icon(Icons.lock_outline), title: Text("Privacy & Security")),
    ListTile(
        leading: Icon(Icons.notifications), title: Text("Notifications")),
    ListTile(
        leading: Icon(Icons.color_lens_outlined), title: Text("Theme")),
  ]);
}

// ================= DRAWER =================
class TelegraphDrawer extends StatefulWidget {
  final bool isDark;
  final VoidCallback onThemeToggle;
  final String selectedLang;
  final Function(String) onLangChange;
  final Future<String> Function(String) autoT;
  const TelegraphDrawer({
    super.key,
    required this.isDark,
    required this.onThemeToggle,
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
      accounts = List<Map<String, dynamic>>.from(json.decode(saved));
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 300,
      child: Container(
        color: widget.isDark ? Colors.black : Colors.white,
        child: Column(children: [
          Container(
            color: widget.isDark ? Colors.grey[900] : Colors.red,
            padding: const EdgeInsets.only(top: 40, left: 10, right: 10, bottom: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const CircleAvatar(radius: 28, backgroundImage: AssetImage('assets/panda.jpg')),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(
                        accounts.isNotEmpty
                            ? "${accounts.first['first_name']} ${accounts.first['last_name']}"
                            : "User",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold))),


                // DropdownButtonHideUnderline(
                //   child: DropdownButton<String>(
                //     dropdownColor: Colors.white,
                //     // 🔹 নির্বাচিত ভাষা উপরে শুধু flag হিসেবে দেখাবে
                //     icon: Text(
                //       langs.firstWhere((l) => l['code'] == widget.selectedLang,
                //           orElse: () => langs.first)['flag']!,
                //       style: const TextStyle(fontSize: 24),
                //     ),
                //     // value: widget.selectedLang,
                //     // 🔹 Dropdown list খুললে flag + name দুটোই দেখাবে
                //     items: langs
                //         .map((lang) => DropdownMenuItem<String>(
                //       value: lang['code'],
                //       child: Row(
                //         children: [
                //           Text(lang['flag']!, style: const TextStyle(fontSize: 20)),
                //           const SizedBox(width: 8),
                //           Text(
                //             lang['name']!,
                //             style: const TextStyle(
                //               fontSize: 14,
                //               color: Colors.black,
                //             ),
                //           ),
                //         ],
                //       ),
                //     ))
                //         .toList(),
                //     onChanged: (code) {
                //       if (code != null) {
                //         widget.onLangChange(code);
                //         setState(() {});
                //       }
                //     },
                //   ),
                // ),


                IconButton(
                    icon: const Icon(Icons.brightness_6_outlined, color: Colors.white),
                    onPressed: widget.onThemeToggle),
              ]),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => setState(() => showAccounts = !showAccounts),
                child: Row(children: const [
                  Icon(Icons.person_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Text("My Accounts", style: TextStyle(color: Colors.white)),
                  Spacer(),
                  Icon(Icons.keyboard_arrow_down, color: Colors.white),
                ]),
              ),
              if (showAccounts)
                Container(
                  decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  margin: const EdgeInsets.only(top: 8),
                  constraints: const BoxConstraints(maxHeight: 230),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: accounts.length + 1,
                    itemBuilder: (context, index) {
                      if (index == accounts.length) {
                        return ListTile(
                            leading: const Icon(Icons.add, color: Colors.black),
                            title: const Text("Add Account",
                                style: TextStyle(color: Colors.black)));
                      }
                      final acc = accounts[index];
                      return ListTile(
                        leading: const CircleAvatar(
                            radius: 16, backgroundImage: AssetImage('assets/panda.jpg')),
                        title: Text("${acc['first_name']} ${acc['last_name']}",
                            style: const TextStyle(color: Colors.black)),
                        subtitle: Text("+${acc['phone']}",
                            style:
                            const TextStyle(color: Colors.black54, fontSize: 12)),
                        trailing: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                      );
                    },
                  ),
                ),
            ]),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: Colors.white,
              icon: const Icon(Icons.translate_outlined, color: Colors.black),
              value: widget.selectedLang,
              items: langs
                  .map((lang) => DropdownMenuItem<String>(
                value: lang['code'],
                child: Text("${lang['flag']}"" ${lang['name']}"
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
        ]),
      ),
    );
  }
}
