class Oposicion {
  final String id;
  final String slug;
  final String nombre;
  final String cuerpo;
  final String administracion;
  final String nivel;

  /// Ámbito territorial: 'estatal', 'autonomico', 'provincial', 'local'
  /// o 'universidad'. Puede ser null en datos antiguos.
  final String? ambito;

  /// Territorio legible ('España', 'Galicia', 'Valencia'...). Null si no consta.
  final String? territorio;
  final bool tienePsicotecnicos;
  final bool tienePruebasFisicas;
  final bool activa;
  final DateTime createdAt;

  const Oposicion({
    required this.id,
    required this.slug,
    required this.nombre,
    required this.cuerpo,
    required this.administracion,
    required this.nivel,
    this.ambito,
    this.territorio,
    required this.tienePsicotecnicos,
    required this.tienePruebasFisicas,
    required this.activa,
    required this.createdAt,
  });

  factory Oposicion.fromMap(Map<String, dynamic> map) {
    return Oposicion(
      id: map['id'] as String,
      slug: map['slug'] as String,
      nombre: map['nombre'] as String,
      cuerpo: map['cuerpo'] as String,
      administracion: map['administracion'] as String,
      nivel: map['nivel'] as String,
      ambito: map['ambito'] as String?,
      territorio: map['territorio'] as String?,
      tienePsicotecnicos: map['tiene_psicotecnicos'] as bool? ?? false,
      tienePruebasFisicas: map['tiene_pruebas_fisicas'] as bool? ?? false,
      activa: map['activa'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'slug': slug,
      'nombre': nombre,
      'cuerpo': cuerpo,
      'administracion': administracion,
      'nivel': nivel,
      'ambito': ambito,
      'territorio': territorio,
      'tiene_psicotecnicos': tienePsicotecnicos,
      'tiene_pruebas_fisicas': tienePruebasFisicas,
      'activa': activa,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
