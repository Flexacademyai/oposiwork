import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/revenuecat_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../providers/suscripcion_provider.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _anualSeleccionado = true;
  bool _consentimientoDesistimiento = false;

  @override
  Widget build(BuildContext context) {
    final suscripcionState = ref.watch(suscripcionNotifierProvider);
    final cargando = suscripcionState.isLoading;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildCerrar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildCabecera(context),
                      const SizedBox(height: 32),
                      _buildBeneficios(context),
                      const SizedBox(height: 32),
                      _buildSelectorPlan(context),
                      const SizedBox(height: 16),
                      _buildConsentimiento(context),
                      const SizedBox(height: 16),
                      _buildBotonComprar(context, cargando),
                      const SizedBox(height: 12),
                      _buildRestaurar(cargando),
                      const SizedBox(height: 8),
                      _buildTerminos(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCerrar(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: IconButton(
        icon: const Icon(Icons.close_rounded, color: Colors.white),
        onPressed: () => context.pop(),
      ),
    );
  }

  Widget _buildCabecera(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(30),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.workspace_premium_rounded,
            size: 48,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Desbloquea todo con Premium',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Accede a todo el contenido para preparar tu oposición',
          style: TextStyle(color: Colors.white.withAlpha(200)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBeneficios(BuildContext context) {
    final items = [
      (Icons.menu_book_rounded, 'Temario completo con resúmenes IA'),
      (Icons.style_rounded, 'Flashcards con repaso espaciado'),
      (Icons.quiz_rounded, 'Tests ilimitados con explicaciones'),
      (Icons.psychology_rounded, 'Psicotécnicos (Policía y Bomberos)'),
      (Icons.trending_up_rounded, 'Seguimiento de progreso completo'),
      (
        Icons.picture_as_pdf_rounded,
        'Descarga del PDF oficial cuando este disponible',
      ),
      (Icons.notifications_rounded, 'Alertas de cambios en convocatorias'),
      (Icons.emoji_events_rounded, 'Gamificación y logros'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children:
            items
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(item.$1, color: Colors.white, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.$2,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _buildSelectorPlan(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TarjetaPlan(
            titulo: AppStrings.planAnual,
            precio: AppStrings.precioAnual,
            badge: AppStrings.ahorro,
            seleccionado: _anualSeleccionado,
            onTap: () => setState(() => _anualSeleccionado = true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TarjetaPlan(
            titulo: AppStrings.planMensual,
            precio: AppStrings.precioMensual,
            seleccionado: !_anualSeleccionado,
            onTap: () => setState(() => _anualSeleccionado = false),
          ),
        ),
      ],
    );
  }

  // Consentimiento expreso de inicio inmediato y renuncia al desistimiento
  // sobre contenido digital (art. 103.m TRLGDCU). Solo aplica al pago web;
  // en móvil el desistimiento lo rigen App Store / Google Play.
  Widget _buildConsentimiento(BuildContext context) {
    if (!kIsWeb || !RevenueCatConfig.pagosHabilitados) {
      return const SizedBox.shrink();
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _consentimientoDesistimiento,
          onChanged: (v) =>
              setState(() => _consentimientoDesistimiento = v ?? false),
          checkColor: AppColors.primary,
          fillColor: WidgetStateProperty.all(Colors.white),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Solicito el inicio inmediato del servicio y acepto que, al '
              'comenzar el acceso al contenido premium, pierdo el derecho de '
              'desistimiento (art. 103.m TRLGDCU).',
              style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBotonComprar(BuildContext context, bool cargando) {
    final pagosActivos = RevenueCatConfig.pagosHabilitados;
    return ElevatedButton(
      onPressed:
          cargando
              ? null
              : pagosActivos
              ? _comprar
              : _mostrarAvisoMvp,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child:
          cargando
              ? const CircularProgressIndicator(color: AppColors.primary)
              : Text(
                pagosActivos
                    ? 'Suscribirse - ${_anualSeleccionado ? AppStrings.precioAnual : AppStrings.precioMensual}'
                    : 'Premium disponible proximamente',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
    );
  }

  Widget _buildRestaurar(bool cargando) {
    if (kIsWeb || !RevenueCatConfig.pagosHabilitados) {
      return const SizedBox.shrink();
    }
    return TextButton(
      onPressed: cargando ? null : _restaurar,
      child: const Text(
        'Restaurar compras',
        style: TextStyle(color: Colors.white70),
      ),
    );
  }

  Widget _buildTerminos(BuildContext context) {
    if (!RevenueCatConfig.pagosHabilitados) {
      return Text(
        'MVP gratuito activo. El pago Premium se activara cuando Stripe, App Store y Google Play esten completamente verificados.',
        style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 11),
        textAlign: TextAlign.center,
      );
    }

    final texto =
        kIsWeb
            ? 'Pago seguro con Stripe. Al suscribirte aceptas los Términos de Uso y la Política de Privacidad. La suscripción se renueva automáticamente.'
            : 'Pago gestionado por App Store o Google Play. Al suscribirte aceptas los Términos de Uso y la Política de Privacidad. La suscripción se renueva automáticamente.';

    return Text(
      texto,
      style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 11),
      textAlign: TextAlign.center,
    );
  }

  void _mostrarAvisoMvp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Premium se activara en la fase final. Ya puedes probar el acceso gratuito.',
        ),
        backgroundColor: AppColors.textTertiary,
      ),
    );
  }

  Future<void> _comprar() async {
    // En web exigimos el consentimiento marcado; en móvil lo rige la tienda.
    final consentimiento = kIsWeb ? _consentimientoDesistimiento : true;
    final exito =
        _anualSeleccionado
            ? await ref
                .read(suscripcionNotifierProvider.notifier)
                .comprarAnual(consentimientoDesistimiento: consentimiento)
            : await ref
                .read(suscripcionNotifierProvider.notifier)
                .comprarMensual(consentimientoDesistimiento: consentimiento);

    if (!mounted) return;
    if (exito) {
      if (!kIsWeb) context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Bienvenido a Premium!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(suscripcionNotifierProvider.notifier).ultimoErrorPago ??
                'No se pudo iniciar el pago. Revisa la configuracion.',
          ),
          backgroundColor: AppColors.textTertiary,
        ),
      );
    }
  }

  Future<void> _restaurar() async {
    final exito =
        await ref.read(suscripcionNotifierProvider.notifier).restaurarCompras();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          exito
              ? 'Compras restauradas correctamente'
              : 'No se encontraron compras',
        ),
        backgroundColor: exito ? AppColors.success : AppColors.textTertiary,
      ),
    );
  }
}

class _TarjetaPlan extends StatelessWidget {
  final String titulo;
  final String precio;
  final String? badge;
  final bool seleccionado;
  final VoidCallback onTap;

  const _TarjetaPlan({
    required this.titulo,
    required this.precio,
    this.badge,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: seleccionado ? Colors.white : Colors.white.withAlpha(20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: seleccionado ? Colors.white : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  gradient: AppColors.premiumGradient,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              titulo,
              style: TextStyle(
                color: seleccionado ? AppColors.primary : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              precio,
              style: TextStyle(
                color: seleccionado ? AppColors.textPrimary : Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
