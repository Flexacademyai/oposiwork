import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OposiWork'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('¡Bienvenido a OposiWork!'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navegar o lanzar función
              },
              child: const Text('Acción principal'),
            ),
          ],
        ),
      ),
    );
  }
}
