import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';

class PremiumLockWidget extends ConsumerWidget {
  final Widget child;
  final bool mostrarBloqueo;

  const PremiumLockWidget({
    super.key,
    required this.child,
    this.mostrarBloqueo = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final esPremium = ref.watch(esPremiumProvider);

    if (esPremium || !mostrarBloqueo) return child;

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(230),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppColors.premiumGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppStrings.contenidoPremium,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Suscríbete para acceder',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.push(AppRoutes.suscripcion),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.premium,
                    minimumSize: const Size(160, 44),
                  ),
                  child: const Text(AppStrings.desbloquearPremium),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
