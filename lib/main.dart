import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';

const FirebaseOptions webOptions = FirebaseOptions(
  apiKey: "AIzaSyCahLcE9AibVxzwYX8xqDr_SzTP3-vhtjo",
  authDomain: "workschedule-8fc6f.firebaseapp.com",
  projectId: "workschedule-8fc6f",
  storageBucket: "workschedule-8fc6f.firebasestorage.app",
  messagingSenderId: "860832415451",
  appId: "1:860832415451:web:21754e4c80bcc6f752d6fe",
  measurementId: "G-FE573RCHWZ",
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(options: webOptions);
  } else {
    await Firebase.initializeApp();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '근무 스케줄 관리 시스템',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          if (snapshot.hasData) {
            // 로그인된 상태
            return const HomeScreen();
          } else {
            // 로그인되지 않은 상태
            return const AuthScreen();
          }
        },
      ),
    );
  }
}
