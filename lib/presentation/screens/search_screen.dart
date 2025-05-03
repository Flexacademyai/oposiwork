import 'package:flutter/material.dart';
import 'package:oposiwork/app/theme/app_theme.dart';
import 'package:oposiwork/presentation/widgets/custom_button.dart';
import 'package:oposiwork/presentation/widgets/custom_text_field.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final List<String> _selectedProvinces = [];
  final List<String> _selectedTypes = [];
  final List<String> _selectedLevels = [];
  String _selectedStatus = 'Todas';

  // Datos de ejemplo
  final List<String> _provinces = [
    'Madrid', 'Barcelona', 'Valencia', 'Sevilla', 'Zaragoza',
    'Málaga', 'Murcia', 'Palma', 'Las Palmas', 'Bilbao',
    'Alicante', 'Córdoba', 'Valladolid', 'Vigo', 'Gijón'
  ];
  
  final List<String> _types = [
    'Administración', 'Sanidad', 'Educación', 'Seguridad',
    'Justicia', 'Hacienda', 'Investigación', 'Servicios Sociales'
  ];
  
  final List<String> _levels = ['A1', 'A2', 'B', 'C1', 'C2', 'E'];
  
  final List<String> _statusOptions = ['Todas', 'Abiertas', 'Próximas', 'Cerradas'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Oposiciones'),
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CustomTextField(
              controller: _searchController,
              hintText: 'Buscar por título, entidad...',
              prefixIcon: Icons.search,
              onChanged: (value) {
                // Implementar búsqueda en tiempo real
              },
            ),
          ),
          
          // Filtros
          Expanded(
            child: DefaultTabController(
              length: 4,
              child: Column(
                children: [
                  const TabBar(
                    labelColor: AppTheme.primaryColor,
                    unselectedLabelColor: AppTheme.secondaryTextColor,
                    indicatorColor: AppTheme.primaryColor,
                    tabs: [
                      Tab(text: 'Provincia'),
                      Tab(text: 'Tipo'),
                      Tab(text: 'Nivel'),
                      Tab(text: 'Estado'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildProvinceFilter(),
                        _buildTypeFilter(),
                        _buildLevelFilter(),
                        _buildStatusFilter(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Botón de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CustomButton(
              text: 'Buscar Oposiciones',
              onPressed: () {
                // Implementar búsqueda con filtros
                _searchWithFilters();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProvinceFilter() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selecciona provincias',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: _provinces.map((province) {
              final isSelected = _selectedProvinces.contains(province);
              return FilterChip(
                label: Text(province),
                selected: isSelected,
                selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                checkmarkColor: AppTheme.primaryColor,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedProvinces.add(province);
                    } else {
                      _selectedProvinces.remove(province);
                    }
                  });
                },
              );
            }).toList(),
          ),
          if (_selectedProvinces.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedProvinces.clear();
                    });
                  },
                  child: const Text('Limpiar selección'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypeFilter() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selecciona tipos de oposición',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: _types.map((type) {
              final isSelected = _selectedTypes.contains(type);
              return FilterChip(
                label: Text(type),
                selected: isSelected,
                selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                checkmarkColor: AppTheme.primaryColor,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTypes.add(type);
                    } else {
                      _selectedTypes.remove(type);
                    }
                  });
                },
              );
            }).toList(),
          ),
          if (_selectedTypes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedTypes.clear();
                    });
                  },
                  child: const Text('Limpiar selección'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLevelFilter() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selecciona niveles académicos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: _levels.map((level) {
              final isSelected = _selectedLevels.contains(level);
              return FilterChip(
                label: Text(level),
                selected: isSelected,
                selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                checkmarkColor: AppTheme.primaryColor,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedLevels.add(level);
                    } else {
                      _selectedLevels.remove(level);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text(
            'Información sobre niveles:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildLevelInfoCard('A1', 'Título de Doctor, Licenciado, Ingeniero, Arquitecto o Grado'),
          _buildLevelInfoCard('A2', 'Título de Ingeniero Técnico, Diplomado Universitario, Arquitecto Técnico o Grado'),
          _buildLevelInfoCard('B', 'Título de Técnico Superior'),
          _buildLevelInfoCard('C1', 'Título de Bachiller o Técnico'),
          _buildLevelInfoCard('C2', 'Título de Graduado en ESO'),
          _buildLevelInfoCard('E', 'Sin titulación específica'),
          if (_selectedLevels.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedLevels.clear();
                    });
                  },
                  child: const Text('Limpiar selección'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLevelInfoCard(String level, String description) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                level,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                description,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilter() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estado de la convocatoria',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(_statusOptions.length, (index) {
            final status = _statusOptions[index];
            return RadioListTile<String>(
              title: Text(status),
              value: status,
              groupValue: _selectedStatus,
              activeColor: AppTheme.primaryColor,
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value!;
                });
              },
            );
          }),
          const SizedBox(height: 16),
          const Text(
            'Información sobre estados:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildStatusInfoCard(
            'Abiertas',
            'Convocatorias con plazo de inscripción actualmente abierto',
            Colors.green,
          ),
          _buildStatusInfoCard(
            'Próximas',
            'Convocatorias anunciadas pero aún no abiertas para inscripción',
            Colors.orange,
          ),
          _buildStatusInfoCard(
            'Cerradas',
            'Convocatorias con plazo de inscripción finalizado',
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusInfoCard(String status, String description, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _searchWithFilters() {
    // Construir mapa de filtros
    final Map<String, dynamic> filters = {
      'query': _searchController.text,
      'provinces': _selectedProvinces,
      'types': _selectedTypes,
      'levels': _selectedLevels,
      'status': _selectedStatus == 'Todas' ? null : _selectedStatus.toLowerCase(),
    };

    // En una implementación real, aquí se llamaría al BLoC o servicio
    // para realizar la búsqueda con estos filtros
    
    // Por ahora, solo mostrar un diálogo con los filtros seleccionados
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Búsqueda con filtros'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Texto: ${filters['query']}'),
              const SizedBox(height: 8),
              Text('Provincias: ${filters['provinces'].join(', ')}'),
              const SizedBox(height: 8),
              Text('Tipos: ${filters['types'].join(', ')}'),
              const SizedBox(height: 8),
              Text('Niveles: ${filters['levels'].join(', ')}'),
              const SizedBox(height: 8),
              Text('Estado: ${filters['status'] ?? 'Todas'}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
