import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/telegraph_qg_provider.dart';

class TelegraphHome extends StatefulWidget {
  const TelegraphHome({super.key});

  @override
  State<TelegraphHome> createState() => _TelegraphHomeState();
}

class _TelegraphHomeState extends State<TelegraphHome>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<TelegraphProvider>(context);

    return Scaffold(
      drawer: _buildDrawer(p, context),
      appBar: AppBar(
        title: Text(p.username.isNotEmpty ? p.username : "Telegraph"),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => p.fetchDialogs(p.phoneNumber),
          )
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChats(p),
          _buildContacts(p),
          _buildCalls(p),
          _buildSettings(),
        ],
      ),
    );
  }

  Widget _buildChats(TelegraphProvider p) {
    if (p.dialogs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView.builder(
      itemCount: p.dialogs.length,
      itemBuilder: (context, i) {
        final d = p.dialogs[i];
        return ListTile(
          leading: CircleAvatar(backgroundImage: NetworkImage(d["avatar"])),
          title:
          Text(d["name"], style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(d["last_message"],
              maxLines: 1, overflow: TextOverflow.ellipsis),
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
    );
  }

  Widget _buildContacts(TelegraphProvider p) {
    return ListView(
      children: p.dialogs
          .map((d) => ListTile(
        leading: const Icon(Icons.person_outline),
        title: Text(d["name"]),
        subtitle: Text("@${d["username"]}"),
      ))
          .toList(),
    );
  }

  Widget _buildCalls(TelegraphProvider p) {
    return ListView(
      children: p.dialogs
          .map((d) => ListTile(
        leading: const Icon(Icons.call, color: Colors.green),
        title: Text(d["name"]),
        subtitle: Text("Last message: ${d["last_message"]}"),
      ))
          .toList(),
    );
  }

  Widget _buildSettings() => ListView(
    children: const [
      ListTile(leading: Icon(Icons.settings), title: Text("Account")),
      ListTile(
          leading: Icon(Icons.lock_outline),
          title: Text("Privacy & Security")),
      ListTile(
          leading: Icon(Icons.notifications), title: Text("Notifications")),
      ListTile(
          leading: Icon(Icons.color_lens_outlined), title: Text("Theme")),
    ],
  );

  Widget _buildDrawer(TelegraphProvider p, BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            color: Colors.green,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const CircleAvatar(
                    radius: 25, backgroundImage: AssetImage("assets/panda.jpg")),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(
                      p.username.isEmpty ? "User" : p.username,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    )),
                IconButton(
                    onPressed: p.toggleTheme,
                    icon: const Icon(Icons.brightness_6, color: Colors.white))
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: p.accounts.length,
              itemBuilder: (context, i) {
                final acc = p.accounts[i];
                return ListTile(
                  leading: const Icon(Icons.account_circle),
                  title: Text(acc["username"] ?? "Unknown"),
                  subtitle: Text(acc["phone"] ?? ""),
                  trailing: IconButton(
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    onPressed: () => p.logoutAccount(i, context),
                  ),
                  onTap: () => p.loadUser({
                    "first_name": acc["first_name"],
                    "last_name": acc["last_name"],
                    "username": acc["username"],
                    "phone_number": acc["phone"],
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
