import 'package:flutter/material.dart';
import 'package:telebirrbybr7/screens/home_screen.dart';
import 'package:telebirrbybr7/screens/notification_screen.dart';

class NotificationArea extends StatelessWidget {
  const NotificationArea({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Search Icon
        const Padding(
          padding: EdgeInsets.only(right: 5.0),
          child: Icon(
            Icons.search,
            color: Colors.white,
            size: 20,
          ),
        ),
        
        // Notification Icon with Badge and Navigation
        Padding(
          padding: const EdgeInsets.only(right: 15),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationScreen(),
                ),
              );
            },
            child: const Badge(
              label: Text('1'),
              backgroundColor: Colors.red,
              textColor: Colors.white,
              child: Icon(
                Icons.notifications_none_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
        
        // Language Dropdown (defined in home_screen.dart)
        const DropDownLang()
      ],
    );
  }
}
