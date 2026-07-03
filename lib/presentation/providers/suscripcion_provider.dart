import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/revenuecat_config.dart';
import 'auth_provider.dart';

final suscripcionProvider = FutureProvider<CustomerInfo?>((ref) async {
  if (kIsWeb || !RevenueCatConfig.pagosHabilitados) return null;
  try {
    return await Purchases.getCustomerInfo();
  } catch (_) {
    return null;
  }
});

final tieneEntitlementPremiumProvider = FutureProvider<bool>((ref) async {
  if (kIsWeb) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return false;
    final perfil =
        await Supabase.instance.client
            .from('perfiles')
            .select('plan, plan_fin')
            .eq('id', userId)
            .maybeSingle();
    final plan = perfil?['plan'] as String?;
    final planFin = perfil?['plan_fin'] as String?;
    if (plan == null || plan == 'free' || planFin == null) return false;
    return DateTime.parse(planFin).isAfter(DateTime.now());
  }
  if (!RevenueCatConfig.pagosHabilitados) return false;
  try {
    final info = await Purchases.getCustomerInfo();
    return info.entitlements.active.containsKey(
      RevenueCatConfig.entitlementPremium,
    );
  } catch (_) {
    return false;
  }
});

class SuscripcionNotifier extends AsyncNotifier<CustomerInfo?> {
  String? _ultimoErrorPago;

  String? get ultimoErrorPago => _ultimoErrorPago;

  @override
  Future<CustomerInfo?> build() async {
    if (kIsWeb || !RevenueCatConfig.pagosHabilitados) return null;
    try {
      return await Purchases.getCustomerInfo();
    } catch (_) {
      return null;
    }
  }

  Future<bool> comprarMensual({bool consentimientoDesistimiento = false}) async {
    if (!RevenueCatConfig.pagosHabilitados) return _pagoNoDisponible();
    if (kIsWeb) return _comprarWeb('monthly', consentimientoDesistimiento);
    return _comprarMovil(RevenueCatConfig.productoMensual);
  }

  Future<bool> comprarAnual({bool consentimientoDesistimiento = false}) async {
    if (!RevenueCatConfig.pagosHabilitados) return _pagoNoDisponible();
    if (kIsWeb) return _comprarWeb('annual', consentimientoDesistimiento);
    return _comprarMovil(RevenueCatConfig.productoAnual);
  }

  Future<bool> _pagoNoDisponible() async {
    _ultimoErrorPago =
        'Premium se activara en la fase final del lanzamiento. De momento puedes usar el acceso gratuito.';
    state = const AsyncData(null);
    return false;
  }

  Future<bool> _comprarMovil(String productoId) async {
    state = const AsyncLoading();
    try {
      await _sincronizarRevenueCatConUsuario();
      final offerings = await Purchases.getOfferings();
      final paquetes = offerings.current?.availablePackages ?? const [];
      if (paquetes.isEmpty) {
        state = const AsyncData(null);
        return false;
      }

      final paquete = paquetes.firstWhere(
        (p) => p.storeProduct.identifier == productoId,
        orElse: () => paquetes.first,
      );

      final info = await Purchases.purchasePackage(paquete);
      state = AsyncData(info);
      final tienePremium = info.entitlements.active.containsKey(
        RevenueCatConfig.entitlementPremium,
      );
      if (tienePremium) {
        ref.invalidate(suscripcionProvider);
        ref.invalidate(tieneEntitlementPremiumProvider);
        ref.invalidate(perfilProvider);
      }
      return tienePremium;
    } catch (e) {
      state = const AsyncData(null);
      return false;
    }
  }

  Future<bool> _comprarWeb(String plan, bool consentimientoDesistimiento) async {
    state = const AsyncLoading();
    _ultimoErrorPago = null;
    try {
      final supabase = Supabase.instance.client;
      if (supabase.auth.currentUser == null) {
        _ultimoErrorPago = 'Inicia sesion antes de suscribirte.';
        state = const AsyncData(null);
        return false;
      }

      // Consentimiento expreso de ejecucion inmediata y renuncia al
      // desistimiento sobre contenido digital (art. 103.m TRLGDCU).
      if (!consentimientoDesistimiento) {
        _ultimoErrorPago =
            'Debes aceptar el inicio inmediato del servicio para continuar.';
        state = const AsyncData(null);
        return false;
      }

      final response = await supabase.functions.invoke(
        'create-stripe-checkout',
        body: {'plan': plan, 'consentimientoDesistimiento': true},
      );
      final data = response.data;
      final error = data is Map ? data['error'] as String? : null;
      if (error != null && error.isNotEmpty) {
        _ultimoErrorPago = error;
        state = const AsyncData(null);
        return false;
      }

      final url = data is Map ? data['url'] as String? : null;
      if (url == null || url.isEmpty) {
        _ultimoErrorPago = 'Stripe no devolvio una URL de pago.';
        state = const AsyncData(null);
        return false;
      }

      final launched = await launchUrl(
        Uri.parse(url),
        webOnlyWindowName: '_self',
      );
      state = const AsyncData(null);
      return launched;
    } catch (error) {
      _ultimoErrorPago = error.toString();
      state = const AsyncData(null);
      return false;
    }
  }

  Future<bool> restaurarCompras() async {
    if (kIsWeb || !RevenueCatConfig.pagosHabilitados) return false;
    state = const AsyncLoading();
    try {
      await _sincronizarRevenueCatConUsuario();
      final info = await Purchases.restorePurchases();
      state = AsyncData(info);
      final tienePremium = info.entitlements.active.containsKey(
        RevenueCatConfig.entitlementPremium,
      );
      if (tienePremium) {
        ref.invalidate(suscripcionProvider);
        ref.invalidate(tieneEntitlementPremiumProvider);
        ref.invalidate(perfilProvider);
      }
      return tienePremium;
    } catch (_) {
      state = const AsyncData(null);
      return false;
    }
  }

  Future<void> _sincronizarRevenueCatConUsuario() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) return;
    await Purchases.logIn(userId);
  }

  Future<bool> abrirPortalCliente() async {
    if (!kIsWeb || !RevenueCatConfig.pagosHabilitados) return false;
    state = const AsyncLoading();
    try {
      final supabase = Supabase.instance.client;
      if (supabase.auth.currentUser == null) {
        state = const AsyncData(null);
        return false;
      }

      final response = await supabase.functions.invoke('create-stripe-portal');
      final data = response.data;
      final url = data is Map ? data['url'] as String? : null;
      if (url == null || url.isEmpty) {
        state = const AsyncData(null);
        return false;
      }

      final launched = await launchUrl(
        Uri.parse(url),
        webOnlyWindowName: '_self',
      );
      state = const AsyncData(null);
      return launched;
    } catch (_) {
      state = const AsyncData(null);
      return false;
    }
  }
}

final suscripcionNotifierProvider =
    AsyncNotifierProvider<SuscripcionNotifier, CustomerInfo?>(
      SuscripcionNotifier.new,
    );
