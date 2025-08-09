import 'package:flutter/material.dart';
import 'pages/home.dart';
import 'pages/personal_data.dart';
import 'pages/home_ai.dart';
import 'pages/setting.dart';

void main() {
  runApp(MyWidgetState());
}

class MyWidgetState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: "Poppins"),
      home: HomeAi(),
    );
  }
}
