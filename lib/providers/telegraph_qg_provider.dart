

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:translator/translator.dart';

import '../screens/auth_screen/phone_login_screen.dart';

class TelegraphProvider with ChangeNotifier {
  String firstName = "";
  String lastName = "";
  String username = "";
  String phoneNumber = "";
  bool isDark = false;
  String selectedLang = "en";
  List<Map<String, dynamic>> dialogs = [];
  List<Map<String, dynamic>> accounts = [];
  List<Map<String, dynamic>> messages = [];

  final String baseUrl = "http://192.168.0.247:8080";
  final GoogleTranslator _translator = GoogleTranslator();

  bool _initialized = false;

  // bool _isTyping = false;
  // bool get isTyping => _isTyping;
  //
  // void setTyping(bool val) {
  //   _isTyping = val;
  //   notifyListeners();
  // }

// Add a new message to the list (real-time)
  void addMessage(Map<String, dynamic> msg) {
    messages.insert(0, msg); // reversed list
    notifyListeners();
  }

  // ✅ INITIALIZE
  Future<void> initProvider() async {
    if (_initialized) return;
    _initialized = true;
    await loadLang();
    await _restoreUserIfExists();
  }

  // ✅ RESTORE SAVED ACCOUNT
  Future<void> _restoreUserIfExists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('accounts');
      if (saved != null) {
        accounts = List<Map<String, dynamic>>.from(json.decode(saved));
        if (accounts.isNotEmpty) {
          final acc = accounts.first;
          firstName = acc["first_name"] ?? "";
          username = acc["username"] ?? "";
          phoneNumber = acc["phone"] ?? "";
          fetchDialogs(phoneNumber, silent: true); // async no await
        }
      }
    } catch (e) {
      debugPrint("⚠️ Restore user error: $e");
    }
  }

  // ✅ LANGUAGE (INSTANT TRANSLATE)
  Future<void> loadLang() async {
    final prefs = await SharedPreferences.getInstance();
    selectedLang = prefs.getString('lang') ?? 'en';
  }

  Future<void> saveLang(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', code);
    selectedLang = code;

    // 🔥 instant translation (no delay)
    if (dialogs.isNotEmpty) {
      compute(_instantTranslate, {"lang": selectedLang, "dialogs": dialogs})
          .then((translated) {
        dialogs = List<Map<String, dynamic>>.from(translated);
        notifyListeners();
      });
    } else if (phoneNumber.isNotEmpty) {
      fetchDialogs(phoneNumber, silent: true);
    }

    notifyListeners();
  }

  // ✅ LOAD USER
  Future<void> loadUser(Map<String, String>? userData) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('accounts');
    if (saved != null) {
      accounts = List<Map<String, dynamic>>.from(json.decode(saved));
    }

    if (userData != null) {
      final newAcc = {
        "first_name": userData["first_name"] ?? "",
        "last_name": userData["last_name"] ?? "",
        "username": userData["username"] ?? "",
        "phone": userData["phone_number"] ?? "",
        "avatar": "assets/panda.jpg",
      };
      accounts.removeWhere((a) => a["phone"] == newAcc["phone"]);
      accounts.insert(0, newAcc);
      await prefs.setString('accounts', json.encode(accounts));
      firstName = newAcc["first_name"]!;
      username = newAcc["username"]!;
      phoneNumber = newAcc["phone"]!;
    } else if (accounts.isNotEmpty) {
      final acc = accounts.first;
      firstName = acc["first_name"];
      username = acc["username"];
      phoneNumber = acc["phone"];
    }

    notifyListeners();

    if (phoneNumber.isNotEmpty) {
      fetchDialogs(phoneNumber);
    }
  }

  // ⚡ SUPER FAST FETCH DIALOGS
  Future<void> fetchDialogs(String phone, {bool silent = false}) async {
    try {
      final url = Uri.parse("$baseUrl/dialogs?phone=$phone");
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        print('dkfdlkfldkf1213456');
        print(data);

        if (data["dialogs"] is List) {
          // ✅ Background isolate parsing
          final parsed = await compute(_parseDialogsIsolate, {
            "data": data["dialogs"],
            "phone": phone,
            "baseUrl": baseUrl,
          });

          dialogs = List<Map<String, dynamic>>.from(parsed);
          notifyListeners();

          // ✅ Instant background translate (no lag)
          compute(_instantTranslate, {"lang": selectedLang, "dialogs": dialogs})
              .then((translated) {
            dialogs = List<Map<String, dynamic>>.from(translated);
            notifyListeners();
          });
        }
      } else {
        debugPrint("❌ Server error: ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Dialog fetch error: $e");
    }

    if (!silent) notifyListeners();
  }

  // ✅ ISOLATE PARSER
  static Future<List<Map<String, dynamic>>> _parseDialogsIsolate(
      Map<String, dynamic> args) async {
    final List raw = args["data"];
    final String phone = args["phone"];
    final String baseUrl = args["baseUrl"];

    return raw.map<Map<String, dynamic>>((d) {
      final user = d["username"] ?? "";
      final lastMsg = d["last_message"];
      String textMsg = "";

      if (lastMsg is Map) {
        textMsg = lastMsg["text"]?.toString() ?? "";
      } else if (lastMsg is String) {
        textMsg = lastMsg;
      }
      if (textMsg.isEmpty && lastMsg is Map && lastMsg["media"] != null) {
        textMsg = "📸 Media message";
      }
      // ✅ server থেকে যা এসেছে সেটাই নেবো
      final bool? serverIsGroup = (d["is_group"] is bool) ? d["is_group"] as bool : null;

      // 🔒 fallback logic (যদি কারও ডাটা missing হয়)
      final bool isGroup = serverIsGroup ??
          (d["is_channel"] == true) ||
              (d["type"] == "group" || d["type"] == "megagroup" || d["type"] == "channel") ||
              // অনেক সময়ে basic group এ access_hash null থাকে
              ((d["is_user"] != true) && d["access_hash"] == null);
      return {
        "id": d["id"],
        "name": (d["first_name"] ?? "Unknown").toString(),
        "access_hash": d["access_hash"],
        "username": user.toString(),
        "last_message": textMsg,
        "unread_count": d["unread_count"] ?? 0,
        "is_group": isGroup,
        "avatar": "$baseUrl/avatar_redirect?phone=$phone&username=@$user",
      };
    }).toList();
  }

  // ✅ ULTRA FAST INSTANT TRANSLATE (no delay)
  static Future<List<Map<String, dynamic>>> _instantTranslate(
      Map<String, dynamic> args) async {
    final lang = args["lang"] as String;
    final dialogs = List<Map<String, dynamic>>.from(args["dialogs"]);
    final translator = GoogleTranslator();

    if (lang == 'en') return dialogs;

    // ⚡ Translate all dialogs simultaneously (parallel)
    await Future.wait(dialogs.map((d) async {
      try {
        final name = d["name"] ?? "";
        final msg = d["last_message"] ?? "";
        d["name"] =
        await translator.translate(name, to: lang).then((t) => t.text);
        d["last_message"] =
        await translator.translate(msg, to: lang).then((t) => t.text);
      } catch (_) {}
    }));

    return dialogs;
  }

  // ✅ LOGOUT

  Future<void> logoutAccount(int index, BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final removed = accounts[index];
    final phone = removed["phone"] ?? "";

    try {
      final url = Uri.parse("$baseUrl/logout");
      await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"phone": phone}),
      );
    } catch (e) {
      debugPrint("⚠️ Logout API error: $e");
    }

    // 🔹 Remove from local list
    accounts.removeAt(index);
    await prefs.setString('accounts', json.encode(accounts));

    // 🔹 যদি সব মুছে যায় → Login screen-এ পাঠাবে
    if (accounts.isEmpty) {
      await prefs.clear();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const PhoneLoginScreen()),
              (route) => false,
        );
      }
      return;
    }

    // 🔹 অন্যথায়, পরের account কে active করবে
    final next = accounts.first;
    await loadUser({
      "first_name": next["first_name"] ?? "",
      "last_name": next["last_name"] ?? "",
      "username": next["username"] ?? "",
      "phone_number": next["phone"] ?? "",
    });

    if (context.mounted) {
      Navigator.pop(context); // Drawer বন্ধ করবে
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Switched to ${next['first_name'] ?? 'next'} account"),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }
  /// chat fach Massage
  ///
  ///
  ///
  ///
  Future<void> fetchMessages(String phone, int chatId, int accessHash) async {
    try {
      final url = Uri.parse(
          "$baseUrl/messages?phone=+$phone&chat_id=$chatId&access_hash=$accessHash");
      print("📥 Fetching → $url");

      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final List raw = data["messages"] ?? [];

        messages = raw.map<Map<String, dynamic>>((m) {
          final type = m["media_type"] ?? "text";
          final call = m["call"];

          // ✅ detect deleted messages
          final bool isDeleted = (m["exists_on_telegram"] == false) ||
              (m["deleted_on_telegram"] == true);

          // ☎️ handle call messages
          if (type.startsWith("call") && call != null) {
            String callText = "";
            final dir = call["direction"] ?? "";
            final status = call["status"] ?? "";
            final dur = call["duration"];
            final sec = (dur is num) ? dur.toInt() : null;

            if (status == "missed") {
              callText =
              "Missed ${type == "call_video" ? "Video" : "Voice"} Call";
            } else if (status == "ended") {
              callText =
              "Ended ${type == "call_video" ? "Video" : "Voice"} Call";
            } else {
              callText =
              "${type == "call_video" ? "Video" : "Voice"} Call";
            }

            if (sec != null && sec > 0) {
              final h = sec ~/ 3600;
              final m = (sec % 3600) ~/ 60;
              final s = sec % 60;
              final durStr = h > 0
                  ? "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}"
                  : "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
              callText += " • $durStr";
            }

            return {
              "id": m["id"],
              "text": callText,
              "is_out": m["is_out"] ?? false,
              "time": m["date"] ?? "",
              "type": type,
              "call_status": status,
              "call_direction": dir,
              "sender_name": m["sender_name"] ?? "",
              "is_deleted": isDeleted,
            };
          }

          // 🧱 Normal message
          return {
            "id": m["id"],
            "text": m["text"] ?? "",
            "is_out": m["is_out"] ?? false,
            "time": m["date"] ?? "",
            "type": type,
            "url": m["media_link"],
            "sender_name": m["sender_name"] ?? "",
            "is_deleted": isDeleted,
          };
        }).toList().reversed.toList();

        notifyListeners();
      } else {
        print("❌ Server error: ${res.statusCode}");
      }
    } catch (e) {
      print("❌ Fetch messages error: $e");
    }
  }


  // Future<void> fetchMessages(String phone, int chatId, int accessHash) async {
  //   try {
  //     final url = Uri.parse(
  //         "$baseUrl/messages?phone=$phone&chat_id=$chatId&access_hash=$accessHash");
  //     print("📥 Fetching → $url");
  //
  //     final res = await http.get(url);
  //     if (res.statusCode == 200) {
  //       final data = json.decode(res.body);
  //       final List raw = data["messages"] ?? [];
  //
  //       messages = raw.map<Map<String, dynamic>>((m) {
  //         final type = m["media_type"] ?? "text";
  //         final call = m["call"];
  //
  //         // Call message
  //         if (type.startsWith("call") && call != null) {
  //           String callText = "";
  //           final dir = call["direction"] ?? "";
  //           final status = call["status"] ?? "";
  //           final dur = call["duration"];
  //           final sec = (dur is num) ? dur.toInt() : null;
  //
  //           if (status == "missed") {
  //             callText = "Missed ${type == "call_video" ? "Video" : "Voice"} Call";
  //           } else if (status == "ended") {
  //             callText = "Ended ${type == "call_video" ? "Video" : "Voice"} Call";
  //           } else {
  //             callText = "${type == "call_video" ? "Video" : "Voice"} Call";
  //           }
  //
  //           if (sec != null && sec > 0) {
  //             final h = sec ~/ 3600;
  //             final m = (sec % 3600) ~/ 60;
  //             final s = sec % 60;
  //             final durStr = h > 0
  //                 ? "${h.toString().padLeft(2,'0')}:${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}"
  //                 : "${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}";
  //             callText += " • $durStr";
  //           }
  //
  //           return {
  //             "id": m["id"],
  //             "text": callText,
  //             "is_out": m["is_out"] ?? false,
  //             "time": m["date"] ?? "",
  //             "type": type, // call_audio / call_video
  //             "call_status": status,
  //             "call_direction": dir,
  //             "sender_name": m["sender_name"] ?? "",
  //           };
  //         }
  //
  //         // Normal messages (text / image / video / file)
  //         return {
  //           "id": m["id"],
  //           "text": m["text"] ?? "",
  //           "is_out": m["is_out"] ?? false,
  //           "time": m["date"] ?? "",
  //           "type": type,
  //           "url": m["media_link"],
  //           "sender_name": m["sender_name"] ?? "",
  //         };
  //       }).toList().reversed.toList();
  //
  //       notifyListeners();
  //     } else {
  //       print("❌ Server error: ${res.statusCode}");
  //     }
  //   } catch (e) {
  //     print("❌ Fetch messages error: $e");
  //   }
  // }



  Future<void> sendMessage(String phone, String to, String text) async {
    try {
      final url = Uri.parse("$baseUrl/send");

      var req = http.MultipartRequest('POST', url)
        ..fields['phone'] = phone
        ..fields['to'] = to
        ..fields['text'] = text;

      final res = await req.send();
      final body = await res.stream.bytesToString();

      debugPrint("📨 Send API Response: $body");

      if (res.statusCode == 200) {
        final data = json.decode(body);
        debugPrint("✅ Message Sent Successfully: ${data.toString()}");
      } else {
        debugPrint("❌ Send Failed [${res.statusCode}]: $body");
      }
    } catch (e) {
      debugPrint("⚠️ Send Message Error: $e");
    }
  }



  // ✅ THEME TOGGLE
  void toggleTheme() {
    isDark = !isDark;
    notifyListeners();
  }
}




