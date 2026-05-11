import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class ResultadoTestScreen extends StatelessWidget {
  const ResultadoTestScreen({
    super.key,
    required this.correctas,
    required this.total,
  });

  final int correctas;
  final int total;

  @override
  Widget build(BuildContext context) {
    final porcentaje = total > 0 ? (correctas / total * 100).round() : 0;
    final aprobado = porcentaje >= 60;
    final color = porcentaje >= 80
        ? AppColors.success
        : porcentaje >= 60
            ? AppColors.primary
            : AppColors.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado del test'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withAlpha(20),
                border: Border.all(color: color, width: 4),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$porcentaje%',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      aprobado ? 'Aprobado' : 'Suspenso',
                      style: TextStyle(color: color, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            _buildFila(context, 'Preguntas correctas', '$correctas/$total', AppColors.success),
            const SizedBox(height: 12),
            _buildFila(context, 'Preguntas incorrectas', '${total - correctas}/$total', AppColors.error),
            const SizedBox(height: 12),
            _buildFila(context, 'Puntuación', '$porcentaje%', color),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Volver al inicio'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Repetir test'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFila(BuildContext context, String etiqueta, String valor, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiqueta, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            valor,
            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
