import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:oposiwork/data/services/user_service.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final UserService _userService = UserService();

  // Inicializar servicio de notificaciones
  Future<void> initialize() async {
    try {
      // Solicitar permisos para notificaciones
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('Permisos de notificación: ${settings.authorizationStatus}');

      // Configurar manejadores de notificaciones
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
      
      // Obtener token del dispositivo
      final token = await _messaging.getToken();
      if (token != null) {
        debugPrint('Token FCM: $token');
        // Guardar token en Firestore (si el usuario está autenticado)
        _saveTokenToDatabase(token);
      }

      // Escuchar cambios en el token
      _messaging.onTokenRefresh.listen(_saveTokenToDatabase);
    } catch (e) {
      debugPrint('Error al inicializar servicio de notificaciones: $e');
    }
  }

  // Guardar token en la base de datos
  Future<void> _saveTokenToDatabase(String token) async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser != null) {
        await _userService.registerDeviceToken(
          userId: currentUser.uid,
          token: token,
        );
      }
    } catch (e) {
      debugPrint('Error al guardar token en la base de datos: $e');
    }
  }

  // Manejar mensajes en primer plano
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Mensaje recibido en primer plano: ${message.notification?.title}');
    
    // Aquí se podría mostrar una notificación local o un diálogo
    // dependiendo de las preferencias del usuario
  }

  // Manejar mensajes cuando se abre la app desde una notificación
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('App abierta desde notificación: ${message.notification?.title}');
    
    // Aquí se podría navegar a una pantalla específica según el tipo de notificación
    // Por ejemplo, si es una notificación de nueva oposición, navegar a la pantalla de detalle
  }

  // Suscribirse a temas para recibir notificaciones específicas
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('Suscrito al tema: $topic');
    } catch (e) {
      debugPrint('Error al suscribirse al tema: $e');
    }
  }

  // Cancelar suscripción a temas
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('Suscripción cancelada al tema: $topic');
    } catch (e) {
      debugPrint('Error al cancelar suscripción al tema: $e');
    }
  }

  // Obtener usuario actual (auxiliar)
  Future<firebase_auth.User?> getCurrentUser() async {
    return firebase_auth.FirebaseAuth.instance.currentUser;
  }
}
