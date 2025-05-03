import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oposiwork/data/services/auth_service.dart';
import 'package:oposiwork/data/services/user_service.dart';
import 'package:oposiwork/domain/entities/user.dart';

// Eventos
abstract class AuthEvent {}

class AuthCheckStatusEvent extends AuthEvent {}

class AuthLoginEvent extends AuthEvent {
  final String email;
  final String password;

  AuthLoginEvent({required this.email, required this.password});
}

class AuthRegisterEvent extends AuthEvent {
  final String name;
  final String email;
  final String password;

  AuthRegisterEvent({
    required this.name,
    required this.email,
    required this.password,
  });
}

class AuthLogoutEvent extends AuthEvent {}

class AuthResetPasswordEvent extends AuthEvent {
  final String email;

  AuthResetPasswordEvent({required this.email});
}

// Estados
abstract class AuthState {}

class AuthInitialState extends AuthState {}

class AuthLoadingState extends AuthState {}

class AuthAuthenticatedState extends AuthState {
  final UserProfile user;

  AuthAuthenticatedState({required this.user});
}

class AuthUnauthenticatedState extends AuthState {}

class AuthErrorState extends AuthState {
  final String message;

  AuthErrorState({required this.message});
}

class AuthPasswordResetSentState extends AuthState {}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  final UserService _userService;

  AuthBloc({
    required AuthService authService,
    required UserService userService,
  })  : _authService = authService,
        _userService = userService,
        super(AuthInitialState()) {
    on<AuthCheckStatusEvent>(_onCheckStatus);
    on<AuthLoginEvent>(_onLogin);
    on<AuthRegisterEvent>(_onRegister);
    on<AuthLogoutEvent>(_onLogout);
    on<AuthResetPasswordEvent>(_onResetPassword);
  }

  Future<void> _onCheckStatus(
    AuthCheckStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        // Obtener perfil de usuario desde Firestore
        final userProfileStream = _userService.getUserProfile(currentUser.uid);
        await for (final userProfile in userProfileStream) {
          if (userProfile != null) {
            emit(AuthAuthenticatedState(user: userProfile));
            break;
          } else {
            // Si no existe el perfil en Firestore, crearlo
            await _userService.createUserProfile(
              userId: currentUser.uid,
              name: currentUser.displayName ?? 'Usuario',
              email: currentUser.email ?? '',
            );
            
            // Volver a obtener el perfil
            continue;
          }
        }
      } else {
        emit(AuthUnauthenticatedState());
      }
    } catch (e) {
      emit(AuthErrorState(message: 'Error al verificar estado de autenticación: $e'));
    }
  }

  Future<void> _onLogin(
    AuthLoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    try {
      // Iniciar sesión con email y contraseña
      final userCredential = await _authService.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      
      if (userCredential != null && userCredential.user != null) {
        // Obtener perfil de usuario desde Firestore
        final userProfileStream = _userService.getUserProfile(userCredential.user!.uid);
        await for (final userProfile in userProfileStream) {
          if (userProfile != null) {
            emit(AuthAuthenticatedState(user: userProfile));
            break;
          } else {
            // Si no existe el perfil en Firestore, crearlo
            await _userService.createUserProfile(
              userId: userCredential.user!.uid,
              name: userCredential.user!.displayName ?? 'Usuario',
              email: userCredential.user!.email ?? '',
            );
            
            // Volver a obtener el perfil
            continue;
          }
        }
      } else {
        emit(AuthErrorState(message: 'Error al iniciar sesión'));
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No existe una cuenta con este email';
          break;
        case 'wrong-password':
          errorMessage = 'Contraseña incorrecta';
          break;
        case 'invalid-email':
          errorMessage = 'El formato del email no es válido';
          break;
        case 'user-disabled':
          errorMessage = 'Esta cuenta ha sido deshabilitada';
          break;
        default:
          errorMessage = 'Error al iniciar sesión: ${e.message}';
      }
      emit(AuthErrorState(message: errorMessage));
    } catch (e) {
      emit(AuthErrorState(message: 'Error al iniciar sesión: $e'));
    }
  }

  Future<void> _onRegister(
    AuthRegisterEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    try {
      // Registrar usuario con email y contraseña
      final userCredential = await _authService.registerWithEmailAndPassword(
        email: event.email,
        password: event.password,
        name: event.name,
      );
      
      if (userCredential != null && userCredential.user != null) {
        // Crear perfil de usuario en Firestore
        await _userService.createUserProfile(
          userId: userCredential.user!.uid,
          name: event.name,
          email: event.email,
        );
        
        // Obtener perfil de usuario desde Firestore
        final userProfileStream = _userService.getUserProfile(userCredential.user!.uid);
        await for (final userProfile in userProfileStream) {
          if (userProfile != null) {
            emit(AuthAuthenticatedState(user: userProfile));
            break;
          }
        }
      } else {
        emit(AuthErrorState(message: 'Error al registrar usuario'));
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'Ya existe una cuenta con este email';
          break;
        case 'invalid-email':
          errorMessage = 'El formato del email no es válido';
          break;
        case 'weak-password':
          errorMessage = 'La contraseña es demasiado débil';
          break;
        case 'operation-not-allowed':
          errorMessage = 'El registro con email y contraseña no está habilitado';
          break;
        default:
          errorMessage = 'Error al registrar usuario: ${e.message}';
      }
      emit(AuthErrorState(message: errorMessage));
    } catch (e) {
      emit(AuthErrorState(message: 'Error al registrar usuario: $e'));
    }
  }

  Future<void> _onLogout(
    AuthLogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    try {
      await _authService.signOut();
      emit(AuthUnauthenticatedState());
    } catch (e) {
      emit(AuthErrorState(message: 'Error al cerrar sesión: $e'));
    }
  }

  Future<void> _onResetPassword(
    AuthResetPasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    try {
      await _authService.resetPassword(email: event.email);
      emit(AuthPasswordResetSentState());
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No existe una cuenta con este email';
          break;
        case 'invalid-email':
          errorMessage = 'El formato del email no es válido';
          break;
        default:
          errorMessage = 'Error al restablecer contraseña: ${e.message}';
      }
      emit(AuthErrorState(message: errorMessage));
    } catch (e) {
      emit(AuthErrorState(message: 'Error al restablecer contraseña: $e'));
    }
  }
}
