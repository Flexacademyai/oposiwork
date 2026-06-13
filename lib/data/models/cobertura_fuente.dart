class ResumenCobertura {
  final int fuentesTotales;
  final int fuentesActivas;
  final int fuentesNacionales;
  final int fuentesAutonomicas;
  final int fuentesProvinciales;
  final int convocatoriasTotales;
  final int convocatoriasAbiertas;
  final int convocatoriasInscripcionAbierta;
  final int fuentesAuditadas;
  final int fuentesOk;
  final int fuentesSinResultados;
  final int fuentesConError;
  final DateTime? ultimaAuditoria;

  const ResumenCobertura({
    required this.fuentesTotales,
    required this.fuentesActivas,
    required this.fuentesNacionales,
    required this.fuentesAutonomicas,
    required this.fuentesProvinciales,
    required this.convocatoriasTotales,
    required this.convocatoriasAbiertas,
    required this.convocatoriasInscripcionAbierta,
    required this.fuentesAuditadas,
    required this.fuentesOk,
    required this.fuentesSinResultados,
    required this.fuentesConError,
    required this.ultimaAuditoria,
  });

  int get fuentesPendientesAuditoria {
    final pendientes = fuentesActivas - fuentesAuditadas;
    return pendientes < 0 ? 0 : pendientes;
  }

  bool get coberturaVerificada {
    return fuentesActivas > 0 &&
        fuentesPendientesAuditoria == 0 &&
        fuentesConError == 0;
  }
}

class FuenteCobertura {
  final String nombre;
  final String ambito;
  final String? territorio;
  final String? url;
  final String tipo;
  final bool activa;
  final int prioridad;
  final String? estadoAuditoria;
  final int itemsDetectados;
  final String? error;
  final DateTime? ejecutadoEn;

  const FuenteCobertura({
    required this.nombre,
    required this.ambito,
    required this.territorio,
    required this.url,
    required this.tipo,
    required this.activa,
    required this.prioridad,
    required this.estadoAuditoria,
    required this.itemsDetectados,
    required this.error,
    required this.ejecutadoEn,
  });

  bool get requiereRevision {
    return activa &&
        (estadoAuditoria == null ||
            estadoAuditoria == 'error' ||
            estadoAuditoria == 'sin_resultados');
  }
}

