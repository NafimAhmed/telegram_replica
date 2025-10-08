import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'url.dart';
import 'home_screen.dart';

class OTPScreen extends StatefulWidget {
  final String phone;
  final String phoneCodeHash;
  const OTPScreen({super.key, required this.phone, required this.phoneCodeHash});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final List<TextEditingController> otpControllers =
  List.generate(5, (_) => TextEditingController());
  bool isVerifying = false;

  Future<void> verifyOtp() async {
    final otp = otpControllers.map((c) => c.text).join();
    if (otp.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter full 5-digit code")),
      );
      return;
    }

    setState(() => isVerifying = true);

    try {
      final url = Uri.parse("$urlLocal/verify");
      final req = http.MultipartRequest('POST', url);
      req.fields['phone'] = widget.phone;
      req.fields['code'] = otp;
      req.fields['phone_code_hash'] = widget.phoneCodeHash;

      final res = await req.send();
      final body = await res.stream.bytesToString();
      print("📩 Response: $body");
      final data = json.decode(body);

      if (data["status"] == "authorized") {
        final prefs = await SharedPreferences.getInstance();

        final userString = data["user"]?.toString() ?? "";
        final id = _extractField(userString, r"id=(\d+)");
        final firstName = _extractField(userString, r"first_name='([^']*)'");
        final lastName = _extractField(userString, r"last_name='([^']*)'");
        final username = _extractField(userString, r"username='([^']*)'");
        final phone = _extractField(userString, r"phone='([^']*)'");

        final newAccount = {
          "id": id ?? '',
          "first_name": firstName ?? '',
          "last_name": lastName ?? '',
          "username": username ?? '',
          "phone": phone ?? '',
          "avatar": "assets/panda.jpg",
          "timestamp": DateTime.now().millisecondsSinceEpoch
        };

        List<Map<String, dynamic>> accounts = [];
        final saved = prefs.getString('accounts');
        if (saved != null) {
          accounts = List<Map<String, dynamic>>.from(json.decode(saved));
        }

        accounts.removeWhere((a) => a['phone'] == phone);
        accounts.insert(0, newAccount);

        await prefs.setString('accounts', json.encode(accounts));
        await prefs.setBool('isLoggedIn', true);

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) =>  TelegraphApp()),
              (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Invalid Code")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => isVerifying = false);
    }
  }

  String? _extractField(String input, String pattern) {
    final regex = RegExp(pattern);
    final match = regex.firstMatch(input);
    return match?.group(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.lock_outline, size: 80, color: Colors.red),
              const SizedBox(height: 20),
              Text("Code sent to ${widget.phone}",
                  style: const TextStyle(fontSize: 18, color: Colors.grey)),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  5,
                      (index) => SizedBox(
                    width: 50,
                    child: TextField(
                      controller: otpControllers[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      decoration: const InputDecoration(counterText: ''),
                      onChanged: (_) {
                        if (index < 4 &&
                            otpControllers[index].text.isNotEmpty) {
                          FocusScope.of(context).nextFocus();
                        }
                      },
                    ),
                  ),
                ),
              ),
              const Spacer(),
              FloatingActionButton(
                backgroundColor: Colors.red,
                onPressed: isVerifying ? null : verifyOtp,
                child: isVerifying
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Icon(Icons.arrow_forward),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
