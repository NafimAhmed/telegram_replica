// screens/create_gropu.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../url.dart';
import 'chant.dart';
import 'chat_screen.dart';

class CreateGropu extends StatefulWidget {
  final String phoneNumber; // active account phone (+880…)
  const CreateGropu({super.key, required this.phoneNumber});

  @override
  State<CreateGropu> createState() => _CreateGropuState();
}

class _CreateGropuState extends State<CreateGropu> {
  final TextEditingController _query = TextEditingController();
  final TextEditingController _title = TextEditingController();

  // 🔧 Search results (current page)
  final List<Map<String, dynamic>> _results = [];

  // ✅ Persistent selection (across searches)
  final Set<String> _selected = {}; // tokens: '@username' or '+880…'
  final Map<String, Map<String, dynamic>> _selectedMap = {}; // token -> person map

  Timer? _debounce;
  bool _loading = false;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _query.addListener(_onChanged);
  }

  @override
  void dispose() {
    _query.removeListener(_onChanged);
    _query.dispose();
    _title.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _search);
  }

  Future<void> _search() async {
    final q = _query.text.trim();
    if (q.isEmpty) {
      setState(() => _results.clear());
      return;
    }
    setState(() => _loading = true);
    try {
      final uri = Uri.parse(
        '$urlLocal/search_people?q=${Uri.encodeComponent(q)}&phone=${Uri.encodeComponent(widget.phoneNumber)}',
      );
      final r = await http.get(uri);
      if (r.statusCode < 200 || r.statusCode >= 300) {
        // throw Exception('Server ${r.statusCode}: ${r.body}');
      }
      final data = jsonDecode(r.body);
      final list = data is List ? data : (data['results'] ?? []) as List;

      // expected keys: first_name, last_name, username, phone, avatar
      _results
        ..clear()
        ..addAll(list.map<Map<String, dynamic>>((e) {
          final m = (e as Map).map((k, v) => MapEntry(k.toString(), v));
          final fn = (m['first_name'] ?? '').toString().trim();
          final ln = (m['last_name'] ?? '').toString().trim();
          final name = [fn, ln].where((x) => x.isNotEmpty).join(' ').trim();
          final username = (m['username'] ?? '').toString().trim();
          final phone = (m['phone'] ?? '').toString().trim();
          final token = username.isNotEmpty
              ? (username.startsWith('@') ? username : '@$username')
              : phone; // fallback phone
          return {
            'display': name.isNotEmpty ? name : (username.isNotEmpty ? username : phone),
            'username': username,
            'phone': phone,
            'avatar': (m['avatar'] ?? '').toString(),
            'token': token,
          };
        }));
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // 🔁 Toggle selection (works for both results & chips)
  void _toggle(Map<String, dynamic> person) {
    final t = (person['token'] as String? ?? '').trim();
    if (t.isEmpty) return;

    setState(() {
      if (_selected.contains(t)) {
        _selected.remove(t);
        _selectedMap.remove(t); // remove from persistent store
      } else {
        _selected.add(t);
        _selectedMap[t] = {
          'display': person['display'],
          'username': person['username'],
          'phone': person['phone'],
          'avatar': person['avatar'],
          'token': t,
        }; // persist
      }
    });
  }

  Future<void> _createGroup() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick at least one member')),
      );
      return;
    }

    setState(() => _creating = true);
    try {
      final uri = Uri.parse('$urlLocal/create_group'); // e.g. http://127.0.0.1:8080/create_group
      final body = jsonEncode({
        'phone': widget.phoneNumber,
        'title': title,
        'type': 'chat',
        // 🔑 send from persistent map (order not guaranteed, ok)
        'members': _selectedMap.keys.toList(),
      });

      final r = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      if (r.statusCode < 200 || r.statusCode >= 300) {
        throw Exception('Server ${r.statusCode}: ${r.body}');
      }
      final m = jsonDecode(r.body) as Map<String, dynamic>;
      final chatId = m['id'];
      if (chatId == null) throw Exception('Missing chat id');

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            phone: widget.phoneNumber,
            chatId: chatId is int ? chatId : int.parse('$chatId'),
            accessHash: null,
            name: title,
            username: '',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Create failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selected.length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('New Group'),
            Text(
              '$selectedCount selected',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          // Quick clear all (optional)
          IconButton(
            tooltip: 'Clear selected',
            onPressed: selectedCount == 0
                ? null
                : () => setState(() {
              _selected.clear();
              _selectedMap.clear();
            }),
            icon: const Icon(Icons.clear_all),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _creating ? null : _createGroup,
        child: _creating
            ? const Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(strokeWidth: 3),
        )
            : const Icon(Icons.check),
      ),
      body: ListView(
        children: [
          // Group title row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const CircleAvatar(radius: 28, child: Icon(Icons.camera_alt_outlined)),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: _title,
                    decoration: const InputDecoration(
                      hintText: 'Group name',
                      border: UnderlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ✅ Chips from persistent selection (NOT from _results)
          if (selectedCount > 0)
            SizedBox(
              height: 70,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                scrollDirection: Axis.horizontal,
                children: _selectedMap.values.map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Chip(
                      label: Text(e['display']),
                      onDeleted: () => _toggle(e), // pass the stored map
                    ),
                  );
                }).toList(),
              ),
            ),

          // Search box
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            child: TextField(
              controller: _query,
              decoration: InputDecoration(
                hintText: 'Search people',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (_loading) const LinearProgressIndicator(minHeight: 2),

          // Search results (tap to toggle, preserved in _selectedMap)
          ..._results.map((e) {
            final selected = _selected.contains(e['token']);
            return Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(e['display'], maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    e['username'].toString().isNotEmpty
                        ? (e['username'].toString().startsWith('@') ? e['username'] : '@${e['username']}')
                        : e['phone'] ?? '',
                  ),
                  trailing: selected
                      ? const Icon(Icons.check_circle, color: Colors.blue)
                      : const Icon(Icons.radio_button_unchecked),
                  onTap: () => _toggle(e),
                ),
                const Divider(height: 1, thickness: 0.4),
              ],
            );
          }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
