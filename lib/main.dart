import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'app.dart';
import 'config/supabase_config.dart';
import 'config/revenuecat_config.dart';
import 'data/services/notifications_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SupabaseConfig.validate();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // RevenueCat no soporta Flutter Web — solo inicializar en móvil
  if (!kIsWeb) {
    await _initRevenueCat();
    await NotificationsService.initialize();
  }

  runApp(const ProviderScope(child: OposiworkApp()));
}

Future<void> _initRevenueCat() async {
  final apiKey =
      defaultTargetPlatform == TargetPlatform.iOS
          ? RevenueCatConfig.apiKeyIos
          : RevenueCatConfig.apiKeyAndroid;

  await Purchases.configure(PurchasesConfiguration(apiKey));
}
