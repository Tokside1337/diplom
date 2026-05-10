import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/login_screen.dart';

/// The main entry point for the application.
void main() {
  // Ensure that plugin services are initialized before running the app.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RehabApp());
}

/// The root widget of the Rehabilitation System application.
///
/// This widget configures the global application settings including:
/// * Theme (Material 3 with Roboto font)
/// * Localization (Russian)
/// * Initial screen ([LoginScreen])
class RehabApp extends StatelessWidget {
  const RehabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Система Реабилитации',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        textTheme: GoogleFonts.robotoTextTheme(),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru', 'RU'),
      ],
      locale: const Locale('ru', 'RU'),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
