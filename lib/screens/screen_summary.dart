import 'package:flutter/material.dart';

class ScreenSummary extends StatefulWidget {
  const ScreenSummary({super.key});

  @override
  State<StatefulWidget> createState() {
    return ScreenSummaryState();
  }
}

class ScreenSummaryState extends State<ScreenSummary> {
  @override
  Widget build(BuildContext context) {
    return const Text("summary");
  }
}