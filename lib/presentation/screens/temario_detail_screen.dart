import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TemarioDetailScreen extends StatefulWidget {
  final String temarioId;

  const TemarioDetailScreen({super.key, required this.temarioId});

  @override
  State<TemarioDetailScreen> createState() => _TemarioDetailScreenState();
}

class _TemarioDetailScreenState extends State<TemarioDetailScreen> {
  bool isLoading = true;
  String titulo = '';
  String contenido = '';
  bool completado = false;

  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    try {
      final temarioDoc = await FirebaseFirestore.instance
          .collection('temarios')
          .doc(widget.temarioId)
          .get();

      final progresoDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('progreso')
          .doc(widget.temarioId)
          .get();

      setState(() {
        titulo = temarioDoc['titulo'] ?? 'Sin título';
        contenido = temarioDoc['contenido'] ?? '';
        completado = progresoDoc.exists ? progresoDoc['completado'] ?? false : false;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        titulo = 'Error al cargar';
        contenido = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> marcarCompletado(bool value) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('progreso')
        .doc(widget.temarioId)
        .set({'completado': value});

    setState(() {
      completado = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(child: SingleChildScrollView(child: Text(contenido))),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: completado,
                        onChanged: (value) {
                          marcarCompletado(value!);
                        },
                      ),
                      const Text('Marcar como completado'),
                    ],
                  )
                ],
              ),
            ),
    );
  }
}
