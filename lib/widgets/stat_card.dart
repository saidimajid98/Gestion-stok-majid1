import 'package:flutter/material.dart';
import '../theme.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String valeur;
  final Color? couleur;

  const StatCard({super.key, required this.label, required this.valeur, this.couleur});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.inkSoft)),
          const SizedBox(height: 6),
          Text(valeur, style: TextStyle(fontFamily: 'serif', fontSize: 21, fontWeight: FontWeight.bold, color: couleur ?? AppColors.ink)),
        ]),
      ),
    );
  }
}
