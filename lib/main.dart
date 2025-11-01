import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'login_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ChungCuApp());
}

class ChungCuApp extends StatelessWidget {
  const ChungCuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mua bán chung cư',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}


