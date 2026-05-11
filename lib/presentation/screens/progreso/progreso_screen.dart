import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/progreso_repository.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/premium_lock_widget.dart';

final _progresoGlobalProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final user = supabase.auth.currentUser;
  if (user == null) return {};
  return ProgresoRepository(supabase).obtenerResumenProgreso(user.id);
});

class ProgresoScreen extends ConsumerWidget {
  const ProgresoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_progresoGlobalProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mi progreso')),
      body: Stack(
        children: [
          async.when(
            data: (datos) => _buildContenido(context, datos),
            loading: () => const LoadingWidget(),
            error: (e, _) => AppErrorWidget(mensaje: e.toString()),
          ),
          PremiumLockWidget(child: const SizedBox.expand()),
        ],
      ),
    );
  }

  Widget _buildContenido(BuildContext context, Map<String, dynamic> datos) {
    final rachaActual = datos['racha_actual'] as int? ?? 0;
    final temasTotales = datos['temas_totales'] as int? ?? 0;
    final temasCompletados = datos['temas_completados'] as int? ?? 0;
    final minutosEstudio = datos['minutos_totales'] as int? ?? 0;
    final puntosTotales = datos['puntos_totales'] as int? ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTarjetaRacha(context, rachaActual),
          const SizedBox(height: 16),
          Text('Resumen general', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMetrica(context, 'Temas', '$temasCompletados/$temasTotales', Icons.menu_book_outlined, AppColors.primary)),
              const SizedBox(width: 12),
              Expanded(child: _buildMetrica(context, 'Minutos', '$minutosEstudio', Icons.timer_outlined, AppColors.secondary)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMetrica(context, 'Puntos', '$puntosTotales', Icons.star_outline_rounded, Colors.amber)),
              const SizedBox(width: 12),
              Expanded(child: _buildMetrica(context, 'Racha', '${rachaActual}d', Icons.local_fire_department_outlined, Colors.orange)),
            ],
          ),
          const SizedBox(height: 24),
          if (temasTotales > 0) ...[
            Text('Progreso temario', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Temas completados'),
                        Text(
                          '$temasCompletados de $temasTotales',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: temasTotales > 0 ? temasCompletados / temasTotales : 0,
                      backgroundColor: AppColors.border,
                      color: AppColors.primary,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTarjetaRacha(BuildContext context, int racha) {
    return Card(
      color: racha >= 7 ? Colors.orange.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Text(
              racha >= 7 ? '🔥' : '📅',
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$racha días seguidos',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: racha >= 7 ? Colors.orange : AppColors.textPrimary,
                  ),
                ),
                Text(
                  racha == 0
                      ? 'Empieza hoy tu racha'
                      : racha >= 30
                          ? '¡Racha legendaria!'
                          : racha >= 7
                              ? '¡Semana perfecta!'
                              : 'Sigue así',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetrica(BuildContext context, String titulo, String valor, IconData icono, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              valor,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(titulo, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
