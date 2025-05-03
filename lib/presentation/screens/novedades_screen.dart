import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NovedadesScreen extends StatelessWidget {
  const NovedadesScreen({super.key});

  Icon _iconoPorTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'plazo':
        return const Icon(Icons.calendar_today, color: Colors.blue);
      case 'listado':
        return const Icon(Icons.list_alt, color: Colors.deepPurple);
      case 'resultado':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'alerta':
        return const Icon(Icons.warning, color: Colors.orange);
      default:
        return const Icon(Icons.info, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Usuario no autenticado')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Últimas novedades')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
        builder: (context, userSnap) {
          if (!userSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = userSnap.data!.data() as Map<String, dynamic>;
          final oposicionId = userData['oposicion'];

          if (oposicionId == null) {
            return const Center(child: Text('No tienes una oposición asignada.'));
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notificaciones')
                .where('oposicionId', isEqualTo: oposicionId)
                .orderBy('fecha', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return const Center(child: Text('No hay novedades aún.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final titulo = data['titulo'] ?? 'Sin título';
                  final tipo = data['tipo'] ?? 'info';
                  final fecha = (data['fecha'] as Timestamp?)?.toDate();

                  return Card(
                    child: ListTile(
                      leading: _iconoPorTipo(tipo),
                      title: Text(titulo),
                      subtitle: fecha != null
                          ? Text('Fecha: ${fecha.day}/${fecha.month}/${fecha.year}')
                          : null,
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
