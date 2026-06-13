import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/constants/app_routes.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/oposiciones/oposiciones_screen.dart';
import 'presentation/screens/oposiciones/cobertura_screen.dart';
import 'presentation/screens/oposiciones/oposicion_detail_screen.dart';
import 'presentation/screens/temario/temario_screen.dart';
import 'presentation/screens/temario/tema_detail_screen.dart';
import 'presentation/screens/flashcards/flashcards_screen.dart';
import 'presentation/screens/tests/test_screen.dart';
import 'presentation/screens/tests/resultado_test_screen.dart';
import 'presentation/screens/supuestos/supuestos_screen.dart';
import 'presentation/screens/psicotecnicos/psicotecnicos_screen.dart';
import 'presentation/screens/progreso/progreso_screen.dart';
import 'presentation/screens/estudio/plan_estudio_screen.dart';
import 'presentation/screens/estudio/alarmas_screen.dart';
import 'presentation/screens/perfil/perfil_screen.dart';
import 'presentation/screens/notificaciones/notificaciones_screen.dart';
import 'presentation/screens/suscripcion/paywall_screen.dart';
import 'presentation/screens/simulacro/simulacro_screen.dart';
import 'presentation/screens/simulacro/resultado_simulacro_screen.dart';
import 'presentation/screens/chat/chat_screen.dart';
import 'presentation/screens/voz/voz_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final estaAuth = ref.watch(estaAutenticadoProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final rutasPublicas = [
        AppRoutes.splash,
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.onboarding,
      ];
      final enRutaPublica = rutasPublicas.contains(state.matchedLocation);
      final enRutaAuth =
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;

      if (estaAuth && enRutaAuth) return AppRoutes.home;
      if (!estaAuth && !enRutaPublica) return AppRoutes.login;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(path: AppRoutes.home, builder: (_, __) => const HomeScreen()),
      GoRoute(
        path: AppRoutes.cobertura,
        builder: (_, __) => const CoberturaScreen(),
      ),

      // Oposiciones + rutas anidadas por oposición
      GoRoute(
        path: '/oposiciones',
        builder: (_, __) => const OposicionesScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder:
                (_, state) => OposicionDetailScreen(
                  oposicionId: state.pathParameters['id']!,
                ),
            routes: [
              // Temario
              GoRoute(
                path: 'temario',
                builder:
                    (_, state) =>
                        TemarioScreen(oposicionId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: ':temaId',
                    builder:
                        (_, state) => TemaDetailScreen(
                          oposicionId: state.pathParameters['id']!,
                          temaId: state.pathParameters['temaId']!,
                        ),
                  ),
                ],
              ),
              // Flashcards
              GoRoute(
                path: 'flashcards',
                builder:
                    (_, state) => FlashcardsScreen(
                      oposicionId: state.pathParameters['id']!,
                    ),
              ),
              // Test
              GoRoute(
                path: 'test',
                builder:
                    (_, state) =>
                        TestScreen(oposicionId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'resultado',
                    builder: (_, state) {
                      final extra = state.extra as Map<String, dynamic>? ?? {};
                      return ResultadoTestScreen(
                        correctas: extra['correctas'] as int? ?? 0,
                        total: extra['total'] as int? ?? 0,
                      );
                    },
                  ),
                ],
              ),
              // Psicotécnicos
              GoRoute(
                path: 'supuestos',
                builder:
                    (_, state) => SupuestosScreen(
                      oposicionId: state.pathParameters['id']!,
                    ),
              ),
              GoRoute(
                path: 'psicotecnicos',
                builder:
                    (_, state) => PsicotecnicosScreen(
                      oposicionId: state.pathParameters['id']!,
                    ),
              ),
              // Chat IA
              GoRoute(
                path: 'chat',
                builder:
                    (_, state) =>
                        ChatScreen(oposicionId: state.pathParameters['id']!),
              ),
              // Voz IA
              GoRoute(
                path: 'voz',
                builder:
                    (_, state) =>
                        VozScreen(oposicionId: state.pathParameters['id']!),
              ),
            ],
          ),
        ],
      ),

      // Progreso
      GoRoute(
        path: AppRoutes.progreso,
        builder: (_, __) => const ProgresoScreen(),
      ),

      // Simulacro (top-level — obtiene la oposición activa internamente)
      GoRoute(
        path: AppRoutes.simulacro,
        builder: (_, __) => const SimulacroScreen(),
        routes: [
          GoRoute(
            path: 'resultado',
            builder: (_, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return ResultadoSimulacroScreen(
                correctas: extra['correctas'] as int? ?? 0,
                total: extra['total'] as int? ?? 0,
                tiempoSegundos: extra['tiempoSegundos'] as int? ?? 0,
              );
            },
          ),
        ],
      ),

      // Estudio
      GoRoute(
        path: AppRoutes.planEstudio,
        builder: (_, __) => const PlanEstudioScreen(),
      ),
      GoRoute(
        path: AppRoutes.alarmas,
        builder: (_, __) => const AlarmasScreen(),
      ),

      // Perfil
      GoRoute(path: AppRoutes.perfil, builder: (_, __) => const PerfilScreen()),
      GoRoute(
        path: AppRoutes.notificaciones,
        builder: (_, __) => const NotificacionesScreen(),
      ),

      // Suscripción
      GoRoute(
        path: AppRoutes.suscripcion,
        builder: (_, __) => const PaywallScreen(),
      ),
    ],
    errorBuilder:
        (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: Center(
            child: Text(
              'Ruta no encontrada: ${state.uri}',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
  );
});

class OposiworkApp extends ConsumerWidget {
  const OposiworkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppStrings.appName,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
