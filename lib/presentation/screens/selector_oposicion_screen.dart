import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SelectorOposicionScreen extends StatelessWidget {
  const SelectorOposicionScreen({super.key});

  Future<void> _asignarOposicion(String userId, String oposicionId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'oposicion': oposicionId});
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Usuario no autenticado')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar oposición')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('opositions').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final oposiciones = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: oposiciones.length,
            itemBuilder: (context, index) {
              final doc = oposiciones[index];
              final data = doc.data() as Map<String, dynamic>;
              final titulo = data['titulo'] ?? 'Sin título';
              final entidad = data['entidad'] ?? '';
              final id = doc.id;

              return Card(
                child: ListTile(
                  title: Text(titulo),
                  subtitle: Text(entidad),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      await _asignarOposicion(user.uid, id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Oposición "$titulo" asignada'),
                        ),
                      );
                      Navigator.pop(context);
                    },
                    child: const Text('Seleccionar'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
