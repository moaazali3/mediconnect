import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart'; 
import 'package:mediconnect/constants/colors.dart';
import 'package:mediconnect/auth/screens/register_screen.dart';
import 'package:mediconnect/home_screen.dart'; 
import 'package:mediconnect/Doctor/doctor_home_screen.dart'; 
import 'package:mediconnect/admin/admin_dashboard.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/services/secure_storage.dart';
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
    
    // حفظ التوكن بشكل آمن (تمت معالجته بالفعل في AuthApi.login ولكن نؤكد عليه هنا)
    await SecureStorage.writeData(key: 'auth_token', value: token);
    ApiService.setToken(token);

    // حفظ البيانات الأخرى في SharedPreferences
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
          Container(color: Colors.black.withOpacity(0.05)),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(25.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Form(
                        key: formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(color: Colors.transparent, shape: BoxShape.circle),
                              child: Image.asset(
                                "assets/images/img.png",
                                height: 100,
                                width: 100,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.lock_person_rounded, size: 80, color: primaryColor),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text("Welcome Back",
                                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: primaryColor)),
                            const Text("Login to your account",
                                style: TextStyle(fontSize: 16, color: Colors.black54)),
                            const SizedBox(height: 35),

                            _buildLoginField(
                              controller: emailController,
                              label: "Email Address",
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) => (value == null || !value.contains("@")) ? "Valid email required" : null,
                            ),
                            const SizedBox(height: 20),

                            _buildLoginField(
                              controller: passwordController,
                              label: "Password",
                              icon: Icons.lock_outline,
                              isPassword: true,
                              isPasswordHidden: isPasswordHidden,
                              onTogglePassword: () => setState(() => isPasswordHidden = !isPasswordHidden),
                              validator: (value) {
                                if (value == null || value.isEmpty) return "Password is required";
                                if (value.length < 6) return "Min 6 characters";
                                return null;
                              },
                            ),

                            const SizedBox(height: 10),
                            Row(
                              children: [
                                SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: Checkbox(
                                    value: rememberMe,
                                    onChanged: (val) => setState(() => rememberMe = val ?? false),
                                    activeColor: primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text("Remember Me", style: TextStyle(fontSize: 14, color: Colors.black87)),
                              ],
                            ),
                            const SizedBox(height: 20),
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
                                        SnackBar(
                                          content: Text(response.message), 
                                          backgroundColor: Colors.red,
                                          duration: const Duration(seconds: 5),
                                        ),
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
                                child: const Text("LOGIN", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
                              ),
                            ),
                            const SizedBox(height: 25),
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

  Widget _buildLoginField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isPasswordHidden = false,
    VoidCallback? onTogglePassword,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && isPasswordHidden,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54, fontSize: 13),
        prefixIcon: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: primaryColor, size: 20),
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(isPasswordHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: primaryColor, size: 20),
                onPressed: onTogglePassword,
              )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.6),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.5))
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 1.5)
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1)
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)
        ),
      ),
      validator: validator,
    );
  }
}
