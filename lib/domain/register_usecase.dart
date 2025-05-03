import 'package:oposiwork/domain/repositories/auth_repository.dart';
import 'package:oposiwork/domain/entities/user.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase({required this.repository});

  Future<User> call({required String email, required String password, String? name}) {
    return repository.register(email: email, password: password, name: name);
  }
}
