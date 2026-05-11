import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/tema.dart';
import '../../../data/models/temario_pdf.dart';
import '../../../data/repositories/contenido_repository.dart';
import '../../../data/repositories/progreso_repository.dart';
import '../../../data/services/storage_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/premium_lock_widget.dart';

final _temasProvider = FutureProvider.autoDispose.family<List<Tema>, String>((
  ref,
  oposicionId,
) async {
  final supabase = ref.watch(supabaseClientProvider);
  return ContenidoRepository(supabase).obtenerTemas(oposicionId);
});

final _progresoOposicionProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, oposicionId) async {
      final supabase = ref.watch(supabaseClientProvider);
      final user = supabase.auth.currentUser;
      if (user == null) return [];
      return ProgresoRepository(
        supabase,
      ).obtenerProgresoOposicion(user.id, oposicionId);
    });

final _pdfsTemarioProvider = FutureProvider.autoDispose
    .family<List<TemarioPdf>, String>((ref, oposicionId) async {
      final supabase = ref.watch(supabaseClientProvider);
      return ContenidoRepository(supabase).obtenerPdfsTemario(oposicionId);
    });

class TemarioScreen extends ConsumerStatefulWidget {
  const TemarioScreen({super.key, required this.oposicionId});

  final String oposicionId;

  @override
  ConsumerState<TemarioScreen> createState() => _TemarioScreenState();
}

class _TemarioScreenState extends ConsumerState<TemarioScreen> {
  bool _descargandoPdf = false;

  @override
  Widget build(BuildContext context) {
    final temasAsync = ref.watch(_temasProvider(widget.oposicionId));
    final progresoAsync = ref.watch(
      _progresoOposicionProvider(widget.oposicionId),
    );
    final pdfsAsync = ref.watch(_pdfsTemarioProvider(widget.oposicionId));

    return Scaffold(
      appBar: AppBar(title: const Text('Temario')),
      body: Stack(
        children: [
          temasAsync.when(
            data: (temas) {
              final progresoMap = _buildProgresoMap(
                progresoAsync.valueOrNull ?? [],
              );
              return _buildContenido(context, temas, progresoMap, pdfsAsync);
            },
            loading: () => const LoadingWidget(),
            error: (e, _) => AppErrorWidget(mensaje: e.toString()),
          ),
          PremiumLockWidget(child: const SizedBox.expand()),
        ],
      ),
    );
  }

  Map<String, int> _buildProgresoMap(List<Map<String, dynamic>> progreso) {
    final map = <String, int>{};
    for (final p in progreso) {
      map[p['tema_id'] as String] = p['porcentaje_completado'] as int? ?? 0;
    }
    return map;
  }

  Widget _buildContenido(
    BuildContext context,
    List<Tema> temas,
    Map<String, int> progresoMap,
    AsyncValue<List<TemarioPdf>> pdfsAsync,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        pdfsAsync.when(
          data: (pdfs) => _buildDescargasPdf(context, pdfs),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        if (temas.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 96),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    size: 64,
                    color: AppColors.textTertiary,
                  ),
                  SizedBox(height: 16),
                  Text('No hay temas disponibles aún'),
                ],
              ),
            ),
          )
        else
          ..._buildTemaItems(context, temas, progresoMap),
      ],
    );
  }

  Widget _buildDescargasPdf(BuildContext context, List<TemarioPdf> pdfs) {
    if (pdfs.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: AppColors.error,
                ),
                const SizedBox(width: 8),
                Text(
                  'PDF oficial',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'La descarga se permite una sola vez por PDF y usuario.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            ...pdfs.map(
              (pdf) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton.icon(
                  onPressed:
                      _descargandoPdf ? null : () => _descargarPdf(pdf.id),
                  icon:
                      _descargandoPdf
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.download_rounded, size: 18),
                  label: Text(pdf.nombre),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _descargarPdf(String pdfId) async {
    setState(() => _descargandoPdf = true);
    try {
      final supabase = ref.read(supabaseClientProvider);
      final descarga = await StorageService(supabase).crearDescargaPdf(pdfId);
      final uri = Uri.parse(descarga.url);
      final abierto = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!abierto) {
        throw Exception('No se pudo abrir la URL de descarga.');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _descargandoPdf = false);
    }
  }

  List<Widget> _buildTemaItems(
    BuildContext context,
    List<Tema> temas,
    Map<String, int> progresoMap,
  ) {
    String? bloqueActual;
    final items = <Widget>[];

    for (var index = 0; index < temas.length; index++) {
      final tema = temas[index];
      final porcentaje = progresoMap[tema.id] ?? 0;
      final widgets = <Widget>[];

      if (tema.bloque != null && tema.bloque != bloqueActual) {
        bloqueActual = tema.bloque;
        widgets.add(
          Padding(
            padding: EdgeInsets.only(top: index == 0 ? 0 : 16, bottom: 8),
            child: Text(
              tema.bloque!,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      }

      widgets.add(
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              backgroundColor:
                  porcentaje == 100
                      ? AppColors.success.withAlpha(30)
                      : AppColors.primaryLight.withAlpha(30),
              child: Text(
                '${tema.numero}',
                style: TextStyle(
                  color:
                      porcentaje == 100 ? AppColors.success : AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            title: Text(
              tema.titulo,
              style: Theme.of(context).textTheme.titleSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle:
                porcentaje > 0
                    ? Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: LinearProgressIndicator(
                        value: porcentaje / 100,
                        backgroundColor: AppColors.border,
                        color:
                            porcentaje == 100
                                ? AppColors.success
                                : AppColors.primary,
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    )
                    : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (porcentaje > 0)
                  Text(
                    '$porcentaje%',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          porcentaje == 100
                              ? AppColors.success
                              : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
            onTap:
                () => context.push(
                  '/oposiciones/${widget.oposicionId}/temario/${tema.id}',
                ),
          ),
        ),
      );

      items.add(
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets),
      );
    }

    return items;
  }
}
