// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myunigo/providers/user_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  // WidgetsFlutterBinding.ensureInitialized();
  // await DBHelper.instance.database; // Ensures DB is initialized
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        // Add more providers here
      ],
      child: MaterialApp(
        title: 'Unigo',
        theme: ThemeData(
          textTheme: GoogleFonts.poppinsTextTheme(),
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.amber.shade900,
            primary: Colors.amber.shade900,
            secondary: Colors.purple.shade600,
            surface: Colors.white,
            background: Colors.grey.shade100,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: Colors.black,
          ),
          scaffoldBackgroundColor: Colors.grey.shade100,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.amber.shade900,
            foregroundColor: Colors.white,
            elevation: 2,
          ),

          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: const OutlineInputBorder(),
            labelStyle: TextStyle(color: Colors.purple.shade600),
            prefixIconColor: Colors.amber.shade900,
          ),
          dividerColor: Colors.amber.shade200,
          useMaterial3: true,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
