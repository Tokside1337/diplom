import 'package:flutter/material.dart';
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
      home: PatientListScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
