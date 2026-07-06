class Flashcard {
  final String id;
  final String temaId;
  final String pregunta;
  final String respuesta;
  final String? articuloReferencia;
  final int dificultad;
  final DateTime createdAt;
  // Campos SM-2 para repaso espaciado
  final int intervalo;
  final int repeticion;
  final double facilidad;
  final DateTime proximaRevision;

  const Flashcard({
    required this.id,
    required this.temaId,
    required this.pregunta,
    required this.respuesta,
    this.articuloReferencia,
    required this.dificultad,
    required this.createdAt,
    this.intervalo = 1,
    this.repeticion = 0,
    this.facilidad = 2.5,
    required this.proximaRevision,
  });

  factory Flashcard.fromMap(Map<String, dynamic> map) {
    return Flashcard(
      id: map['id'] as String,
      temaId: map['tema_id'] as String,
      pregunta: map['pregunta'] as String,
      respuesta: map['respuesta'] as String,
      articuloReferencia: map['articulo_referencia'] as String?,
      dificultad: map['dificultad'] as int? ?? 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      intervalo: map['intervalo'] as int? ?? 1,
      repeticion: map['repeticion'] as int? ?? 0,
      facilidad: (map['facilidad'] as num?)?.toDouble() ?? 2.5,
      proximaRevision:
          map['proxima_revision'] != null
              ? DateTime.parse(map['proxima_revision'] as String)
              : DateTime.now(),
    );
  }

  /// SM-2: calificacion 0=mal, 1=difícil, 2=correcto, 3=fácil
  Flashcard calcularSiguienteRevision(int calificacion) {
    double nuevaFacilidad =
        facilidad +
        (0.1 - (3 - calificacion) * (0.08 + (3 - calificacion) * 0.02));
    nuevaFacilidad = nuevaFacilidad.clamp(1.3, 2.5);

    int nuevoIntervalo;
    int nuevaRepeticion;

    if (calificacion < 2) {
      nuevoIntervalo = 1;
      nuevaRepeticion = 0;
    } else {
      nuevaRepeticion = repeticion + 1;
      nuevoIntervalo = switch (nuevaRepeticion) {
        1 => 1,
        2 => 6,
        _ => (intervalo * nuevaFacilidad).round(),
      };
    }

    return copyWith(
      intervalo: nuevoIntervalo,
      repeticion: nuevaRepeticion,
      facilidad: nuevaFacilidad,
      proximaRevision: DateTime.now().add(Duration(days: nuevoIntervalo)),
    );
  }

  /// Compatibilidad — convierte bool a calificacion SM-2
  Flashcard calcularProximaRevision(bool sabia) =>
      calcularSiguienteRevision(sabia ? 2 : 0);

  Flashcard copyWith({
    String? id,
    String? temaId,
    String? pregunta,
    String? respuesta,
    String? articuloReferencia,
    int? dificultad,
    DateTime? createdAt,
    int? intervalo,
    int? repeticion,
    double? facilidad,
    DateTime? proximaRevision,
  }) {
    return Flashcard(
      id: id ?? this.id,
      temaId: temaId ?? this.temaId,
      pregunta: pregunta ?? this.pregunta,
      respuesta: respuesta ?? this.respuesta,
      articuloReferencia: articuloReferencia ?? this.articuloReferencia,
      dificultad: dificultad ?? this.dificultad,
      createdAt: createdAt ?? this.createdAt,
      intervalo: intervalo ?? this.intervalo,
      repeticion: repeticion ?? this.repeticion,
      facilidad: facilidad ?? this.facilidad,
      proximaRevision: proximaRevision ?? this.proximaRevision,
    );
  }
}
