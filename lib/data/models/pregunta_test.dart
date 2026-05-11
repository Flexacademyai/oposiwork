class PreguntaTest {
  final String id;
  final String temaId;
  final String oposicionId;
  final String enunciado;
  final String opcionA;
  final String opcionB;
  final String opcionC;
  final String opcionD;
  final String respuestaCorrecta;
  final String? explicacion;
  final String? articuloReferencia;
  final int dificultad;
  final int vecesFallada;
  final DateTime createdAt;

  const PreguntaTest({
    required this.id,
    required this.temaId,
    required this.oposicionId,
    required this.enunciado,
    required this.opcionA,
    required this.opcionB,
    required this.opcionC,
    required this.opcionD,
    required this.respuestaCorrecta,
    this.explicacion,
    this.articuloReferencia,
    required this.dificultad,
    required this.vecesFallada,
    required this.createdAt,
  });

  factory PreguntaTest.fromMap(Map<String, dynamic> map) {
    return PreguntaTest(
      id: map['id'] as String,
      temaId: map['tema_id'] as String,
      oposicionId: map['oposicion_id'] as String,
      enunciado: map['enunciado'] as String,
      opcionA: map['opcion_a'] as String,
      opcionB: map['opcion_b'] as String,
      opcionC: map['opcion_c'] as String,
      opcionD: map['opcion_d'] as String,
      respuestaCorrecta: map['respuesta_correcta'] as String,
      explicacion: map['explicacion'] as String?,
      articuloReferencia: map['articulo_referencia'] as String?,
      dificultad: map['dificultad'] as int? ?? 1,
      vecesFallada: map['veces_fallada'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  String opcionPorLetra(String letra) {
    return switch (letra) {
      'a' => opcionA,
      'b' => opcionB,
      'c' => opcionC,
      'd' => opcionD,
      _ => '',
    };
  }

  bool esCorrecta(String respuesta) => respuesta == respuestaCorrecta;
}
