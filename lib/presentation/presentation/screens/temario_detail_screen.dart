import 'package:flutter/material.dart';
class TemarioDetailScreen extends StatelessWidget {
  final String temarioId;
  const TemarioDetailScreen({required this.temarioId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text("Detalles del Temario: \$temarioId")),
    );
  }
}
