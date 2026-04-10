import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.init();
  runApp(const GmpMobileApp());
}

/// [GmpMobileApp] là entry point của ứng dụng Mobile eBMR.
/// Bắt đầu từ [LoginScreen] để bảo mật truy cập.
class GmpMobileApp extends StatelessWidget {
  const GmpMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'eBMR - Nhật ký sản xuất điện tử',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: AuthService.isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
