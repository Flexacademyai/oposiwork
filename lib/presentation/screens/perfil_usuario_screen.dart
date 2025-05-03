import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PerfilUsuarioScreen extends StatelessWidget {
  const PerfilUsuarioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Usuario no autenticado")),
      );
    }

    final uid = user.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final email = data['email'] ?? user.email ?? 'No disponible';
          final tipo = data['subscriptionType'] ?? 'free';
          final fecha = data['createdAt']?.toDate();
          final oposicion = data['oposicion'] ?? 'No seleccionada';

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Datos del usuario',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Text('📧 Correo: $email'),
                Text('⭐ Tipo de cuenta: ${tipo == 'premium' ? 'Premium' : 'Freemium'}'),
                if (fecha != null)
                  Text('📅 Registro: ${fecha.day}/${fecha.month}/${fecha.year}'),
                Text('🎯 Oposición actual: $oposicion'),
                const Spacer(),
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text('Cerrar sesión'),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/login', (route) => false);
                    },
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
