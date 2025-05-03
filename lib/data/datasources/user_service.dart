import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:oposiwork/domain/entities/user.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final String _collection = 'users';

  // Crear perfil de usuario después del registro
  Future<void> createUserProfile({
    required String userId,
    required String name,
    required String email,
  }) async {
    try {
      await _firestore.collection(_collection).doc(userId).set({
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'photoURL': null,
        'favoriteOpositions': [],
        'favoriteTopics': [],
        'studyProgress': [],
        'purchasedTemarios': [],
        'subscriptionStatus': 'none',
        'subscriptionType': null,
        'subscriptionStartDate': null,
        'subscriptionEndDate': null,
        'notificationSettings': {
          'newOpositions': true,
          'deadlineReminders': true,
          'studyReminders': false,
          'marketingEmails': true,
        },
      });
    } catch (e) {
      debugPrint('Error al crear perfil de usuario: $e');
      rethrow;
    }
  }

  // Obtener perfil de usuario
  Stream<UserProfile?> getUserProfile(String userId) {
    return _firestore
        .collection(_collection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        return null;
      }
      return _userProfileFromFirestore(doc);
    });
  }

  // Actualizar perfil de usuario
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? photoURL,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) {
        updateData['name'] = name;
      }

      if (photoURL != null) {
        updateData['photoURL'] = photoURL;
      }

      await _firestore.collection(_collection).doc(userId).update(updateData);

      // También actualizar el displayName en Firebase Auth si se proporciona
      if (name != null) {
        await _auth.currentUser?.updateDisplayName(name);
      }

      // También actualizar la foto de perfil en Firebase Auth si se proporciona
      if (photoURL != null) {
        await _auth.currentUser?.updatePhotoURL(photoURL);
      }
    } catch (e) {
      debugPrint('Error al actualizar perfil de usuario: $e');
      rethrow;
    }
  }

  // Actualizar configuración de notificaciones
  Future<void> updateNotificationSettings({
    required String userId,
    required Map<String, bool> settings,
  }) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'notificationSettings': settings,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error al actualizar configuración de notificaciones: $e');
      rethrow;
    }
  }

  // Registrar token de dispositivo para notificaciones push
  Future<void> registerDeviceToken({
    required String userId,
    required String token,
  }) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'deviceTokens': FieldValue.arrayUnion([token]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error al registrar token de dispositivo: $e');
      rethrow;
    }
  }

  // Eliminar token de dispositivo
  Future<void> removeDeviceToken({
    required String userId,
    required String token,
  }) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'deviceTokens': FieldValue.arrayRemove([token]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error al eliminar token de dispositivo: $e');
      rethrow;
    }
  }

  // Actualizar estado de suscripción
  Future<void> updateSubscriptionStatus({
    required String userId,
    required String status,
    required String type,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'subscriptionStatus': status,
        'subscriptionType': type,
        'subscriptionStartDate': Timestamp.fromDate(startDate),
        'subscriptionEndDate': Timestamp.fromDate(endDate),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error al actualizar estado de suscripción: $e');
      rethrow;
    }
  }

  // Registrar compra única de temario
  Future<void> addPurchasedTemario({
    required String userId,
    required String temarioId,
  }) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'purchasedTemarios': FieldValue.arrayUnion([temarioId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error al registrar compra de temario: $e');
      rethrow;
    }
  }

  // Eliminar cuenta de usuario
  Future<void> deleteUserAccount(String userId) async {
    try {
      // Eliminar documento del usuario en Firestore
      await _firestore.collection(_collection).doc(userId).delete();
      
      // Eliminar usuario en Firebase Auth
      await _auth.currentUser?.delete();
    } catch (e) {
      debugPrint('Error al eliminar cuenta de usuario: $e');
      rethrow;
    }
  }

  // Convertir documento de Firestore a objeto UserProfile
  UserProfile _userProfileFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return UserProfile(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      photoURL: data['photoURL'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      favoriteOpositions: List<String>.from(data['favoriteOpositions'] ?? []),
      favoriteTopics: List<Map<String, dynamic>>.from(data['favoriteTopics'] ?? []),
      studyProgress: List<Map<String, dynamic>>.from(data['studyProgress'] ?? []),
      purchasedTemarios: List<String>.from(data['purchasedTemarios'] ?? []),
      subscriptionStatus: data['subscriptionStatus'] ?? 'none',
      subscriptionType: data['subscriptionType'],
      subscriptionStartDate: (data['subscriptionStartDate'] as Timestamp?)?.toDate(),
      subscriptionEndDate: (data['subscriptionEndDate'] as Timestamp?)?.toDate(),
      notificationSettings: Map<String, bool>.from(data['notificationSettings'] ?? {}),
      deviceTokens: List<String>.from(data['deviceTokens'] ?? []),
    );
  }
}
