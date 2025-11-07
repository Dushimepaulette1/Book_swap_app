import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/welcome_screen.dart';
import 'screens/homepage.dart';
import 'providers/book_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const BookSwap());
}

class BookSwap extends StatelessWidget {
  const BookSwap({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => BookProvider())],
      child: MaterialApp(
        title: 'BookSwap',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFF2C2855),
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2C2855)),
        ),
        home: const AuthWrapper(), // Check if user is already logged in
      ),
    );
  }
}

/// Wrapper to check authentication state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF2C2855)),
            ),
          );
        }

        // If user is logged in, go to homepage
        if (snapshot.hasData) {
          return const Homepage();
        }

        // Otherwise, show welcome screen
        return const WelcomeScreen();
      },
    );
  }
}
