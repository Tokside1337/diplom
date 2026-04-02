import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/patient_list_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(RehabApp());
}

class RehabApp extends StatelessWidget {
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
      // Добавляем поддержку русского языка для стандартных виджетов (календарь и т.д.)
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('ru', 'RU'),
      ],
      locale: Locale('ru', 'RU'),
      home: PatientListScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
