import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'House Keeper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF46DFB1),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF46DFB1),
          primary: const Color(0xFF46DFB1),
          secondary: const Color(0xFF15919B),
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF46DFB1),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        cardTheme: CardTheme(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          titleLarge: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          titleMedium: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          bodyLarge: TextStyle(
            color: Colors.black87,
          ),
          bodyMedium: TextStyle(
            color: Colors.black87,
          ),
        ),
      ),
      home: FutureBuilder<SharedPreferences>(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          } else {
            // Kiểm tra xem token đã tồn tại chưa (người dùng đã đăng nhập chưa)
            final prefs = snapshot.data;
            final token = prefs?.getString('token_nguoi_dung');

            if (token != null && token.isNotEmpty) {
              // Nếu có token, điều hướng đến trang chủ
              return const HomeScreen();
            } else {
              // Nếu chưa đăng nhập, điều hướng đến trang đăng nhập
              return const LoginScreen();
            }
          }
        },
      ),
    );
  }
}
