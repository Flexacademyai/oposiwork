
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TemarioYContenidoWidget extends StatelessWidget {
  final String oposicionId;

  const TemarioYContenidoWidget({Key? key, required this.oposicionId}) : super(key: key);

  Future<Map<String, dynamic>?> obtenerDatos() async {
    final doc = await FirebaseFirestore.instance.collection('opositions').doc(oposicionId).get();
    return doc.exists ? doc.data() : null;
  }

  Future<bool> esPremium() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return doc.exists && doc.data()?['premium'] == true;
  }

  void abrirUrl(BuildContext context, String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo abrir el enlace.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([obtenerDatos(), esPremium()]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

        final datos = snapshot.data![0] as Map<String, dynamic>?;
        final premium = snapshot.data![1] as bool;

        if (!premium) {
          return Text("Zona premium: hazte miembro para descargar el temario completo.");
        }

        final temarioUrl = datos?['temario_url'];
        final contenidoUrl = datos?['contenido_url'];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (temarioUrl != null)
              ElevatedButton.icon(
                icon: Icon(Icons.download),
                label: Text('Descargar Temario Oficial'),
                onPressed: () => abrirUrl(context, temarioUrl),
              ),
            if (contenidoUrl != null)
              ElevatedButton.icon(
                icon: Icon(Icons.book),
                label: Text('Descargar Contenido del Temario'),
                onPressed: () => abrirUrl(context, contenidoUrl),
              ),
            if (temarioUrl == null && contenidoUrl == null)
              Text("No hay archivos disponibles aún para esta oposición.")
          ],
        );
      },
    );
  }
}
