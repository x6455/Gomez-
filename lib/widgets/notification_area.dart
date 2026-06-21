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
        // Custom Search Icon - thin circle, short handle
        const Padding(
          padding: EdgeInsets.only(right: 5.0),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CustomPaint(
              painter: ThinSearchIconPainter(color: Colors.white),
            ),
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

class ThinSearchIconPainter extends CustomPainter {
  final Color color;
  
  ThinSearchIconPainter({this.color = Colors.white});
  
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    // Thin circle
    canvas.drawCircle(
      Offset(size.width * 0.38, size.height * 0.38),
      size.width * 0.28,
      paint,
    );
    
    // Short handle
    canvas.drawLine(
      Offset(size.width * 0.58, size.height * 0.58),
      Offset(size.width * 0.85, size.height * 0.85),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
