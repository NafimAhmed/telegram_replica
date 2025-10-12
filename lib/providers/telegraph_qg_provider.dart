//
//
// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:translator/translator.dart';
//
// class TelegraphProvider with ChangeNotifier {
//   String firstName = "";
//   String lastName = "";
//   String username = "";
//   String phoneNumber = "";
//   bool isDark = false;
//   String selectedLang = "en";
//   List<Map<String, dynamic>> dialogs = [];
//   List<Map<String, dynamic>> accounts = [];
//
//   final String baseUrl = "http://192.168.0.247:8080";
//   final GoogleTranslator _translator = GoogleTranslator();
//
//   bool _initialized = false;
//
//   Future<void> initProvider() async {
//     if (_initialized) return;
//     _initialized = true;
//     await loadLang();
//     await _restoreUserIfExists();
//   }
//
//   // ---------------- RESTORE ----------------
//   Future<void> _restoreUserIfExists() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final saved = prefs.getString('accounts');
//       if (saved != null) {
//         accounts = List<Map<String, dynamic>>.from(json.decode(saved));
//         if (accounts.isNotEmpty) {
//           final acc = accounts.first;
//           firstName = acc["first_name"] ?? "";
//           username = acc["username"] ?? "";
//           phoneNumber = acc["phone"] ?? "";
//           fetchDialogs(phoneNumber, silent: true); // 🔥 async call (no await)
//         }
//       }
//     } catch (e) {
//       print("⚠️ Restore user error: $e");
//     }
//   }
//
//   // ---------------- LANGUAGE ----------------
//   Future<void> loadLang() async {
//     final prefs = await SharedPreferences.getInstance();
//     selectedLang = prefs.getString('lang') ?? 'en';
//   }
//
//   Future<void> saveLang(String code) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('lang', code);
//     selectedLang = code;
//
//     // Translate asynchronously (no lag)
//     compute(_backgroundTranslate, {"lang": selectedLang, "dialogs": dialogs})
//         .then((result) {
//       dialogs = List<Map<String, dynamic>>.from(result);
//       notifyListeners();
//     });
//   }
//
//   // ---------------- LOAD USER ----------------
//   Future<void> loadUser(Map<String, String>? userData) async {
//     final prefs = await SharedPreferences.getInstance();
//     final saved = prefs.getString('accounts');
//     if (saved != null) accounts = List<Map<String, dynamic>>.from(json.decode(saved));
//
//     if (userData != null) {
//       final newAcc = {
//         "first_name": userData["first_name"] ?? "",
//         "last_name": userData["last_name"] ?? "",
//         "username": userData["username"] ?? "",
//         "phone": userData["phone_number"] ?? "",
//         "avatar": "assets/panda.jpg",
//       };
//       accounts.removeWhere((a) => a["phone"] == newAcc["phone"]);
//       accounts.insert(0, newAcc);
//       await prefs.setString('accounts', json.encode(accounts));
//       firstName = newAcc["first_name"]!;
//       username = newAcc["username"]!;
//       phoneNumber = newAcc["phone"]!;
//     } else if (accounts.isNotEmpty) {
//       final acc = accounts.first;
//       firstName = acc["first_name"];
//       username = acc["username"];
//       phoneNumber = acc["phone"];
//     }
//
//     // ✅ সঙ্গে সঙ্গে name update
//     notifyListeners();
//
//     if (phoneNumber.isNotEmpty) {
//       fetchDialogs(phoneNumber); // async run (UI freeze করবে না)
//     }
//   }
//
//   // ---------------- FETCH DIALOGS ----------------
//   // Future<void> fetchDialogs(String phone, {bool silent = false}) async {
//   //   try {
//   //     final url = Uri.parse("$baseUrl/dialogs?phone=$phone");
//   //     final res = await http.get(url);
//   //
//   //     if (res.statusCode == 200) {
//   //       final data = json.decode(res.body);
//   //
//   //       if (data["dialogs"] is List) {
//   //         final allDialogs = (data["dialogs"] as List).map<Map<String, dynamic>>((d) {
//   //           final user = d["username"] ?? "";
//   //           dynamic lastMsg = d["last_message"];
//   //
//   //           String textMsg = "";
//   //           if (lastMsg is Map) {
//   //             textMsg = lastMsg["text"]?.toString() ?? "";
//   //           } else if (lastMsg is String) {
//   //             textMsg = lastMsg;
//   //           }
//   //           if (textMsg.isEmpty && lastMsg is Map && lastMsg["media"] != null) {
//   //             textMsg = "📸 Media message";
//   //           }
//   //
//   //           return {
//   //             "name": (d["name"] ?? "Unknown").toString(),
//   //             "username": user.toString(),
//   //             "last_message": textMsg,
//   //             "unread_count": d["unread_count"] ?? 0,
//   //             "avatar": "$baseUrl/avatar_redirect?phone=$phone&username=@$user",
//   //             "id": d["id"],
//   //           };
//   //         }).toList();
//   //
//   //         dialogs = [];
//   //         notifyListeners();
//   //
//   //         // 🔹 ultra-fast batch insert (2-item batches, 90 ms delay)
//   //         const batchSize = 2;
//   //         for (int i = 0; i < allDialogs.length; i += batchSize) {
//   //           final end = (i + batchSize > allDialogs.length)
//   //               ? allDialogs.length
//   //               : i + batchSize;
//   //           dialogs.addAll(allDialogs.sublist(i, end));
//   //
//   //           // ⚡ super-short delay keeps animation smooth but instant
//   //           await Future.delayed(const Duration(milliseconds: 90));
//   //           notifyListeners();
//   //         }
//   //
//   //         // 🔹 background translate (no lag on UI)
//   //         compute(_backgroundTranslate, {"lang": selectedLang, "dialogs": dialogs})
//   //             .then((result) {
//   //           dialogs = List<Map<String, dynamic>>.from(result);
//   //           notifyListeners();
//   //         });
//   //       }
//   //     } else {
//   //       print("❌ Server error: ${res.statusCode}");
//   //     }
//   //   } catch (e) {
//   //     print("❌ Dialog fetch error: $e");
//   //   }
//   //
//   //   if (!silent) notifyListeners();
//   // }
//
// // ---------------- SUPER FAST FETCH DIALOGS ----------------
//   Future<void> fetchDialogs(String phone, {bool silent = false}) async {
//     try {
//       final url = Uri.parse("$baseUrl/dialogs?phone=$phone");
//       final res = await http.get(url);
//
//       if (res.statusCode == 200) {
//         final data = json.decode(res.body);
//
//         if (data["dialogs"] is List) {
//           // ✅ Step 1: Heavy parsing in background isolate
//           final parsed = await compute(_parseDialogsIsolate, {
//             "data": data["dialogs"],
//             "phone": phone,
//             "baseUrl": baseUrl,
//           });
//
//           // ✅ Step 2: UI instantly updated (no artificial delay)
//           dialogs = List<Map<String, dynamic>>.from(parsed);
//           notifyListeners();
//
//           // ✅ Step 3: Background translate (non-blocking)
//           compute(_backgroundTranslate, {"lang": selectedLang, "dialogs": dialogs})
//               .then((translated) {
//             dialogs = List<Map<String, dynamic>>.from(translated);
//             notifyListeners();
//           });
//         }
//       } else {
//         debugPrint("❌ Server error: ${res.statusCode}");
//       }
//     } catch (e) {
//       debugPrint("❌ Dialog fetch error: $e");
//     }
//
//     if (!silent) notifyListeners();
//   }
//
// // ---------------- ISOLATE PARSER ----------------
//   static Future<List<Map<String, dynamic>>> _parseDialogsIsolate(
//       Map<String, dynamic> args) async {
//     final List raw = args["data"];
//     final String phone = args["phone"];
//     final String baseUrl = args["baseUrl"];
//
//     return raw.map<Map<String, dynamic>>((d) {
//       final user = d["username"] ?? "";
//       final lastMsg = d["last_message"];
//
//       String textMsg = "";
//       if (lastMsg is Map) {
//         textMsg = lastMsg["text"]?.toString() ?? "";
//       } else if (lastMsg is String) {
//         textMsg = lastMsg;
//       }
//
//       if (textMsg.isEmpty && lastMsg is Map && lastMsg["media"] != null) {
//         textMsg = "📸 Media message";
//       }
//
//       return {
//         "id": d["id"],
//         "name": (d["name"] ?? "Unknown").toString(),
//         "username": user.toString(),
//         "last_message": textMsg,
//         "unread_count": d["unread_count"] ?? 0,
//         "avatar": "$baseUrl/avatar_redirect?phone=$phone&username=@$user",
//       };
//     }).toList();
//   }
//   // ---------------- BACKGROUND TRANSLATE (runs off main thread) ----------------
//   static Future<List<Map<String, dynamic>>> _backgroundTranslate(
//       Map<String, dynamic> args) async {
//     final lang = args["lang"] as String;
//     final dialogs = List<Map<String, dynamic>>.from(args["dialogs"]);
//     final translator = GoogleTranslator();
//
//     if (lang == 'en') return dialogs;
//
//     for (int i = 0; i < dialogs.length; i++) {
//       final d = dialogs[i];
//       try {
//         final name = d["name"] ?? "";
//         final msg = d["last_message"] ?? "";
//         dialogs[i]["name"] = await translator.translate(name, to: lang).then((t) => t.text);
//         dialogs[i]["last_message"] =
//         await translator.translate(msg, to: lang).then((t) => t.text);
//       } catch (_) {}
//     }
//     return dialogs;
//   }
//
//   // ---------------- LOGOUT ----------------
//   Future<void> logoutAccount(int index, BuildContext context) async {
//     final prefs = await SharedPreferences.getInstance();
//     final removed = accounts[index];
//     final phone = removed["phone"] ?? "";
//
//     try {
//       final url = Uri.parse("$baseUrl/logout");
//       await http.post(url,
//           headers: {"Content-Type": "application/json"},
//           body: json.encode({"phone": phone}));
//     } catch (e) {
//       print("⚠️ Logout API error: $e");
//     }
//
//     accounts.removeAt(index);
//     await prefs.setString('accounts', json.encode(accounts));
//
//     if (accounts.isEmpty) {
//       await prefs.clear();
//       Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
//     } else {
//       final next = accounts.first;
//       await loadUser({
//         "first_name": next["first_name"] ?? "",
//         "last_name": next["last_name"] ?? "",
//         "username": next["username"] ?? "",
//         "phone_number": next["phone"] ?? "",
//       });
//       Navigator.pop(context);
//     }
//   }
//
//   // ---------------- THEME ----------------
//   void toggleTheme() {
//     isDark = !isDark;
//     notifyListeners();
//   }
// }



