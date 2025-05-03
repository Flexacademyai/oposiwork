import 'package:flutter/material.dart';

class OppositionCard extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const OppositionCard({
    super.key,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontSize: 18)),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap ?? () {},
      ),
    );
  }
}
