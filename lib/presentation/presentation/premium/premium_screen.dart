
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'premium_area.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({Key? key}) : super(key: key);

  void _abrirTemario() async {
    const url = 'https://oposiwork.com/temarios/temario-general.pdf';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      throw 'No se pudo abrir el temario';
    }
  }

  void _abrirContenidoTemario() async {
    const url = 'https://oposiwork.com/temarios/contenido-temario.pdf';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      throw 'No se pudo abrir el contenido del temario';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumArea(
      premiumChild: Scaffold(
        appBar: AppBar(title: Text('Zona Premium')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.download),
              label: Text('Descargar Temario'),
              onPressed: _abrirTemario,
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.menu_book),
              label: Text('Ver Contenido del Temario'),
              onPressed: _abrirContenidoTemario,
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.lightbulb),
              label: Text('Técnicas de Estudio (próximamente)'),
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Función en desarrollo')),
              ),
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.calendar_today),
              label: Text('Calendario de Alarmas (próximamente)'),
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Función en desarrollo')),
              ),
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.newspaper),
              label: Text('Noticias Personalizadas (próximamente)'),
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Función en desarrollo')),
              ),
            ),
          ],
        ),
      ),
      freeChild: Scaffold(
        appBar: AppBar(title: Text('Zona Premium')),
        body: Center(child: Text('Solo usuarios premium pueden acceder a esta sección.')),
      ),
    );
  }
}
