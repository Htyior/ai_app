// ignore_for_file: sort_child_properties_last

import 'package:flutter/material.dart';
import 'package:my_app/pages/personal_data.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 10,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: ClipRRect(
            child: Image.asset('assets/images/pfp.png'),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        title: const Padding(
          padding: EdgeInsets.only(left: 30),
          child: Text("Hello kitty"),
        ),
      ),
      body: Column(
        children: [
          myDivider(),
          menuItem(context, Icons.person, "Personal Data", PersonalData()),
          menuItem(context, Icons.settings, "Setting", null),
          menuItem(context, Icons.receipt_long, "E-Statement", null),
          menuItem(context, Icons.favorite, "Referral Code", null),
          myDivider(),
          menuItem(context, Icons.help_outline, "FAQs", null),
          menuItem(context, Icons.menu_book, "Our Handbook", null),
          menuItem(context, Icons.group, "Community", null),
          helpButton(),
        ],
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

  Widget myDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Divider(),
    );
  }

  Widget helpButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.headset_mic, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              "Feel Free to Ask, We Ready to Help",
              style: TextStyle(color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }
}
