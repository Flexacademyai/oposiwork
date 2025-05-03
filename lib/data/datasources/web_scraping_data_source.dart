import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;

class WebScrapingDataSource {
  // URLs de los portales de empleo público
  static const Map<String, String> employmentPortals = {
    'EmpleoPublico': 'https://administracion.gob.es/pag_Home/empleoBecas/empleo/buscadorEmpleo.html',
    'FuncionPublica': 'https://funcionpublica.digital.gob.es/funcion-publica/Acceso-Empleo-Publico.html',
    'MadridEmpleo': 'https://www.comunidad.madrid/servicios/empleo/empleo-publico',
    'GenCat': 'https://administraciopublica.gencat.cat/ca/funcio-publica/proces-de-seleccio-de-personal/',
    // Añadir más portales según sea necesario
  };

  // Obtener datos de un portal específico
  Future<List<Map<String, dynamic>>> scrapePortal(String source) async {
    try {
      final url = employmentPortals[source];
      if (url == null) {
        throw Exception('Portal no encontrado: $source');
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Error al acceder al portal: ${response.statusCode}');
      }

      // Parsear HTML de la página
      final document = html_parser.parse(response.body);
      
      // Extraer datos según la estructura de cada portal
      switch (source) {
        case 'EmpleoPublico':
          return _scrapeEmpleoPublico(document, url);
        case 'FuncionPublica':
          return _scrapeFuncionPublica(document, url);
        case 'MadridEmpleo':
          return _scrapeMadridEmpleo(document, url);
        case 'GenCat':
          return _scrapeGenCat(document, url);
        default:
          return _scrapeGeneric(document, url, source);
      }
    } catch (e) {
      debugPrint('Error al obtener datos del portal $source: $e');
      return [];
    }
  }

  // Obtener datos de todos los portales configurados
  Future<List<Map<String, dynamic>>> scrapeAllPortals() async {
    final allResults = <Map<String, dynamic>>[];
    
    for (final source in employmentPortals.keys) {
      final results = await scrapePortal(source);
      allResults.addAll(results);
    }
    
    // Ordenar por fecha (más reciente primero)
    allResults.sort((a, b) {
      final dateA = a['publicationDate'] as DateTime? ?? DateTime(1970);
      final dateB = b['publicationDate'] as DateTime? ?? DateTime(1970);
      return dateB.compareTo(dateA);
    });
    
    return allResults;
  }

