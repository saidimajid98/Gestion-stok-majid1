import 'package:flutter/material.dart';
import '../theme.dart';

class EmptyState extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({super.key, required this.message, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      child: Column(children: [
        Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.inkSoft)),
        if (actionLabel != null) ...[
          const SizedBox(height: 14),
          ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ]),
    );
  }
}
