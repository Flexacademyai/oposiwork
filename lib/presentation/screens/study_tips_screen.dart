import 'package:flutter/material.dart';

class StudyTipsScreen extends StatelessWidget {
  const StudyTipsScreen({super.key});

  final List<Map<String, dynamic>> studyTips = const [
    {
      'title': '📌 Técnica Pomodoro',
      'description':
          'Estudia durante 25 minutos y toma descansos de 5 minutos. Después de 4 sesiones, haz una pausa larga.',
    },
    {
      'title': '🧠 Active Recall',
      'description':
          'Haz preguntas sobre lo que estudias y responde sin mirar. Refuerza tu memoria activa.',
    },
    {
      'title': '📆 Revisión Espaciada',
      'description':
          'Repasa el contenido en intervalos progresivos para mejorar la retención a largo plazo.',
    },
    {
      'title': '✍️ Técnica Feynman',
      'description':
          'Explica lo que aprendes como si enseñaras a un niño. Si no puedes, repásalo hasta dominarlo.',
    },
    {
      'title': '🧘 Descansos conscientes',
      'description':
          'Haz pausas reales sin distracciones digitales para relajar tu mente y volver con claridad.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Técnicas de Estudio')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: studyTips.length,
        itemBuilder: (context, index) {
          final tip = studyTips[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: ListTile(
              title: Text(
                tip['title'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(tip['description']),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}
