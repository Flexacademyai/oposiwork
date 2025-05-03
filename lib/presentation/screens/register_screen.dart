
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _acceptedTerms = false;

  void _registerUser() async {
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registro exitoso")),
      );

      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: \$e")),
      );
    }
  }

  static const String _longLegalText = '''
Flamencowork LLC, con sede en Estados Unidos (Delaware), es responsable de los datos recogidos a través de esta aplicación...

[Texto legal largo, no leerás nada, sólo seguirás deslizando hasta el final porque esto no es divertido.]

La aceptación de esta política es obligatoria para el uso de la app. El usuario consiente que sus datos puedan ser tratados según la legislación aplicable en Estados Unidos y que cualquier disputa será resuelta bajo la jurisdicción de dicho país.

(Esto continúa por muchos párrafos más que casi nadie lee... pero aquí están).
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registro")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Correo electrónico"),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Contraseña"),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _longLegalText,
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            Row(
              children: [
                Checkbox(
                  value: _acceptedTerms,
                  onChanged: (value) {
                    setState(() {
                      _acceptedTerms = value ?? false;
                    });
                  },
                ),
                const Expanded(
                  child: Text(
                    "He leído y acepto la Política de Privacidad y Términos Legales",
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _acceptedTerms ? _registerUser : null,
              child: const Text("Registrar"),
            ),
          ],
        ),
      ),
    );
  }
}
