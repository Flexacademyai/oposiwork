import 'package:oposiwork/domain/entities/user.dart';

abstract class AuthRepository {
  Future<User> login({required String email, required String password});
  Future<User> register({required String email, required String password, String? name});
  Future<bool> logout();
  Future<User?> getCurrentUser();
  Future<bool> isLoggedIn();
  Future<bool> updateUserPreferences(UserPreferences preferences);
  Future<bool> updateUserProfile({String? name, String? email});
}
