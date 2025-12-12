import 'package:flutter/material.dart';

// --- EMERGENCY CARD WIDGET ---
// Display emergency contact information.
class EmergencyCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String number;
  final Color bgColor;
  final Color textColor;
  final VoidCallback onTap;

  const EmergencyCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.number,
    required this.bgColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: bgColor,
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.phone, color: textColor),
        onTap: onTap,
      ),
    );
  }
}
