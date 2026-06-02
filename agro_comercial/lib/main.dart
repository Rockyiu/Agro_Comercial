import 'package:agro_comercial/app.dart';
import 'package:agro_comercial/firebase_options.dart';
import 'package:agro_comercial/locator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  setupDependencies();
  runApp(const App());
}
