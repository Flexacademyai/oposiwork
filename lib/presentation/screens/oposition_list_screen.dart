import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'opposition_detail_screen.dart';

class OpositionListScreen extends StatelessWidget {
  const OpositionListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final opositionsRef = FirebaseFirestore.instance.collection('opositions');

    return Scaffold(
      appBar: AppBar(title: const Text('Oposiciones Disponibles')),
      body: StreamBuilder<QuerySnapshot>(
        stream: opositionsRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No hay oposiciones disponibles."));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;

              return ListTile(
                title: Text(data['titulo'] ?? 'Oposición'),
                subtitle: Text(data['municipio'] ?? ''),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OppositionDetailScreen(oppositionId: docId),
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