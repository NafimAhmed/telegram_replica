// //
// //
// // import 'dart:convert';
// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:shared_preferences/shared_preferences.dart';
// // import 'package:translator/translator.dart';
// //
// // class TelegraphProvider with ChangeNotifier {
// //   String firstName = "";
// //   String lastName = "";
// //   String username = "";
// //   String phoneNumber = "";
// //   bool isDark = false;
// //   String selectedLang = "en";
// //   List<Map<String, dynamic>> dialogs = [];
// //   List<Map<String, dynamic>> accounts = [];
// //
// //   final String baseUrl = "http://192.168.0.247:8080";
// //   final GoogleTranslator _translator = GoogleTranslator();
// //
// //   bool _initialized = false; // ✅ Prevents duplicate init
// //
// //   Future<void> initProvider() async {
// //     if (_initialized) return;
// //     _initialized = true;
// //
// //     await loadLang();
// //     await _restoreUserIfExists();
// //   }
// //
// //   // 🔹 Restore old data if any
// //   Future<void> _restoreUserIfExists() async {
// //     try {
// //       final prefs = await SharedPreferences.getInstance();
// //       final saved = prefs.getString('accounts');
// //       if (saved != null) {
// //         accounts = List<Map<String, dynamic>>.from(json.decode(saved));
// //         if (accounts.isNotEmpty) {
// //           final acc = accounts.first;
// //           firstName = acc["first_name"] ?? "";
// //           username = acc["username"] ?? "";
// //           phoneNumber = acc["phone"] ?? "";
// //           await fetchDialogs(phoneNumber);
// //         }
// //       }
// //     } catch (e) {
// //       print("⚠️ Restore user error: $e");
// //     }
// //   }
// //
// //   // ---------------- LANGUAGE ----------------
// //   Future<void> loadLang() async {
// //     final prefs = await SharedPreferences.getInstance();
// //     selectedLang = prefs.getString('lang') ?? 'en';
// //   }
// //
// //   Future<void> saveLang(String code) async {
// //     final prefs = await SharedPreferences.getInstance();
// //     await prefs.setString('lang', code);
// //     selectedLang = code;
// //
// //     if (dialogs.isNotEmpty) {
// //       await _translateDialogs();
// //     } else if (phoneNumber.isNotEmpty) {
// //       await fetchDialogs(phoneNumber);
// //     }
// //     notifyListeners();
// //   }
// //
// //   Future<String> autoT(String text) async {
// //     if (selectedLang == 'en' || text.isEmpty) return text;
// //     try {
// //       final t = await _translator.translate(text, to: selectedLang);
// //       return t.text;
// //     } catch (_) {
// //       return text;
// //     }
// //   }
// //
// //   Future<void> _translateDialogs() async {
// //     if (selectedLang == 'en') return;
// //     dialogs = await Future.wait(dialogs.map((d) async {
// //       return {
// //         "name": await autoT(d["name"] ?? ""),
// //         "username": d["username"],
// //         "last_message": await autoT(d["last_message"] ?? ""),
// //         "unread_count": d["unread_count"],
// //         "avatar": d["avatar"],
// //       };
// //     }));
// //   }
// //
// //   // ---------------- LOAD USER ----------------
// //   Future<void> loadUser(Map<String, String>? userData) async {
// //     final prefs = await SharedPreferences.getInstance();
// //     final saved = prefs.getString('accounts');
// //     if (saved != null) accounts = List<Map<String, dynamic>>.from(json.decode(saved));
// //
// //     if (userData != null) {
// //       final newAcc = {
// //         "first_name": userData["first_name"] ?? "",
// //         "last_name": userData["last_name"] ?? "",
// //         "username": userData["username"] ?? "",
// //         "phone": userData["phone_number"] ?? "",
// //         "avatar": "assets/panda.jpg",
// //       };
// //       accounts.removeWhere((a) => a["phone"] == newAcc["phone"]);
// //       accounts.insert(0, newAcc);
// //       await prefs.setString('accounts', json.encode(accounts));
// //       firstName = newAcc["first_name"]!;
// //       username = newAcc["username"]!;
// //       phoneNumber = newAcc["phone"]!;
// //     } else if (accounts.isNotEmpty) {
// //       final acc = accounts.first;
// //       firstName = acc["first_name"];
// //       username = acc["username"];
// //       phoneNumber = acc["phone"];
// //     }
// //
// //     if (phoneNumber.isNotEmpty) {
// //       await fetchDialogs(phoneNumber);
// //     }
// //     notifyListeners();
// //   }
// //
// //   // ---------------- FETCH DIALOGS ----------------
// //   Future<void> fetchDialogs(String phone) async {
// //     try {
// //       final url = Uri.parse("$baseUrl/dialogs?phone=$phone");
// //       final res = await http.get(url);
// //
// //       if (res.statusCode == 200) {
// //         final data = json.decode(res.body);
// //
// //         if (data["dialogs"] is List) {
// //           dialogs = (data["dialogs"] as List).map<Map<String, dynamic>>((d) {
// //             final user = d["username"] ?? "";
// //             dynamic lastMsg = d["last_message"];
// //
// //             // ✅ শুধু text নাও (যদি map হয়)
// //             String textMsg = "";
// //             if (lastMsg is Map) {
// //               textMsg = lastMsg["text"]?.toString() ?? "";
// //             } else if (lastMsg is String) {
// //               textMsg = lastMsg;
// //             }
// //
// //             // 📸 যদি text ফাঁকা কিন্তু media থাকে
// //             if (textMsg.isEmpty && lastMsg is Map && lastMsg["media"] != null) {
// //               textMsg = "📸 Media message";
// //             }
// //
// //             return {
// //               "name": (d["name"] ?? "Unknown").toString(),
// //               "username": user.toString(),
// //               "last_message": textMsg, // ✅ এখন শুধুই text ফিল্ড থাকবে
// //               "unread_count": d["unread_count"] ?? 0,
// //               "avatar":
// //               "$baseUrl/avatar_redirect?phone=$phone&username=@$user",
// //             };
// //           }).toList();
// //
// //           await _translateDialogs();
// //         }
// //       } else {
// //         print("❌ Server error: ${res.statusCode}");
// //       }
// //     } catch (e) {
// //       print("❌ Dialog fetch error: $e");
// //     }
// //
// //     notifyListeners();
// //   }
// //   // Future<void> fetchDialogs(String phone) async {
// //   //   try {
// //   //     final url = Uri.parse("$baseUrl/dialogs?phone=$phone");
// //   //     final res = await http.get(url);
// //   //     if (res.statusCode == 200) {
// //   //       final data = json.decode(res.body);
// //   //       if (data["dialogs"] is List) {
// //   //         dialogs = (data["dialogs"] as List).map<Map<String, dynamic>>((d) {
// //   //           final user = d["username"] ?? "";
// //   //           return {
// //   //             "name": (d["name"] ?? "Unknown").toString(),
// //   //             "username": user.toString(),
// //   //             "last_message": (d["last_message"] ?? "").toString(),
// //   //             "unread_count": d["unread_count"] ?? 0,
// //   //             "avatar": "$baseUrl/avatar_redirect?phone=$phone&username=@$user",
// //   //           };
// //   //         }).toList();
// //   //         await _translateDialogs();
// //   //       }
// //   //     } else {
// //   //       print("❌ Server error: ${res.statusCode}");
// //   //     }
// //   //   } catch (e) {
// //   //     print("❌ Dialog fetch error: $e");
// //   //   }
// //   //   notifyListeners();
// //   // }
// //
// //   // ---------------- LOGOUT ----------------
// //   Future<void> logoutAccount(int index, BuildContext context) async {
// //     final prefs = await SharedPreferences.getInstance();
// //     final removed = accounts[index];
// //     final phone = removed["phone"] ?? "";
// //
// //     try {
// //       final url = Uri.parse("$baseUrl/logout");
// //       await http.post(url,
// //           headers: {"Content-Type": "application/json"},
// //           body: json.encode({"phone": phone}));
// //     } catch (e) {
// //       print("⚠️ Logout API error: $e");
// //     }
// //
// //     accounts.removeAt(index);
// //     await prefs.setString('accounts', json.encode(accounts));
// //
// //     if (accounts.isEmpty) {
// //       await prefs.clear();
// //       Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
// //     } else {
// //       final next = accounts.first;
// //       await loadUser({
// //         "first_name": next["first_name"] ?? "",
// //         "last_name": next["last_name"] ?? "",
// //         "username": next["username"] ?? "",
// //         "phone_number": next["phone"] ?? "",
// //       });
// //       Navigator.pop(context);
// //     }
// //   }
// //
// //   void toggleTheme() {
// //     isDark = !isDark;
// //     notifyListeners();
// //   }
// // }
//
// import 'dart:convert';
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
//
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
//           await fetchDialogs(phoneNumber, silent: true);
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
//     if (dialogs.isNotEmpty) {
//       // ভাষা বদলালে ধীরে ধীরে translate করবো
//       _translateDialogsGradually();
//     } else if (phoneNumber.isNotEmpty) {
//       await fetchDialogs(phoneNumber, silent: true);
//     }
//
//     notifyListeners(); // শুধু একবার rebuild
//   }
//
//   Future<String> autoT(String text) async {
//     if (selectedLang == 'en' || text.isEmpty) return text;
//     try {
//       final t = await _translator.translate(text, to: selectedLang);
//       return t.text;
//     } catch (_) {
//       return text;
//     }
//   }
//
//   // ---------------- OPTIMIZED TRANSLATE ----------------
//   Future<void> _translateDialogsGradually() async {
//     if (selectedLang == 'en') return;
//
//     for (int i = 0; i < dialogs.length; i++) {
//       final d = dialogs[i];
//       dialogs[i]["name"] = await autoT(d["name"] ?? "");
//       dialogs[i]["last_message"] = await autoT(d["last_message"] ?? "");
//       if (i % 3 == 0) notifyListeners(); // প্রতি 3 item পর UI update করবে
//     }
//
//     notifyListeners();
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
//
//       accounts.removeWhere((a) => a["phone"] == newAcc["phone"]);
//       accounts.insert(0, newAcc);
//       await prefs.setString('accounts', json.encode(accounts));
//
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
//     if (phoneNumber.isNotEmpty) {
//       await fetchDialogs(phoneNumber);
//     }
//
//     notifyListeners();
//   }
//
//   // ---------------- FETCH DIALOGS ----------------
//   Future<void> fetchDialogs(String phone, {bool silent = false}) async {
//     try {
//       final url = Uri.parse("$baseUrl/dialogs?phone=$phone");
//       final res = await http.get(url);
//
//       if (res.statusCode == 200) {
//         final data = json.decode(res.body);
//
//         if (data["dialogs"] is List) {
//           // 🔹 Step 1: সব dialogs রাখবো tempList এ
//           final tempList = (data["dialogs"] as List).map<Map<String, dynamic>>((d) {
//             final user = d["username"] ?? "";
//             dynamic lastMsg = d["last_message"];
//
//             String textMsg = "";
//             if (lastMsg is Map) {
//               textMsg = lastMsg["text"]?.toString() ?? "";
//             } else if (lastMsg is String) {
//               textMsg = lastMsg;
//             }
//             if (textMsg.isEmpty && lastMsg is Map && lastMsg["media"] != null) {
//               textMsg = "📸 Media message";
//             }
//
//             return {
//               "name": (d["name"] ?? "Unknown").toString(),
//               "username": user.toString(),
//               "last_message": textMsg,
//               "unread_count": d["unread_count"] ?? 0,
//               "avatar": "$baseUrl/avatar_redirect?phone=$phone&username=@$user",
//             };
//           }).toList();
//
//           dialogs = []; // 🔹 Step 2: শুরুতে খালি করো
//           notifyListeners();
//
//           // 🔹 Step 3: ধীরে ধীরে ৩টা করে যোগ করবো
//           int batchSize = 3;
//           for (int i = 0; i < tempList.length; i += batchSize) {
//             await Future.delayed(const Duration(milliseconds: 600)); // smooth delay
//             final end = (i + batchSize > tempList.length)
//                 ? tempList.length
//                 : i + batchSize;
//             dialogs.addAll(tempList.sublist(i, end));
//
//             notifyListeners(); // 🔥 প্রতি ব্যাচে UI আপডেট
//           }
//
//           // 🔹 Step 4: ভাষা translate parallel এ শুরু করো
//           _translateDialogsGradually();
//         }
//       } else {
//         print("❌ Server error: ${res.statusCode}");
//       }
//     } catch (e) {
//       print("❌ Dialog fetch error: $e");
//     }
//
//     if (!silent) notifyListeners();
//   }
//   // Future<void> fetchDialogs(String phone, {bool silent = false}) async {
//   //   try {
//   //     final url = Uri.parse("$baseUrl/dialogs?phone=$phone");
//   //     final res = await http.get(url);
//   //
//   //     if (res.statusCode == 200) {
//   //       final data = json.decode(res.body);
//   //       if (data["dialogs"] is List) {
//   //         dialogs = (data["dialogs"] as List).map<Map<String, dynamic>>((d) {
//   //           final user = d["username"] ?? "";
//   //           dynamic lastMsg = d["last_message"];
//   //
//   //           String textMsg = "";
//   //           if (lastMsg is Map) {
//   //             textMsg = lastMsg["text"]?.toString() ?? "";
//   //           } else if (lastMsg is String) {
//   //             textMsg = lastMsg;
//   //           }
//   //
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
//   //           };
//   //         }).toList();
//   //
//   //         // 🌐 Background translate শুরু করো (UI block হবে না)
//   //         _translateDialogsGradually();
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

  final String baseUrl = "http://192.168.0.247:8080";
  final GoogleTranslator _translator = GoogleTranslator();

  bool _initialized = false;

  Future<void> initProvider() async {
    if (_initialized) return;
    _initialized = true;
    await loadLang();
    await _restoreUserIfExists();
  }

  // ---------------- RESTORE ----------------
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
          fetchDialogs(phoneNumber, silent: true); // 🔥 async call (no await)
        }
      }
    } catch (e) {
      print("⚠️ Restore user error: $e");
    }
  }

  // ---------------- LANGUAGE ----------------
  Future<void> loadLang() async {
    final prefs = await SharedPreferences.getInstance();
    selectedLang = prefs.getString('lang') ?? 'en';
  }

  Future<void> saveLang(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', code);
    selectedLang = code;

    // Translate asynchronously (no lag)
    compute(_backgroundTranslate, {"lang": selectedLang, "dialogs": dialogs})
        .then((result) {
      dialogs = List<Map<String, dynamic>>.from(result);
      notifyListeners();
    });
  }

  // ---------------- LOAD USER ----------------
  Future<void> loadUser(Map<String, String>? userData) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('accounts');
    if (saved != null) accounts = List<Map<String, dynamic>>.from(json.decode(saved));

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

    // ✅ সঙ্গে সঙ্গে name update
    notifyListeners();

    if (phoneNumber.isNotEmpty) {
      fetchDialogs(phoneNumber); // async run (UI freeze করবে না)
    }
  }

  // ---------------- FETCH DIALOGS ----------------
  Future<void> fetchDialogs(String phone, {bool silent = false}) async {
    try {
      final url = Uri.parse("$baseUrl/dialogs?phone=$phone");
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = json.decode(res.body);

        if (data["dialogs"] is List) {
          final allDialogs = (data["dialogs"] as List).map<Map<String, dynamic>>((d) {
            final user = d["username"] ?? "";
            dynamic lastMsg = d["last_message"];

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
              "name": (d["name"] ?? "Unknown").toString(),
              "username": user.toString(),
              "last_message": textMsg,
              "unread_count": d["unread_count"] ?? 0,
              "avatar": "$baseUrl/avatar_redirect?phone=$phone&username=@$user",
              "id": d["id"],
            };
          }).toList();

          dialogs = [];
          notifyListeners();

          // 🔹 ultra-fast batch insert (2-item batches, 90 ms delay)
          const batchSize = 2;
          for (int i = 0; i < allDialogs.length; i += batchSize) {
            final end = (i + batchSize > allDialogs.length)
                ? allDialogs.length
                : i + batchSize;
            dialogs.addAll(allDialogs.sublist(i, end));

            // ⚡ super-short delay keeps animation smooth but instant
            await Future.delayed(const Duration(milliseconds: 90));
            notifyListeners();
          }

          // 🔹 background translate (no lag on UI)
          compute(_backgroundTranslate, {"lang": selectedLang, "dialogs": dialogs})
              .then((result) {
            dialogs = List<Map<String, dynamic>>.from(result);
            notifyListeners();
          });
        }
      } else {
        print("❌ Server error: ${res.statusCode}");
      }
    } catch (e) {
      print("❌ Dialog fetch error: $e");
    }

    if (!silent) notifyListeners();
  }


  // ---------------- BACKGROUND TRANSLATE (runs off main thread) ----------------
  static Future<List<Map<String, dynamic>>> _backgroundTranslate(
      Map<String, dynamic> args) async {
    final lang = args["lang"] as String;
    final dialogs = List<Map<String, dynamic>>.from(args["dialogs"]);
    final translator = GoogleTranslator();

    if (lang == 'en') return dialogs;

    for (int i = 0; i < dialogs.length; i++) {
      final d = dialogs[i];
      try {
        final name = d["name"] ?? "";
        final msg = d["last_message"] ?? "";
        dialogs[i]["name"] = await translator.translate(name, to: lang).then((t) => t.text);
        dialogs[i]["last_message"] =
        await translator.translate(msg, to: lang).then((t) => t.text);
      } catch (_) {}
    }
    return dialogs;
  }

  // ---------------- LOGOUT ----------------
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
      print("⚠️ Logout API error: $e");
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

  // ---------------- THEME ----------------
  void toggleTheme() {
    isDark = !isDark;
    notifyListeners();
  }
}
