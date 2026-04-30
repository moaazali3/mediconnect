import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart'; 
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/auth/screens/register_screen.dart';
import 'package:mediconnect/home_screen.dart'; 
import 'package:mediconnect/Doctor/doctor_home_screen.dart'; 
import 'package:mediconnect/admin/admin_dashboard.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool isPasswordHidden = true;
  bool rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      emailController.text = prefs.getString('saved_email') ?? '';
      rememberMe = emailController.text.isNotEmpty;
    });
  }

  Future<void> _saveSession(String token, String role, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('user_role', role);
    await prefs.setString('user_id', userId);
    if (rememberMe) {
      await prefs.setString('saved_email', emailController.text);
    } else {
      await prefs.remove('saved_email');
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryColor.withOpacity(0.8), Colors.white],
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.4)),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(25.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Form(
                        key: formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(15),
                              decoration: const BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                              child: const Icon(Icons.lock_person_rounded, size: 50, color: Colors.white),
                            ),
                            const SizedBox(height: 20),
                            const Text("Welcome Back", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87)),
                            const Text("Login to your account", style: TextStyle(fontSize: 16, color: Colors.black54)),
                            const SizedBox(height: 35),
                            TextFormField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.email_outlined, color: primaryColor),
                                labelText: "Email",
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                              ),
                              validator: (value) => (value == null || !value.contains("@")) ? "Valid email required" : null,
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: passwordController,
                              obscureText: isPasswordHidden,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.lock_outline, color: primaryColor),
                                suffixIcon: IconButton(
                                  icon: Icon(isPasswordHidden ? Icons.visibility_off : Icons.visibility, color: primaryColor),
                                  onPressed: () => setState(() => isPasswordHidden = !isPasswordHidden),
                                ),
                                labelText: "Password",
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                              ),
                              validator: (value) => (value == null || value.length < 6) ? "Min 6 characters" : null,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Checkbox(
                                  value: rememberMe,
                                  onChanged: (val) => setState(() => rememberMe = val ?? false),
                                  activeColor: primaryColor,
                                ),
                                const Text("Remember Me", style: TextStyle(fontSize: 14, color: Colors.black87)),
                              ],
                            ),
                            const SizedBox(height: 15),
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (formKey.currentState!.validate()) {
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (context) => const Center(child: CircularProgressIndicator(color: primaryColor)),
                                    );

                                    var response = await ApiService().login(emailController.text, passwordController.text);

                                    if (!mounted) return;
                                    Navigator.pop(context); 

                                    if (response.success && response.data != null) {
                                      String token = response.data['token'];
                                      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
                                      
                                      String userId = decodedToken['userId'] ?? 
                                                     decodedToken['id'] ?? 
                                                     decodedToken['nameid'] ?? 
                                                     decodedToken['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'] ?? 
                                                     "";

                                      String role = (decodedToken['role'] ?? 
                                                    decodedToken['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'] ?? 
                                                    "").toString().toLowerCase();

                                      // حفظ الجلسة للبقاء قيد تسجيل الدخول
                                      await _saveSession(token, role, userId);

                                      if (mounted) {
                                        if (role == "admin") {
                                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminDashboard()));
                                        } else if (role == "doctor") {
                                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DoctorHomeScreen(userId: userId)));
                                        } else {
                                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen(userId: userId, userRole: role)));
                                        }
                                      }
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(response.message), backgroundColor: Colors.red),
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                  elevation: 5,
                                ),
                                child: const Text("LOGIN", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Don't have an account?"),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                                  },
                                  child: const Text("Sign Up", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
