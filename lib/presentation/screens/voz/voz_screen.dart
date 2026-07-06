import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/premium_lock_widget.dart';

class VozScreen extends ConsumerStatefulWidget {
  const VozScreen({super.key, required this.oposicionId});
  final String oposicionId;

  @override
  ConsumerState<VozScreen> createState() => _VozScreenState();
}

class _VozScreenState extends ConsumerState<VozScreen>
    with SingleTickerProviderStateMixin {
  bool _consentimientoAceptado = false;
  bool _iniciando = false;
  bool _sesionActiva = false;
  int _cuotaRestante = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _verificarConsentimiento();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _verificarConsentimiento() async {
    final supabase = ref.read(supabaseClientProvider);
    final user = supabase.auth.currentUser;
    if (user == null) return;
    final data =
        await supabase
            .from('consentimientos')
            .select()
            .eq('usuario_id', user.id)
            .eq('tipo', 'voz')
            .maybeSingle();
    if (data != null && mounted) {
      setState(() => _consentimientoAceptado = true);
    } else if (mounted) {
      _mostrarDialogoConsentimiento();
    }
  }

  Future<void> _mostrarDialogoConsentimiento() async {
    final aceptado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            title: const Text('Asistente de voz por IA'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AVISO IMPORTANTE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Esta función usa inteligencia artificial para generar voz sintética. Las respuestas son generadas automáticamente y pueden contener errores. Siempre contrasta la información con las fuentes oficiales del BOE antes de tu examen.',
                  style: TextStyle(height: 1.5),
                ),
                SizedBox(height: 12),
                Text('El uso tiene un límite mensual de tiempo según tu plan.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Rechazar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Entendido, continuar'),
              ),
            ],
          ),
    );

    if (aceptado == true && mounted) {
      await _registrarConsentimiento();
      setState(() => _consentimientoAceptado = true);
    } else if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _registrarConsentimiento() async {
    final supabase = ref.read(supabaseClientProvider);
    final user = supabase.auth.currentUser;
    if (user == null) return;
    await supabase.from('consentimientos').upsert({
      'usuario_id': user.id,
      'tipo': 'voz',
      'aceptado': true,
      'aceptado_en': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _iniciarSesion() async {
    if (_iniciando) return;
    setState(() => _iniciando = true);

    try {
      final supabase = ref.read(supabaseClientProvider);
      final response = await supabase.functions.invoke(
        'crear-sesion-voz',
        body: {'oposicion_id': widget.oposicionId},
      );
      final data = response.data as Map<String, dynamic>?;
      final cuota = data?['cuota_restante_segundos'] as int? ?? 0;

      if (mounted) {
        setState(() {
          _sesionActiva = true;
          _cuotaRestante = cuota;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('cuota')
                  ? 'Has agotado tu cuota mensual de voz.'
                  : 'Error al iniciar la sesión de voz.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _iniciando = false);
    }
  }

  void _finalizarSesion() {
    setState(() => _sesionActiva = false);
  }

  String _formatCuota(int segundos) {
    final m = segundos ~/ 60;
    final s = segundos % 60;
    return '${m}m ${s}s restantes';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistente de voz'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'Voz generada por inteligencia artificial',
            onPressed: () => _mostrarDialogoConsentimiento(),
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildContenido(),
          PremiumLockWidget(child: const SizedBox.expand()),
        ],
      ),
    );
  }

  Widget _buildContenido() {
    if (_iniciando) return const LoadingWidget();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_sesionActiva) ...[
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withAlpha(20),
                    border: Border.all(color: AppColors.primary, width: 3),
                  ),
                  child: const Icon(
                    Icons.mic_rounded,
                    size: 56,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Sesión activa',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatCuota(_cuotaRestante),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Habla para hacer preguntas sobre el temario',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_outlined,
                      color: Colors.orange,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Voz generada por IA. Contrasta con fuentes oficiales.',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: _finalizarSesion,
                icon: const Icon(
                  Icons.stop_circle_outlined,
                  color: AppColors.error,
                ),
                label: const Text(
                  'Finalizar sesión',
                  style: TextStyle(color: AppColors.error),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ] else ...[
              const Icon(
                Icons.mic_none_rounded,
                size: 80,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: 24),
              Text(
                'Asistente de voz',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Habla con tu asistente de IA para resolver dudas sobre el temario. Responde basándose exclusivamente en el contenido oficial.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      _consentimientoAceptado
                          ? _iniciarSesion
                          : _mostrarDialogoConsentimiento,
                  icon: const Icon(Icons.mic_rounded),
                  label: const Text('Iniciar sesión de voz'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
