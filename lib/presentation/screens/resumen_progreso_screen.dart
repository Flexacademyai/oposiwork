import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ResumenProgresoScreen extends StatelessWidget {
  const ResumenProgresoScreen({super.key});

  Future<Map<String, dynamic>> _loadProgreso(String uid) async {
    final progresoDocs = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('progreso')
        .get();

    final temariosDocs =
        await FirebaseFirestore.instance.collection('temarios').get();

    // Map: {opositionId: [temas]}
    final Map<String, List<Map<String, dynamic>>> temariosPorOpo = {};
    for (var doc in temariosDocs.docs) {
      final data = doc.data();
      final opoId = data['oposicionId'] ?? 'sin_oposicion';
      temariosPorOpo.putIfAbsent(opoId, () => []).add({
        'id': doc.id,
        'titulo': data['titulo'] ?? 'Sin título',
      });
    }

    // Progreso total
    Map<String, int> completadosPorOpo = {};

    for (var doc in progresoDocs.docs) {
      final isComplete = doc.data()['completado'] ?? false;
      if (!isComplete) continue;

      // Buscar a qué oposición pertenece este tema
      final temarioDoc = temariosDocs.docs.firstWhere(
        (t) => t.id == doc.id,
        orElse: () => throw Exception('Temario no encontrado'),
      );

      final opoId = temarioDoc['oposicionId'];
      if (opoId != null) {
        completadosPorOpo[opoId] = (completadosPorOpo[opoId] ?? 0) + 1;
      }
    }

    return {
      'temariosPorOpo': temariosPorOpo,
      'completadosPorOpo': completadosPorOpo,
    };
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(body: Center(child: Text('No autenticado')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Resumen de progreso')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadProgreso(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final temariosPorOpo = snapshot.data!['temariosPorOpo'] as Map<String, List>;
          final completadosPorOpo = snapshot.data!['completadosPorOpo'] as Map<String, int>;

          if (temariosPorOpo.isEmpty) {
            return const Center(child: Text('No hay temarios registrados.'));
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: temariosPorOpo.entries.map((entry) {
              final opoId = entry.key;
              final total = entry.value.length;
              final done = completadosPorOpo[opoId] ?? 0;
              final porcentaje = (done / total);

              return Card(
                margin: const EdgeInsets.only(bottom: 20),
                child: ListTile(
                  title: Text("Oposición: $opoId"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: porcentaje,
                        minHeight: 8,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 4),
                      Text("$done de $total temas completados"),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
