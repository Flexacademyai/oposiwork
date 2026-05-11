import 'package:supabase_flutter/supabase_flutter.dart';

class SignedPdfDownload {
  final String url;
  final String nombre;

  const SignedPdfDownload({required this.url, required this.nombre});
}

class StorageService {
  final SupabaseClient _supabase;

  StorageService(this._supabase);

  Future<SignedPdfDownload> crearDescargaPdf(String pdfId) async {
    final response = await _supabase.functions.invoke(
      'download-pdf',
      body: {'pdfId': pdfId},
    );

    final data = response.data;
    if (data is! Map) {
      throw Exception('Respuesta inesperada al preparar la descarga.');
    }

    if (data['error'] != null) {
      throw Exception(data['error'].toString());
    }

    final url = data['url'] as String?;
    final nombre = data['nombre'] as String?;
    if (url == null || nombre == null) {
      throw Exception('La función no devolvió una URL de descarga válida.');
    }

    return SignedPdfDownload(url: url, nombre: nombre);
  }
}
