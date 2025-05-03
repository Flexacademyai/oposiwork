import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

Future<void> main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final rssUrl = 'https://www.boe.es/rss/oposiciones.xml'; // RSS oficial
  final response = await http.get(Uri.parse(rssUrl));

  if (response.statusCode != 200) {
    print('Error al obtener el RSS: ${response.statusCode}');
    return;
  }

  final document = XmlDocument.parse(response.body);
  final items = document.findAllElements('item');

  for (final item in items) {
    final title = item.getElement('title')?.text ?? 'Sin título';
    final pubDate = item.getElement('pubDate')?.text ?? '';
    final link = item.getElement('link')?.text ?? '';
    final guid = item.getElement('guid')?.text ?? '';

    final tipo = _detectarTipo(title);
    final oposicionId = _extraerOposicionId(title);

    if (oposicionId == null) continue; // ignorar si no se reconoce

    // Evitar duplicados por GUID
    final existe = await FirebaseFirestore.instance
        .collection('notificaciones')
        .doc(guid)
        .get();

    if (existe.exists) continue;

    await FirebaseFirestore.instance.collection('notificaciones').doc(guid).set({
      'titulo': title,
      'tipo': tipo,
      'oposicionId': oposicionId,
      'fecha': DateTime.tryParse(pubDate) ?? DateTime.now(),
      'link': link,
    });

    print('Notificación añadida: $title');
  }
}

String _detectarTipo(String titulo) {
  final t = titulo.toLowerCase();
  if (t.contains('listado')) return 'listado';
  if (t.contains('plazo') || t.contains('instancia')) return 'plazo';
  if (t.contains('resultado') || t.contains('aprobado')) return 'resultado';
  if (t.contains('aviso') || t.contains('modificación')) return 'alerta';
  return 'info';
}

String? _extraerOposicionId(String titulo) {
  final lower = titulo.toLowerCase();
  if (lower.contains('guardia civil')) return 'guardia_civil_2025';
  if (lower.contains('policía nacional')) return 'policia_nacional_2025';
  if (lower.contains('administrativo')) return 'administrativo_estado_2025';
  return null;
}
