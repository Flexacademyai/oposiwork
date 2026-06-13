class Supuesto {
  final String id;
  final String oposicionId;
  final String? temaId;
  final String titulo;
  final String enunciado;
  final String solucion;
  final List<String> normativaAplicable;
  final int dificultad;
  final DateTime createdAt;

  const Supuesto({
    required this.id,
    required this.oposicionId,
    this.temaId,
    required this.titulo,
    required this.enunciado,
    required this.solucion,
    required this.normativaAplicable,
    required this.dificultad,
    required this.createdAt,
  });

  factory Supuesto.fromMap(Map<String, dynamic> map) {
    return Supuesto(
      id: map['id'] as String,
      oposicionId: map['oposicion_id'] as String,
      temaId: map['tema_id'] as String?,
      titulo: map['titulo'] as String,
      enunciado: map['enunciado'] as String,
      solucion: map['solucion'] as String,
      normativaAplicable:
          (map['normativa_aplicable'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toList(),
      dificultad: map['dificultad'] as int? ?? 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
