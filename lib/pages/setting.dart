import 'package:flutter/material.dart';

class Setting extends StatelessWidget {
  const Setting({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setting', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.red,
        elevation: 0,
      ),
      body: Container(
        color: Colors.white,
        child: ListView(
          children: [
            menuItem(context, Icons.person, 'Profile', null),
            menuItem(context, Icons.lock, 'Change Password', null),
            menuItem(context, Icons.info, 'About', null),
            Divider(),
            sectionLabel('General'),
            menuItem(context, Icons.feedback, 'Send Feedback', null),
            menuItem(context, Icons.lightbulb, 'Request feature', null),
          ],
        ),
      ),
    );
  }
}

Widget sectionLabel(String text) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
    child: Text(
      text,
      style: const TextStyle(fontSize: 12, color: Colors.grey),
      textAlign: TextAlign.left,
    ),
  );
}

Widget menuItem(BuildContext context, IconData icon, String title, link) {
  return ListTile(
    leading: Icon(icon, color: Colors.black),
    title: Text(title, style: TextStyle(fontSize: 14)),
    trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black),
    onTap: link != null
        ? () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => link),
            );
          }
        : null,
  );
}
