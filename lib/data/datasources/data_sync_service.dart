import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:oposiwork/data/datasources/rss_data_source.dart';
import 'package:oposiwork/data/datasources/web_scraping_data_source.dart';
import 'package:oposiwork/domain/entities/oposition.dart';

class DataSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RssDataSource _rssDataSource = RssDataSource();
  final WebScrapingDataSource _webScrapingDataSource = WebScrapingDataSource();
  
  // Sincronizar datos de todas las fuentes
  Future<Map<String, dynamic>> syncAllData() async {
    try {
      int totalProcessed = 0;
      int newItems = 0;
      int updatedItems = 0;
      int errors = 0;
      
      // Sincronizar datos de feeds RSS
      final rssResults = await _syncRssData();
      totalProcessed += rssResults['totalProcessed'] as int;
      newItems += rssResults['newItems'] as int;
      updatedItems += rssResults['updatedItems'] as int;
      errors += rssResults['errors'] as int;
      
      // Sincronizar datos de web scraping
      final webResults = await _syncWebScrapingData();
      totalProcessed += webResults['totalProcessed'] as int;
      newItems += webResults['newItems'] as int;
      updatedItems += webResults['updatedItems'] as int;
      errors += webResults['errors'] as int;
      
      // Actualizar metadatos de sincronización
      await _updateSyncMetadata();
      
      return {
        'success': true,
        'totalProcessed': totalProcessed,
        'newItems': newItems,
        'updatedItems': updatedItems,
        'errors': errors,
        'timestamp': DateTime.now(),
      };
    } catch (e) {
      debugPrint('Error en sincronización de datos: $e');
      return {
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now(),
      };
    }
  }
  
  // Sincronizar datos de feeds RSS
  Future<Map<String, dynamic>> _syncRssData() async {
    int totalProcessed = 0;
    int newItems = 0;
    int updatedItems = 0;
    int errors = 0;
    
    try {
      // Obtener datos de todos los feeds RSS
      final rssItems = await _rssDataSource.fetchAllRssFeeds();
      totalProcessed = rssItems.length;
      
      // Procesar cada ítem
      for (final item in rssItems) {
        try {
          // Verificar si ya existe en Firestore
          final existingQuery = await _firestore
              .collection('opositions')
              .where('originalSource.url', isEqualTo: item['link'])
              .limit(1)
              .get();
          
          if (existingQuery.docs.isEmpty) {
            // Es un nuevo ítem, obtener detalles completos
            final details = await _rssDataSource.fetchOpositionDetails(item['link']);
            
            if (details != null) {
              // Crear nuevo documento en Firestore
              await _createOpositionDocument(details, item);
              newItems++;
            }
          } else {
            // Ya existe, actualizar si es necesario
            final existingDoc = existingQuery.docs.first;
            final existingData = existingDoc.data();
            
            // Verificar si hay cambios significativos
            if (_needsUpdate(existingData, item)) {
              // Obtener detalles actualizados
              final details = await _rssDataSource.fetchOpositionDetails(item['link']);
              
              if (details != null) {
                // Actualizar documento en Firestore
                await _updateOpositionDocument(existingDoc.id, details, item);
                updatedItems++;
              }
            }
          }
        } catch (e) {
          debugPrint('Error al procesar ítem RSS: $e');
          errors++;
        }
      }
    } catch (e) {
      debugPrint('Error en sincronización de datos RSS: $e');
      errors++;
    }
    
    return {
      'totalProcessed': totalProcessed,
      'newItems': newItems,
      'updatedItems': updatedItems,
      'errors': errors,
    };
  }
  
  // Sincronizar datos de web scraping
  Future<Map<String, dynamic>> _syncWebScrapingData() async {
    int totalProcessed = 0;
    int newItems = 0;
    int updatedItems = 0;
    int errors = 0;
    
    try {
      // Obtener datos de todos los portales
      final webItems = await _webScrapingDataSource.scrapeAllPortals();
      totalProcessed = webItems.length;
      
      // Procesar cada ítem
      for (final item in webItems) {
        try {
          // Verificar si ya existe en Firestore
          final existingQuery = await _firestore
              .collection('opositions')
              .where('originalSource.url', isEqualTo: item['link'])
              .limit(1)
              .get();
          
          if (existingQuery.docs.isEmpty) {
            // Es un nuevo ítem, obtener detalles completos
            final details = await _webScrapingDataSource.scrapeOpositionDetails(
              item['link'],
              item['source'],
            );
            
            if (details != null) {
              // Crear nuevo documento en Firestore
              await _createOpositionDocument(details, item);
              newItems++;
            }
          } else {
            // Ya existe, actualizar si es necesario
            final existingDoc = existingQuery.docs.first;
            final existingData = existingDoc.data();
            
            // Verificar si hay cambios significativos
            if (_needsUpdate(existingData, item)) {
              // Obtener detalles actualizados
              final details = await _webScrapingDataSource.scrapeOpositionDetails(
                item['link'],
                item['source'],
              );
              
              if (details != null) {
                // Actualizar documento en Firestore
                await _updateOpositionDocument(existingDoc.id, details, item);
                updatedItems++;
              }
            }
          }
        } catch (e) {
          debugPrint('Error al procesar ítem de web scraping: $e');
          errors++;
        }
      }
    } catch (e) {
      debugPrint('Error en sincronización de datos de web scraping: $e');
      errors++;
    }
    
    return {
      'totalProcessed': totalProcessed,
      'newItems': newItems,
      'updatedItems': updatedItems,
      'errors': errors,
    };
  }
  
  // Crear nuevo documento de oposición en Firestore
  Future<void> _createOpositionDocument(
    Map<String, dynamic> details,
    Map<String, dynamic> item,
  ) async {
    // Combinar datos de detalles e ítem
    final data = {
      ...details,
      'title': details['title'] ?? item['title'] ?? '',
      'entity': details['entity'] ?? item['entity'] ?? '',
      'status': details['status'] ?? item['status'] ?? 'abierta',
      'publicationDate': details['publicationDate'] != null
          ? Timestamp.fromDate(details['publicationDate'] as DateTime)
          : item['publicationDate'] != null
              ? Timestamp.fromDate(item['publicationDate'] as DateTime)
              : Timestamp.now(),
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'viewCount': 0,
    };
    
    // Convertir fechas a Timestamp
    if (data['registrationStartDate'] != null) {
      data['registrationStartDate'] = Timestamp.fromDate(data['registrationStartDate'] as DateTime);
    }
    
    if (data['registrationEndDate'] != null) {
      data['registrationEndDate'] = Timestamp.fromDate(data['registrationEndDate'] as DateTime);
    }
    
    if (data['examDates'] != null) {
      data['examDates'] = (data['examDates'] as List<DateTime>)
          .map((date) => Timestamp.fromDate(date))
          .toList();
    }
    
    // Crear documento en Firestore
    await _firestore.collection('opositions').add(data);
  }
  
  // Actualizar documento de oposición en Firestore
  Future<void> _updateOpositionDocument(
    String docId,
    Map<String, dynamic> details,
    Map<String, dynamic> item,
  ) async {
    // Combinar datos de detalles e ítem
    final data = {
      ...details,
      'title': details['title'] ?? item['title'] ?? '',
      'entity': details['entity'] ?? item['entity'] ?? '',
      'status': details['status'] ?? item['status'] ?? 'abierta',
      'updatedAt': Timestamp.now(),
    };
    
    // Convertir fechas a Timestamp
    if (data['publicationDate'] != null) {
      data['publicationDate'] = Timestamp.fromDate(data['publicationDate'] as DateTime);
    }
    
    if (data['registrationStartDate'] != null) {
      data['registrationStartDate'] = Timestamp.fromDate(data['registrationStartDate'] as DateTime);
    }
    
    if (data['registrationEndDate'] != null) {
      data['registrationEndDate'] = Timestamp.fromDate(data['registrationEndDate'] as DateTime);
    }
    
    if (data['examDates'] != null) {
      data['examDates'] = (data['examDates'] as List<DateTime>)
          .map((date) => Timestamp.fromDate(date))
          .toList();
    }
    
    // Actualizar documento en Firestore
    await _firestore.collection('opositions').doc(docId).update(data);
  }
  
  // Verificar si un documento necesita actualización
  bool _needsUpdate(Map<String, dynamic> existingData, Map<String, dynamic> newItem) {
    // Verificar cambios en el estado
    if (existingData['status'] != newItem['status'] && newItem['status'] != null) {
      return true;
    }
    
    // Verificar si hay una fecha de publicación más reciente
    if (newItem['publicationDate'] != null && existingData['publicationDate'] != null) {
      final existingDate = (existingData['publicationDate'] as Timestamp).toDate();
      final newDate = newItem['publicationDate'] as DateTime;
      
      if (newDate.isAfter(existingDate)) {
        return true;
      }
    }
    
    // Verificar si han pasado más de 7 días desde la última actualización
    if (existingData['updatedAt'] != null) {
      final lastUpdate = (existingData['updatedAt'] as Timestamp).toDate();
      final daysSinceUpdate = DateTime.now().difference(lastUpdate).inDays;
      
      if (daysSinceUpdate > 7) {
        return true;
      }
    }
    
    return false;
  }
  
  // Actualizar metadatos de sincronización
  Future<void> _updateSyncMetadata() async {
    await _firestore.collection('metadata').doc('sync').set({
      'lastSync': Timestamp.now(),
      'status': 'success',
    }, SetOptions(merge: true));
  }
  
  // Programar sincronización periódica
  void schedulePeriodicSync({int intervalHours = 24}) {
    // En una implementación real, esto utilizaría Firebase Cloud Functions
    // o un servicio de backend para programar la sincronización periódica
    
    debugPrint('Sincronización programada cada $intervalHours horas');
  }
}
