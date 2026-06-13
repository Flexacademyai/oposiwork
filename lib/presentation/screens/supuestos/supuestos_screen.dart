import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/supuesto.dart';
import '../../../data/repositories/contenido_repository.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/premium_lock_widget.dart';

final _supuestosProvider = FutureProvider.autoDispose
    .family<List<Supuesto>, String>((ref, oposicionId) async {
      final supabase = ref.watch(supabaseClientProvider);
      return ContenidoRepository(
        supabase,
      ).obtenerSupuestosPorOposicion(oposicionId);
    });

class SupuestosScreen extends ConsumerWidget {
  const SupuestosScreen({super.key, required this.oposicionId});

  final String oposicionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_supuestosProvider(oposicionId));

    return Scaffold(
      appBar: AppBar(title: const Text('Supuestos practicos')),
      body: Stack(
        children: [
          async.when(
            data: (supuestos) {
              if (supuestos.isEmpty) {
                return const Center(
                  child: Text('No hay supuestos disponibles aun'),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: supuestos.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _SupuestoCard(supuesto: supuestos[index]);
                },
              );
            },
            loading: () => const LoadingWidget(),
            error: (error, _) => AppErrorWidget(mensaje: error.toString()),
          ),
          PremiumLockWidget(child: const SizedBox.expand()),
        ],
      ),
    );
  }
}

class _SupuestoCard extends StatefulWidget {
  const _SupuestoCard({required this.supuesto});

  final Supuesto supuesto;

  @override
  State<_SupuestoCard> createState() => _SupuestoCardState();
}

class _SupuestoCardState extends State<_SupuestoCard> {
  bool _mostrarSolucion = false;

  @override
  Widget build(BuildContext context) {
    final supuesto = widget.supuesto;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.assignment_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        supuesto.titulo,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dificultad ${supuesto.dificultad}/5',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              supuesto.enunciado,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            if (supuesto.normativaAplicable.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    supuesto.normativaAplicable
                        .map(
                          (n) => Chip(
                            label: Text(n),
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                        .toList(),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() => _mostrarSolucion = !_mostrarSolucion);
                },
                icon: Icon(
                  _mostrarSolucion
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                ),
                label: Text(
                  _mostrarSolucion ? 'Ocultar solucion' : 'Ver solucion',
                ),
              ),
            ),
            if (_mostrarSolucion) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.success.withAlpha(80)),
                ),
                child: Text(
                  supuesto.solucion,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
