import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../home_screen.dart';
import '../../otp screen.dart';
import '../../providers/telegraph_qg_provider.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  Country? selectedCountry;
  final TextEditingController phoneController = TextEditingController();
  bool isLoading = false;

  Future<void> sendLoginRequest() async {
    final provider = Provider.of<TelegraphProvider>(context, listen: false);

    if (selectedCountry == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Select your country")));
      return;
    }

    final phone = "+${selectedCountry!.phoneCode}${phoneController.text.trim()}";
    if (phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Enter phone number")));
      return;
    }

    setState(() => isLoading = true);

    try {
      final url = Uri.parse("${provider.baseUrl}/login");
      final req = http.MultipartRequest('POST', url);
      req.fields['phone'] = phone;

      final res = await req.send();
      final body = await res.stream.bytesToString();
      final data = json.decode(body);
      print("📩 Login Response → $data");

      if (data["status"] == "already_authorized") {
        // ✅ already logged in user
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('phone', phone);

        // 🔹 Provider update
        await provider.loadUser({
          "first_name": "",
          "last_name": "",
          "username": "",
          "phone_number": phone,
        });

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const TelegraphApp()),
              (route) => false,
        );
        return;
      }

      if (data["status"] == "code_sent" &&
          data["phone_code_hash"] != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OTPScreen(
              phone: phone,
              phoneCodeHash: data["phone_code_hash"],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["error"] ?? "Invalid number")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text("Your phone number",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              const Text("Please confirm your country code and enter number.",
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: () {
                  showCountryPicker(
                    context: context,
                    showPhoneCode: true,
                    onSelect: (Country c) => setState(() {
                      selectedCountry = c;
                    }),
                  );
                },
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Text(
                        selectedCountry == null
                            ? "Choose Country"
                            : "${selectedCountry!.flagEmoji} ${selectedCountry!.name}",
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "Phone number",
                  prefixText: selectedCountry != null
                      ? "+${selectedCountry!.phoneCode} "
                      : "",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: FloatingActionButton(
                  backgroundColor: Colors.red,
                  onPressed: isLoading ? null : sendLoginRequest,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Icon(Icons.arrow_forward),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
