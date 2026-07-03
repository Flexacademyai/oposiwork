import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/oposiciones_provider.dart';
import '../../providers/progreso_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSaludo(context, ref),
              const SizedBox(height: 24),
              _buildTarjetaRacha(context, ref),
              const SizedBox(height: 24),
              _buildSeccionOposiciones(context, ref),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildNavBar(context),
    );
  }

  Widget _buildSaludo(BuildContext context, WidgetRef ref) {
    final perfilAsync = ref.watch(perfilProvider);
    final nombreUsuario = perfilAsync.when(
      data: (p) => p?.nombre ?? 'Opositor',
      loading: () => '...',
      error: (_, __) => 'Opositor',
    );

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, $nombreUsuario',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(
                '¿Qué estudias hoy?',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded),
          onPressed: () => context.push(AppRoutes.notificaciones),
        ),
        IconButton(
          icon: const Icon(Icons.person_outline_rounded),
          onPressed: () => context.push(AppRoutes.perfil),
        ),
      ],
    );
  }

  Widget _buildTarjetaRacha(BuildContext context, WidgetRef ref) {
    final rachaAsync = ref.watch(rachaActualProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 40)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              rachaAsync.when(
                data:
                    (racha) => Text(
                      '$racha días de racha',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                    ),
                loading:
                    () => const CircularProgressIndicator(color: Colors.white),
                error:
                    (_, __) => const Text(
                      '0 días de racha',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
              ),
              Text(
                '¡Sigue así!',
                style: TextStyle(color: Colors.white.withAlpha(200)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionOposiciones(BuildContext context, WidgetRef ref) {
    final oposicionesAsync = ref.watch(todasLasOposicionesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.oposiciones,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            TextButton(
              onPressed: () => context.push(AppRoutes.oposiciones),
              child: const Text('Ver todas'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        oposicionesAsync.when(
          data:
              (oposiciones) => ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: oposiciones.take(3).length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final oposicion = oposiciones[index];
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.gavel_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      title: Text(
                        oposicion.nombre,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      subtitle: Text(
                        '${oposicion.administracion} · ${oposicion.nivel}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: AppColors.textTertiary,
                      ),
                      onTap:
                          () => context.push(
                            AppRoutes.oposicionDetail.replaceFirst(
                              ':id',
                              oposicion.id,
                            ),
                          ),
                    ),
                  );
                },
              ),
          loading: () => const LoadingWidget(),
          error: (e, _) => AppErrorWidget(mensaje: e.toString()),
        ),
      ],
    );
  }

  Widget _buildNavBar(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home_rounded),
          label: AppStrings.inicio,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.menu_book_outlined),
          activeIcon: Icon(Icons.menu_book_rounded),
          label: AppStrings.oposiciones,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_outlined),
          activeIcon: Icon(Icons.bar_chart_rounded),
          label: AppStrings.miProgreso,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline_rounded),
          activeIcon: Icon(Icons.person_rounded),
          label: AppStrings.perfil,
        ),
      ],
      onTap: (index) {
        switch (index) {
          case 1:
            context.push(AppRoutes.oposiciones);
          case 2:
            context.push(AppRoutes.progreso);
          case 3:
            context.push(AppRoutes.perfil);
        }
      },
    );
  }
}
