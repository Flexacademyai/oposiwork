import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;

class RssDataSource {
  // URLs de los feeds RSS de boletines oficiales
  static const Map<String, String> rssFeeds = {
    'BOE': 'https://www.boe.es/rss/boe/empleo_publico.xml',
    'BOJA': 'https://www.juntadeandalucia.es/boja/rss/ultimas-disposiciones.xml',
    'BOCM': 'http://www.bocm.es/rss/feed/bocm',
    'DOGC': 'https://dogc.gencat.cat/es/pdogc_canals_interns/pdogc_resultats_fitxa_dogc/rss',
    'BOPA': 'https://sede.asturias.es/bopa/rss/ultimas-disposiciones.xml',
    // Añadir más feeds según sea necesario
  };

  // Obtener datos de un feed RSS específico
  Future<List<Map<String, dynamic>>> fetchRssFeed(String source) async {
    try {
      final url = rssFeeds[source];
      if (url == null) {
        throw Exception('Fuente RSS no encontrada: $source');
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Error al obtener feed RSS: ${response.statusCode}');
      }

      // Parsear XML del feed RSS
      final document = XmlDocument.parse(response.body);
      final items = document.findAllElements('item');

      // Convertir elementos XML a mapas de datos
      final result = <Map<String, dynamic>>[];
      for (final item in items) {
        final title = _getElementText(item, 'title');
        final link = _getElementText(item, 'link');
        final description = _getElementText(item, 'description');
        final pubDate = _getElementText(item, 'pubDate');
        final guid = _getElementText(item, 'guid');

        // Solo procesar si parece una oposición (filtro básico)
        if (_isOpositionRelated(title, description)) {
          result.add({
            'title': title,
            'link': link,
            'description': description,
            'pubDate': pubDate,
            'guid': guid,
            'source': source,
          });
        }
      }

      return result;
    } catch (e) {
      debugPrint('Error al obtener feed RSS $source: $e');
      return [];
    }
  }

  // Obtener datos de todos los feeds RSS configurados
  Future<List<Map<String, dynamic>>> fetchAllRssFeeds() async {
    final allResults = <Map<String, dynamic>>[];
    
    for (final source in rssFeeds.keys) {
      final results = await fetchRssFeed(source);
      allResults.addAll(results);
    }
    
    // Ordenar por fecha de publicación (más reciente primero)
    allResults.sort((a, b) {
      final dateA = DateTime.tryParse(a['pubDate'] ?? '') ?? DateTime(1970);
      final dateB = DateTime.tryParse(b['pubDate'] ?? '') ?? DateTime(1970);
      return dateB.compareTo(dateA);
    });
    
    return allResults;
  }

  // Obtener detalles completos de una oposición a partir de su URL
  Future<Map<String, dynamic>?> fetchOpositionDetails(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Error al obtener detalles: ${response.statusCode}');
      }

      // Parsear HTML de la página
      final document = html_parser.parse(response.body);
      
      // Extraer información según la estructura de la página
      // Nota: Esto varía según la fuente (BOE, BOJA, etc.)
      final details = _extractDetailsFromHtml(document, url);
      
      return details;
    } catch (e) {
      debugPrint('Error al obtener detalles de oposición: $e');
      return null;
    }
  }

  // Extraer texto de un elemento XML
  String _getElementText(XmlElement element, String name) {
    final child = element.findElements(name).firstOrNull;
    return child?.innerText.trim() ?? '';
  }

  // Verificar si un ítem está relacionado con oposiciones
  bool _isOpositionRelated(String title, String description) {
    final keywords = [
      'oposicion', 'oposición', 'convocatoria', 'plaza', 'empleo público',
      'proceso selectivo', 'concurso', 'funcionario', 'personal laboral'
    ];
    
    final text = '${title.toLowerCase()} ${description.toLowerCase()}';
    return keywords.any((keyword) => text.contains(keyword));
  }

  // Extraer detalles de una oposición a partir del HTML
  Map<String, dynamic> _extractDetailsFromHtml(html_dom.Document document, String url) {
    // Esta función debe adaptarse según la estructura de cada fuente
    // Aquí se muestra un ejemplo genérico
    
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
    
    // Extraer fecha de publicación
    final dateElements = document.querySelectorAll('time') ?? document.querySelectorAll('.fecha');
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
    final requirementsList = document.querySelectorAll('ul li');
    for (final item in requirementsList) {
      final text = item.text.trim();
      if (text.contains('requisito') || text.contains('titulación')) {
        requirements.add(text);
      }
    }
    
    // Determinar entidad y tipo
    if (url.contains('boe.es')) {
      entityType = 'Administración General del Estado';
    } else if (url.contains('juntadeandalucia')) {
      entityType = 'Administración Autonómica';
      autonomousCommunity = 'Andalucía';
    } else if (url.contains('madrid.org') || url.contains('bocm')) {
      entityType = 'Administración Autonómica';
      autonomousCommunity = 'Madrid';
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
        'type': _getSourceTypeFromUrl(url),
        'url': url,
      },
    };
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

  // Determinar tipo de fuente a partir de la URL
  String _getSourceTypeFromUrl(String url) {
    if (url.contains('boe.es')) return 'BOE';
    if (url.contains('juntadeandalucia')) return 'BOJA';
    if (url.contains('madrid.org') || url.contains('bocm')) return 'BOCM';
    if (url.contains('gencat.cat') || url.contains('dogc')) return 'DOGC';
    if (url.contains('asturias.es') || url.contains('bopa')) return 'BOPA';
    return 'Desconocido';
  }
}
