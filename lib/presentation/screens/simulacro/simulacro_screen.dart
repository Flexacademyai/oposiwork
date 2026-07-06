import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/pregunta_test.dart';
import '../../../data/repositories/contenido_repository.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/premium_lock_widget.dart';

const _duracionSimulacroMinutos = 60;
const _preguntasPorSimulacro = 40;

final _preguntasSimulacroProvider = FutureProvider.autoDispose
    .family<List<PreguntaTest>, String>((ref, oposicionId) async {
      final supabase = ref.watch(supabaseClientProvider);
      return ContenidoRepository(supabase).obtenerPreguntasTestPorOposicion(
        oposicionId,
        limite: _preguntasPorSimulacro,
      );
    });

class SimulacroScreen extends ConsumerStatefulWidget {
  const SimulacroScreen({super.key});

  @override
  ConsumerState<SimulacroScreen> createState() => _SimulacroScreenState();
}

class _SimulacroScreenState extends ConsumerState<SimulacroScreen> {
  String? _oposicionId;
  bool _cargandoOposicion = true;

  Timer? _timer;
  int _segundosRestantes = _duracionSimulacroMinutos * 60;
  int _indice = 0;
  final Map<String, String> _respuestas = {};
  bool _iniciado = false;

  @override
  void initState() {
    super.initState();
    _cargarOposicion();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _cargarOposicion() async {
    final perfil = await ref.read(perfilProvider.future);
    if (perfil == null || !mounted) {
      setState(() => _cargandoOposicion = false);
      return;
    }
    final data =
        await Supabase.instance.client
            .from('usuario_oposiciones')
            .select('oposicion_id')
            .eq('usuario_id', perfil.id)
            .eq('activa', true)
            .limit(1)
            .maybeSingle();
    if (mounted) {
      setState(() {
        _oposicionId = data?['oposicion_id'] as String?;
        _cargandoOposicion = false;
      });
    }
  }

  void _iniciarTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_segundosRestantes <= 0) {
        _timer?.cancel();
        _finalizarSimulacro([]);
      } else {
        setState(() => _segundosRestantes--);
      }
    });
  }

  void _iniciar() {
    setState(() => _iniciado = true);
    _iniciarTimer();
  }

  void _responder(String preguntaId, String opcion) {
    setState(() => _respuestas[preguntaId] = opcion);
  }

  void _finalizarSimulacro(List<PreguntaTest> preguntas) {
    _timer?.cancel();
    final correctas =
        preguntas.where((p) => _respuestas[p.id] == p.respuestaCorrecta).length;
    final tiempoUsado = _duracionSimulacroMinutos * 60 - _segundosRestantes;
    _guardarResultado(preguntas.length, correctas, tiempoUsado);
    if (mounted) {
      context.pushReplacement(
        '/simulacro/resultado',
        extra: {
          'correctas': correctas,
          'total': preguntas.length,
          'tiempoSegundos': tiempoUsado,
        },
      );
    }
  }

  Future<void> _guardarResultado(int total, int correctas, int tiempo) async {
    if (_oposicionId == null) return;
    final supabase = ref.read(supabaseClientProvider);
    final user = supabase.auth.currentUser;
    if (user == null) return;
    try {
      await supabase.from('simulacros').insert({
        'usuario_id': user.id,
        'oposicion_id': _oposicionId,
        'total_preguntas': total,
        'correctas': correctas,
        'tiempo_segundos': tiempo,
      });
    } catch (_) {}
  }

  String _formatTiempo(int segundos) {
    final m = (segundos ~/ 60).toString().padLeft(2, '0');
    final s = (segundos % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_cargandoOposicion) {
      return const Scaffold(
        body: LoadingWidget(mensaje: 'Cargando simulacro...'),
      );
    }

    if (_oposicionId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Simulacro')),
        body: const Center(
          child: Text(
            'No tienes ninguna oposición activa.\nSelecciona una oposición primero.',
          ),
        ),
      );
    }

    final async = ref.watch(_preguntasSimulacroProvider(_oposicionId!));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulacro'),
        actions: [
          if (_iniciado)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  _formatTiempo(_segundosRestantes),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _segundosRestantes < 300 ? AppColors.error : null,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          async.when(
            data: (preguntas) {
              if (!_iniciado) return _buildPantallaInicio(preguntas.length);
              if (preguntas.isEmpty) {
                return const Center(child: Text('Sin preguntas disponibles'));
              }
              return _buildSimulacro(preguntas);
            },
            loading: () => const LoadingWidget(),
            error: (e, _) => AppErrorWidget(mensaje: e.toString()),
          ),
          PremiumLockWidget(child: const SizedBox.expand()),
        ],
      ),
    );
  }

  Widget _buildPantallaInicio(int numPreguntas) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.quiz_rounded, size: 72, color: AppColors.primary),
            const SizedBox(height: 24),
            Text(
              'Simulacro de examen',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.help_outline_rounded,
              '$numPreguntas preguntas',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.timer_outlined,
              '$_duracionSimulacroMinutos minutos',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.warning_amber_outlined,
              'No podrás pausar el cronómetro',
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _iniciar,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Comenzar simulacro',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icono, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(texto, style: const TextStyle(color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildSimulacro(List<PreguntaTest> preguntas) {
    final pregunta = preguntas[_indice];
    final opciones = {
      'a': pregunta.opcionA,
      'b': pregunta.opcionB,
      'c': pregunta.opcionC,
      'd': pregunta.opcionD,
    };

    return Column(
      children: [
        LinearProgressIndicator(
          value: (_indice + 1) / preguntas.length,
          backgroundColor: AppColors.border,
          color: AppColors.primary,
          minHeight: 3,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pregunta ${_indice + 1} de ${preguntas.length}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              Text(
                '${_respuestas.length} respondidas',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pregunta.enunciado,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 20),
                ...opciones.entries.map((e) {
                  final elegida = _respuestas[pregunta.id] == e.key;
                  return GestureDetector(
                    onTap: () => _responder(pregunta.id, e.key),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color:
                            elegida
                                ? AppColors.primary.withAlpha(15)
                                : Colors.transparent,
                        border: Border.all(
                          color: elegida ? AppColors.primary : AppColors.border,
                          width: elegida ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(
                            e.key.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color:
                                  elegida
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(e.value)),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              if (_indice > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _indice--),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Anterior'),
                  ),
                ),
              if (_indice > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child:
                    _indice < preguntas.length - 1
                        ? ElevatedButton(
                          onPressed: () => setState(() => _indice++),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Siguiente'),
                        )
                        : ElevatedButton(
                          onPressed: () => _finalizarSimulacro(preguntas),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Entregar',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
