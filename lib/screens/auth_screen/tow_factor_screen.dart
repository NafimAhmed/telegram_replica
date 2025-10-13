import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../home_screen.dart';
import '../../url.dart';

class TwoFactorScreen extends StatefulWidget {
  final String phone;
  const TwoFactorScreen({super.key, required this.phone});

  @override
  State<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends State<TwoFactorScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool isVerifying = false;
  String? errorMsg;

  // ✅ VERIFY PASSWORD API CALL
  Future<void> verifyPassword() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      setState(() => errorMsg = "Please enter your Telegram password");
      return;
    }

    setState(() {
      isVerifying = true;
      errorMsg = null;
    });

    try {
      final url = Uri.parse("$urlLocal/verify_password");
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"phone": widget.phone, "password": password}),
      );

      final data = json.decode(res.body);
      print("🔐 2FA Response: $data");

      if (data["status"] == "authorized_by_password" ||
          data["status"] == "already_authorized") {
        await _saveAccount(data); // ✅ Save user info to SharedPreferences

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ 2FA Verified Successfully")),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => TelegraphApp()),
              (route) => false,
        );
      } else {
        setState(() => errorMsg = data["detail"] ?? "Wrong password");
      }
    } catch (e) {
      setState(() => errorMsg = e.toString());
    } finally {
      setState(() => isVerifying = false);
    }
  }

  // ✅ CLEAN JSON-BASED ACCOUNT SAVE FUNCTION
  Future<void> _saveAccount(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final user = data["user"] ?? {};

    // 🧩 Extract user fields safely
    final newAccount = {
      "id": user["id"]?.toString() ?? "",
      "first_name": user["first_name"] ?? "",
      "last_name": user["last_name"] ?? "",
      "username": user["username"] ?? "",
      "phone": user["phone"] ?? "",
      "avatar": user["photo"] != null
          ? "$urlLocal/avatar_redirect?phone=${user["phone"]}&username=@${user["username"]}"
          : "",
      "was_online": user["status"]?["was_online"] ?? "",
      "is_premium": user["premium"] ?? false,
      "verified": user["verified"] ?? false,
      "lang_code": user["lang_code"] ?? "",
      "timestamp": DateTime.now().millisecondsSinceEpoch
    };

    // 🔹 Load previous accounts
    List<Map<String, dynamic>> accounts = [];
    final saved = prefs.getString('accounts');
    if (saved != null) {
      accounts = List<Map<String, dynamic>>.from(json.decode(saved));
    }

    // 🔹 Remove if already exists
    accounts.removeWhere((a) => a["phone"] == newAccount["phone"]);

    // 🔹 Insert new account at top
    accounts.insert(0, newAccount);

    // 🔹 Save to SharedPreferences
    await prefs.setString('accounts', json.encode(accounts));
    await prefs.setBool('isLoggedIn', true);

    print("✅ Account saved successfully: $newAccount");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Two-Step Verification"),
        backgroundColor: Colors.redAccent,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "🔒 Enter your Telegram Password",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Password",
                hintText: "Enter Telegram 2FA password",
                errorText: errorMsg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                onPressed: isVerifying ? null : verifyPassword,
                icon: isVerifying
                    ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.lock_open),
                label: Text(
                  isVerifying ? "Verifying..." : "Verify Password",
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import '../../home_screen.dart';
// import '../../url.dart';
//
// class TwoFactorScreen extends StatefulWidget {
//   final String phone;
//   const TwoFactorScreen({super.key, required this.phone});
//
//   @override
//   State<TwoFactorScreen> createState() => _TwoFactorScreenState();
// }
//
// class _TwoFactorScreenState extends State<TwoFactorScreen> {
//   final TextEditingController _passwordController = TextEditingController();
//   bool isVerifying = false;
//   String? errorMsg;
//
//   // ✅ VERIFY PASSWORD API CALL
//   Future<void> verifyPassword() async {
//     final password = _passwordController.text.trim();
//     if (password.isEmpty) {
//       setState(() => errorMsg = "Please enter your Telegram password");
//       return;
//     }
//
//     setState(() {
//       isVerifying = true;
//       errorMsg = null;
//     });
//
//     try {
//       final url = Uri.parse("$urlLocal/verify_password");
//       final res = await http.post(
//         url,
//         headers: {"Content-Type": "application/json"},
//         body: json.encode({"phone": widget.phone, "password": password}),
//       );
//
//       final data = json.decode(res.body);
//       print("🔐 2FA Response: $data");
//
//       if (data["status"] == "authorized_by_password" ||
//           data["status"] == "already_authorized") {
//         await _saveAccount(data); // ✅ Save user info to SharedPreferences
//
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("✅ 2FA Verified Successfully")),
//         );
//
//         Navigator.pushAndRemoveUntil(
//           context,
//           MaterialPageRoute(builder: (_) => TelegraphApp()),
//               (route) => false,
//         );
//       } else {
//         setState(() => errorMsg = data["detail"] ?? "Wrong password");
//       }
//     } catch (e) {
//       setState(() => errorMsg = e.toString());
//     } finally {
//       setState(() => isVerifying = false);
//     }
//   }
//
//   // ✅ CLEAN JSON-BASED ACCOUNT SAVE FUNCTION
//   Future<void> _saveAccount(Map<String, dynamic> data) async {
//     final prefs = await SharedPreferences.getInstance();
//     final user = data["user"] ?? {};
//
//     // 🧩 Extract user fields safely
//     final newAccount = {
//       "id": user["id"]?.toString() ?? "",
//       "first_name": user["first_name"] ?? "",
//       "last_name": user["last_name"] ?? "",
//       "username": user["username"] ?? "",
//       "phone": user["phone"] ?? "",
//       "avatar": user["photo"] != null
//           ? "$urlLocal/avatar_redirect?phone=${user["phone"]}&username=@${user["username"]}"
//           : "",
//       "was_online": user["status"]?["was_online"] ?? "",
//       "is_premium": user["premium"] ?? false,
//       "verified": user["verified"] ?? false,
//       "lang_code": user["lang_code"] ?? "",
//       "timestamp": DateTime.now().millisecondsSinceEpoch
//     };
//
//     // 🔹 Load previous accounts
//     List<Map<String, dynamic>> accounts = [];
//     final saved = prefs.getString('accounts');
//     if (saved != null) {
//       accounts = List<Map<String, dynamic>>.from(json.decode(saved));
//     }
//
//     // 🔹 Remove if already exists
//     accounts.removeWhere((a) => a["phone"] == newAccount["phone"]);
//
//     // 🔹 Insert new account at top
//     accounts.insert(0, newAccount);
//
//     // 🔹 Save to SharedPreferences
//     await prefs.setString('accounts', json.encode(accounts));
//     await prefs.setBool('isLoggedIn', true);
//
//     print("✅ Account saved successfully: $newAccount");
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Two-Step Verification"),
//         backgroundColor: Colors.redAccent,
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               "🔒 Enter your Telegram Password",
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 20),
//             TextField(
//               controller: _passwordController,
//               obscureText: true,
//               decoration: InputDecoration(
//                 labelText: "Password",
//                 hintText: "Enter Telegram 2FA password",
//                 errorText: errorMsg,
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 30),
//             Center(
//               child: ElevatedButton.icon(
//                 onPressed: isVerifying ? null : verifyPassword,
//                 icon: isVerifying
//                     ? const SizedBox(
//                   height: 18,
//                   width: 18,
//                   child: CircularProgressIndicator(strokeWidth: 2),
//                 )
//                     : const Icon(Icons.lock_open),
//                 label: Text(
//                   isVerifying ? "Verifying..." : "Verify Password",
//                   style: const TextStyle(fontSize: 16),
//                 ),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.redAccent,
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 30,
//                     vertical: 12,
//                   ),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
