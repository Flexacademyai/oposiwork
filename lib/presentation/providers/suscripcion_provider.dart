import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../config/revenuecat_config.dart';

final suscripcionProvider = FutureProvider<CustomerInfo?>((ref) async {
  try {
    return await Purchases.getCustomerInfo();
  } catch (_) {
    return null;
  }
});

final tieneEntitlementPremiumProvider = FutureProvider<bool>((ref) async {
  try {
    final info = await Purchases.getCustomerInfo();
    return info.entitlements.active
        .containsKey(RevenueCatConfig.entitlementPremium);
  } catch (_) {
    return false;
  }
});

class SuscripcionNotifier extends AsyncNotifier<CustomerInfo?> {
  @override
  Future<CustomerInfo?> build() async {
    try {
      return await Purchases.getCustomerInfo();
    } catch (_) {
      return null;
    }
  }

  Future<bool> comprarMensual() async {
    return _comprar(RevenueCatConfig.productoMensual);
  }

  Future<bool> comprarAnual() async {
    return _comprar(RevenueCatConfig.productoAnual);
  }

  Future<bool> _comprar(String productoId) async {
    try {
      final offerings = await Purchases.getOfferings();
      final paquete = offerings.current?.availablePackages.firstWhere(
        (p) => p.storeProduct.identifier == productoId,
        orElse: () => offerings.current!.availablePackages.first,
      );
      if (paquete == null) return false;

      final info = await Purchases.purchasePackage(paquete);
      state = AsyncData(info);
      return info.entitlements.active
          .containsKey(RevenueCatConfig.entitlementPremium);
    } catch (e) {
      return false;
    }
  }

  Future<bool> restaurarCompras() async {
    try {
      final info = await Purchases.restorePurchases();
      state = AsyncData(info);
      return info.entitlements.active
          .containsKey(RevenueCatConfig.entitlementPremium);
    } catch (_) {
      return false;
    }
  }
}

final suscripcionNotifierProvider =
    AsyncNotifierProvider<SuscripcionNotifier, CustomerInfo?>(
  SuscripcionNotifier.new,
);
