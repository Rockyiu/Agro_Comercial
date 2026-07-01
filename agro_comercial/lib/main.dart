import 'package:agro_comercial/app.dart';
import 'package:agro_comercial/firebase_options.dart';
import 'package:agro_comercial/locator.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // IMPORTANTE: Importação do Firestore adicionada
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ATIVA O BANCO DE DADOS LOCAL (OFFLINE PERSISTENCE)
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true, // Liga o cache em disco (banco local)
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED, // Espaço ilimitado
  );

  setupDependencies();
  runApp(const App());
}
