import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/repositories/oposiciones_repository.dart';
import '../../providers/oposiciones_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';

class OposicionesScreen extends ConsumerWidget {
  const OposicionesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final oposicionesAsync = ref.watch(oposicionesConEstadoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.todasLasOposiciones),
        actions: [
          IconButton(
            tooltip: 'Cobertura oficial',
            icon: const Icon(Icons.public_rounded),
            onPressed: () => context.push(AppRoutes.cobertura),
          ),
        ],
      ),
      body: oposicionesAsync.when(
        data: (oposiciones) {
          if (oposiciones.isEmpty) {
            return const _EstadoVacioOposiciones();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: oposiciones.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final op = oposiciones[index].oposicion;
              final estado = oposiciones[index].estado;
              return _TarjetaOposicion(
                nombre: op.nombre,
                cuerpo: op.cuerpo,
                administracion: op.administracion,
                nivel: op.nivel,
                tienePsicotecnicos: op.tienePsicotecnicos,
                tienePruebasFisicas: op.tienePruebasFisicas,
                estado: estado,
                onTap:
                    () => context.push(
                      AppRoutes.oposicionDetail.replaceFirst(':id', op.id),
                    ),
              );
            },
          );
        },
        loading: () => const LoadingWidget(mensaje: 'Cargando oposiciones...'),
        error:
            (e, _) => AppErrorWidget(
              mensaje: e.toString(),
              onReintentar: () => ref.invalidate(oposicionesConEstadoProvider),
            ),
      ),
    );
  }
}

class _EstadoVacioOposiciones extends StatelessWidget {
  const _EstadoVacioOposiciones();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'Aún no hay oposiciones disponibles',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'El monitor oficial seguirá revisando BOE, boletines autonómicos y boletines provinciales.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaOposicion extends StatelessWidget {
  final String nombre;
  final String cuerpo;
  final String administracion;
  final String nivel;
  final bool tienePsicotecnicos;
  final bool tienePruebasFisicas;
  final EstadoInscripcion estado;
  final VoidCallback onTap;

  const _TarjetaOposicion({
    required this.nombre,
    required this.cuerpo,
    required this.administracion,
    required this.nivel,
    required this.tienePsicotecnicos,
    required this.tienePruebasFisicas,
    required this.estado,
    required this.onTap,
  });

  ({String label, Color color}) get _estadoChip {
    switch (estado) {
      case EstadoInscripcion.abierta:
        return (label: 'Inscripción abierta', color: AppColors.success);
      case EstadoInscripcion.proxima:
        return (label: 'Próxima', color: AppColors.warning);
      case EstadoInscripcion.cerrada:
        return (label: 'Inscripción cerrada', color: AppColors.textTertiary);
      case EstadoInscripcion.sinConvocatoria:
        return (label: 'Sin convocatoria', color: AppColors.textTertiary);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.gavel_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombre,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          cuerpo,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _Chip(label: _estadoChip.label, color: _estadoChip.color),
                  _Chip(label: administracion, color: AppColors.primaryLight),
                  _Chip(label: 'Grupo $nivel', color: AppColors.secondary),
                  if (tienePsicotecnicos)
                    _Chip(label: 'Psicotécnicos', color: AppColors.warning),
                  if (tienePruebasFisicas)
                    _Chip(label: 'Pruebas físicas', color: AppColors.success),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
