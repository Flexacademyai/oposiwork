import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/security/security_service.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _ocultarPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;

    final permitido = await SecurityService(
      ref.read(supabaseClientProvider),
    ).checkRateLimit('login');

    if (!mounted) return;
    if (!permitido) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demasiados intentos. Espera un momento.')),
      );
      return;
    }

    await ref.read(authNotifierProvider.notifier).iniciarSesion(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    final state = ref.read(authNotifierProvider);
    state.when(
      data: (_) => context.go(AppRoutes.home),
      error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.errorCredenciales),
          backgroundColor: AppColors.error,
        ),
      ),
      loading: () {},
    );
  }

  Future<void> _iniciarSesionGoogle() async {
    await ref.read(authNotifierProvider.notifier).iniciarSesionGoogle();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final cargando = authState.isLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                _buildHeader(context),
                const SizedBox(height: 48),
                _buildFormulario(cargando),
                const SizedBox(height: 24),
                _buildBotonesAccion(context, cargando),
                const SizedBox(height: 32),
                _buildRegistrarse(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.school_rounded, size: 40, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(
          AppStrings.appName,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 4),
        Text(
          AppStrings.iniciarSesion,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFormulario(bool cargando) {
    return Column(
      children: [
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          enabled: !cargando,
          decoration: const InputDecoration(
            labelText: AppStrings.email,
            prefixIcon: Icon(Icons.email_outlined),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return AppStrings.campoRequerido;
            if (!v.contains('@')) return AppStrings.emailInvalido;
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          obscureText: _ocultarPassword,
          enabled: !cargando,
          decoration: InputDecoration(
            labelText: AppStrings.contrasena,
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                _ocultarPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () =>
                  setState(() => _ocultarPassword = !_ocultarPassword),
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return AppStrings.campoRequerido;
            if (v.length < 6) return AppStrings.contrasenaMuyCorta;
            return null;
          },
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: cargando ? null : () {},
            child: const Text(AppStrings.olvidasteContrasena),
          ),
        ),
      ],
    );
  }

  Widget _buildBotonesAccion(BuildContext context, bool cargando) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: cargando ? null : _iniciarSesion,
          child: cargando
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(AppStrings.iniciarSesion),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'o',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: cargando ? null : _iniciarSesionGoogle,
          icon: const Icon(Icons.g_mobiledata_rounded, size: 24),
          label: const Text(AppStrings.continuarGoogle),
        ),
      ],
    );
  }

  Widget _buildRegistrarse(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppStrings.noTienesCuenta,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        TextButton(
          onPressed: () => context.push(AppRoutes.register),
          child: const Text(AppStrings.registrarse),
        ),
      ],
    );
  }
}
