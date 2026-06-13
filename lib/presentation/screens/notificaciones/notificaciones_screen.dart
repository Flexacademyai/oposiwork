import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/loading_widget.dart';

final notificacionesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      return Supabase.instance.client
          .from('notificacion_destinatarios')
          .select('''
            id,
            canal,
            estado,
            enviada_en,
            leida_en,
            created_at,
            notificaciones_convocatoria (
              id,
              tipo,
              titulo,
              mensaje,
              created_at,
              convocatoria_id,
              convocatorias (
                oposicion_id
              )
            )
          ''')
          .eq('canal', 'in_app')
          .order('created_at', ascending: false)
          .limit(50);
    });

class NotificacionesScreen extends ConsumerWidget {
  const NotificacionesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificacionesAsync = ref.watch(notificacionesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Avisos'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(notificacionesProvider),
          ),
        ],
      ),
      body: notificacionesAsync.when(
        loading: () => const LoadingWidget(mensaje: 'Cargando avisos...'),
        error:
            (_, __) => AppErrorWidget(
              mensaje: 'No se han podido cargar los avisos',
              onReintentar: () => ref.invalidate(notificacionesProvider),
            ),
        data: (notificaciones) {
          if (notificaciones.isEmpty) return const _EstadoVacio();

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: notificaciones.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final row = notificaciones[index];
              final aviso =
                  row['notificaciones_convocatoria'] as Map<String, dynamic>?;
              final convocatoria =
                  aviso?['convocatorias'] as Map<String, dynamic>?;
              final oposicionId = convocatoria?['oposicion_id']?.toString();
              return _AvisoCard(
                id: row['id'] as String,
                titulo: aviso?['titulo'] as String? ?? 'Aviso de convocatoria',
                mensaje: aviso?['mensaje'] as String? ?? '',
                tipo: aviso?['tipo'] as String? ?? '',
                leido: row['leida_en'] != null,
                onAbrir:
                    oposicionId == null
                        ? null
                        : () => context.push(
                          AppRoutes.oposicionDetail.replaceFirst(
                            ':id',
                            oposicionId,
                          ),
                        ),
                onLeido: () async {
                  await Supabase.instance.client
                      .from('notificacion_destinatarios')
                      .update({'leida_en': DateTime.now().toIso8601String()})
                      .eq('id', row['id'] as String);
                  ref.invalidate(notificacionesProvider);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _AvisoCard extends StatelessWidget {
  const _AvisoCard({
    required this.id,
    required this.titulo,
    required this.mensaje,
    required this.tipo,
    required this.leido,
    required this.onAbrir,
    required this.onLeido,
  });

  final String id;
  final String titulo;
  final String mensaje;
  final String tipo;
  final bool leido;
  final VoidCallback? onAbrir;
  final VoidCallback onLeido;

  @override
  Widget build(BuildContext context) {
    final color = switch (tipo) {
      'nueva_convocatoria' => AppColors.success,
      'convocatoria_cerrada' => AppColors.warning,
      'cambio_convocatoria' => AppColors.primary,
      _ => AppColors.textSecondary,
    };

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(30),
          child: Icon(Icons.campaign_rounded, color: color),
        ),
        title: Text(
          titulo,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: leido ? FontWeight.w500 : FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(mensaje),
        ),
        onTap: onAbrir,
        trailing:
            leido
                ? const Icon(Icons.done_rounded, color: AppColors.textTertiary)
                : IconButton(
                  tooltip: 'Marcar como leido',
                  icon: const Icon(Icons.mark_email_read_outlined),
                  onPressed: onLeido,
                ),
      ),
    );
  }
}

class _EstadoVacio extends StatelessWidget {
  const _EstadoVacio();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 64,
              color: AppColors.textTertiary.withAlpha(180),
            ),
            const SizedBox(height: 16),
            Text('Sin avisos', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Aqui apareceran nuevas convocatorias, cambios de plazo y cierres.',
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
