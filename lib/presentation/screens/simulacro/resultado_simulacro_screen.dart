import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class ResultadoSimulacroScreen extends StatelessWidget {
  const ResultadoSimulacroScreen({
    super.key,
    required this.correctas,
    required this.total,
    required this.tiempoSegundos,
  });

  final int correctas;
  final int total;
  final int tiempoSegundos;

  @override
  Widget build(BuildContext context) {
    final porcentaje = total > 0 ? (correctas / total * 100).round() : 0;
    final aprobado = porcentaje >= 60;
    final color = porcentaje >= 80
        ? AppColors.success
        : porcentaje >= 60
            ? AppColors.primary
            : AppColors.error;
    final minutos = tiempoSegundos ~/ 60;
    final segundos = tiempoSegundos % 60;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado del simulacro'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withAlpha(20),
                border: Border.all(color: color, width: 5),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$porcentaje%',
                      style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: color),
                    ),
                    Text(
                      aprobado ? '¡Aprobado!' : 'Suspenso',
                      style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 36),
            _buildFila(context, Icons.check_circle_outline, 'Respuestas correctas', '$correctas de $total', AppColors.success),
            const SizedBox(height: 10),
            _buildFila(context, Icons.cancel_outlined, 'Respuestas incorrectas', '${total - correctas} de $total', AppColors.error),
            const SizedBox(height: 10),
            _buildFila(context, Icons.timer_outlined, 'Tiempo empleado', '${minutos}m ${segundos}s', AppColors.primary),
            const SizedBox(height: 10),
            _buildFila(context, Icons.grade_outlined, 'Nota', '$porcentaje / 100', color),
            const SizedBox(height: 40),
            if (!aprobado)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Repasa los temas con menor progreso antes del próximo simulacro.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
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
          ],
        ),
      ),
    );
  }

  Widget _buildFila(BuildContext context, IconData icono, String etiqueta, String valor, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icono, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(etiqueta)),
          Text(valor, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
