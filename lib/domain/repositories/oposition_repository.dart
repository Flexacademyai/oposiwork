import 'package:oposiwork/domain/entities/oposition.dart';

abstract class OpositionRepository {
  Future<List<Oposition>> getOpositions({
    String? query,
    Map<String, dynamic>? filters,
    int? limit,
    int? offset,
  });
  
  Future<Oposition> getOpositionById(String id);
  
  Future<List<Oposition>> getFavoriteOpositions();
  
  Future<bool> addToFavorites(String opositionId);
  
  Future<bool> removeFromFavorites(String opositionId);
  
  Future<List<Oposition>> getRecentOpositions({int limit = 10});
  
  Future<List<Oposition>> getOpositionsByType(String type, {int? limit});
  
  Future<List<Oposition>> getOpositionsByLocation(String location, {int? limit});
}
