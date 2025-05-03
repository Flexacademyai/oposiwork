import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:oposiwork/domain/entities/temario.dart';

class TemarioService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _collection = 'temarios';

  // Obtener todos los temarios
  Stream<List<Temario>> getTemarios() {
    return _firestore
        .collection(_collection)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return _temarioFromFirestore(doc);
      }).toList();
    });
  }

  // Obtener temario por ID de oposición
  Stream<Temario?> getTemarioByOpositionId(String opositionId) {
    return _firestore
        .collection(_collection)
        .where('opositionId', isEqualTo: opositionId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return null;
      }
      return _temarioFromFirestore(snapshot.docs.first);
    });
  }

  // Obtener temario por ID
  Future<Temario?> getTemarioById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return _temarioFromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error al obtener temario: $e');
      return null;
    }
  }

  // Obtener URL de descarga para un PDF
  Future<String?> getPdfDownloadUrl(String pdfPath) async {
    try {
      final ref = _storage.ref(pdfPath);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error al obtener URL de descarga: $e');
      return null;
    }
  }

  // Verificar si el usuario tiene acceso premium al temario
  Future<bool> hasUserPremiumAccess(String userId, String temarioId) async {
    try {
      // Verificar si el usuario tiene una suscripción activa
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return false;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final subscriptionStatus = userData['subscriptionStatus'] as String?;
      final subscriptionEndDate = (userData['subscriptionEndDate'] as Timestamp?)?.toDate();

      // Si tiene suscripción activa y no ha expirado
      if (subscriptionStatus == 'active' && 
          subscriptionEndDate != null && 
          subscriptionEndDate.isAfter(DateTime.now())) {
        return true;
      }

      // Si tiene compra única de este temario específico
      final purchasedTemarios = List<String>.from(userData['purchasedTemarios'] ?? []);
      return purchasedTemarios.contains(temarioId);
    } catch (e) {
      debugPrint('Error al verificar acceso premium: $e');
      return false;
    }
  }

  // Marcar tema como favorito
  Future<void> addTopicToFavorites(String userId, String temarioId, int topicNumber) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'favoriteTopics': FieldValue.arrayUnion([{
          'temarioId': temarioId,
          'topicNumber': topicNumber,
          'addedAt': FieldValue.serverTimestamp(),
        }]),
      });
    } catch (e) {
      debugPrint('Error al añadir tema a favoritos: $e');
      rethrow;
    }
  }

  // Eliminar tema de favoritos
  Future<void> removeTopicFromFavorites(String userId, String temarioId, int topicNumber) async {
    try {
      // Primero obtenemos los favoritos actuales
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final favoriteTopics = List<dynamic>.from(userData['favoriteTopics'] ?? []);

      // Encontramos el índice del tema a eliminar
      final index = favoriteTopics.indexWhere((topic) => 
        topic['temarioId'] == temarioId && topic['topicNumber'] == topicNumber);

      if (index != -1) {
        // Eliminamos el tema de la lista
        favoriteTopics.removeAt(index);
        
        // Actualizamos el documento del usuario
        await _firestore.collection('users').doc(userId).update({
          'favoriteTopics': favoriteTopics,
        });
      }
    } catch (e) {
      debugPrint('Error al eliminar tema de favoritos: $e');
      rethrow;
    }
  }

  // Obtener temas favoritos de un usuario
  Future<List<Map<String, dynamic>>> getFavoriteTopics(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return [];
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final favoriteTopics = List<dynamic>.from(userData['favoriteTopics'] ?? []);

      // Para cada tema favorito, obtenemos información adicional
      final result = <Map<String, dynamic>>[];
      
      for (final topic in favoriteTopics) {
        final temarioId = topic['temarioId'] as String;
        final topicNumber = topic['topicNumber'] as int;
        
        // Obtener información del temario
        final temario = await getTemarioById(temarioId);
        if (temario != null) {
          // Encontrar el tema específico
          final topicData = temario.topics.firstWhere(
            (t) => t.number == topicNumber,
            orElse: () => Topic(number: 0, title: 'Desconocido', summary: ''),
          );
          
          if (topicData.number > 0) {
            result.add({
              'temarioId': temarioId,
              'topicNumber': topicNumber,
              'title': topicData.title,
              'summary': topicData.summary,
              'temarioTitle': temario.title,
              'addedAt': (topic['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            });
          }
        }
      }
      
      // Ordenar por fecha de adición (más reciente primero)
      result.sort((a, b) => (b['addedAt'] as DateTime).compareTo(a['addedAt'] as DateTime));
      
      return result;
    } catch (e) {
      debugPrint('Error al obtener temas favoritos: $e');
      return [];
    }
  }

  // Registrar progreso de estudio
  Future<void> updateStudyProgress(String userId, String temarioId, int topicNumber, double progress) async {
    try {
      // Estructura para almacenar el progreso de estudio
      final progressData = {
        'temarioId': temarioId,
        'topicNumber': topicNumber,
        'progress': progress,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Verificar si ya existe un registro para este tema
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final studyProgress = List<dynamic>.from(userData['studyProgress'] ?? []);

      final index = studyProgress.indexWhere((item) => 
        item['temarioId'] == temarioId && item['topicNumber'] == topicNumber);

      if (index != -1) {
        // Actualizar progreso existente
        studyProgress[index] = {
          ...studyProgress[index] as Map<String, dynamic>,
          'progress': progress,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        
        await _firestore.collection('users').doc(userId).update({
          'studyProgress': studyProgress,
        });
      } else {
        // Añadir nuevo registro de progreso
        await _firestore.collection('users').doc(userId).update({
          'studyProgress': FieldValue.arrayUnion([progressData]),
        });
      }
    } catch (e) {
      debugPrint('Error al actualizar progreso de estudio: $e');
      rethrow;
    }
  }

  // Convertir documento de Firestore a objeto Temario
  Temario _temarioFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Temario(
      id: doc.id,
      opositionId: data['opositionId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      accessType: data['accessType'] ?? 'free',
      topics: _parseTopics(data['topics'] ?? []),
      resources: _parseResources(data['resources'] ?? []),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Parsear lista de temas
  List<Topic> _parseTopics(List<dynamic> topicsData) {
    return topicsData.map((topicData) {
      final Map<String, dynamic> topic = topicData as Map<String, dynamic>;
      
      return Topic(
        number: topic['number'] ?? 0,
        title: topic['title'] ?? '',
        summary: topic['summary'] ?? '',
        fullContent: topic['fullContent'] != null
            ? FullContent(
                text: topic['fullContent']['text'],
                pdfUrl: topic['fullContent']['pdfUrl'],
              )
            : null,
      );
    }).toList();
  }

  // Parsear lista de recursos
  List<Resource> _parseResources(List<dynamic> resourcesData) {
    return resourcesData.map((resourceData) {
      final Map<String, dynamic> resource = resourceData as Map<String, dynamic>;
      
      return Resource(
        title: resource['title'] ?? '',
        description: resource['description'] ?? '',
        type: resource['type'] ?? 'pdf',
        url: resource['url'] ?? '',
        accessType: resource['accessType'] ?? 'free',
      );
    }).toList();
  }
}
