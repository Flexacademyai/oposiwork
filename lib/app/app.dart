import 'package:flutter/material.dart';
import 'package:oposiwork/app/routes/app_router.dart';
import 'package:oposiwork/app/theme/app_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oposiwork/presentation/blocs/auth/auth_bloc.dart';
import 'package:oposiwork/core/di/injection_container.dart' as di;

class OposiworkApp extends StatelessWidget {
  const OposiworkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => di.sl<AuthBloc>(),
        ),
        // Otros BLoCs se añadirán aquí
      ],
      child: MaterialApp.router(
        title: 'Oposiwork',
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        themeMode: ThemeMode.light, // Por defecto tema claro
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          // Delegados de localización se añadirán en el futuro
        ],
        supportedLocales: const [
          Locale('es', ''), // Español
        ],
      ),
    );
  }
}
