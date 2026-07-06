class Perfil {
  final String id;
  final String? nombre;
  final String? apellidos;
  final String? avatarUrl;
  final String plan;
  final DateTime? planInicio;
  final DateTime? planFin;
  final String? revenuecatId;
  final bool notificacionesPush;
  final bool notificacionesEmail;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Perfil({
    required this.id,
    this.nombre,
    this.apellidos,
    this.avatarUrl,
    required this.plan,
    this.planInicio,
    this.planFin,
    this.revenuecatId,
    required this.notificacionesPush,
    required this.notificacionesEmail,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Perfil.fromMap(Map<String, dynamic> map) {
    return Perfil(
      id: map['id'] as String,
      nombre: map['nombre'] as String?,
      apellidos: map['apellidos'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      plan: map['plan'] as String? ?? 'free',
      planInicio:
          map['plan_inicio'] != null
              ? DateTime.parse(map['plan_inicio'] as String)
              : null,
      planFin:
          map['plan_fin'] != null
              ? DateTime.parse(map['plan_fin'] as String)
              : null,
      revenuecatId: map['revenuecat_id'] as String?,
      notificacionesPush: map['notificaciones_push'] as bool? ?? true,
      notificacionesEmail: map['notificaciones_email'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  bool get esPremium {
    if (plan == 'free') return false;
    if (planFin == null) return false;
    return planFin!.isAfter(DateTime.now());
  }

  String get nombreCompleto {
    if (nombre == null && apellidos == null) return 'Usuario';
    return [nombre, apellidos].where((e) => e != null).join(' ');
  }
}
