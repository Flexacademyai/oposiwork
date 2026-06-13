import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/pregunta_test.dart';
import '../../../data/repositories/contenido_repository.dart';
import '../../../data/repositories/progreso_repository.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/premium_lock_widget.dart';

final _preguntasTestProvider = FutureProvider.autoDispose
    .family<List<PreguntaTest>, String>((ref, oposicionId) async {
      final supabase = ref.watch(supabaseClientProvider);
      return ContenidoRepository(
        supabase,
      ).obtenerPreguntasTestPorOposicion(oposicionId, limite: 20);
    });

class TestScreen extends ConsumerStatefulWidget {
  const TestScreen({super.key, required this.oposicionId});
  final String oposicionId;

  @override
  ConsumerState<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends ConsumerState<TestScreen> {
  int _indice = 0;
  String? _respuestaElegida;
  bool _confirmada = false;
  final Map<String, String> _respuestas = {};
  final List<bool> _aciertos = [];

  void _elegir(String opcion) {
    if (_confirmada) return;
    setState(() => _respuestaElegida = opcion);
  }

  Future<void> _confirmar(PreguntaTest pregunta) async {
    if (_respuestaElegida == null || _confirmada) return;
    final correcto = _respuestaElegida == pregunta.respuestaCorrecta;
    setState(() {
      _confirmada = true;
      _respuestas[pregunta.id] = _respuestaElegida!;
      _aciertos.add(correcto);
    });
    final userId = ref.read(usuarioActualProvider)?.id;
    if (userId == null) return;
    try {
      await ProgresoRepository(
        ref.read(supabaseClientProvider),
      ).registrarResultadoEjercicio(
        userId: userId,
        tipo: 'test',
        referenciaId: pregunta.id,
        correcto: correcto,
        respuestaDada: _respuestaElegida,
      );
    } catch (_) {
      // El test no debe bloquearse si falla el registro estadistico.
    }
  }

  void _siguiente(List<PreguntaTest> preguntas) {
    if (_indice < preguntas.length - 1) {
      setState(() {
        _indice++;
        _respuestaElegida = null;
        _confirmada = false;
      });
    } else {
      final correctas = _aciertos.where((a) => a).length;
      context.pushReplacement(
        '/oposiciones/${widget.oposicionId}/test/resultado',
        extra: {
          'correctas': correctas,
          'total': preguntas.length,
          'preguntas': preguntas,
          'respuestas': _respuestas,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_preguntasTestProvider(widget.oposicionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test'),
        actions: [
          async.whenOrNull(
                data:
                    (preguntas) => Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Center(
                        child: Text(
                          '${_indice + 1}/${preguntas.length}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: Stack(
        children: [
          async.when(
            data: (preguntas) {
              if (preguntas.isEmpty) {
                return const Center(
                  child: Text('No hay preguntas disponibles aún'),
                );
              }
              final pregunta = preguntas[_indice];
              return Column(
                children: [
                  LinearProgressIndicator(
                    value: (_indice + 1) / preguntas.length,
                    backgroundColor: AppColors.border,
                    color: AppColors.primary,
                    minHeight: 3,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDificultad(pregunta.dificultad),
                          const SizedBox(height: 12),
                          Text(
                            pregunta.enunciado,
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(height: 1.5),
                          ),
                          const SizedBox(height: 24),
                          ..._buildOpciones(pregunta),
                          if (_confirmada) ...[
                            const SizedBox(height: 16),
                            _buildExplicacion(context, pregunta),
                          ],
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                  _buildBotonesAccion(preguntas, pregunta),
                ],
              );
            },
            loading: () => const LoadingWidget(),
            error: (e, _) => AppErrorWidget(mensaje: e.toString()),
          ),
          PremiumLockWidget(child: const SizedBox.expand()),
        ],
      ),
    );
  }

  Widget _buildDificultad(int dificultad) {
    final colores = [
      Colors.green,
      Colors.green,
      Colors.orange,
      Colors.orange,
      Colors.red,
    ];
    final etiquetas = ['', 'Fácil', 'Básica', 'Media', 'Difícil', 'Experto'];
    final color = colores[(dificultad - 1).clamp(0, 4)];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        etiquetas[dificultad.clamp(1, 5)],
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  List<Widget> _buildOpciones(PreguntaTest pregunta) {
    final opciones = {
      'a': pregunta.opcionA,
      'b': pregunta.opcionB,
      'c': pregunta.opcionC,
      'd': pregunta.opcionD,
    };
    return opciones.entries.map((e) {
      final esElegida = _respuestaElegida == e.key;
      final esCorrecta = pregunta.respuestaCorrecta == e.key;
      Color borderColor = AppColors.border;
      Color bgColor = Colors.transparent;
      if (_confirmada) {
        if (esCorrecta) {
          borderColor = AppColors.success;
          bgColor = AppColors.success.withAlpha(15);
        } else if (esElegida) {
          borderColor = AppColors.error;
          bgColor = AppColors.error.withAlpha(15);
        }
      } else if (esElegida) {
        borderColor = AppColors.primary;
        bgColor = AppColors.primary.withAlpha(15);
      }
      return GestureDetector(
        onTap: () => _elegir(e.key),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color:
                      esElegida && !_confirmada
                          ? AppColors.primary
                          : Colors.transparent,
                  border: Border.all(
                    color:
                        esElegida && !_confirmada
                            ? AppColors.primary
                            : AppColors.border,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    e.key.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color:
                          esElegida && !_confirmada
                              ? Colors.white
                              : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(e.value, style: const TextStyle(height: 1.4)),
              ),
              if (_confirmada && esCorrecta)
                const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 20,
                ),
              if (_confirmada && esElegida && !esCorrecta)
                const Icon(Icons.cancel, color: AppColors.error, size: 20),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildExplicacion(BuildContext context, PreguntaTest pregunta) {
    if (pregunta.explicacion == null && pregunta.articuloReferencia == null) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Explicación',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          if (pregunta.explicacion != null)
            Text(pregunta.explicacion!, style: const TextStyle(height: 1.5)),
          if (pregunta.articuloReferencia != null) ...[
            const SizedBox(height: 6),
            Text(
              pregunta.articuloReferencia!,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBotonesAccion(
    List<PreguntaTest> preguntas,
    PreguntaTest pregunta,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SizedBox(
        width: double.infinity,
        child:
            _confirmada
                ? ElevatedButton(
                  onPressed: () => _siguiente(preguntas),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _indice < preguntas.length - 1
                        ? 'Siguiente pregunta'
                        : 'Ver resultado',
                  ),
                )
                : ElevatedButton(
                  onPressed:
                      _respuestaElegida != null
                          ? () => _confirmar(pregunta)
                          : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Confirmar respuesta'),
                ),
      ),
    );
  }
}
