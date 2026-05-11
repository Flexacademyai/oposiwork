import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/flashcard.dart';
import '../../../data/repositories/contenido_repository.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/premium_lock_widget.dart';

final _flashcardsProvider = FutureProvider.autoDispose
    .family<List<Flashcard>, String>((ref, oposicionId) async {
  final supabase = ref.watch(supabaseClientProvider);
  final perfil = await ref.watch(perfilProvider.future);
  return ContenidoRepository(supabase).obtenerFlashcardsParaRepasar(
    oposicionId,
    usuarioId: perfil?.id,
  );
});

class FlashcardsScreen extends ConsumerStatefulWidget {
  const FlashcardsScreen({super.key, required this.oposicionId});
  final String oposicionId;

  @override
  ConsumerState<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends ConsumerState<FlashcardsScreen> {
  int _indiceActual = 0;
  bool _mostrandoRespuesta = false;
  bool _animando = false;
  double _angulo = 0;

  void _voltear() {
    if (_animando) return;
    setState(() {
      _animando = true;
      _angulo = _mostrandoRespuesta ? 0 : pi;
      _mostrandoRespuesta = !_mostrandoRespuesta;
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _animando = false);
    });
  }

  Future<void> _responder(List<Flashcard> flashcards, int calificacion) async {
    final supabase = ref.read(supabaseClientProvider);
    final perfil = await ref.read(perfilProvider.future);
    if (perfil == null) return;
    final flashcard = flashcards[_indiceActual];
    await ContenidoRepository(supabase).actualizarProgresoFlashcardConCalificacion(
      flashcardId: flashcard.id,
      usuarioId: perfil.id,
      calificacion: calificacion,
    );
    if (!mounted) return;
    if (_indiceActual < flashcards.length - 1) {
      setState(() {
        _indiceActual++;
        _mostrandoRespuesta = false;
        _angulo = 0;
      });
    } else {
      _mostrarFinSesion(flashcards.length);
    }
  }

  void _mostrarFinSesion(int total) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Sesión completada'),
        content: Text('Has repasado $total flashcards. ¡Bien hecho!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Volver'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_flashcardsProvider(widget.oposicionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards'),
        actions: [
          async.whenOrNull(
            data: (cards) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_indiceActual + 1}/${cards.length}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ) ?? const SizedBox.shrink(),
        ],
      ),
      body: Stack(
        children: [
          async.when(
            data: (flashcards) {
              if (flashcards.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline, size: 64, color: AppColors.success),
                      SizedBox(height: 16),
                      Text('Sin flashcards pendientes hoy'),
                      SizedBox(height: 8),
                      Text(
                        'Vuelve mañana para el siguiente repaso',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                );
              }
              final flashcard = flashcards[_indiceActual];
              return Column(
                children: [
                  LinearProgressIndicator(
                    value: (_indiceActual + 1) / flashcards.length,
                    backgroundColor: AppColors.border,
                    color: AppColors.primary,
                    minHeight: 3,
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: _voltear,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: _angulo, end: _angulo),
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                          builder: (context, value, child) => _buildTarjeta(flashcard, value),
                        ),
                      ),
                    ),
                  ),
                  if (_mostrandoRespuesta)
                    _buildBotonesRespuesta(flashcards)
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: Text(
                        'Toca la tarjeta para ver la respuesta',
                        style: TextStyle(color: AppColors.textTertiary),
                      ),
                    ),
                  const SizedBox(height: 16),
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

  Widget _buildTarjeta(Flashcard flashcard, double angulo) {
    final mostrarReverso = angulo > pi / 2;
    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateY(angulo),
      alignment: Alignment.center,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                mostrarReverso ? 'RESPUESTA' : 'PREGUNTA',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: mostrarReverso ? AppColors.success : AppColors.primary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Transform(
                transform: Matrix4.identity()..rotateY(mostrarReverso ? pi : 0),
                alignment: Alignment.center,
                child: Text(
                  mostrarReverso ? flashcard.respuesta : flashcard.pregunta,
                  style: const TextStyle(fontSize: 18, height: 1.6),
                  textAlign: TextAlign.center,
                ),
              ),
              if (mostrarReverso && flashcard.articuloReferencia != null) ...[
                const SizedBox(height: 20),
                Transform(
                  transform: Matrix4.identity()..rotateY(pi),
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      flashcard.articuloReferencia!,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBotonesRespuesta(List<Flashcard> flashcards) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _responder(flashcards, 0),
              icon: const Icon(Icons.close_rounded, color: AppColors.error),
              label: const Text('No sabía', style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _responder(flashcards, 1),
              icon: const Icon(Icons.help_outline_rounded, color: AppColors.warning),
              label: const Text('Dudé', style: TextStyle(color: AppColors.warning)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.warning),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _responder(flashcards, 2),
              icon: const Icon(Icons.check_rounded, color: Colors.white),
              label: const Text('Lo sabía', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
