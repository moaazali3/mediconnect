import 'package:flutter/material.dart';
import 'package:mediconnect/auth/screens/splash_screen.dart';
import 'package:mediconnect/services/secure_storage.dart';
import 'package:mediconnect/services/api_service.dart';
import 'package:mediconnect/services/theme_service.dart';
import 'package:mediconnect/constants/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SecureStorage.init();
  await ThemeService().init();

  // Load token for early initialization if needed
  String? token = await SecureStorage.readData(key: 'auth_token');
  ApiService.setToken(token);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeService(),
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: ApiService.navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'MediConnect',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeService().themeMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
