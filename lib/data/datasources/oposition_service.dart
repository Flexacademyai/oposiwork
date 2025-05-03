import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:oposiwork/domain/entities/oposition.dart';

class OpositionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'opositions';

  // Obtener todas las oposiciones
  Stream<List<Oposition>> getOpositions() {
    return _firestore
        .collection(_collection)
        .orderBy('publicationDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return _opositionFromFirestore(doc);
      }).toList();
    });
  }

  // Obtener oposiciones recientes
  Stream<List<Oposition>> getRecentOpositions({int limit = 10}) {
    return _firestore
        .collection(_collection)
        .orderBy('publicationDate', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return _opositionFromFirestore(doc);
      }).toList();
    });
  }

  // Obtener oposiciones populares
  Stream<List<Oposition>> getPopularOpositions({int limit = 10}) {
    return _firestore
        .collection(_collection)
        .orderBy('viewCount', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return _opositionFromFirestore(doc);
      }).toList();
    });
  }

  // Obtener oposiciones por categoría
  Stream<List<Oposition>> getOpositionsByType(String type, {int limit = 20}) {
    return _firestore
        .collection(_collection)
        .where('opositionType', isEqualTo: type)
        .orderBy('publicationDate', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return _opositionFromFirestore(doc);
      }).toList();
    });
  }

  // Obtener oposiciones por provincia
  Stream<List<Oposition>> getOpositionsByProvince(String province, {int limit = 20}) {
    return _firestore
        .collection(_collection)
        .where('province', isEqualTo: province)
        .orderBy('publicationDate', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return _opositionFromFirestore(doc);
      }).toList();
    });
  }

  // Obtener oposiciones por comunidad autónoma
  Stream<List<Oposition>> getOpositionsByAutonomousCommunity(String community, {int limit = 20}) {
    return _firestore
        .collection(_collection)
        .where('autonomousCommunity', isEqualTo: community)
        .orderBy('publicationDate', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return _opositionFromFirestore(doc);
      }).toList();
    });
  }

  // Obtener oposiciones por nivel académico
  Stream<List<Oposition>> getOpositionsByAcademicLevel(String level, {int limit = 20}) {
    return _firestore
        .collection(_collection)
        .where('academicLevel', isEqualTo: level)
        .orderBy('publicationDate', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return _opositionFromFirestore(doc);
      }).toList();
    });
  }

  // Obtener oposiciones por estado
  Stream<List<Oposition>> getOpositionsByStatus(String status, {int limit = 20}) {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: status)
        .orderBy('publicationDate', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return _opositionFromFirestore(doc);
      }).toList();
    });
  }

  // Buscar oposiciones
  Stream<List<Oposition>> searchOpositions(String query) {
    // En una implementación real, usaríamos Algolia o ElasticSearch para búsquedas más complejas
    // Por ahora, hacemos una búsqueda simple en Firestore
    return _firestore
        .collection(_collection)
        .orderBy('title')
        .startAt([query])
        .endAt([query + '\uf8ff'])
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return _opositionFromFirestore(doc);
      }).toList();
    });
  }

  // Búsqueda avanzada con filtros
  Future<List<Oposition>> advancedSearch({
    String? query,
    List<String>? provinces,
    List<String>? types,
    List<String>? levels,
    String? status,
  }) async {
    Query opositionsQuery = _firestore.collection(_collection);

    // Aplicar filtros si están presentes
    if (provinces != null && provinces.isNotEmpty) {
      opositionsQuery = opositionsQuery.where('province', whereIn: provinces);
    }

    if (types != null && types.isNotEmpty) {
      opositionsQuery = opositionsQuery.where('opositionType', whereIn: types);
    }

    if (levels != null && levels.isNotEmpty) {
      opositionsQuery = opositionsQuery.where('academicLevel', whereIn: levels);
    }

    if (status != null && status.isNotEmpty) {
      opositionsQuery = opositionsQuery.where('status', isEqualTo: status);
    }

    // Ejecutar la consulta
    final snapshot = await opositionsQuery.get();
    final opositions = snapshot.docs.map((doc) => _opositionFromFirestore(doc)).toList();

    // Filtrar por texto de búsqueda si está presente
    if (query != null && query.isNotEmpty) {
      final lowercaseQuery = query.toLowerCase();
      return opositions.where((oposition) {
        return oposition.title.toLowerCase().contains(lowercaseQuery) ||
            oposition.entity.toLowerCase().contains(lowercaseQuery);
      }).toList();
    }

    return opositions;
  }

  // Obtener una oposición por ID
  Future<Oposition?> getOpositionById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return _opositionFromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error al obtener oposición: $e');
      return null;
    }
  }

  // Incrementar contador de vistas
  Future<void> incrementViewCount(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error al incrementar contador de vistas: $e');
    }
  }

  // Añadir oposición a favoritos
  Future<void> addToFavorites(String userId, String opositionId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'favoriteOpositions': FieldValue.arrayUnion([opositionId]),
      });
    } catch (e) {
      debugPrint('Error al añadir a favoritos: $e');
      rethrow;
    }
  }

  // Eliminar oposición de favoritos
  Future<void> removeFromFavorites(String userId, String opositionId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'favoriteOpositions': FieldValue.arrayRemove([opositionId]),
      });
    } catch (e) {
      debugPrint('Error al eliminar de favoritos: $e');
      rethrow;
    }
  }

  // Obtener oposiciones favoritas de un usuario
  Stream<List<Oposition>> getFavoriteOpositions(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .asyncMap((userDoc) async {
      if (!userDoc.exists) {
        return [];
      }

      final List<dynamic> favoriteIds = userDoc.data()?['favoriteOpositions'] ?? [];
      if (favoriteIds.isEmpty) {
        return [];
      }

      // Obtener las oposiciones favoritas
      final opositionsSnapshot = await _firestore
          .collection(_collection)
          .where(FieldPath.documentId, whereIn: favoriteIds.cast<String>())
          .get();

      return opositionsSnapshot.docs.map((doc) => _opositionFromFirestore(doc)).toList();
    });
  }

  // Convertir documento de Firestore a objeto Oposition
  Oposition _opositionFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Oposition(
      id: doc.id,
      title: data['title'] ?? '',
      entity: data['entity'] ?? '',
      entityType: data['entityType'] ?? '',
      province: data['province'] ?? '',
      autonomousCommunity: data['autonomousCommunity'] ?? '',
      opositionType: data['opositionType'] ?? '',
      academicLevel: data['academicLevel'] ?? '',
      places: data['places'] ?? 0,
      status: data['status'] ?? 'cerrada',
      publicationDate: (data['publicationDate'] as Timestamp?)?.toDate(),
      registrationStartDate: (data['registrationStartDate'] as Timestamp?)?.toDate(),
      registrationEndDate: (data['registrationEndDate'] as Timestamp?)?.toDate(),
      examDates: (data['examDates'] as List<dynamic>?)
          ?.map((date) => (date as Timestamp).toDate())
          .toList(),
      requirements: List<String>.from(data['requirements'] ?? []),
      salary: data['salary'] != null
          ? Salary(
              minimum: data['salary']['minimum'] ?? 0.0,
              maximum: data['salary']['maximum'] ?? 0.0,
              currency: data['salary']['currency'] ?? 'EUR',
            )
          : null,
      originalSource: data['originalSource'] != null
          ? OriginalSource(
              type: data['originalSource']['type'] ?? '',
              url: data['originalSource']['url'],
              reference: data['originalSource']['reference'],
            )
          : const OriginalSource(type: ''),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
