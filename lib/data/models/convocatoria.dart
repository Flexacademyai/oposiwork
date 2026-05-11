class Convocatoria {
  final String id;
  final String oposicionId;
  final DateTime? fechaPublicacionBoe;
  final DateTime? fechaInicioInstancias;
  final DateTime? fechaFinInstancias;
  final DateTime? fechaExamen;
  final bool fechaExamenConfirmada;
  final int? plazas;
  final String estado;
  final String? urlBoe;
  final String? notas;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Convocatoria({
    required this.id,
    required this.oposicionId,
    this.fechaPublicacionBoe,
    this.fechaInicioInstancias,
    this.fechaFinInstancias,
    this.fechaExamen,
    required this.fechaExamenConfirmada,
    this.plazas,
    required this.estado,
    this.urlBoe,
    this.notas,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Convocatoria.fromMap(Map<String, dynamic> map) {
    return Convocatoria(
      id: map['id'] as String,
      oposicionId: map['oposicion_id'] as String,
      fechaPublicacionBoe: map['fecha_publicacion_boe'] != null
          ? DateTime.parse(map['fecha_publicacion_boe'] as String)
          : null,
      fechaInicioInstancias: map['fecha_inicio_instancias'] != null
          ? DateTime.parse(map['fecha_inicio_instancias'] as String)
          : null,
      fechaFinInstancias: map['fecha_fin_instancias'] != null
          ? DateTime.parse(map['fecha_fin_instancias'] as String)
          : null,
      fechaExamen: map['fecha_examen'] != null
          ? DateTime.parse(map['fecha_examen'] as String)
          : null,
      fechaExamenConfirmada: map['fecha_examen_confirmada'] as bool? ?? false,
      plazas: map['plazas'] as int?,
      estado: map['estado'] as String? ?? 'abierta',
      urlBoe: map['url_boe'] as String?,
      notas: map['notas'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  bool get estaAbierta => estado == 'abierta';
  bool get estaProxima => estado == 'proxima';
  bool get estaCerrada => estado == 'cerrada' || estado == 'suspendida';

  bool get instanciasAbiertas {
    if (fechaInicioInstancias == null || fechaFinInstancias == null) return false;
    final ahora = DateTime.now();
    return ahora.isAfter(fechaInicioInstancias!) && ahora.isBefore(fechaFinInstancias!);
  }

  int? get diasParaExamen {
    if (fechaExamen == null) return null;
    return fechaExamen!.difference(DateTime.now()).inDays;
  }
}
