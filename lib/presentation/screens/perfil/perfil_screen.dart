import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/revenuecat_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/suscripcion_provider.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/loading_widget.dart';

final _perfilProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((
  ref,
) async {
  final supabase = ref.watch(supabaseClientProvider);
  final user = supabase.auth.currentUser;
  if (user == null) return null;
  final data =
      await supabase.from('perfiles').select().eq('id', user.id).maybeSingle();
  return data;
});

class PerfilScreen extends ConsumerWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final esPremium = ref.watch(esPremiumProvider);
    final perfilAsync = ref.watch(_perfilProvider);
    final user = ref.watch(supabaseClientProvider).auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: perfilAsync.when(
        data:
            (perfil) => SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildAvatar(context, perfil, user?.email),
                  const SizedBox(height: 24),
                  _buildTarjetaPlan(context, ref, esPremium, perfil),
                  const SizedBox(height: 16),
                  _buildSeccion(context, 'Cuenta', [
                    _buildItem(
                      context,
                      Icons.person_outline,
                      'Nombre',
                      perfil?['nombre'] as String? ?? 'Sin nombre',
                    ),
                    _buildItem(
                      context,
                      Icons.email_outlined,
                      'Email',
                      user?.email ?? '',
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _buildSeccion(context, 'Preferencias', [
                    _buildSwitch(
                      context,
                      ref,
                      Icons.notifications_outlined,
                      'Notificaciones push',
                      perfil?['notificaciones_push'] as bool? ?? true,
                      'notificaciones_push',
                      perfil,
                    ),
                    _buildSwitch(
                      context,
                      ref,
                      Icons.email_outlined,
                      'Notificaciones email',
                      perfil?['notificaciones_email'] as bool? ?? true,
                      'notificaciones_email',
                      perfil,
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _buildSeccion(context, 'Aplicación', [
                    ListTile(
                      leading: const Icon(
                        Icons.star_outline,
                        color: AppColors.textSecondary,
                      ),
                      title: const Text('Valorar app'),
                      trailing: const Icon(
                        Icons.open_in_new,
                        size: 16,
                        color: AppColors.textTertiary,
                      ),
                      // Sin ficha en tiendas todavía: la valoración llega por
                      // email. Al publicar en App Store/Play, cambiar a
                      // valoración nativa (in_app_review).
                      onTap:
                          () => _abrirEnlace(
                            context,
                            'mailto:soporte@oposiwork.com?subject=Mi%20opini%C3%B3n%20sobre%20Oposiwork',
                          ),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.privacy_tip_outlined,
                        color: AppColors.textSecondary,
                      ),
                      title: const Text('Política de privacidad'),
                      trailing: const Icon(
                        Icons.open_in_new,
                        size: 16,
                        color: AppColors.textTertiary,
                      ),
                      onTap:
                          () => _abrirEnlace(
                            context,
                            'https://www.oposiwork.com/privacidad/',
                          ),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.description_outlined,
                        color: AppColors.textSecondary,
                      ),
                      title: const Text('Términos de uso'),
                      trailing: const Icon(
                        Icons.open_in_new,
                        size: 16,
                        color: AppColors.textTertiary,
                      ),
                      onTap:
                          () => _abrirEnlace(
                            context,
                            'https://www.oposiwork.com/terminos/',
                          ),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _cerrarSesion(context, ref),
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: AppColors.error,
                      ),
                      label: const Text(
                        'Cerrar sesión',
                        style: TextStyle(color: AppColors.error),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        loading: () => const LoadingWidget(),
        error: (e, _) => AppErrorWidget(mensaje: e.toString()),
      ),
    );
  }

  Widget _buildAvatar(
    BuildContext context,
    Map<String, dynamic>? perfil,
    String? email,
  ) {
    final nombre = perfil?['nombre'] as String? ?? '';
    final inicial =
        nombre.isNotEmpty
            ? nombre[0].toUpperCase()
            : (email?.isNotEmpty == true ? email![0].toUpperCase() : '?');
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: AppColors.primary,
          child: Text(
            inicial,
            style: const TextStyle(
              fontSize: 32,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          nombre.isNotEmpty ? nombre : email ?? '',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (email != null && nombre.isNotEmpty)
          Text(
            email,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
      ],
    );
  }

  Widget _buildTarjetaPlan(
    BuildContext context,
    WidgetRef ref,
    bool esPremium,
    Map<String, dynamic>? perfil,
  ) {
    final pagosActivos = RevenueCatConfig.pagosHabilitados;
    final planFin =
        perfil?['plan_fin'] != null
            ? DateTime.tryParse(perfil!['plan_fin'] as String)
            : null;
    return Card(
      color: esPremium ? AppColors.primary.withAlpha(15) : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              esPremium
                  ? Icons.workspace_premium_rounded
                  : Icons.lock_outline_rounded,
              color: esPremium ? AppColors.primary : AppColors.textSecondary,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    esPremium ? 'Plan Premium activo' : 'Plan gratuito',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (esPremium && planFin != null)
                    Text(
                      'Válido hasta ${planFin.day}/${planFin.month}/${planFin.year}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    )
                  else if (!esPremium)
                    const Text(
                      'Acceso limitado al contenido',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            if (!esPremium)
              TextButton(
                onPressed: () => context.push(AppRoutes.suscripcion),
                child: Text(pagosActivos ? 'Mejorar' : 'Ver Premium'),
              )
            else if (pagosActivos && perfil?['stripe_customer_id'] != null)
              TextButton(
                onPressed: () => _abrirPortalStripe(context, ref),
                child: const Text('Gestionar'),
              ),
          ],
        ),
      ),
    );
  }

  /// Abre un enlace externo (web legal, mailto...) en pestaña/app externa.
  Future<void> _abrirEnlace(BuildContext context, String url) async {
    final abierto = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!context.mounted || abierto) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No se pudo abrir el enlace'),
        backgroundColor: AppColors.textTertiary,
      ),
    );
  }

  Future<void> _abrirPortalStripe(BuildContext context, WidgetRef ref) async {
    final abierto =
        await ref
            .read(suscripcionNotifierProvider.notifier)
            .abrirPortalCliente();
    if (!context.mounted || abierto) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No se pudo abrir el portal de Stripe'),
        backgroundColor: AppColors.textTertiary,
      ),
    );
  }

  Widget _buildSeccion(
    BuildContext context,
    String titulo,
    List<Widget> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            titulo,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: AppColors.textSecondary),
          ),
        ),
        Card(child: Column(children: items)),
      ],
    );
  }

  Widget _buildItem(
    BuildContext context,
    IconData icono,
    String titulo,
    String valor,
  ) {
    return ListTile(
      leading: Icon(icono, color: AppColors.textSecondary),
      title: Text(titulo),
      trailing: Text(
        valor,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
    );
  }

  Widget _buildSwitch(
    BuildContext context,
    WidgetRef ref,
    IconData icono,
    String titulo,
    bool valor,
    String campo,
    Map<String, dynamic>? perfil,
  ) {
    return SwitchListTile(
      secondary: Icon(icono, color: AppColors.textSecondary),
      title: Text(titulo),
      value: valor,
      onChanged: (val) async {
        if (perfil == null) return;
        final supabase = ref.read(supabaseClientProvider);
        final user = supabase.auth.currentUser;
        if (user == null) return;
        await supabase.from('perfiles').update({campo: val}).eq('id', user.id);
        ref.invalidate(_perfilProvider);
      },
    );
  }

  Future<void> _cerrarSesion(BuildContext context, WidgetRef ref) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Cerrar sesión'),
            content: const Text('¿Seguro que quieres salir de tu cuenta?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Salir',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
    );
    if (confirmar == true && context.mounted) {
      await AuthRepository(ref.read(supabaseClientProvider)).cerrarSesion();
      if (context.mounted) context.go(AppRoutes.login);
    }
  }
}
