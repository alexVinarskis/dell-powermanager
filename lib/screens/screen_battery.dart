import 'package:flutter/material.dart';

class ScreenBattery extends StatefulWidget {
  const ScreenBattery({super.key});

  @override
  State<StatefulWidget> createState() {
    return ScreenBatteryState();
  }
}

class ScreenBatteryState extends State<ScreenBattery> {
  @override
  Widget build(BuildContext context) {
    return const Text("battery");
  }
}