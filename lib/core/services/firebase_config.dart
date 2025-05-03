import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:oposiwork/firebase_options.dart';

class FirebaseConfig {
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('Firebase inicializado correctamente');
    } catch (e) {
      debugPrint('Error al inicializar Firebase: $e');
      // En una aplicación real, deberíamos manejar este error de manera más robusta
      // Por ejemplo, mostrando un diálogo al usuario o intentando reiniciar la app
    }
  }
}
