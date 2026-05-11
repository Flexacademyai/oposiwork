class TemarioPdf {
  final String id;
  final String oposicionId;
  final String nombre;
  final String storagePath;
  final String? version;
  final DateTime? fechaBoe;
  final bool activo;
  final DateTime createdAt;

  const TemarioPdf({
    required this.id,
    required this.oposicionId,
    required this.nombre,
    required this.storagePath,
    this.version,
    this.fechaBoe,
    required this.activo,
    required this.createdAt,
  });

  factory TemarioPdf.fromMap(Map<String, dynamic> map) {
    return TemarioPdf(
      id: map['id'] as String,
      oposicionId: map['oposicion_id'] as String,
      nombre: map['nombre'] as String,
      storagePath: map['storage_path'] as String,
      version: map['version'] as String?,
      fechaBoe:
          map['fecha_boe'] == null
              ? null
              : DateTime.parse(map['fecha_boe'] as String),
      activo: map['activo'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