import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:translator/translator.dart';

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

      return {
        "id": d["id"],
        "name": (d["name"] ?? "Unknown").toString(),
        "username": user.toString(),
        "last_message": textMsg,
        "unread_count": d["unread_count"] ?? 0,
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
      await http.post(url,
          headers: {"Content-Type": "application/json"},
          body: json.encode({"phone": phone}));
    } catch (e) {
      debugPrint("⚠️ Logout API error: $e");
    }

    accounts.removeAt(index);
    await prefs.setString('accounts', json.encode(accounts));

    if (accounts.isEmpty) {
      await prefs.clear();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } else {
      final next = accounts.first;
      await loadUser({
        "first_name": next["first_name"] ?? "",
        "last_name": next["last_name"] ?? "",
        "username": next["username"] ?? "",
        "phone_number": next["phone"] ?? "",
      });
      Navigator.pop(context);
    }
  }

  ///// chat fach Massage

  Future<void> fetchMessages(String phone, int chatId) async {
    try {
      final url = Uri.parse("$baseUrl/messages?phone=$phone&chat_id=$chatId");
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        messages = (data["messages"] ?? [])
            .map<Map<String, dynamic>>((m) => {
          "text": m["text"] ?? "",
          "is_out": m["is_out"] ?? false,
          "time": m["date"] ?? "",
        })
            .toList()
            .reversed
            .toList();
        notifyListeners();
      } else {
        print("❌ Server error: ${res.statusCode}");
      }
    } catch (e) {
      print("❌ Fetch messages error: $e");
    }
  }



  // ✅ THEME TOGGLE
  void toggleTheme() {
    isDark = !isDark;
    notifyListeners();
  }
}



// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:translator/translator.dart';
//
// class TelegraphProvider with ChangeNotifier {
//   String firstName = "";
//   String lastName = "";
//   String username = "";
//   String phoneNumber = "";
//   bool isDark = false;
//   String selectedLang = "en";
//   List<Map<String, dynamic>> dialogs = [];
//   List<Map<String, dynamic>> accounts = [];
//
//   final String baseUrl = "http://192.168.0.247:8080";
//   final GoogleTranslator _translator = GoogleTranslator();
//
//   bool _initialized = false;
//
//   // ✅ INITIALIZE
//   Future<void> initProvider() async {
//     if (_initialized) return;
//     _initialized = true;
//     await loadLang();
//     await _restoreUserIfExists();
//   }
//
//   // ✅ RESTORE SAVED ACCOUNT
//   Future<void> _restoreUserIfExists() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final saved = prefs.getString('accounts');
//       if (saved != null) {
//         accounts = List<Map<String, dynamic>>.from(json.decode(saved));
//         if (accounts.isNotEmpty) {
//           final acc = accounts.first;
//           firstName = acc["first_name"] ?? "";
//           username = acc["username"] ?? "";
//           phoneNumber = acc["phone"] ?? "";
//           fetchDialogs(phoneNumber, silent: true); // async no await
//         }
//       }
//     } catch (e) {
//       debugPrint("⚠️ Restore user error: $e");
//     }
//   }
//
//   // ✅ LANGUAGE
//   Future<void> loadLang() async {
//     final prefs = await SharedPreferences.getInstance();
//     selectedLang = prefs.getString('lang') ?? 'en';
//   }
//
//   Future<void> saveLang(String code) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('lang', code);
//     selectedLang = code;
//
//     // background translate (non-blocking)
//     compute(_backgroundTranslate, {"lang": selectedLang, "dialogs": dialogs})
//         .then((result) {
//       dialogs = List<Map<String, dynamic>>.from(result);
//       notifyListeners();
//     });
//   }
//
//   // ✅ LOAD USER
//   Future<void> loadUser(Map<String, String>? userData) async {
//     final prefs = await SharedPreferences.getInstance();
//     final saved = prefs.getString('accounts');
//     if (saved != null) {
//       accounts = List<Map<String, dynamic>>.from(json.decode(saved));
//     }
//
//     if (userData != null) {
//       final newAcc = {
//         "first_name": userData["first_name"] ?? "",
//         "last_name": userData["last_name"] ?? "",
//         "username": userData["username"] ?? "",
//         "phone": userData["phone_number"] ?? "",
//         "avatar": "assets/panda.jpg",
//       };
//       accounts.removeWhere((a) => a["phone"] == newAcc["phone"]);
//       accounts.insert(0, newAcc);
//       await prefs.setString('accounts', json.encode(accounts));
//       firstName = newAcc["first_name"]!;
//       username = newAcc["username"]!;
//       phoneNumber = newAcc["phone"]!;
//     } else if (accounts.isNotEmpty) {
//       final acc = accounts.first;
//       firstName = acc["first_name"];
//       username = acc["username"];
//       phoneNumber = acc["phone"];
//     }
//
//     notifyListeners();
//
//     if (phoneNumber.isNotEmpty) {
//       fetchDialogs(phoneNumber); // async
//     }
//   }
//
//   // ⚡ SUPER FAST FETCH DIALOGS
//   Future<void> fetchDialogs(String phone, {bool silent = false}) async {
//     try {
//       final url = Uri.parse("$baseUrl/dialogs?phone=$phone");
//       final res = await http.get(url);
//
//       if (res.statusCode == 200) {
//         final data = json.decode(res.body);
//
//         if (data["dialogs"] is List) {
//           // ✅ Background isolate parsing
//           final parsed = await compute(_parseDialogsIsolate, {
//             "data": data["dialogs"],
//             "phone": phone,
//             "baseUrl": baseUrl,
//           });
//
//           dialogs = List<Map<String, dynamic>>.from(parsed);
//           notifyListeners();
//
//           // ✅ Background translation (no lag)
//           compute(_backgroundTranslate, {"lang": selectedLang, "dialogs": dialogs})
//               .then((translated) {
//             dialogs = List<Map<String, dynamic>>.from(translated);
//             notifyListeners();
//           });
//         }
//       } else {
//         debugPrint("❌ Server error: ${res.statusCode}");
//       }
//     } catch (e) {
//       debugPrint("❌ Dialog fetch error: $e");
//     }
//
//     if (!silent) notifyListeners();
//   }
//
//   // ✅ ISOLATE PARSER (runs off main thread)
//   static Future<List<Map<String, dynamic>>> _parseDialogsIsolate(
//       Map<String, dynamic> args) async {
//     final List raw = args["data"];
//     final String phone = args["phone"];
//     final String baseUrl = args["baseUrl"];
//
//     return raw.map<Map<String, dynamic>>((d) {
//       final user = d["username"] ?? "";
//       final lastMsg = d["last_message"];
//
//       String textMsg = "";
//       if (lastMsg is Map) {
//         textMsg = lastMsg["text"]?.toString() ?? "";
//       } else if (lastMsg is String) {
//         textMsg = lastMsg;
//       }
//       if (textMsg.isEmpty && lastMsg is Map && lastMsg["media"] != null) {
//         textMsg = "📸 Media message";
//       }
//
//       return {
//         "id": d["id"],
//         "name": (d["name"] ?? "Unknown").toString(),
//         "username": user.toString(),
//         "last_message": textMsg,
//         "unread_count": d["unread_count"] ?? 0,
//         "avatar": "$baseUrl/avatar_redirect?phone=$phone&username=@$user",
//       };
//     }).toList();
//   }
//
//   // ✅ BACKGROUND TRANSLATE (async)
//   static Future<List<Map<String, dynamic>>> _backgroundTranslate(
//       Map<String, dynamic> args) async {
//     final lang = args["lang"] as String;
//     final dialogs = List<Map<String, dynamic>>.from(args["dialogs"]);
//     final translator = GoogleTranslator();
//
//     if (lang == 'en') return dialogs;
//
//     for (int i = 0; i < dialogs.length; i++) {
//       final d = dialogs[i];
//       try {
//         final name = d["name"] ?? "";
//         final msg = d["last_message"] ?? "";
//         dialogs[i]["name"] =
//         await translator.translate(name, to: lang).then((t) => t.text);
//         dialogs[i]["last_message"] =
//         await translator.translate(msg, to: lang).then((t) => t.text);
//       } catch (_) {}
//     }
//     return dialogs;
//   }
//
//   // ✅ LOGOUT
//   Future<void> logoutAccount(int index, BuildContext context) async {
//     final prefs = await SharedPreferences.getInstance();
//     final removed = accounts[index];
//     final phone = removed["phone"] ?? "";
//
//     try {
//       final url = Uri.parse("$baseUrl/logout");
//       await http.post(url,
//           headers: {"Content-Type": "application/json"},
//           body: json.encode({"phone": phone}));
//     } catch (e) {
//       debugPrint("⚠️ Logout API error: $e");
//     }
//
//     accounts.removeAt(index);
//     await prefs.setString('accounts', json.encode(accounts));
//
//     if (accounts.isEmpty) {
//       await prefs.clear();
//       Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
//     } else {
//       final next = accounts.first;
//       await loadUser({
//         "first_name": next["first_name"] ?? "",
//         "last_name": next["last_name"] ?? "",
//         "username": next["username"] ?? "",
//         "phone_number": next["phone"] ?? "",
//       });
//       Navigator.pop(context);
//     }
//   }
//
//   // ✅ THEME TOGGLE
//   void toggleTheme() {
//     isDark = !isDark;
//     notifyListeners();
//   }
// }
