import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OppositionDetailScreen extends StatelessWidget {
  final String oppositionId;

  const OppositionDetailScreen({super.key, required this.oppositionId});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('opositions').doc(oppositionId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final requiresPremium = data['requiere_premium'] == true;

        return FutureBuilder<DocumentSnapshot>(
          future: userDoc.get(),
          builder: (context, userSnap) {
            if (!userSnap.hasData) return const Center(child: CircularProgressIndicator());

            final userData = userSnap.data!.data() as Map<String, dynamic>;
            final isPremium = userData['isPremium'] == true;

            return Scaffold(
              appBar: AppBar(title: Text(data['titulo'] ?? 'Oposición')),
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Plazas: ${data['plazas']}"),
                    Text("Organismo: ${data['organismo']}"),
                    Text("Ámbito: ${data['ambito']}"),
                    Text("Plazo: ${data['plazo_inicio']} - ${data['plazo_fin']}"),
                    const SizedBox(height: 20),
                    if (requiresPremium && !isPremium)
                      const Text("Contenido disponible solo para usuarios Premium."),
                    if (!requiresPremium || isPremium)
                      Expanded(child: TemarioList(oppositionId: oppositionId)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class TemarioList extends StatelessWidget {
  final String oppositionId;

  const TemarioList({super.key, required this.oppositionId});

  @override
  Widget build(BuildContext context) {
    final temariosRef = FirebaseFirestore.instance
        .collection('opositions')
        .doc(oppositionId)
        .collection('temarios');

    return StreamBuilder<QuerySnapshot>(
      stream: temariosRef.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return ListTile(
              title: Text(data['titulo'] ?? 'Tema'),
              subtitle: Text(data['contenido'] ?? ''),
              trailing: data['descargable'] == true
                  ? IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Contenido descargado localmente")),
                        );
                      },
                    )
                  : null,
            );
          },
        );
      },
    );
  }
}
