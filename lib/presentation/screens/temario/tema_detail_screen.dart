import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/contenido_repository.dart';
import '../../../data/repositories/progreso_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/suscripcion_provider.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/premium_lock_widget.dart';

final _contenidoProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, (String, String)>((ref, args) async {
      final supabase = ref.watch(supabaseClientProvider);
      return ContenidoRepository(
        supabase,
      ).obtenerContenidoTema(args.$1, args.$2);
    });

class TemaDetailScreen extends ConsumerStatefulWidget {
  const TemaDetailScreen({
    super.key,
    required this.oposicionId,
    required this.temaId,
  });

  final String oposicionId;
  final String temaId;

  @override
  ConsumerState<TemaDetailScreen> createState() => _TemaDetailScreenState();
}

class _TemaDetailScreenState extends ConsumerState<TemaDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _guardandoProgreso = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resumenAsync = ref.watch(
      _contenidoProvider((widget.temaId, 'resumen')),
    );
    final esPremiumLocal = ref.watch(esPremiumProvider);
    final esPremium = ref
        .watch(tieneEntitlementPremiumProvider)
        .when(
          data: (value) => value || esPremiumLocal,
          loading: () => esPremiumLocal,
          error: (_, __) => esPremiumLocal,
        );

    return Scaffold(
      appBar: AppBar(
        title: resumenAsync.when(
          data: (data) {
            final titulo = data?['contenido']?['titulo'] as String?;
            return Text(
              titulo ?? 'Tema',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          },
          loading: () => const Text('Cargando...'),
          error: (_, __) => const Text('Tema'),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Resumen'),
            Tab(text: 'Artículos'),
            Tab(text: 'Conceptos'),
          ],
        ),
      ),
      floatingActionButton:
          esPremium
              ? FloatingActionButton.extended(
                onPressed: _guardandoProgreso ? null : _marcarTemaCompletado,
                icon:
                    _guardandoProgreso
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.check_rounded),
                label: const Text('Completado'),
              )
              : null,
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _TabResumen(temaId: widget.temaId),
              _TabArticulos(temaId: widget.temaId),
              _TabConceptos(temaId: widget.temaId),
            ],
          ),
          PremiumLockWidget(child: const SizedBox.expand()),
        ],
      ),
    );
  }

  Future<void> _marcarTemaCompletado() async {
    final userId = ref.read(usuarioActualProvider)?.id;
    if (userId == null) return;
    setState(() => _guardandoProgreso = true);
    try {
      final repo = ProgresoRepository(ref.read(supabaseClientProvider));
      await repo.actualizarProgresoTema(
        userId: userId,
        temaId: widget.temaId,
        porcentaje: 100,
        tiempoMinutos: 10,
      );
      await repo.iniciarSesionEstudio(
        userId: userId,
        oposicionId: widget.oposicionId,
        tipoActividad: 'temario',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tema marcado como completado')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se ha podido guardar el progreso')),
      );
    } finally {
      if (mounted) setState(() => _guardandoProgreso = false);
    }
  }
}

class _TabResumen extends ConsumerWidget {
  const _TabResumen({required this.temaId});
  final String temaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_contenidoProvider((temaId, 'resumen')));
    return async.when(
      data: (data) {
        if (data == null) return _sinContenido('resumen');
        final resumen = data['contenido']?['resumen'] as String? ?? '';
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                resumen,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.7,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const LoadingWidget(),
      error: (e, _) => AppErrorWidget(mensaje: e.toString()),
    );
  }
}

class _TabArticulos extends ConsumerWidget {
  const _TabArticulos({required this.temaId});
  final String temaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_contenidoProvider((temaId, 'resumen')));
    return async.when(
      data: (data) {
        if (data == null) return _sinContenido('artículos');
        final articulos =
            (data['contenido']?['articulos_clave'] as List?) ?? [];
        if (articulos.isEmpty) return _sinContenido('artículos');
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: articulos.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final art = articulos[i] as Map<String, dynamic>;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            art['articulo'] as String? ?? '',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            art['ley'] as String? ?? '',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      art['contenido'] as String? ?? '',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const LoadingWidget(),
      error: (e, _) => AppErrorWidget(mensaje: e.toString()),
    );
  }
}

class _TabConceptos extends ConsumerWidget {
  const _TabConceptos({required this.temaId});
  final String temaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_contenidoProvider((temaId, 'resumen')));
    return async.when(
      data: (data) {
        if (data == null) return _sinContenido('conceptos');
        final conceptos = (data['contenido']?['conceptos'] as List?) ?? [];
        if (conceptos.isEmpty) return _sinContenido('conceptos');
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: conceptos.length,
          itemBuilder: (context, i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        conceptos[i] as String? ?? '',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(height: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const LoadingWidget(),
      error: (e, _) => AppErrorWidget(mensaje: e.toString()),
    );
  }
}

Widget _sinContenido(String tipo) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.hourglass_empty_rounded,
          size: 48,
          color: AppColors.textTertiary,
        ),
        const SizedBox(height: 12),
        Text('No hay $tipo disponibles aún'),
      ],
    ),
  );
}
