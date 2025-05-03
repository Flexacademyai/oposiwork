import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/login_screen.dart';
import '../../presentation/screens/register_screen.dart';
import '../../presentation/screens/oposition_list_screen.dart';
import '../../presentation/screens/oposition_detail_screen.dart';
import '../../presentation/screens/premium_screen.dart';

final GoRouter AppRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/opositions',
      builder: (context, state) => const OpositionListScreen(),
    ),
    GoRoute(
      path: '/opositions/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return OpositionDetailScreen(opositionId: id);
      },
    ),
    GoRoute(
      path: '/premium',
      builder: (context, state) => const PremiumScreen(),
    ),
  ],
);
