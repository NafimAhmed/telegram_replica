//
//
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:country_picker/country_picker.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'otp screen.dart';
// import 'url.dart';
// import 'home_screen.dart';
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   final prefs = await SharedPreferences.getInstance();
//   final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
//   runApp(
//     TelegramApp(
//       startScreen: isLoggedIn ?  TelegraphApp() : const PhoneLoginScreen(),
//     ),
//   );
// }
//
// class TelegramApp extends StatelessWidget {
//   final Widget startScreen;
//   const TelegramApp({super.key, required this.startScreen});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: "Telegram Multi Account",
//       theme: ThemeData(
//         primaryColor: Colors.white,
//         scaffoldBackgroundColor: Colors.white,
//       ),
//       home: startScreen,
//     );
//   }
// }
//
// /// ================= PHONE LOGIN SCREEN =================
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
//       ScaffoldMessenger.of(context)
//           .showSnackBar(const SnackBar(content: Text("Select your country")));
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
//       final res = await req.send();
//       final body = await res.stream.bytesToString();
//       final data = json.decode(body);
//       print("📩 $data");
//
//       if (data["status"] == "already_authorized") {
//         final prefs = await SharedPreferences.getInstance();
//         await prefs.setBool('isLoggedIn', true);
//         await prefs.setString('phone', phone);
//         Navigator.pushAndRemoveUntil(
//           context,
//           MaterialPageRoute(builder: (_) =>  TelegraphApp()),
//               (route) => false,
//         );
//         return;
//       }
//
//       if (data["status"] == "code_sent" && data["phone_code_hash"] != null) {
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
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(data["error"] ?? "Invalid number")),
//         );
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
//                   style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
//               const SizedBox(height: 10),
//               const Text("Please confirm your country code and enter number.",
//                   style: TextStyle(color: Colors.grey)),
//               const SizedBox(height: 30),
//               GestureDetector(
//                 onTap: () {
//                   showCountryPicker(
//                     context: context,
//                     showPhoneCode: true,
//                     onSelect: (Country c) => setState(() {
//                       selectedCountry = c;
//                     }),
//                   );
//                 },
//                 child: Container(
//                   padding:
//                   const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
//                   decoration: BoxDecoration(
//                       border: Border.all(color: Colors.grey.shade400),
//                       borderRadius: BorderRadius.circular(8)),
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
//                   prefixText:
//                   selectedCountry != null ? "+${selectedCountry!.phoneCode} " : "",
//                   border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8)),
//                 ),
//               ),
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

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:country_picker/country_picker.dart';

// 📦 Local imports
import 'package:ag_taligram/providers/telegraph_qg_provider.dart';
import 'package:ag_taligram/screens/auth_screen/phone_login_screen.dart';
import 'package:ag_taligram/url.dart';

import 'home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TelegraphProvider()),
      ],
      child: TelegramApp(
        startScreen:
        isLoggedIn ? const TelegraphApp() : const PhoneLoginScreen(),
      ),
    ),
  );
}

class TelegramApp extends StatelessWidget {
  final Widget startScreen;
  const TelegramApp({super.key, required this.startScreen});

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<TelegraphProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Telegram Multi Account",
      themeMode: p.isDark ? ThemeMode.dark : ThemeMode.light,
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E2429),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2C343A),
          foregroundColor: Colors.white,
        ),
      ),
      theme: ThemeData(
        primaryColor: Colors.green,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          color: Colors.green,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: startScreen,
    );
  }
}




// import 'dart:convert';
// import 'package:ag_taligram/providers/telegraph_qg_provider.dart';
// import 'package:ag_taligram/screens/auth_screen/phone_login_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:country_picker/country_picker.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:provider/provider.dart';
//
// import 'home_screen.dart';
// import 'otp screen.dart';
// import 'url.dart';
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   final prefs = await SharedPreferences.getInstance();
//   final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
//
//   runApp(
//     ChangeNotifierProvider(
//       create: (_) => TelegraphProvider(),
//       child: TelegramApp(
//         startScreen:
//         isLoggedIn ? const TelegraphApp() : const PhoneLoginScreen(),
//       ),
//     ),
//   );
// }
//
// class TelegramApp extends StatelessWidget {
//   final Widget startScreen;
//   const TelegramApp({super.key, required this.startScreen});
//
//   @override
//   Widget build(BuildContext context) {
//     final p = Provider.of<TelegraphProvider>(context);
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: "Telegram Multi Account",
//       themeMode: p.isDark ? ThemeMode.dark : ThemeMode.light,
//       darkTheme: ThemeData.dark(),
//       theme: ThemeData(
//         primaryColor: Colors.white,
//         scaffoldBackgroundColor: Colors.white,
//       ),
//       home: startScreen,
//     );
//   }
// }
