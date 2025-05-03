import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream para escuchar cambios en el estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Obtener usuario actual
  User? get currentUser => _auth.currentUser;

  // Registrar usuario con email y contraseña
  Future<UserCredential?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Crear usuario en Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Actualizar el perfil del usuario con su nombre
      await userCredential.user?.updateDisplayName(name);
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Error en registro: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Error desconocido en registro: $e');
      rethrow;
    }
  }

  // Iniciar sesión con email y contraseña
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('Error en inicio de sesión: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Error desconocido en inicio de sesión: $e');
      rethrow;
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error al cerrar sesión: $e');
      rethrow;
    }
  }

  // Restablecer contraseña
  Future<void> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      debugPrint('Error al restablecer contraseña: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Error desconocido al restablecer contraseña: $e');
      rethrow;
    }
  }

  // Actualizar perfil de usuario
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      await _auth.currentUser?.updateDisplayName(displayName);
      await _auth.currentUser?.updatePhotoURL(photoURL);
    } catch (e) {
      debugPrint('Error al actualizar perfil: $e');
      rethrow;
    }
  }

  // Verificar email
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } catch (e) {
      debugPrint('Error al enviar verificación de email: $e');
      rethrow;
    }
  }

  // Cambiar contraseña
  Future<void> changePassword({required String newPassword}) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      debugPrint('Error al cambiar contraseña: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Error desconocido al cambiar contraseña: $e');
      rethrow;
    }
  }

  // Reautenticar usuario (necesario para operaciones sensibles)
  Future<UserCredential> reauthenticateUser({
    required String email,
    required String password,
  }) async {
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      return await _auth.currentUser!.reauthenticateWithCredential(credential);
    } catch (e) {
      debugPrint('Error al reautenticar: $e');
      rethrow;
    }
  }

  // Eliminar cuenta
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      debugPrint('Error al eliminar cuenta: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Error desconocido al eliminar cuenta: $e');
      rethrow;
    }
  }
}
