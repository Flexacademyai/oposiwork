import 'package:oposiwork/domain/entities/temario.dart';

abstract class TemarioRepository {
  Future<List<Temario>> getTemariosByOpositionId(String opositionId);
  
  Future<Temario> getTemarioById(String id);
  
  Future<List<Topic>> getTopicsByTemarioId(String temarioId);
  
  Future<Topic> getTopicById(String temarioId, int topicNumber);
  
  Future<String?> getTopicPdfUrl(String temarioId, int topicNumber);
  
  Future<bool> downloadTemario(String temarioId);
  
  Future<List<Temario>> getDownloadedTemarios();
  
  Future<bool> checkPremiumAccess();
}
