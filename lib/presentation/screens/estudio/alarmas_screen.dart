import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/security_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/premium_lock_widget.dart';

final alarmasProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((
  ref,
) async {
  final perfil = await ref.watch(perfilProvider.future);
  if (perfil == null) return [];
  final data = await Supabase.instance.client
      .from('alarmas_estudio')
      .select()
      .eq('usuario_id', perfil.id)
      .order('hora');
  return List<Map<String, dynamic>>.from(data as List);
});

class AlarmasScreen extends ConsumerStatefulWidget {
  const AlarmasScreen({super.key});

  @override
  ConsumerState<AlarmasScreen> createState() => _AlarmasScreenState();
}

class _AlarmasScreenState extends ConsumerState<AlarmasScreen> {
  static const _diasNombres = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final alarmasAsync = ref.watch(alarmasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarmas de estudio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_alarm_rounded),
            onPressed: () => _mostrarDialogoNuevaAlarma(context),
          ),
        ],
      ),
      body: PremiumLockWidget(
        child: alarmasAsync.when(
          loading: () => const LoadingWidget(mensaje: 'Cargando alarmas...'),
          error:
              (_, __) => AppErrorWidget(
                mensaje: 'Error al cargar alarmas',
                onReintentar: () => ref.invalidate(alarmasProvider),
              ),
          data:
              (alarmas) =>
                  alarmas.isEmpty
                      ? _EstadoVacio(
                        onCrear: () => _mostrarDialogoNuevaAlarma(context),
                      )
                      : _ListaAlarmas(
                        alarmas: alarmas,
                        diasNombres: _diasNombres,
                        onToggle: _toggleAlarma,
                        onEliminar: _eliminarAlarma,
                      ),
        ),
      ),
    );
  }

  Future<void> _mostrarDialogoNuevaAlarma(BuildContext context) async {
    TimeOfDay hora = const TimeOfDay(hour: 9, minute: 0);
    List<int> diasSeleccionados = [1, 2, 3, 4, 5];

    final resultado = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setDialogState) => AlertDialog(
                  title: const Text('Nueva alarma'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.access_time_rounded),
                        title: Text('Hora: ${hora.format(context)}'),
                        onTap: () async {
                          final nueva = await showTimePicker(
                            context: ctx,
                            initialTime: hora,
                          );
                          if (nueva != null) setDialogState(() => hora = nueva);
                        },
                      ),
                      const SizedBox(height: 8),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Días:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        children: List.generate(7, (i) {
                          final dia = i + 1;
                          final sel = diasSeleccionados.contains(dia);
                          return FilterChip(
                            label: Text(_diasNombres[i]),
                            selected: sel,
                            onSelected:
                                (v) => setDialogState(() {
                                  v
                                      ? diasSeleccionados.add(dia)
                                      : diasSeleccionados.remove(dia);
                                }),
                          );
                        }),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed:
                          diasSeleccionados.isEmpty
                              ? null
                              : () => Navigator.pop(ctx, true),
                      child: const Text('Crear'),
                    ),
                  ],
                ),
          ),
    );

    if (resultado == true && mounted) {
      await _crearAlarma(hora, diasSeleccionados);
    }
  }

  Future<void> _crearAlarma(TimeOfDay hora, List<int> dias) async {
    final perfil = await ref.read(perfilProvider.future);
    if (perfil == null) return;
    final diasValidos =
        dias.toSet().where((d) => d >= 1 && d <= 7).toList()..sort();
    if (diasValidos.isEmpty) return;
    try {
      await Supabase.instance.client.from('alarmas_estudio').insert({
        'usuario_id': perfil.id,
        'dias_semana': diasValidos,
        'hora':
            '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}:00',
        'activa': true,
      });
      ref.invalidate(alarmasProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alarma creada'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al crear la alarma'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _toggleAlarma(String id, bool activa) async {
    if (!SecurityService.esUuidValido(id)) return;
    await Supabase.instance.client
        .from('alarmas_estudio')
        .update({'activa': activa})
        .eq('id', id);
    ref.invalidate(alarmasProvider);
  }

  Future<void> _eliminarAlarma(String id) async {
    if (!SecurityService.esUuidValido(id)) return;
    await Supabase.instance.client
        .from('alarmas_estudio')
        .delete()
        .eq('id', id);
    ref.invalidate(alarmasProvider);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Alarma eliminada')));
    }
  }
}

class _ListaAlarmas extends StatelessWidget {
  final List<Map<String, dynamic>> alarmas;
  final List<String> diasNombres;
  final Function(String, bool) onToggle;
  final Function(String) onEliminar;

  const _ListaAlarmas({
    required this.alarmas,
    required this.diasNombres,
    required this.onToggle,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.all(16),
    itemCount: alarmas.length,
    separatorBuilder: (_, __) => const SizedBox(height: 8),
    itemBuilder: (context, i) {
      final a = alarmas[i];
      final hora = (a['hora'] as String).substring(0, 5);
      final dias = List<int>.from(a['dias_semana'] as List);
      final activa = a['activa'] as bool;
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: activa ? AppColors.primary.withAlpha(76) : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hora,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color:
                          activa ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children: List.generate(7, (i) {
                      final sel = dias.contains(i + 1);
                      return Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: sel ? AppColors.primary : AppColors.border,
                        ),
                        child: Center(
                          child: Text(
                            diasNombres[i],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color:
                                  sel ? Colors.white : AppColors.textTertiary,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            Switch(
              value: activa,
              onChanged: (v) => onToggle(a['id'] as String, v),
              activeColor: AppColors.primary,
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error,
              ),
              onPressed: () => onEliminar(a['id'] as String),
            ),
          ],
        ),
      );
    },
  );
}

class _EstadoVacio extends StatelessWidget {
  final VoidCallback onCrear;

  const _EstadoVacio({required this.onCrear});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('⏰', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        const Text(
          'Sin alarmas configuradas',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        const Text(
          'Crea una alarma para no olvidar estudiar',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: onCrear,
          icon: const Icon(Icons.add_alarm_rounded),
          label: const Text('Crear primera alarma'),
        ),
      ],
    ),
  );
}
