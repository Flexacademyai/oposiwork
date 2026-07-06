import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/repositories/oposiciones_repository.dart';
import '../../providers/oposiciones_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';

/// Filtros de ámbito disponibles (null = todas).
const _ambitos = <({String? valor, String etiqueta})>[
  (valor: null, etiqueta: 'Todas'),
  (valor: 'estatal', etiqueta: 'Estatales'),
  (valor: 'autonomico', etiqueta: 'Autonómicas'),
  (valor: 'provincial', etiqueta: 'Provinciales'),
  (valor: 'local', etiqueta: 'Locales'),
  (valor: 'universidad', etiqueta: 'Universidades'),
];

class OposicionesScreen extends ConsumerStatefulWidget {
  const OposicionesScreen({super.key});

  @override
  ConsumerState<OposicionesScreen> createState() => _OposicionesScreenState();
}

class _OposicionesScreenState extends ConsumerState<OposicionesScreen> {
  String _busqueda = '';
  String? _ambito;
  String? _territorio;

  /// Normaliza para buscar sin distinguir tildes ni mayúsculas.
  static String _normalizar(String texto) {
    const conTilde = 'áéíóúüñÁÉÍÓÚÜÑ';
    const sinTilde = 'aeiouunAEIOUUN';
    var salida = texto.toLowerCase();
    for (var i = 0; i < conTilde.length; i++) {
      salida = salida.replaceAll(conTilde[i], sinTilde[i].toLowerCase());
    }
    return salida;
  }

  List<OposicionConEstado> _filtrar(List<OposicionConEstado> todas) {
    final consulta = _normalizar(_busqueda.trim());
    return todas.where((item) {
      final op = item.oposicion;
      if (_ambito != null && op.ambito != _ambito) return false;
      if (_territorio != null && op.territorio != _territorio) return false;
      if (consulta.isEmpty) return true;
      final texto = _normalizar(
        '${op.nombre} ${op.administracion} ${op.territorio ?? ''}',
      );
      return texto.contains(consulta);
    }).toList();
  }

  /// Territorios disponibles dentro del ámbito seleccionado, ordenados.
  List<String> _territorios(List<OposicionConEstado> todas) {
    final set = <String>{};
    for (final item in todas) {
      final op = item.oposicion;
      if (_ambito != null && op.ambito != _ambito) continue;
      final t = op.territorio;
      if (t != null && t.isNotEmpty) set.add(t);
    }
    final lista = set.toList()..sort();
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final oposicionesAsync = ref.watch(oposicionesConEstadoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.todasLasOposiciones),
        actions: [
          IconButton(
            tooltip: 'Cobertura oficial',
            icon: const Icon(Icons.public_rounded),
            onPressed: () => context.push(AppRoutes.cobertura),
          ),
        ],
      ),
      body: oposicionesAsync.when(
        data: (oposiciones) {
          if (oposiciones.isEmpty) {
            return const _EstadoVacioOposiciones();
          }

          final filtradas = _filtrar(oposiciones);
          final territorios = _territorios(oposiciones);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: TextField(
                  onChanged: (v) => setState(() => _busqueda = v),
                  decoration: InputDecoration(
                    hintText: 'Buscar por puesto, provincia o localidad...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon:
                        _busqueda.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => setState(() => _busqueda = ''),
                            )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                  ),
                ),
              ),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  children: [
                    for (final opcion in _ambitos)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(opcion.etiqueta),
                          selected: _ambito == opcion.valor,
                          onSelected:
                              (_) => setState(() {
                                _ambito = opcion.valor;
                                // El territorio elegido puede no existir en el
                                // nuevo ámbito: se resetea.
                                _territorio = null;
                              }),
                        ),
                      ),
                  ],
                ),
              ),
              if (territorios.length > 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.place_rounded,
                        size: 18,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<String?>(
                          value: _territorio,
                          isExpanded: true,
                          hint: const Text('Todos los territorios'),
                          underline: const SizedBox.shrink(),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Todos los territorios'),
                            ),
                            for (final t in territorios)
                              DropdownMenuItem<String?>(
                                value: t,
                                child: Text(t),
                              ),
                          ],
                          onChanged: (v) => setState(() => _territorio = v),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child:
                    filtradas.isEmpty
                        ? const _SinResultadosFiltro()
                        : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtradas.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final op = filtradas[index].oposicion;
                            final estado = filtradas[index].estado;
                            return _TarjetaOposicion(
                              nombre: op.nombre,
                              cuerpo: op.cuerpo,
                              administracion: op.administracion,
                              nivel: op.nivel,
                              tienePsicotecnicos: op.tienePsicotecnicos,
                              tienePruebasFisicas: op.tienePruebasFisicas,
                              estado: estado,
                              onTap:
                                  () => context.push(
                                    AppRoutes.oposicionDetail.replaceFirst(
                                      ':id',
                                      op.id,
                                    ),
                                  ),
                            );
                          },
                        ),
              ),
            ],
          );
        },
        loading: () => const LoadingWidget(mensaje: 'Cargando oposiciones...'),
        error:
            (e, _) => AppErrorWidget(
              mensaje: e.toString(),
              onReintentar: () => ref.invalidate(oposicionesConEstadoProvider),
            ),
      ),
    );
  }
}

class _SinResultadosFiltro extends StatelessWidget {
  const _SinResultadosFiltro();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.filter_alt_off_rounded,
              size: 56,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              'Sin resultados con estos filtros',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Prueba con otro término o cambia el ámbito o territorio.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _EstadoVacioOposiciones extends StatelessWidget {
  const _EstadoVacioOposiciones();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'Aún no hay oposiciones disponibles',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'El monitor oficial seguirá revisando BOE, boletines autonómicos y boletines provinciales.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaOposicion extends StatelessWidget {
  final String nombre;
  final String cuerpo;
  final String administracion;
  final String nivel;
  final bool tienePsicotecnicos;
  final bool tienePruebasFisicas;
  final EstadoInscripcion estado;
  final VoidCallback onTap;

  const _TarjetaOposicion({
    required this.nombre,
    required this.cuerpo,
    required this.administracion,
    required this.nivel,
    required this.tienePsicotecnicos,
    required this.tienePruebasFisicas,
    required this.estado,
    required this.onTap,
  });

  ({String label, Color color}) get _estadoChip {
    switch (estado) {
      case EstadoInscripcion.abierta:
        return (label: 'Inscripción abierta', color: AppColors.success);
      case EstadoInscripcion.proxima:
        return (label: 'Próxima', color: AppColors.warning);
      case EstadoInscripcion.cerrada:
        return (label: 'Inscripción cerrada', color: AppColors.textTertiary);
      case EstadoInscripcion.sinConvocatoria:
        return (label: 'Sin convocatoria', color: AppColors.textTertiary);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.gavel_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombre,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          cuerpo,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _Chip(label: _estadoChip.label, color: _estadoChip.color),
                  _Chip(label: administracion, color: AppColors.primaryLight),
                  _Chip(label: 'Grupo $nivel', color: AppColors.secondary),
                  if (tienePsicotecnicos)
                    _Chip(label: 'Psicotécnicos', color: AppColors.warning),
                  if (tienePruebasFisicas)
                    _Chip(label: 'Pruebas físicas', color: AppColors.success),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