  // Obtener detalles completos de una oposición a partir de su URL
  Future<Map<String, dynamic>?> scrapeOpositionDetails(String url, String source) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Error al obtener detalles: ${response.statusCode}');
      }

      // Parsear HTML de la página
      final document = html_parser.parse(response.body);
      
      // Extraer información según la fuente
      switch (source) {
        case 'EmpleoPublico':
          return _extractEmpleoPublicoDetails(document, url);
        case 'FuncionPublica':
          return _extractFuncionPublicaDetails(document, url);
        case 'MadridEmpleo':
          return _extractMadridEmpleoDetails(document, url);
        case 'GenCat':
          return _extractGenCatDetails(document, url);
        default:
          return _extractGenericDetails(document, url, source);
      }
    } catch (e) {
      debugPrint('Error al obtener detalles de oposición: $e');
      return null;
    }
  }

  // Métodos específicos para cada portal
  
  // Portal de Empleo Público
  List<Map<String, dynamic>> _scrapeEmpleoPublico(html_dom.Document document, String baseUrl) {
    final results = <Map<String, dynamic>>[];
    
    // Buscar elementos que contengan oposiciones
    final opositionElements = document.querySelectorAll('.resultado-busqueda');
    
    for (final element in opositionElements) {
      try {
        // Extraer título
        final titleElement = element.querySelector('.titulo a');
        final title = titleElement?.text.trim() ?? '';
        final link = titleElement?.attributes['href'] ?? '';
        final fullLink = _resolveUrl(baseUrl, link);
        
        // Extraer entidad
        final entityElement = element.querySelector('.organismo');
        final entity = entityElement?.text.trim() ?? '';
        
        // Extraer fecha
        final dateElement = element.querySelector('.fecha');
        final dateText = dateElement?.text.trim() ?? '';
        final publicationDate = _parseDate(dateText);
        
        // Extraer estado
        final statusElement = element.querySelector('.estado');
        final statusText = statusElement?.text.trim().toLowerCase() ?? '';
        String status = 'desconocido';
        if (statusText.contains('abierto') || statusText.contains('plazo')) {
          status = 'abierta';
        } else if (statusText.contains('próxima')) {
          status = 'proxima';
        } else if (statusText.contains('cerrado') || statusText.contains('finalizado')) {
          status = 'cerrada';
        }
        
        // Solo añadir si parece una oposición válida
        if (title.isNotEmpty && link.isNotEmpty) {
          results.add({
            'title': title,
            'entity': entity,
            'link': fullLink,
            'publicationDate': publicationDate,
            'status': status,
            'source': 'EmpleoPublico',
          });
        }
      } catch (e) {
        debugPrint('Error al procesar elemento de oposición: $e');
      }
    }
    
    return results;
  }
  
  // Portal de Función Pública
  List<Map<String, dynamic>> _scrapeFuncionPublica(html_dom.Document document, String baseUrl) {
    final results = <Map<String, dynamic>>[];
    
    // Buscar elementos que contengan oposiciones
    final opositionElements = document.querySelectorAll('.card-convocatoria');
    
    for (final element in opositionElements) {
      try {
        // Extraer título
        final titleElement = element.querySelector('.card-title');
        final title = titleElement?.text.trim() ?? '';
        
        // Extraer link
        final linkElement = element.querySelector('a');
        final link = linkElement?.attributes['href'] ?? '';
        final fullLink = _resolveUrl(baseUrl, link);
        
        // Extraer entidad
        final entityElement = element.querySelector('.card-subtitle');
        final entity = entityElement?.text.trim() ?? '';
        
        // Extraer fecha
        final dateElement = element.querySelector('.card-date');
        final dateText = dateElement?.text.trim() ?? '';
        final publicationDate = _parseDate(dateText);
        
        // Extraer plazas
        final placesElement = element.querySelector('.card-places');
        final placesText = placesElement?.text.trim() ?? '';
        final placesRegex = RegExp(r'(\d+)\s+plaza[s]?');
        final placesMatch = placesRegex.firstMatch(placesText);
        final places = placesMatch != null ? int.tryParse(placesMatch.group(1) ?? '0') ?? 0 : 0;
        
        // Solo añadir si parece una oposición válida
        if (title.isNotEmpty && link.isNotEmpty) {
          results.add({
            'title': title,
            'entity': entity,
            'link': fullLink,
            'publicationDate': publicationDate,
            'places': places,
            'status': 'abierta', // Por defecto asumimos que está abierta
            'source': 'FuncionPublica',
          });
        }
      } catch (e) {
        debugPrint('Error al procesar elemento de oposición: $e');
      }
    }
    
    return results;
  }
  
  // Portal de Empleo Público de Madrid
  List<Map<String, dynamic>> _scrapeMadridEmpleo(html_dom.Document document, String baseUrl) {
    final results = <Map<String, dynamic>>[];
    
    // Buscar elementos que contengan oposiciones
    final opositionElements = document.querySelectorAll('.listado-resultados .resultado');
    
    for (final element in opositionElements) {
      try {
        // Extraer título
        final titleElement = element.querySelector('h2 a');
        final title = titleElement?.text.trim() ?? '';
        final link = titleElement?.attributes['href'] ?? '';
        final fullLink = _resolveUrl(baseUrl, link);
        
        // Extraer entidad
        final entityElement = element.querySelector('.organismo');
        final entity = entityElement?.text.trim() ?? 'Comunidad de Madrid';
        
        // Extraer fecha
        final dateElement = element.querySelector('.fecha');
        final dateText = dateElement?.text.trim() ?? '';
        final publicationDate = _parseDate(dateText);
        
        // Extraer estado
        final statusElement = element.querySelector('.estado');
        final statusText = statusElement?.text.trim().toLowerCase() ?? '';
        String status = 'desconocido';
        if (statusText.contains('abierto') || statusText.contains('plazo')) {
          status = 'abierta';
        } else if (statusText.contains('próxima')) {
          status = 'proxima';
        } else if (statusText.contains('cerrado') || statusText.contains('finalizado')) {
          status = 'cerrada';
        }
        
        // Solo añadir si parece una oposición válida
        if (title.isNotEmpty && link.isNotEmpty) {
          results.add({
            'title': title,
            'entity': entity,
            'link': fullLink,
            'publicationDate': publicationDate,
            'status': status,
            'source': 'MadridEmpleo',
            'autonomousCommunity': 'Comunidad de Madrid',
            'province': 'Madrid',
          });
        }
      } catch (e) {
        debugPrint('Error al procesar elemento de oposición: $e');
      }
    }
    
    return results;
  }
  
  // Portal de Función Pública de Cataluña
  List<Map<String, dynamic>> _scrapeGenCat(html_dom.Document document, String baseUrl) {
    final results = <Map<String, dynamic>>[];
    
    // Buscar elementos que contengan oposiciones
    final opositionElements = document.querySelectorAll('.llistat-resultats .item');
    
    for (final element in opositionElements) {
      try {
        // Extraer título
        final titleElement = element.querySelector('.titol a');
        final title = titleElement?.text.trim() ?? '';
        final link = titleElement?.attributes['href'] ?? '';
        final fullLink = _resolveUrl(baseUrl, link);
        
        // Extraer entidad
        final entityElement = element.querySelector('.organisme');
        final entity = entityElement?.text.trim() ?? 'Generalitat de Catalunya';
        
        // Extraer fecha
        final dateElement = element.querySelector('.data');
        final dateText = dateElement?.text.trim() ?? '';
        final publicationDate = _parseDate(dateText);
        
        // Solo añadir si parece una oposición válida
        if (title.isNotEmpty && link.isNotEmpty) {
          results.add({
            'title': title,
            'entity': entity,
            'link': fullLink,
            'publicationDate': publicationDate,
            'status': 'abierta', // Por defecto asumimos que está abierta
            'source': 'GenCat',
            'autonomousCommunity': 'Cataluña',
          });
        }
      } catch (e) {
        debugPrint('Error al procesar elemento de oposición: $e');
      }
    }
    
    return results;
  }
  
  // Método genérico para otros portales
  List<Map<String, dynamic>> _scrapeGeneric(html_dom.Document document, String baseUrl, String source) {
    final results = <Map<String, dynamic>>[];
    
    // Buscar enlaces que puedan ser oposiciones
    final links = document.querySelectorAll('a');
    
    for (final link in links) {
      try {
        final text = link.text.trim();
        final href = link.attributes['href'] ?? '';
        
        // Filtrar solo enlaces que parezcan oposiciones
        if (_isOpositionRelated(text) && href.isNotEmpty) {
          final fullLink = _resolveUrl(baseUrl, href);
          
          results.add({
            'title': text,
            'entity': '',
            'link': fullLink,
            'publicationDate': null,
            'status': 'desconocido',
            'source': source,
          });
        }
      } catch (e) {
        debugPrint('Error al procesar enlace: $e');
      }
    }
    
    return results;
  }
  
  // Métodos para extraer detalles específicos
  
  Map<String, dynamic> _extractEmpleoPublicoDetails(html_dom.Document document, String url) {
    // Implementación específica para el portal de Empleo Público
    return _extractGenericDetails(document, url, 'EmpleoPublico');
  }
  
  Map<String, dynamic> _extractFuncionPublicaDetails(html_dom.Document document, String url) {
    // Implementación específica para el portal de Función Pública
    return _extractGenericDetails(document, url, 'FuncionPublica');
  }
  
  Map<String, dynamic> _extractMadridEmpleoDetails(html_dom.Document document, String url) {
    // Implementación específica para el portal de Madrid
    return _extractGenericDetails(document, url, 'MadridEmpleo');
  }
  
  Map<String, dynamic> _extractGenCatDetails(html_dom.Document document, String url) {
    // Implementación específica para el portal de Cataluña
    return _extractGenericDetails(document, url, 'GenCat');
  }
  
  // Método genérico para extraer detalles
  Map<String, dynamic> _extractGenericDetails(html_dom.Document document, String url, String source) {
    String title = '';
    String entity = '';
    String entityType = '';
    String province = '';
    String autonomousCommunity = '';
    String opositionType = '';
    String academicLevel = '';
    int places = 0;
    String status = 'abierta';
    DateTime? publicationDate;
    DateTime? registrationStartDate;
    DateTime? registrationEndDate;
    List<String> requirements = [];
    
    // Extraer título
    final titleElement = document.querySelector('h1') ?? document.querySelector('h2');
    if (titleElement != null) {
      title = titleElement.text.trim();
    }
    
    // Extraer entidad
    final entityElements = document.querySelectorAll('.organismo, .entidad, .entity');
    if (entityElements.isNotEmpty) {
      entity = entityElements.first.text.trim();
    }
    
    // Extraer fecha de publicación
    final dateElements = document.querySelectorAll('.fecha, .date, time');
    if (dateElements.isNotEmpty) {
      final dateText = dateElements.first.text.trim();
      publicationDate = _parseDate(dateText);
    }
    
    // Extraer número de plazas
    final contentText = document.body?.text ?? '';
    final placesRegex = RegExp(r'(\d+)\s+plaza[s]?');
    final placesMatch = placesRegex.firstMatch(contentText);
    if (placesMatch != null) {
      places = int.tryParse(placesMatch.group(1) ?? '0') ?? 0;
    }
    
    // Extraer requisitos
    final requirementsList = document.querySelectorAll('ul li, ol li');
    for (final item in requirementsList) {
      final text = item.text.trim();
      if (text.contains('requisito') || text.contains('titulación')) {
        requirements.add(text);
      }
    }
    
    // Determinar comunidad autónoma y provincia según la fuente
    switch (source) {
      case 'MadridEmpleo':
        autonomousCommunity = 'Comunidad de Madrid';
        province = 'Madrid';
        break;
      case 'GenCat':
        autonomousCommunity = 'Cataluña';
        break;
    }
    
    // Determinar tipo de entidad
    if (entity.toLowerCase().contains('ministerio') || entity.toLowerCase().contains('estado')) {
      entityType = 'Administración General del Estado';
    } else if (entity.toLowerCase().contains('ayuntamiento')) {
      entityType = 'Administración Local';
    } else if (entity.toLowerCase().contains('diputación')) {
      entityType = 'Administración Provincial';
    } else if (entity.toLowerCase().contains('comunidad') || entity.toLowerCase().contains('generalitat')) {
      entityType = 'Administración Autonómica';
    }
    
    // Determinar tipo de oposición
    if (title.toLowerCase().contains('sanidad') || title.toLowerCase().contains('médico') || title.toLowerCase().contains('enfermero')) {
      opositionType = 'Sanidad';
    } else if (title.toLowerCase().contains('educación') || title.toLowerCase().contains('profesor') || title.toLowerCase().contains('maestro')) {
      opositionType = 'Educación';
    } else if (title.toLowerCase().contains('policía') || title.toLowerCase().contains('guardia') || title.toLowerCase().contains('seguridad')) {
      opositionType = 'Seguridad';
    } else if (title.toLowerCase().contains('justicia') || title.toLowerCase().contains('juez') || title.toLowerCase().contains('fiscal')) {
      opositionType = 'Justicia';
    } else {
      opositionType = 'Administración';
    }
    
    // Determinar nivel académico basado en el contenido
    if (contentText.contains('Grupo A1') || contentText.contains('Grupo I')) {
      academicLevel = 'A1';
    } else if (contentText.contains('Grupo A2') || contentText.contains('Grupo II')) {
      academicLevel = 'A2';
    } else if (contentText.contains('Grupo B') || contentText.contains('Grupo III')) {
      academicLevel = 'B';
    } else if (contentText.contains('Grupo C1') || contentText.contains('Grupo IV')) {
      academicLevel = 'C1';
    } else if (contentText.contains('Grupo C2') || contentText.contains('Grupo V')) {
      academicLevel = 'C2';
    } else if (contentText.contains('Agrupación Profesional') || contentText.contains('Grupo E')) {
      academicLevel = 'E';
    }
    
    return {
      'title': title,
      'entity': entity,
      'entityType': entityType,
      'province': province,
      'autonomousCommunity': autonomousCommunity,
      'opositionType': opositionType,
      'academicLevel': academicLevel,
      'places': places,
      'status': status,
      'publicationDate': publicationDate,
      'registrationStartDate': registrationStartDate,
      'registrationEndDate': registrationEndDate,
      'requirements': requirements,
      'originalSource': {
        'type': source,
        'url': url,
      },
    };
  }
  
  // Verificar si un texto está relacionado con oposiciones
  bool _isOpositionRelated(String text) {
    final keywords = [
      'oposicion', 'oposición', 'convocatoria', 'plaza', 'empleo público',
      'proceso selectivo', 'concurso', 'funcionario', 'personal laboral'
    ];
    
    final lowerText = text.toLowerCase();
    return keywords.any((keyword) => lowerText.contains(keyword));
  }
  
  // Resolver URL relativa a absoluta
  String _resolveUrl(String base, String relative) {
    if (relative.startsWith('http')) {
      return relative;
    }
    
    final uri = Uri.parse(base);
    if (relative.startsWith('/')) {
      // URL relativa a la raíz
      return '${uri.scheme}://${uri.host}$relative';
    } else {
      // URL relativa a la página actual
      final baseDir = base.substring(0, base.lastIndexOf('/') + 1);
      return '$baseDir$relative';
    }
  }
  
  // Parsear fecha de texto
  DateTime? _parseDate(String dateText) {
    try {
      // Intentar varios formatos comunes
      final formats = [
        RegExp(r'(\d{1,2})[/\-](\d{1,2})[/\-](\d{4})'), // DD/MM/YYYY o DD-MM-YYYY
        RegExp(r'(\d{4})[/\-](\d{1,2})[/\-](\d{1,2})'), // YYYY/MM/DD o YYYY-MM-DD
      ];
      
      for (final format in formats) {
        final match = format.firstMatch(dateText);
        if (match != null) {
          if (format == formats[0]) {
            // DD/MM/YYYY
            final day = int.parse(match.group(1)!);
            final month = int.parse(match.group(2)!);
            final year = int.parse(match.group(3)!);
            return DateTime(year, month, day);
          } else {
            // YYYY/MM/DD
            final year = int.parse(match.group(1)!);
            final month = int.parse(match.group(2)!);
            final day = int.parse(match.group(3)!);
            return DateTime(year, month, day);
          }
        }
      }
      
      // Intentar con DateTime.parse para formatos estándar
      return DateTime.parse(dateText);
    } catch (e) {
      debugPrint('Error al parsear fecha: $dateText');
      return null;
    }
  }
}
