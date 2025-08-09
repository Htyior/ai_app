import 'package:flutter/material.dart';
import 'package:my_app/pages/setting.dart';
import 'package:my_app/pages/pick_image_page.dart';

class HomeAi extends StatelessWidget {
  const HomeAi({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("CleanCut AI"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.black, size: 32),
            onPressed: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  transitionDuration: Duration(milliseconds: 200),
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      Setting(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        const begin = Offset(0.0, 1.0);
                        const end = Offset.zero;
                        final tween = Tween(begin: begin, end: end);
                        final offsetAnimation = animation.drive(tween);

                        return SlideTransition(
                          position: offsetAnimation,
                          child: child,
                        );
                      },
                ),
              );
            },
          ),
          SizedBox(width: 10), // Add some padding at the end
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.yellow.shade600, Colors.red],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 18.0, bottom: 8.0),
                    child: Text(
                      "Create new",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ActionBox(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ActionBox extends StatelessWidget {
  const ActionBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      height: 180,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ActionButton(
            gradientColors: [Colors.red, Colors.redAccent],
            icon: Icons.format_paint,
            label: "Remove Background",
          ),
          ActionButton(
            gradientColors: [Colors.orange, Colors.deepOrange],
            icon: Icons.emoji_objects,
            label: "Remove Object",
          ),
        ],
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  final List<Color> gradientColors;
  final IconData icon;
  final String label;

  const ActionButton({
    super.key,
    required this.gradientColors,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: label == "Remove Background"
              ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PickImagePage(),
                    ),
                  );
                }
              : null,
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(child: Icon(icon, color: Colors.white, size: 40)),
          ),
        ),
        SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 16, color: Colors.black)),
      ],
    );
  }
}
