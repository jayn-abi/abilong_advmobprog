import 'package:facebook_replication/firebase_options.dart';
import 'package:facebook_replication/screens/sign_up_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'screens/reset_password_screen.dart';

// Import your screens
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then(
    (_) async {
      await dotenv.load(fileName: 'assets/.env');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      runApp(const MainApp());
    },
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: ScreenUtilInit(
        designSize: const Size(412, 715),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          final themeModel = context.watch<ThemeProvider>();

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Blog App',

            // Light/Dark mode
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: themeModel.isDark ? ThemeMode.dark : ThemeMode.light,

            
            initialRoute: '/login',

            // Register all routes
            routes: {
              '/login': (context) => const LoginScreen(),
              '/splash': (context) => const SplashScreen(),
              '/home': (context) => const HomeScreen(),
              '/signup': (context) => const SignUpScreen(),
              '/resetPassword': (context) => const ResetPasswordScreen(),

            },
          );
        },
      ),
    );
  }
}
