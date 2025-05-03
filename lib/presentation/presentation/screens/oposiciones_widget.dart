
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OposicionesWidget extends StatefulWidget {
  @override
  _OposicionesWidgetState createState() => _OposicionesWidgetState();
}

class _OposicionesWidgetState extends State<OposicionesWidget> {
  String? selectedAmbito;
  String? selectedProvincia;
  String? selectedAutonomia;
  String? selectedLocalidad;

  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('opositions');

    if (selectedAmbito != null) {
      query = query.where('ambito', isEqualTo: selectedAmbito);
    }
    if (selectedProvincia != null) {
      query = query.where('provincia', isEqualTo: selectedProvincia);
    }
    if (selectedAutonomia != null) {
      query = query.where('autonomia', isEqualTo: selectedAutonomia);
    }
    if (selectedLocalidad != null) {
      query = query.where('localidad', isEqualTo: selectedLocalidad!.toLowerCase());
    }

    return Column(
      children: [
        Wrap(
          spacing: 10,
          children: [
            DropdownButton<String>(
              hint: Text("Ámbito"),
              value: selectedAmbito,
              items: ['local', 'autonomico', 'nacional'].map((amb) {
                return DropdownMenuItem(value: amb, child: Text(amb));
              }).toList(),
              onChanged: (value) => setState(() => selectedAmbito = value),
            ),
            DropdownButton<String>(
              hint: Text("Provincia"),
              value: selectedProvincia,
              items: ['Ciudad Real', 'Madrid', 'Barcelona'].map((prov) {
                return DropdownMenuItem(value: prov, child: Text(prov));
              }).toList(),
              onChanged: (value) => setState(() => selectedProvincia = value),
            ),
            DropdownButton<String>(
              hint: Text("Autonomía"),
              value: selectedAutonomia,
              items: ['Andalucía', 'Castilla-La Mancha', 'Madrid'].map((auto) {
                return DropdownMenuItem(value: auto, child: Text(auto));
              }).toList(),
              onChanged: (value) => setState(() => selectedAutonomia = value),
            ),
            SizedBox(
              width: 200,
              child: TextField(
                decoration: InputDecoration(labelText: 'Localidad'),
                onSubmitted: (value) => setState(() {
                  selectedLocalidad = value.trim().toLowerCase();
                }),
              ),
            )
          ],
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: query.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return Center(child: Text("No hay oposiciones"));
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final doc = docs[i].data() as Map<String, dynamic>;
                  return ListTile(
                    title: Text(doc['titulo'] ?? 'Sin título'),
                    subtitle: Text(doc['fuente'] ?? ''),
                    trailing: Text(doc['ambito'] ?? ''),
                    onTap: () => print(doc['enlace_oficial']),
                  );
                },
              );
            },
          ),
        )
      ],
    );
  }
}
