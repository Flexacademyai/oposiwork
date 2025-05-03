import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:oposiwork/data/services/user_service.dart';

class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();
  final String _collection = 'subscriptions';

  // Obtener planes de suscripción disponibles
  Future<List<Map<String, dynamic>>> getSubscriptionPlans() async {
    try {
      final snapshot = await _firestore.collection('subscription_plans').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'description': data['description'] ?? '',
          'price': data['price'] ?? 0.0,
          'currency': data['currency'] ?? 'EUR',
          'duration': data['duration'] ?? 0, // en días
          'features': List<String>.from(data['features'] ?? []),
          'isPopular': data['isPopular'] ?? false,
          'type': data['type'] ?? 'monthly',
        };
      }).toList();
    } catch (e) {
      debugPrint('Error al obtener planes de suscripción: $e');
      
      // Si hay un error o no hay planes configurados, devolver los planes predeterminados
      return [
        {
          'id': 'one_time',
          'title': 'Pago único',
          'description': 'Acceso a todos los temarios y funciones extra.',
          'price': 17.0,
          'currency': 'EUR',
          'duration': 36500, // Aproximadamente 100 años (permanente)
          'features': [
            'Acceso a todos los temarios',
            'Descarga de PDFs',
            'Sin renovación automática',
            'Acceso permanente',
          ],
          'isPopular': false,
          'type': 'one_time',
        },
        {
          'id': 'monthly',
          'title': 'Mensual',
          'description': 'Acceso completo, actualizaciones y alertas exclusivas.',
          'price': 4.49,
          'currency': 'EUR',
          'duration': 30, // 30 días
          'features': [
            'Acceso a todos los temarios',
            'Descarga de PDFs',
            'Actualizaciones de temarios',
            'Alertas exclusivas',
            'Cancelación en cualquier momento',
          ],
          'isPopular': true,
          'type': 'monthly',
        },
        {
          'id': 'annual',
          'title': 'Anual',
          'description': 'Precio ideal para fidelizar y asegurar ingresos.',
          'price': 34.99,
          'currency': 'EUR',
          'duration': 365, // 365 días
          'features': [
            'Acceso a todos los temarios',
            'Descarga de PDFs',
            'Actualizaciones de temarios',
            'Alertas exclusivas',
            'Ahorro de 18,89 € respecto al plan mensual',
            'Cancelación en cualquier momento',
          ],
          'isPopular': false,
          'type': 'annual',
        },
      ];
    }
  }

  // Procesar nueva suscripción
  Future<Map<String, dynamic>> processSubscription({
    required String planId,
    required String paymentMethod,
    required String paymentToken,
  }) async {
    try {
      // Verificar que el usuario esté autenticado
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Obtener detalles del plan
      final plans = await getSubscriptionPlans();
      final plan = plans.firstWhere(
        (p) => p['id'] == planId,
        orElse: () => throw Exception('Plan no encontrado'),
      );

      // En una implementación real, aquí se procesaría el pago con una pasarela de pago
      // como Stripe, PayPal, Google Pay o Apple Pay
      
      // Simular procesamiento de pago exitoso
      final paymentId = 'payment_${DateTime.now().millisecondsSinceEpoch}';
      
      // Calcular fechas de inicio y fin de suscripción
      final startDate = DateTime.now();
      final endDate = startDate.add(Duration(days: plan['duration'] as int));
      
      // Registrar la suscripción en Firestore
      final subscriptionId = await _createSubscriptionRecord(
        userId: user.uid,
        planId: planId,
        paymentId: paymentId,
        startDate: startDate,
        endDate: endDate,
        amount: plan['price'] as double,
        currency: plan['currency'] as String,
        type: plan['type'] as String,
      );
      
      // Actualizar el estado de suscripción del usuario
      await _userService.updateSubscriptionStatus(
        userId: user.uid,
        status: 'active',
        type: plan['type'] as String,
        startDate: startDate,
        endDate: endDate,
      );
      
      // Devolver información de la suscripción
      return {
        'success': true,
        'subscriptionId': subscriptionId,
        'planId': planId,
        'startDate': startDate,
        'endDate': endDate,
        'amount': plan['price'],
        'currency': plan['currency'],
        'type': plan['type'],
      };
    } catch (e) {
      debugPrint('Error al procesar suscripción: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Procesar compra única de temario
  Future<Map<String, dynamic>> processSinglePurchase({
    required String temarioId,
    required String paymentMethod,
    required String paymentToken,
    required double amount,
  }) async {
    try {
      // Verificar que el usuario esté autenticado
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // En una implementación real, aquí se procesaría el pago con una pasarela de pago
      
      // Simular procesamiento de pago exitoso
      final paymentId = 'payment_${DateTime.now().millisecondsSinceEpoch}';
      
      // Registrar la compra en Firestore
      final purchaseId = await _createPurchaseRecord(
        userId: user.uid,
        temarioId: temarioId,
        paymentId: paymentId,
        amount: amount,
        currency: 'EUR',
      );
      
      // Añadir el temario a la lista de temarios comprados del usuario
      await _userService.addPurchasedTemario(
        userId: user.uid,
        temarioId: temarioId,
      );
      
      // Devolver información de la compra
      return {
        'success': true,
        'purchaseId': purchaseId,
        'temarioId': temarioId,
        'amount': amount,
        'currency': 'EUR',
      };
    } catch (e) {
      debugPrint('Error al procesar compra única: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Cancelar suscripción
  Future<bool> cancelSubscription(String subscriptionId) async {
    try {
      // Verificar que el usuario esté autenticado
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Verificar que la suscripción pertenece al usuario
      final subscriptionDoc = await _firestore
          .collection(_collection)
          .doc(subscriptionId)
          .get();
      
      if (!subscriptionDoc.exists || subscriptionDoc.data()?['userId'] != user.uid) {
        throw Exception('Suscripción no encontrada o no pertenece al usuario');
      }

      // Actualizar el estado de la suscripción
      await _firestore.collection(_collection).doc(subscriptionId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Actualizar el estado de suscripción del usuario
      // Nota: No eliminamos la suscripción inmediatamente, sino que la marcamos como cancelada
      // y seguirá activa hasta la fecha de finalización
      await _firestore.collection('users').doc(user.uid).update({
        'subscriptionStatus': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('Error al cancelar suscripción: $e');
      return false;
    }
  }

  // Verificar estado de suscripción
  Future<Map<String, dynamic>> checkSubscriptionStatus() async {
    try {
      // Verificar que el usuario esté autenticado
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Obtener perfil de usuario
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        throw Exception('Perfil de usuario no encontrado');
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final subscriptionStatus = userData['subscriptionStatus'] as String?;
      final subscriptionType = userData['subscriptionType'] as String?;
      final subscriptionEndDate = (userData['subscriptionEndDate'] as Timestamp?)?.toDate();

      // Verificar si la suscripción ha expirado
      if (subscriptionStatus == 'active' && 
          subscriptionEndDate != null && 
          subscriptionEndDate.isBefore(DateTime.now())) {
        // Actualizar estado a expirado
        await _firestore.collection('users').doc(user.uid).update({
          'subscriptionStatus': 'expired',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        return {
          'status': 'expired',
          'type': subscriptionType,
          'endDate': subscriptionEndDate,
        };
      }

      return {
        'status': subscriptionStatus ?? 'none',
        'type': subscriptionType,
        'endDate': subscriptionEndDate,
      };
    } catch (e) {
      debugPrint('Error al verificar estado de suscripción: $e');
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }

  // Crear registro de suscripción en Firestore
  Future<String> _createSubscriptionRecord({
    required String userId,
    required String planId,
    required String paymentId,
    required DateTime startDate,
    required DateTime endDate,
    required double amount,
    required String currency,
    required String type,
  }) async {
    final docRef = await _firestore.collection(_collection).add({
      'userId': userId,
      'planId': planId,
      'paymentId': paymentId,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'amount': amount,
      'currency': currency,
      'type': type,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'cancelledAt': null,
    });
    
    return docRef.id;
  }

  // Crear registro de compra única en Firestore
  Future<String> _createPurchaseRecord({
    required String userId,
    required String temarioId,
    required String paymentId,
    required double amount,
    required String currency,
  }) async {
    final docRef = await _firestore.collection('purchases').add({
      'userId': userId,
      'temarioId': temarioId,
      'paymentId': paymentId,
      'amount': amount,
      'currency': currency,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    return docRef.id;
  }
}
