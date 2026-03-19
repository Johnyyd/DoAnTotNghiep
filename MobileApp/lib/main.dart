import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/main_navigation.dart';

void main() {
  runApp(const GmpMobileApp());
}

/// [GmpMobileApp] là entry point của ứng dụng Mobile eBMR (Nhật ký sản xuất điện tử).
/// Thiết lập [ThemeData] chung và khởi chạy [MainNavigationScreen] làm màn hình gốc.
class GmpMobileApp extends StatelessWidget {
  const GmpMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'eBMR - Nhật ký sản xuất điện tử',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainNavigationScreen(),
    );
  }
}
