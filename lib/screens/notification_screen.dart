import 'package:flutter/material.dart';
import 'package:telebirrbybr7/screens/transaction_messages_screen.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color brandGreen = Color(0xFF8DC73F);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Notification',
          style: TextStyle(
            color: Colors.black, 
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        children: [
          _NotificationTile(
            icon: Icons.settings_outlined,
            color: const Color(0xFF2196F3),
            title: 'System Information',
            arrowColor: brandGreen,
            onTap: () {},
          ),
          Divider(height: 1, indent: 70, color: Colors.grey.withOpacity(0.2)),
          _NotificationTile(
            icon: Icons.mail_outline,
            color: const Color(0xFF4CAF50),
            title: 'Transaction Message',
            arrowColor: brandGreen,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TransactionMessagesScreen(),
                ),
              );
            },
          ),
          Divider(height: 1, indent: 70, color: Colors.grey.withOpacity(0.2)),
          _NotificationTile(
            icon: Icons.percent_outlined,
            color: const Color(0xFFFFA726),
            title: 'Promotion News',
            arrowColor: brandGreen,
            onTap: () {},
          ),
          Divider(height: 1, indent: 70, color: Colors.grey.withOpacity(0.2)),
          _NotificationTile(
            icon: Icons.shopping_cart_outlined,
            color: const Color(0xFFFFF44F), // Lemon color
            title: 'E-commerce Message',
            arrowColor: brandGreen,
            onTap: () {},
          ),
          Divider(height: 1, indent: 70, color: Colors.grey.withOpacity(0.2)),
          _NotificationTile(
            icon: Icons.drive_eta_outlined,
            color: const Color(0xFF90EE90), // Light green
            title: 'Driver Message',
            arrowColor: brandGreen,
            onTap: () {},
          ),
          Divider(height: 1, indent: 70, color: Colors.grey.withOpacity(0.2)),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final Color arrowColor;
  final VoidCallback onTap;

  const _NotificationTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.arrowColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16, 
          color: Colors.black87,
          fontWeight: FontWeight.w400,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios, 
        color: arrowColor,
        size: 14,
      ),
    );
  }
}