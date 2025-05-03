import 'package:flutter/material.dart';

class VentajasPremiumScreen extends StatelessWidget {
  const VentajasPremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ventajas = [
      {
        "icon": Icons.lock_open,
        "title": "Acceso a temarios completos",
        "description": "Desbloquea todos los contenidos detallados de cada tema."
      },
      {
        "icon": Icons.calendar_month,
        "title": "Calendario de estudio personalizado",
        "description": "Organiza tu tiempo y recibe recordatorios automáticos."
      },
      {
        "icon": Icons.star,
        "title": "Técnicas de estudio premium",
        "description": "Consejos exclusivos aplicables a tu oposición."
      },
      {
        "icon": Icons.track_changes,
        "title": "Seguimiento de tu progreso",
        "description": "Marca temas completados y mide tu avance real."
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Ventajas de ser Premium")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              '¿Por qué hacerte Premium?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: ventajas.length,
                itemBuilder: (context, index) {
                  final v = ventajas[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Icon(v['icon'] as IconData, color: Colors.indigo),
                      title: Text(v['title'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(v['description'] as String),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.upgrade),
              label: const Text("Hazte Premium"),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Funcionalidad aún no implementada.'),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
