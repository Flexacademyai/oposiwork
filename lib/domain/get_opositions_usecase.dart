import 'package:oposiwork/domain/repositories/oposition_repository.dart';
import 'package:oposiwork/domain/entities/oposition.dart';

class GetOpositionsUseCase {
  final OpositionRepository repository;

  GetOpositionsUseCase({required this.repository});

  Future<List<Oposition>> call({
    String? query,
    Map<String, dynamic>? filters,
    int? limit,
    int? offset,
  }) {
    return repository.getOpositions(
      query: query,
      filters: filters,
      limit: limit,
      offset: offset,
    );
  }
}
