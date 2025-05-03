import 'package:oposiwork/domain/repositories/auth_repository.dart';
import 'package:oposiwork/domain/entities/user.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase({required this.repository});

  Future<User> call({required String email, required String password}) {
    return repository.login(email: email, password: password);
  }
}
