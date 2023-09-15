import 'package:flutter/material.dart';

import '../classes/battery_state.dart';
import '../classes/api_battery.dart';

class ScreenSummary extends StatefulWidget {
  const ScreenSummary({super.key});

  @override
  State<StatefulWidget> createState() {
    return ScreenSummaryState();
  }
}

class ScreenSummaryState extends State<ScreenSummary> {
  BatteryState? _batteryState;
  final Duration _refreshInternal = const Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _handleStateUpdate(ApiBattery.batteryState);
    ApiBattery.addCallbacksStateChanged(_handleStateUpdate);
    ApiBattery.addQueryDuration(_refreshInternal);
  }
  @override
  void dispose() {
    // set faster API refresh rate
    ApiBattery.removeCallbacksStateChanged(_handleStateUpdate);
    ApiBattery.removeQueryDuration(_refreshInternal);
    super.dispose();
  }
  void _handleStateUpdate(BatteryState? batteryState) {
    setState(() {
      _batteryState = batteryState;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text("health: ${_batteryState != null ? _batteryState!.batteryHealth!.round() : '-'}%, Power ${_batteryState != null ? _batteryState!.batteryCurrentPower!.round() : '-'}W");
  }
}
