
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class TemarioOposicionWidget extends StatelessWidget {
  final String oposicionId;

  const TemarioOposicionWidget({Key? key, required this.oposicionId}) : super(key: key);

  Future<Map<String, dynamic>?> obtenerDatos() async {
    final doc = await FirebaseFirestore.instance.collection('opositions').doc(oposicionId).get();
    return doc.exists ? doc.data() : null;
  }

  void abrirUrl(BuildContext context, String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo abrir el enlace')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: obtenerDatos(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        final data = snapshot.data!;
        final temarioUrl = data['temario_url'];
        final contenidoUrl = data['contenido_url'];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (temarioUrl != null)
              ElevatedButton.icon(
                icon: Icon(Icons.download),
                label: Text('Descargar Temario'),
                onPressed: () => abrirUrl(context, temarioUrl),
              ),
            if (contenidoUrl != null)
              ElevatedButton.icon(
                icon: Icon(Icons.menu_book),
                label: Text('Ver Contenido del Temario'),
                onPressed: () => abrirUrl(context, contenidoUrl),
              ),
            if (temarioUrl == null && contenidoUrl == null)
              Text('Esta oposición aún no tiene temario asociado.')
          ],
        );
      },
    );
  }
}
