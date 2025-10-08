// import 'package:ag_taligram/url.dart';
// import 'package:flutter/material.dart';
// import 'package:country_picker/country_picker.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';
// import 'home_screen.dart';
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   final prefs = await SharedPreferences.getInstance();
//   final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
//
//   runApp(TelegramApp(startScreen: isLoggedIn ?  TelegraphApp() : const PhoneLoginScreen()));
// }
//
// class TelegramApp extends StatelessWidget {
//   final Widget startScreen;
//   const TelegramApp({super.key, required this.startScreen});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: "Telegram Login",
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         primaryColor: Colors.white,
//         scaffoldBackgroundColor: Colors.white,
//       ),
//       home: startScreen,
//     );
//   }
// }
//
// /// -------------------- PHONE LOGIN SCREEN --------------------
// class PhoneLoginScreen extends StatefulWidget {
//   const PhoneLoginScreen({super.key});
//
//   @override
//   State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
// }
//
// class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
//   Country? selectedCountry;
//   final TextEditingController phoneController = TextEditingController();
//   bool isLoading = false;
//
//   Future<void> sendLoginRequest() async {
//     if (selectedCountry == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please select a country")),
//       );
//       return;
//     }
//
//     final phone = "+${selectedCountry!.phoneCode}${phoneController.text.trim()}";
//     if (phoneController.text.trim().isEmpty) {
//       ScaffoldMessenger.of(context)
//           .showSnackBar(const SnackBar(content: Text("Enter phone number")));
//       return;
//     }
//
//     setState(() => isLoading = true);
//
//     try {
//       final url = Uri.parse("$urlLocal/login");
//       final req = http.MultipartRequest('POST', url);
//       req.fields['phone'] = phone;
//
//       final res = await req.send();
//       final body = await res.stream.bytesToString();
//       final data = json.decode(body);
//       print(data);
//
//       if (data["status"] == "already_authorized") {
//         final prefs = await SharedPreferences.getInstance();
//         await prefs.setBool('isLoggedIn', true);
//         await prefs.setString('phone', phone);
//
//         Navigator.pushAndRemoveUntil(
//           context,
//           MaterialPageRoute(builder: (_) =>  TelegraphApp()),
//               (route) => false,
//         );
//         return;
//       }
//
//       if ((res.statusCode == 200 || res.statusCode == 201) &&
//           data["status"] == "code_sent" &&
//           data["phone_code_hash"] != null) {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => OTPScreen(
//               phone: phone,
//               phoneCodeHash: data["phone_code_hash"],
//             ),
//           ),
//         );
//       } else {
//         String err = data["error"] ?? "Phone number invalid or unknown error";
//         ScaffoldMessenger.of(context)
//             .showSnackBar(SnackBar(content: Text("Failed: $err")));
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context)
//           .showSnackBar(SnackBar(content: Text("Error: $e")));
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const SizedBox(height: 40),
//               const Text("Your phone number",
//                   style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
//               const SizedBox(height: 8),
//               const Text(
//                 "Please confirm your country code and enter your phone number.",
//                 style: TextStyle(color: Colors.grey),
//               ),
//               const SizedBox(height: 30),
//               GestureDetector(
//                 onTap: () {
//                   showCountryPicker(
//                     context: context,
//                     showPhoneCode: true,
//                     onSelect: (Country c) => setState(() => selectedCountry = c),
//                   );
//                 },
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
//                   decoration: BoxDecoration(
//                     border: Border.all(color: Colors.grey.shade400),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Row(
//                     children: [
//                       Text(
//                         selectedCountry == null
//                             ? "Choose Country"
//                             : "${selectedCountry!.flagEmoji} ${selectedCountry!.name}",
//                         style: const TextStyle(fontSize: 16),
//                       ),
//                       const Spacer(),
//                       const Icon(Icons.arrow_forward_ios, size: 16),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               TextField(
//                 controller: phoneController,
//                 keyboardType: TextInputType.phone,
//                 decoration: InputDecoration(
//                   labelText: "Phone number",
//                   prefixText: selectedCountry != null
//                       ? "+${selectedCountry!.phoneCode} "
//                       : "",
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               const Spacer(),
//               Align(
//                 alignment: Alignment.bottomRight,
//                 child: FloatingActionButton(
//                   backgroundColor: Colors.red,
//                   onPressed: isLoading ? null : sendLoginRequest,
//                   child: isLoading
//                       ? const CircularProgressIndicator(color: Colors.white)
//                       : const Icon(Icons.arrow_forward),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// /// -------------------- OTP SCREEN --------------------
// ///
// ///
//
// class OTPScreen extends StatefulWidget {
//   final String phone;
//   final String phoneCodeHash;
//   const OTPScreen({super.key, required this.phone, required this.phoneCodeHash});
//
//   @override
//   State<OTPScreen> createState() => _OTPScreenState();
// }
//
// class _OTPScreenState extends State<OTPScreen> {
//   final List<TextEditingController> otpControllers =
//   List.generate(5, (_) => TextEditingController());
//   bool isVerifying = false;
//
//   Future<void> verifyOtp() async {
//     final otp = otpControllers.map((c) => c.text).join();
//     if (otp.length < 5) {
//       ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Please enter full 5-digit code")));
//       return;
//     }
//
//     setState(() => isVerifying = true);
//
//     try {
//       final url = Uri.parse("$urlLocal/verify");
//       final req = http.MultipartRequest('POST', url);
//       req.fields['phone'] = widget.phone;
//       req.fields['code'] = otp;
//       req.fields['phone_code_hash'] = widget.phoneCodeHash;
//
//       final res = await req.send();
//       final body = await res.stream.bytesToString();
//       print("📩 Response: $body");
//
//       final data = json.decode(body);
//
//       if (data["status"] == "authorized") {
//         final prefs = await SharedPreferences.getInstance();
//         await prefs.setBool('isLoggedIn', true);
//         await prefs.setString('phone', widget.phone);
//
//         // 🔹 user string extract from server
//         final userString = data["user"]?.toString() ?? "";
//
//         // Extract useful info via RegExp
//         final id = _extractField(userString, r"id=(\d+)");
//         final firstName = _extractField(userString, r"first_name='([^']*)'");
//         final lastName = _extractField(userString, r"last_name='([^']*)'");
//         final username = _extractField(userString, r"username='([^']*)'");
//         final phone = _extractField(userString, r"phone='([^']*)'");
//
//         // ✅ Save to SharedPreferences
//         await prefs.setString('user_id', id ?? '');
//         await prefs.setString('first_name', firstName ?? '');
//         await prefs.setString('last_name', lastName ?? '');
//         await prefs.setString('username', username ?? '');
//         await prefs.setString('phone_number', phone ?? '');
//
//         print("✅ Saved User Info:");
//         print("ID: $id, Name: $firstName $lastName, Username: $username, Phone: $phone");
//
//         final userData = {
//           "id": id ?? '',
//           "first_name": firstName ?? '',
//           "last_name": lastName ?? '',
//           "username": username ?? '',
//           "phone_number": phone ?? '',
//         };
//         // Go to main home
//         Navigator.pushAndRemoveUntil(
//           context,
//           MaterialPageRoute(builder: (_) =>  TelegraphApp(userData: userData)),
//               (route) => false,
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Invalid Code: ${data['error'] ?? 'Failed'}")),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context)
//           .showSnackBar(SnackBar(content: Text("Error: $e")));
//     } finally {
//       setState(() => isVerifying = false);
//     }
//   }
//
//   /// 🧩 Helper: extract field from user string
//   String? _extractField(String input, String pattern) {
//     final regex = RegExp(pattern);
//     final match = regex.firstMatch(input);
//     return match != null ? match.group(1) : null;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             children: [
//               const SizedBox(height: 40),
//               const Icon(Icons.lock_outline, size: 80, color: Colors.redAccent),
//               const SizedBox(height: 20),
//               const Text(
//                 "Check your Telegram messages",
//                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
//               ),
//               const SizedBox(height: 10),
//               Text("We've sent the code to ${widget.phone}",
//                   textAlign: TextAlign.center,
//                   style: const TextStyle(color: Colors.grey)),
//               const SizedBox(height: 20),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: List.generate(
//                   5,
//                       (index) => SizedBox(
//                     width: 50,
//                     child: TextField(
//                       controller: otpControllers[index],
//                       keyboardType: TextInputType.number,
//                       textAlign: TextAlign.center,
//                       maxLength: 1,
//                       decoration: const InputDecoration(counterText: ''),
//                       onChanged: (_) {
//                         if (index < 4 &&
//                             otpControllers[index].text.isNotEmpty) {
//                           FocusScope.of(context).nextFocus();
//                         }
//                       },
//                     ),
//                   ),
//                 ),
//               ),
//               const Spacer(),
//               Align(
//                 alignment: Alignment.bottomRight,
//                 child: FloatingActionButton(
//                   backgroundColor: Colors.red,
//                   onPressed: isVerifying ? null : verifyOtp,
//                   child: isVerifying
//                       ? const CircularProgressIndicator(color: Colors.white)
//                       : const Icon(Icons.arrow_forward),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'otp screen.dart';
import 'url.dart';
import 'home_screen.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  runApp(
    TelegramApp(
      startScreen: isLoggedIn ?  TelegraphApp() : const PhoneLoginScreen(),
    ),
  );
}

class TelegramApp extends StatelessWidget {
  final Widget startScreen;
  const TelegramApp({super.key, required this.startScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Telegram Multi Account",
      theme: ThemeData(
        primaryColor: Colors.white,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: startScreen,
    );
  }
}

/// ================= PHONE LOGIN SCREEN =================
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
      final url = Uri.parse("$urlLocal/login");
      final req = http.MultipartRequest('POST', url);
      req.fields['phone'] = phone;
      final res = await req.send();
      final body = await res.stream.bytesToString();
      final data = json.decode(body);
      print("📩 $data");

      if (data["status"] == "already_authorized") {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('phone', phone);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) =>  TelegraphApp()),
              (route) => false,
        );
        return;
      }

      if (data["status"] == "code_sent" && data["phone_code_hash"] != null) {
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
                  prefixText:
                  selectedCountry != null ? "+${selectedCountry!.phoneCode} " : "",
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
