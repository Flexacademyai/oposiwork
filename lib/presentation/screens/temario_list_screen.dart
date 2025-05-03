import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'temario_detail_screen.dart';

class TemarioListScreen extends StatelessWidget {
  final String opositionId;

  const TemarioListScreen({super.key, required this.opositionId});

  Future<bool> isCompleted(String temarioId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('progreso')
        .doc(temarioId)
        .get();

    return doc.exists && (doc.data()?['completado'] ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Temario')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('temarios')
            .where('oposicionId', isEqualTo: opositionId)
            .orderBy('orden')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final temarios = snapshot.data!.docs;

          if (temarios.isEmpty) {
            return const Center(child: Text('No hay temarios disponibles.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: temarios.length,
            itemBuilder: (context, index) {
              final doc = temarios[index];
              final data = doc.data() as Map<String, dynamic>;
              final title = data['titulo'] ?? 'Sin título';
              final id = doc.id;

              return FutureBuilder<bool>(
                future: isCompleted(id),
                builder: (context, progressSnap) {
                  final isDone = progressSnap.data ?? false;

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(child: Text('${index + 1}')),
                      title: Text(title),
                      trailing: Icon(
                        isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isDone ? Colors.green : Colors.grey,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TemarioDetailScreen(temarioId: id),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
