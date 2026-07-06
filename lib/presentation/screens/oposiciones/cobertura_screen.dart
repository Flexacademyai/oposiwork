import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/cobertura_fuente.dart';
import '../../providers/oposiciones_provider.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/loading_widget.dart';

class CoberturaScreen extends ConsumerWidget {
  const CoberturaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumenAsync = ref.watch(resumenCoberturaProvider);
    final fuentesAsync = ref.watch(fuentesCoberturaProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cobertura oficial')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(resumenCoberturaProvider);
          ref.invalidate(fuentesCoberturaProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            resumenAsync.when(
              data: (resumen) => _ResumenCoberturaCard(resumen: resumen),
              loading:
                  () =>
                      const LoadingWidget(mensaje: 'Comprobando cobertura...'),
              error:
                  (e, _) => AppErrorWidget(
                    mensaje: e.toString(),
                    onReintentar:
                        () => ref.invalidate(resumenCoberturaProvider),
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Fuentes monitorizadas',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            fuentesAsync.when(
              data:
                  (fuentes) => Column(
                    children:
                        fuentes
                            .map(
                              (fuente) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _FuenteCard(fuente: fuente),
                              ),
                            )
                            .toList(),
                  ),
              loading:
                  () => const LoadingWidget(mensaje: 'Cargando fuentes...'),
              error:
                  (e, _) => AppErrorWidget(
                    mensaje: e.toString(),
                    onReintentar:
                        () => ref.invalidate(fuentesCoberturaProvider),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumenCoberturaCard extends StatelessWidget {
  final ResumenCobertura resumen;

  const _ResumenCoberturaCard({required this.resumen});

  @override
  Widget build(BuildContext context) {
    final estadoColor =
        resumen.coberturaVerificada
            ? AppColors.success
            : resumen.fuentesConError > 0
            ? AppColors.error
            : AppColors.warning;
    final estadoTexto =
        resumen.coberturaVerificada
            ? 'Cobertura auditada'
            : 'Cobertura en revision';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.public_rounded, color: estadoColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    estadoTexto,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                _Badge(
                  texto: '${resumen.fuentesActivas} fuentes',
                  color: estadoColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'La app solo debe prometer cobertura nacional completa cuando todas las fuentes activas hayan sido auditadas sin errores recientes.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetricChip(
                  label: 'Nacionales',
                  value: resumen.fuentesNacionales,
                ),
                _MetricChip(
                  label: 'Autonomicas',
                  value: resumen.fuentesAutonomicas,
                ),
                _MetricChip(
                  label: 'Provinciales',
                  value: resumen.fuentesProvinciales,
                ),
                _MetricChip(
                  label: 'Convocatorias abiertas',
                  value: resumen.convocatoriasInscripcionAbierta,
                ),
                _MetricChip(label: 'Fuentes OK', value: resumen.fuentesOk),
                _MetricChip(
                  label: 'Sin resultados',
                  value: resumen.fuentesSinResultados,
                ),
                _MetricChip(label: 'Errores', value: resumen.fuentesConError),
                _MetricChip(
                  label: 'Pendientes',
                  value: resumen.fuentesPendientesAuditoria,
                ),
              ],
            ),
            if (resumen.ultimaAuditoria != null) ...[
              const SizedBox(height: 12),
              Text(
                'Ultima auditoria: ${_formatDateTime(resumen.ultimaAuditoria!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}

class _FuenteCard extends StatelessWidget {
  final FuenteCobertura fuente;

  const _FuenteCard({required this.fuente});

  @override
  Widget build(BuildContext context) {
    final color = switch (fuente.estadoAuditoria) {
      'ok' => AppColors.success,
      'error' => AppColors.error,
      'sin_resultados' => AppColors.warning,
      _ => AppColors.textTertiary,
    };
    final estado = fuente.estadoAuditoria ?? 'pendiente';

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(30),
          child: Icon(Icons.feed_rounded, color: color),
        ),
        title: Text(fuente.nombre),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${fuente.ambito} · ${fuente.territorio ?? 'Sin territorio'} · ${fuente.tipo}',
            ),
            Text(
              'Estado: $estado · Items: ${fuente.itemsDetectados}',
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
            if (fuente.error != null && fuente.error!.isNotEmpty)
              Text(
                fuente.error!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.error),
              ),
          ],
        ),
        trailing:
            fuente.url == null
                ? null
                : IconButton(
                  tooltip: 'Abrir fuente oficial',
                  icon: const Icon(Icons.open_in_new_rounded),
                  onPressed: () => launchUrl(Uri.parse(fuente.url!)),
                ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final int value;

  const _MetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withAlpha(24),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String texto;
  final Color color;

  const _Badge({required this.texto, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        texto,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
