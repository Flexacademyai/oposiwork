class Tema {
  final String id;
  final String oposicionId;
  final int numero;
  final String titulo;
  final String? bloque;
  final int orden;
  final DateTime createdAt;

  const Tema({
    required this.id,
    required this.oposicionId,
    required this.numero,
    required this.titulo,
    this.bloque,
    required this.orden,
    required this.createdAt,
  });

  factory Tema.fromMap(Map<String, dynamic> map) {
    return Tema(
      id: map['id'] as String,
      oposicionId: map['oposicion_id'] as String,
      numero: map['numero'] as int,
      titulo: map['titulo'] as String,
      bloque: map['bloque'] as String?,
      orden: map['orden'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  String get tituloCompleto => 'Tema $numero. $titulo';
}
