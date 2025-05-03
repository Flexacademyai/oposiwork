import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/register_screen.dart';
import 'presentation/screens/profile_screen.dart';
import 'presentation/screens/study_calendar_screen.dart';
// Añade más imports de pantallas según lo necesites

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/calendar',
      builder: (context, state) => const StudyCalendarScreen(),
    ),
    // Agrega más rutas aquí según tu estructura
  ],
);
