import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/premium_lock_widget.dart';

class PlanEstudioScreen extends ConsumerWidget {
  const PlanEstudioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfilAsync = ref.watch(perfilProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mi plan de estudio')),
      body: PremiumLockWidget(
        child: perfilAsync.when(
          loading: () => const LoadingWidget(mensaje: 'Cargando plan...'),
          error: (_, __) => const AppErrorWidget(mensaje: 'Error al cargar'),
          data:
              (perfil) =>
                  perfil == null
                      ? const Center(child: Text('No hay sesión activa'))
                      : _PlanContent(usuarioId: perfil.id),
        ),
      ),
    );
  }
}

class _PlanContent extends StatefulWidget {
  final String usuarioId;

  const _PlanContent({required this.usuarioId});

  @override
  State<_PlanContent> createState() => _PlanContentState();
}

class _PlanContentState extends State<_PlanContent> {
  Map<String, dynamic>? _datos;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final uoData =
          await Supabase.instance.client
              .from('usuario_oposiciones')
              .select(
                'oposicion_id, fecha_examen_objetivo, oposiciones(nombre, nivel)',
              )
              .eq('usuario_id', widget.usuarioId)
              .eq('activa', true)
              .limit(1)
              .maybeSingle();

      final progresoData = await Supabase.instance.client
          .from('progreso_temas')
          .select('tema_id, porcentaje_completado')
          .eq('usuario_id', widget.usuarioId);

      if (mounted) {
        setState(() {
          _datos = {'oposicion': uoData, 'progreso': progresoData as List};
          _cargando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const LoadingWidget(mensaje: 'Calculando tu plan...');

    final oposicion = _datos?['oposicion'];
    final progreso = (_datos?['progreso'] as List?) ?? [];

    final fechaExamen =
        oposicion?['fecha_examen_objetivo'] != null
            ? DateTime.tryParse(oposicion!['fecha_examen_objetivo'] as String)
            : null;
    final diasRestantes = fechaExamen?.difference(DateTime.now()).inDays;

    final temasTotal = progreso.length;
    final temasCompletados =
        progreso
            .where((p) => (p['porcentaje_completado'] as int? ?? 0) >= 100)
            .length;
    final temasPendientes = temasTotal - temasCompletados;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (oposicion != null) _buildHeaderOposicion(oposicion),
          const SizedBox(height: 16),
          if (diasRestantes != null && diasRestantes > 0) ...[
            _TarjetaDias(dias: diasRestantes),
            const SizedBox(height: 16),
          ],
          Text(
            'Progreso del temario',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatCard(
                valor: '$temasCompletados',
                label: 'Completados',
                color: AppColors.success,
              ),
              const SizedBox(width: 10),
              _StatCard(
                valor: '$temasPendientes',
                label: 'Pendientes',
                color: AppColors.warning,
              ),
              const SizedBox(width: 10),
              _StatCard(
                valor: '$temasTotal',
                label: 'Total temas',
                color: AppColors.info,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (temasTotal > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Avance global',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${((temasCompletados / temasTotal) * 100).round()}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: temasCompletados / temasTotal,
                backgroundColor: AppColors.border,
                color: AppColors.success,
                minHeight: 12,
              ),
            ),
            const SizedBox(height: 20),
          ],
          _buildRecomendacion(temasPendientes, diasRestantes),
          const SizedBox(height: 16),
          if (fechaExamen == null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.calendar_today_outlined),
                label: const Text('Configurar fecha de examen'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderOposicion(Map<String, dynamic> oposicion) {
    final oposData = oposicion['oposiciones'];
    final nombre = oposData != null ? oposData['nombre'] as String? : null;
    final nivel = oposData != null ? oposData['nivel'] as String? : null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Text('🎯', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre ?? 'Oposición activa',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                ),
                if (nivel != null)
                  Text(
                    'Grupo $nivel',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecomendacion(int pendientes, int? dias) {
    String texto;
    if (pendientes > 0 && dias != null && dias > 0) {
      texto =
          'Con $dias días, estudia ${(pendientes / (dias / 7)).ceil()} temas por semana para cubrir todo el temario.';
    } else if (pendientes == 0) {
      texto = '¡Temario completado! Enfócate en simulacros y repaso de fallos.';
    } else {
      texto =
          'Configura tu fecha de examen para obtener recomendaciones personalizadas.';
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.info.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: AppColors.info,
                size: 16,
              ),
              SizedBox(width: 6),
              Text(
                'Recomendación',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.info,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(texto, style: const TextStyle(fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }
}

class _TarjetaDias extends StatelessWidget {
  final int dias;

  const _TarjetaDias({required this.dias});

  @override
  Widget build(BuildContext context) {
    final color = dias < 30 ? AppColors.warning : AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: color, size: 24),
          const SizedBox(width: 12),
          Text(
            '$dias días',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text('para el examen', style: TextStyle(color: color)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String valor;
  final String label;
  final Color color;

  const _StatCard({
    required this.valor,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Column(
        children: [
          Text(
            valor,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
