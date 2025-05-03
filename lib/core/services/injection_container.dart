import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:oposiwork/data/datasources/auth_datasource.dart';
import 'package:oposiwork/data/datasources/oposition_datasource.dart';
import 'package:oposiwork/data/repositories/auth_repository_impl.dart';
import 'package:oposiwork/data/repositories/oposition_repository_impl.dart';
import 'package:oposiwork/domain/repositories/auth_repository.dart';
import 'package:oposiwork/domain/repositories/oposition_repository.dart';
import 'package:oposiwork/domain/usecases/auth/login_usecase.dart';
import 'package:oposiwork/domain/usecases/auth/register_usecase.dart';
import 'package:oposiwork/domain/usecases/opositions/get_opositions_usecase.dart';
import 'package:oposiwork/presentation/blocs/auth/auth_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => Dio());
  sl.registerLazySingleton(() => const FlutterSecureStorage());

  // Data sources
  sl.registerLazySingleton<AuthDataSource>(
    () => AuthDataSourceImpl(dio: sl(), secureStorage: sl()),
  );
  sl.registerLazySingleton<OpositionDataSource>(
    () => OpositionDataSourceImpl(dio: sl()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(dataSource: sl()),
  );
  sl.registerLazySingleton<OpositionRepository>(
    () => OpositionRepositoryImpl(dataSource: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => LoginUseCase(repository: sl()));
  sl.registerLazySingleton(() => RegisterUseCase(repository: sl()));
  sl.registerLazySingleton(() => GetOpositionsUseCase(repository: sl()));

  // BLoCs
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      registerUseCase: sl(),
    ),
  );
}
