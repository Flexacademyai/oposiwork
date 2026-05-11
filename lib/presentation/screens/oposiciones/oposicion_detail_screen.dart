import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../providers/oposiciones_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../../data/models/convocatoria.dart';

class OposicionDetailScreen extends ConsumerWidget {
  final String oposicionId;

  const OposicionDetailScreen({super.key, required this.oposicionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final oposicionAsync = ref.watch(oposicionProvider(oposicionId));
    final convocatoriaAsync = ref.watch(convocatoriaActualProvider(oposicionId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: oposicionAsync.when(
        data: (oposicion) {
          if (oposicion == null) {
            return const AppErrorWidget(mensaje: 'Oposición no encontrada');
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCabecera(context, oposicion.nombre, oposicion.cuerpo),
                const SizedBox(height: 24),
                convocatoriaAsync.when(
                  data: (conv) => conv != null
                      ? _buildConvocatoria(context, conv)
                      : _buildSinConvocatoria(context),
                  loading: () => const LoadingWidget(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),
                _buildAccionesPremium(context, oposicionId),
              ],
            ),
          );
        },
        loading: () => const LoadingWidget(),
        error: (e, _) => AppErrorWidget(mensaje: e.toString()),
      ),
    );
  }

  Widget _buildCabecera(BuildContext context, String nombre, String cuerpo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.gavel_rounded, size: 36, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Text(nombre, style: Theme.of(context).textTheme.headlineMedium),
        Text(
          cuerpo,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildConvocatoria(BuildContext context, Convocatoria conv) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  AppStrings.convocatoriaActual,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                _BadgeEstado(estado: conv.estado),
              ],
            ),
            const Divider(height: 24),
            if (conv.plazas != null)
              _InfoRow(
                icono: Icons.people_outline_rounded,
                etiqueta: AppStrings.plazas,
                valor: '${conv.plazas}',
              ),
            if (conv.fechaFinInstancias != null)
              _InfoRow(
                icono: Icons.calendar_today_outlined,
                etiqueta: AppStrings.instanciasHasta,
                valor: _formatearFecha(conv.fechaFinInstancias!),
              ),
            if (conv.fechaExamen != null)
              _InfoRow(
                icono: Icons.event_rounded,
                etiqueta: AppStrings.fechaExamen,
                valor: _formatearFecha(conv.fechaExamen!),
                destacar: true,
              ),
            if (conv.urlBoe != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => launchUrl(Uri.parse(conv.urlBoe!)),
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('Ver en BOE'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 40),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSinConvocatoria(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.textTertiary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No hay convocatoria abierta actualmente',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccionesPremium(BuildContext context, String id) {
    final acciones = [
      (
        icono: Icons.menu_book_rounded,
        titulo: 'Temario',
        subtitulo: 'Resúmenes y esquemas',
        ruta: AppRoutes.temario.replaceFirst(':id', id),
        premium: true,
      ),
      (
        icono: Icons.style_rounded,
        titulo: 'Flashcards',
        subtitulo: 'Repaso espaciado',
        ruta: AppRoutes.flashcards.replaceFirst(':id', id),
        premium: true,
      ),
      (
        icono: Icons.quiz_rounded,
        titulo: 'Tests',
        subtitulo: 'Simulacros de examen',
        ruta: AppRoutes.test.replaceFirst(':id', id),
        premium: true,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Herramientas de estudio',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        ...acciones.map(
          (a) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(a.icono, color: AppColors.primary),
                ),
                title: Text(a.titulo),
                subtitle: Text(a.subtitulo),
                trailing: a.premium
                    ? const Icon(Icons.lock_rounded, color: AppColors.premium, size: 20)
                    : const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () => context.push(a.ruta),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year}';
  }
}

class _BadgeEstado extends StatelessWidget {
  final String estado;

  const _BadgeEstado({required this.estado});

  @override
  Widget build(BuildContext context) {
    final (color, texto) = switch (estado) {
      'abierta' => (AppColors.success, AppStrings.abierta),
      'proxima' => (AppColors.info, AppStrings.proxima),
      'cerrada' => (AppColors.textTertiary, AppStrings.cerrada),
      'suspendida' => (AppColors.error, AppStrings.suspendida),
      _ => (AppColors.textTertiary, estado),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;
  final bool destacar;

  const _InfoRow({
    required this.icono,
    required this.etiqueta,
    required this.valor,
    this.destacar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icono, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            '$etiqueta: ',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            valor,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: destacar ? FontWeight.w600 : FontWeight.w400,
              color: destacar ? AppColors.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}
