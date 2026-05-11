enum TipoPsicotecnico { verbal, numerico, espacial, memoria, atencion }

class Psicotecnico {
  final String id;
  final String oposicionId;
  final TipoPsicotecnico tipo;
  final String? subtipo;
  final String enunciado;
  final Map<String, dynamic>? datos;
  final List<String> opciones;
  final String respuestaCorrecta;
  final String? explicacion;
  final int dificultad;
  final DateTime createdAt;

  const Psicotecnico({
    required this.id,
    required this.oposicionId,
    required this.tipo,
    this.subtipo,
    required this.enunciado,
    this.datos,
    required this.opciones,
    required this.respuestaCorrecta,
    this.explicacion,
    required this.dificultad,
    required this.createdAt,
  });

  factory Psicotecnico.fromMap(Map<String, dynamic> map) => Psicotecnico(
        id: map['id'] as String,
        oposicionId: map['oposicion_id'] as String,
        tipo: _parseTipo(map['tipo'] as String),
        subtipo: map['subtipo'] as String?,
        enunciado: map['enunciado'] as String,
        datos: map['datos'] as Map<String, dynamic>?,
        opciones: List<String>.from(map['opciones'] as List),
        respuestaCorrecta: map['respuesta_correcta'] as String,
        explicacion: map['explicacion'] as String?,
        dificultad: map['dificultad'] as int? ?? 1,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  static TipoPsicotecnico _parseTipo(String t) => switch (t) {
        'numerico' => TipoPsicotecnico.numerico,
        'espacial' => TipoPsicotecnico.espacial,
        'memoria' => TipoPsicotecnico.memoria,
        'atencion' => TipoPsicotecnico.atencion,
        _ => TipoPsicotecnico.verbal,
      };

  bool esCorrecta(String r) => r == respuestaCorrecta;

  String get tipoLabel => switch (tipo) {
        TipoPsicotecnico.verbal => 'Razonamiento verbal',
        TipoPsicotecnico.numerico => 'Razonamiento numérico',
        TipoPsicotecnico.espacial => 'Razonamiento espacial',
        TipoPsicotecnico.memoria => 'Memoria',
        TipoPsicotecnico.atencion => 'Atención',
      };
}
