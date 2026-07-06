import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _paginaActual = 0;

  static const _paginas = [
    _PaginaOnboarding(
      emoji: '📚',
      titulo: 'Oposiwork',
      subtitulo: 'Prepara tu oposición con IA',
      descripcion:
          'El contenido oficial del BOE procesado y organizado para que estudies de forma eficiente.',
    ),
    _PaginaOnboarding(
      emoji: '📖',
      titulo: 'BOE procesado por IA',
      subtitulo: 'Resúmenes, artículos clave y conceptos',
      descripcion:
          '28 temas organizados por bloques. Olvídate de leer el BOE en crudo.',
    ),
    _PaginaOnboarding(
      emoji: '🧠',
      titulo: 'Aprende activamente',
      subtitulo: 'Tests, flashcards y psicotécnicos',
      descripcion:
          'Repaso espaciado SM-2, simulacros cronometrados y asistente de IA para resolver dudas.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _siguientePagina() {
    if (_paginaActual < _paginas.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.go(AppRoutes.login),
                child: const Text('Saltar'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _paginas.length,
                onPageChanged: (i) => setState(() => _paginaActual = i),
                itemBuilder: (_, i) => _paginas[i],
              ),
            ),
            _buildIndicadores(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _siguientePagina,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _paginaActual < _paginas.length - 1
                            ? 'Siguiente'
                            : 'Empezar',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.login),
                    child: const Text('Ya tengo cuenta'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicadores() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_paginas.length, (i) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _paginaActual == i ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _paginaActual == i ? AppColors.primary : AppColors.border,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _PaginaOnboarding extends StatelessWidget {
  final String emoji;
  final String titulo;
  final String subtitulo;
  final String descripcion;

  const _PaginaOnboarding({
    required this.emoji,
    required this.titulo,
    required this.subtitulo,
    required this.descripcion,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 80)),
          const SizedBox(height: 32),
          Text(
            titulo,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitulo,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            descripcion,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
