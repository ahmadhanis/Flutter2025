import 'package:flutter/material.dart';
import 'package:myunigo/models/user.dart';
import 'package:myunigo/providers/user_provider.dart';
import 'package:myunigo/views/main/mainscreen.dart';
import 'package:provider/provider.dart';



class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String statusMessage = "Checking credentials...";

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), _attemptAutoLogin);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.amber.shade900,
              Colors.purple.shade600,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("assets/images/unigo.png", scale: 3.5),
              const SizedBox(height: 20),
              const CircularProgressIndicator(
                backgroundColor: Colors.white,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
              ),
              const SizedBox(height: 20),
              Text(
                statusMessage,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _attemptAutoLogin() async {
    setState(() {
      statusMessage = "Loading saved user data...";
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.loadUserFromPrefs();

    if (userProvider.user != null) {
      setState(() {
        statusMessage = "Welcome back, ${userProvider.user!.userName}!";
      });
      await Future.delayed(const Duration(seconds: 1));
      _navigateToMain(userProvider.user!);
    } else {
      setState(() {
        statusMessage = "Proceeding as guest...";
      });
      await Future.delayed(const Duration(seconds: 1));
      _navigateToMain(User(
        userId: "0",
        userName: "Guest",
        userEmail: "",
        userPhone: "",
        userUniversity: "",
        userAddress: "",
        userPassword: "",
        userDatereg: "",
      ));
    }
  }

  void _navigateToMain(User user) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MainScreen(user: user)),
    );
  }
}
