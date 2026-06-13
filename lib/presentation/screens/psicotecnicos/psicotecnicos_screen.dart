import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/contenido_repository.dart';
import '../../../data/repositories/progreso_repository.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/premium_lock_widget.dart';

final _psicotecnicosProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, oposicionId) async {
      final supabase = ref.watch(supabaseClientProvider);
      return ContenidoRepository(supabase).obtenerPsicotecnicos(oposicionId);
    });

class PsicotecnicosScreen extends ConsumerStatefulWidget {
  const PsicotecnicosScreen({super.key, required this.oposicionId});
  final String oposicionId;

  @override
  ConsumerState<PsicotecnicosScreen> createState() =>
      _PsicotecnicosScreenState();
}

class _PsicotecnicosScreenState extends ConsumerState<PsicotecnicosScreen> {
  int _indice = 0;
  String? _elegida;
  bool _confirmada = false;
  int _aciertos = 0;

  void _elegir(String opcion) {
    if (_confirmada) return;
    setState(() => _elegida = opcion);
  }

  Future<void> _confirmar(Map<String, dynamic> pregunta) async {
    if (_elegida == null || _confirmada) return;
    final correcta = _elegida == pregunta['respuesta_correcta'];
    setState(() {
      _confirmada = true;
      if (correcta) _aciertos++;
    });
    final userId = ref.read(usuarioActualProvider)?.id;
    final referenciaId = pregunta['id']?.toString();
    if (userId == null || referenciaId == null || referenciaId.isEmpty) return;
    try {
      await ProgresoRepository(
        ref.read(supabaseClientProvider),
      ).registrarResultadoEjercicio(
        userId: userId,
        tipo: 'psicotecnico',
        referenciaId: referenciaId,
        correcto: correcta,
        respuestaDada: _elegida,
      );
    } catch (_) {
      // El ejercicio sigue funcionando aunque falle el registro estadistico.
    }
  }

  void _siguiente(List<Map<String, dynamic>> lista) {
    if (_indice < lista.length - 1) {
      setState(() {
        _indice++;
        _elegida = null;
        _confirmada = false;
      });
    } else {
      _mostrarResultado(lista.length);
    }
  }

  void _mostrarResultado(int total) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            title: const Text('Ejercicio completado'),
            content: Text('Has acertado $_aciertos de $total ejercicios.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Volver'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _indice = 0;
                    _elegida = null;
                    _confirmada = false;
                    _aciertos = 0;
                  });
                },
                child: const Text('Repetir'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_psicotecnicosProvider(widget.oposicionId));

    return Scaffold(
      appBar: AppBar(title: const Text('Psicotécnicos')),
      body: Stack(
        children: [
          async.when(
            data: (lista) {
              if (lista.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.psychology_outlined,
                        size: 64,
                        color: AppColors.textTertiary,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No hay psicotécnicos disponibles para esta oposición',
                      ),
                    ],
                  ),
                );
              }
              final pregunta = lista[_indice];
              final opciones = List<String>.from(
                pregunta['opciones'] as List? ?? [],
              );
              final correcta = pregunta['respuesta_correcta'] as String? ?? '';

              return Column(
                children: [
                  LinearProgressIndicator(
                    value: (_indice + 1) / lista.length,
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
                          _buildTipo(pregunta),
                          const SizedBox(height: 16),
                          Text(
                            pregunta['enunciado'] as String? ?? '',
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(height: 1.5),
                          ),
                          const SizedBox(height: 24),
                          ...opciones.map(
                            (op) => _buildOpcion(op, correcta, context),
                          ),
                          if (_confirmada &&
                              pregunta['explicacion'] != null) ...[
                            const SizedBox(height: 16),
                            _buildExplicacion(
                              context,
                              pregunta['explicacion'] as String,
                            ),
                          ],
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                  _buildBotones(lista, pregunta),
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

  Widget _buildTipo(Map<String, dynamic> pregunta) {
    final tipo = pregunta['tipo'] as String? ?? '';
    final iconos = {
      'verbal': Icons.abc_rounded,
      'numerico': Icons.calculate_outlined,
      'espacial': Icons.view_in_ar_outlined,
      'memoria': Icons.memory_outlined,
      'atencion': Icons.visibility_outlined,
    };
    return Row(
      children: [
        Icon(
          iconos[tipo] ?? Icons.quiz_outlined,
          color: AppColors.primary,
          size: 18,
        ),
        const SizedBox(width: 6),
        Text(
          tipo.toUpperCase(),
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 11,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildOpcion(String opcion, String correcta, BuildContext context) {
    final esElegida = _elegida == opcion;
    final esCorrecta = correcta == opcion;
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
      onTap: () => _elegir(opcion),
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
            Expanded(child: Text(opcion, style: const TextStyle(height: 1.4))),
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
  }

  Widget _buildExplicacion(BuildContext context, String explicacion) {
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
          Text(explicacion, style: const TextStyle(height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildBotones(
    List<Map<String, dynamic>> lista,
    Map<String, dynamic> pregunta,
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
                  onPressed: () => _siguiente(lista),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _indice < lista.length - 1 ? 'Siguiente' : 'Ver resultado',
                  ),
                )
                : ElevatedButton(
                  onPressed:
                      _elegida != null ? () => _confirmar(pregunta) : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Confirmar'),
                ),
      ),
    );
  }
}
