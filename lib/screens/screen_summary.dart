import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeleton_text/skeleton_text.dart';

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
    ApiBattery.removeCallbacksStateChanged(_handleStateUpdate);
    ApiBattery.removeQueryDuration(_refreshInternal);
    super.dispose();
  }
  void _handleStateUpdate(BatteryState? batteryState) {
    setState(() {
      _batteryState = batteryState;
    });
  }

  Widget _getBatteryStatValue(BuildContext context, String title, var value, {String unit = "", bool toInt = false}) {
    return Row(children: [
        Text(title, style: TextStyle(fontSize: Theme.of(context).textTheme.titleMedium!.fontSize)),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                value == null ? "" :
                value is String ? value :
                toInt ? "${value.toInt()}" :
                '${double.parse((value).toStringAsFixed(1))}',
                style: GoogleFonts.sourceCodePro().copyWith(fontSize: Theme.of(context).textTheme.titleMedium!.fontSize),
              ),
              const SizedBox(width: 5,),
              SizedBox(
                width: 20,
                child: Text(unit, style: GoogleFonts.sourceCodePro().copyWith(fontSize: Theme.of(context).textTheme.titleMedium!.fontSize),),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _getBatteryStatsInkwell(BuildContext context, {var onPress, double padding = 25}) {
    return InkWell(
      onTap: onPress,
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              alignment: Alignment.centerLeft,
              margin: const EdgeInsets.only(bottom: 10),
              child: Text(
                "Battery Overview",
                style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary),
              ),
            ),
            _getBatteryStatValue(context, "Health:", _batteryState?.batteryHealth, unit: "%"),
            _getBatteryStatValue(context, "Cycles count:", _batteryState?.batteryCycleCount != null ? _batteryState?.batteryCycleCount!.toDouble() : "", toInt: true),
            Container(
              alignment: Alignment.centerLeft,
              margin: const EdgeInsets.only(top: 20, bottom: 10),
                child: Text(
                "Battery Information",
                style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary),
              ),
            ),
            _getBatteryStatValue(context, "Model:", _batteryState?.batteryModelName),
            _getBatteryStatValue(context, "Vendor:", _batteryState?.batteryManufacturer),
            _getBatteryStatValue(context, "Type:", _batteryState?.batteryTechnology),
            _getBatteryStatValue(context, "Design Capacity:", _batteryState?.batteryDesignCapacity, unit: "Wh"),
            _getBatteryStatValue(context, "Design Voltage:", _batteryState?.batteryVoltageMinDesign, unit: "V"),
            _getBatteryStatValue(context, "S/N:", _batteryState?.batterySerialNumber),
          ],
        ),
      ),
    );
  }
  Widget _getBatteryChargingInkwell(BuildContext context, {var onPress, double padding = 25}) {
    return InkWell(
      onTap: onPress,
      child: Padding(
        padding: EdgeInsets.only(left: padding-5, right: padding, top: padding, bottom: padding),
        child: _batteryState != null && _batteryState!.powerSupplyPresent != null && _batteryState!.batteryPercentage != null && _batteryState!.batteryCharging != null ?
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                _batteryState!.powerSupplyPresent! ? Icons.power_rounded : Icons.battery_4_bar_rounded,
                size: 25,
                color: Theme.of(context).colorScheme.primary,
              ),
              Text('  ${_batteryState!.powerSupplyPresent! ? _batteryState!.batteryCharging! ? "Plugged, charging with" : "Plugged, not charging" : "On Battery, discharging with"}',
                style: TextStyle(fontSize: Theme.of(context).textTheme.titleMedium!.fontSize),
              ),
              _batteryState!.powerSupplyPresent! && !_batteryState!.batteryCharging! ?
                const SizedBox() : Text(
                  ' ${_batteryState!.batteryCurrentPower!.toInt()}W',
                  style: GoogleFonts.sourceCodePro().copyWith(fontSize: Theme.of(context).textTheme.titleMedium!.fontSize, fontWeight: FontWeight.bold),
                ),
            ],
          ) : const Row(children: [Text(""),],),
      ),
    );
  }

  Widget _getBatteryLogo(BuildContext context) {
    double size = 250;
    if (_batteryState == null || _batteryState!.batteryPercentage == null) {
      return Icon(
        Icons.battery_0_bar_rounded,
        size: size,
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      );
    }
    if (_batteryState!.batteryPercentageLow != null && _batteryState!.batteryPercentageLow!) {
      return Icon(
        Icons.battery_0_bar_rounded,
        size: size,
        color: Colors.red.shade300,
      );
    }
    switch (_batteryState!.batteryPercentage!) {
      case >95: return Icon(
        Icons.battery_std_rounded,
        size: size,
        color: Colors.green.shade300,
      );
      case >95-15: return Icon(
        Icons.battery_6_bar_rounded,
        size: size,
        color: Colors.green.shade300,
      );
      case >95-15*2: return Icon(
        Icons.battery_5_bar_rounded,
        size: size,
        color: Colors.green.shade300,
      );
      case >95-15*3: return Icon(
        Icons.battery_4_bar_rounded,
        size: size,
        color: Colors.green.shade300,
      );
      case >95-15*4: return Icon(
        Icons.battery_3_bar_rounded,
        size: size,
        color: Colors.green.shade300,
      );
      case >95-15*5: return Icon(
        Icons.battery_2_bar_rounded,
        size: size,
        color: Colors.green.shade300,
      );
      case >5: return Icon(
        Icons.battery_1_bar_rounded,
        size: size,
        color: Colors.green.shade300,
      );
      default: return Icon(
        Icons.battery_0_bar_rounded,
        size: size,
        color: Colors.green.shade300,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Stack(
            alignment: AlignmentDirectional.center,
            children: [
              _getBatteryLogo(context),
              Padding(
                padding: const EdgeInsets.only(top: 260.0),
                child: Text(
                  _batteryState == null || _batteryState!.batteryPercentage == null ? "" :
                  "${_batteryState!.batteryPercentage!.toInt()}%",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: Theme.of(context).textTheme.bodyMedium!.color!.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          )
        ),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              Card(
                clipBehavior: Clip.antiAlias,
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
                elevation: 0,
                margin: const EdgeInsets.only(top: 25, bottom: 25, right: 25),
                child: _batteryState == null ?
                  SkeletonAnimation(
                    curve: Curves.easeInOutCirc,
                    shimmerColor: Theme.of(context).colorScheme.secondaryContainer,
                    gradientColor: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0),
                    child: _getBatteryStatsInkwell(context),
                  ) :
                  _getBatteryStatsInkwell(context),
              ),
              Card(
                clipBehavior: Clip.antiAlias,
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 25, right: 25),
                child: _batteryState == null ?
                  SkeletonAnimation(
                    curve: Curves.easeInOutCirc,
                    shimmerColor: Theme.of(context).colorScheme.secondaryContainer,
                    gradientColor: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0),
                    child: _getBatteryChargingInkwell(context),
                  ) :
                  _getBatteryChargingInkwell(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
