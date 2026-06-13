class RevenueCatConfig {
  RevenueCatConfig._();

  static const bool pagosHabilitados = bool.fromEnvironment(
    'PAGOS_HABILITADOS',
    defaultValue: false,
  );

  static const String apiKeyIos = String.fromEnvironment(
    'REVENUECAT_API_KEY_IOS',
  );
  static const String apiKeyAndroid = String.fromEnvironment(
    'REVENUECAT_API_KEY_ANDROID',
  );

  // Identificadores de productos en tiendas
  static const String productoMensual = 'oposiwork_monthly_999';
  static const String productoAnual = 'oposiwork_annual_7999';

  // Entitlement configurado en RevenueCat
  static const String entitlementPremium = 'premium';
}
