import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../home_screen.dart';
import '../../otp screen.dart';
import '../../providers/telegraph_qg_provider.dart';

class QrLoginScreen extends StatefulWidget {
  const QrLoginScreen({Key? key}) : super(key: key);

  @override
  State<QrLoginScreen> createState() => _QrLoginScreenState();
}

class _QrLoginScreenState extends State<QrLoginScreen> {
  String? qrUrl;
  String? authId;
  bool isAuthorized = false;
  bool isLoading = false;
  Timer? _timer;

  // তোমার Flask সার্ভার IP
  final String baseUrl = "http://192.168.0.247:8080";

  @override
  void initState() {
    super.initState();
    startQrLogin();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // =====================================================
  // 🔹 Step 1: Generate QR login
  // =====================================================
  Future<void> startQrLogin() async {
    setState(() => isLoading = true);

    try {
      final res = await http.post(Uri.parse("$baseUrl/login_qr_link"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          qrUrl = data["qr_url"];
          authId = data["auth_id"];
          isLoading = false;
        });

        // 🔁 Poll status every 3s
        _timer = Timer.periodic(const Duration(seconds: 3), (_) {
          checkQrStatus();
        });
      } else {
        print("❌ QR error: ${res.body}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("❌ Exception: $e");
      setState(() => isLoading = false);
    }
  }

  // =====================================================
  // 🔹 Step 2: Check QR Authorization Status
  // =====================================================
  Future<void> checkQrStatus() async {
    if (authId == null || isAuthorized) return;

    try {
      final res = await http.get(
        Uri.parse("$baseUrl/login_qr_status?auth_id=$authId"),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final status = data["status"];
        print("🌀 QR Status: $status");

        if (status == "authorized") {
          _timer?.cancel();
          setState(() => isAuthorized = true);

          // 🔹 Directly save user & redirect
          await verifyQrAuth(authId!);
        } else if (status == "expired") {
          _timer?.cancel();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("QR expired. Try again.")),
          );
        }
      }
    } catch (e) {
      print("⚠️ checkQrStatus error: $e");
    }
  }

  // =====================================================
  // 🔹 Step 3: Verify QR Auth & Save User
  // =====================================================


  // Future<void> verifyQrAuth(String authId) async {
  //   if (authId.isEmpty) return;
  //   setState(() => isLoading = true);
  //
  //   try {
  //     final url = Uri.parse("$baseUrl/login_qr_status?auth_id=$authId");
  //     final res = await http.get(url);
  //     final body = res.body;
  //     print("📩 QR Verify Response: $body");
  //
  //     if (res.statusCode != 200) return;
  //
  //     final data = jsonDecode(body);
  //     final status = data["status"];
  //
  //     if (status == "authorized") {
  //       final prefs = await SharedPreferences.getInstance();
  //       final Map<String, dynamic> user = Map<String, dynamic>.from(data["user"] ?? {});
  //
  //       final userPhone = user["phone"] != null ? "+${user["phone"]}" : "";
  //       final userPhoto = (user["photo"] is Map && user["photo"]["photo_id"] != null)
  //           ? user["photo"]["photo_id"].toString()
  //           : "";
  //
  //       // ✅ Prepare account object
  //       final newAccount = {
  //         "id": user["id"]?.toString() ?? '',
  //         "first_name": user["first_name"] ?? '',
  //         "last_name": user["last_name"] ?? '',
  //         "username": user["username"] ?? '',
  //         "phone": userPhone,
  //         "avatar": userPhoto,
  //         "timestamp": DateTime.now().millisecondsSinceEpoch,
  //       };
  //
  //       // ✅ Load & update saved accounts
  //       List<Map<String, dynamic>> accounts = [];
  //       final saved = prefs.getString('accounts');
  //       if (saved != null) {
  //         accounts = List<Map<String, dynamic>>.from(json.decode(saved));
  //       }
  //
  //       accounts.removeWhere((a) => a['phone'] == newAccount['phone']);
  //       accounts.insert(0, newAccount);
  //
  //       // ✅ Save locally
  //       await prefs.setString('accounts', json.encode(accounts));
  //       await prefs.setBool('isLoggedIn', true);
  //
  //       print("✅ Account saved via QR: $newAccount");
  //
  //       // 🔹 Redirect to Home immediately
  //       if (!mounted) return;
  //       Navigator.pushAndRemoveUntil(
  //         context,
  //         MaterialPageRoute(builder: (_) => const TelegraphApp()),
  //             (route) => false,
  //       );
  //     }
  //   } catch (e) {
  //     print("❌ verifyQrAuth error: $e");
  //   } finally {
  //     setState(() => isLoading = false);
  //   }
  // }











  Future<void> verifyQrAuth(String authId) async {
    if (authId.isEmpty) return;
    setState(() => isLoading = true);

    try {
      final url = Uri.parse("$baseUrl/login_qr_status?auth_id=$authId");
      final res = await http.get(url);
      final body = res.body;
      print("📩 QR Verify Response: $body");

      if (res.statusCode != 200) return;

      final data = jsonDecode(body);
      final status = data["status"];

      if (status == "authorized") {
        final user = Map<String, dynamic>.from(data["user"] ?? {});
        final userPhone = user["phone"] != null ? "+${user["phone"]}" : "";

        if (userPhone.isEmpty) {
          print("⚠️ No phone found in QR response!");
          return;
        }

        print("📱 Phone from QR: $userPhone");

        // 🔹 Step 2: Call /login API to send OTP
        final loginUrl = Uri.parse("$baseUrl/login");
        final req = http.MultipartRequest('POST', loginUrl);
        req.fields['phone'] = userPhone;

        final loginRes = await req.send();
        final loginBody = await loginRes.stream.bytesToString();
        final loginData = json.decode(loginBody);

        print("📩 Login API Response → $loginData");

        // 🔹 Step 3: Navigate to OTP Screen
        if (loginData["status"] == "code_sent" &&
            loginData["phone_code_hash"] != null) {
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => OTPScreen(
                phone: userPhone,
                phoneCodeHash: loginData["phone_code_hash"],
              ),
            ),
                (route) => false,
          );
        } else if (loginData["status"] == "already_authorized") {
          print("✅ Already authorized via QR");
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const TelegraphApp()),
                (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("⚠️ ${loginData["detail"] ?? "OTP send failed"}")),
          );
        }
      }
    } catch (e) {
      print("❌ verifyQrAuth error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }













  // =====================================================
  // 🔹 Step 4: UI
  // =====================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login with Telegram QR"),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : qrUrl == null
            ? ElevatedButton(
          onPressed: startQrLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            padding: const EdgeInsets.symmetric(
                horizontal: 32, vertical: 12),
          ),
          child: const Text("Generate QR Code"),
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            QrImageView(
              data: qrUrl!,
              size: 240,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 20),
            const Text(
              "Scan this QR with Telegram App",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: startQrLogin,
              icon: const Icon(Icons.refresh),
              label: const Text("Refresh QR"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
