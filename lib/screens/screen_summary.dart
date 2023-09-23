import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeleton_text/skeleton_text.dart';

import '../classes/battery_state.dart';
import '../classes/api_battery.dart';
import '../classes/api_cctk.dart';
import '../classes/cctk.dart';
import '../classes/cctk_state.dart';
import '../screens/screen_parent.dart';

const indexTitle = 0;

class ScreenSummary extends StatefulWidget {
  const ScreenSummary({super.key, this.menuCallback});

  final menuCallback;

  @override
  State<StatefulWidget> createState() {
    return ScreenSummaryState();
  }
}

class ScreenSummaryState extends State<ScreenSummary> {
  BatteryState? _batteryState;
  String _currentBatteryModeExtended = '';
  String _currentBatteryMode = '';
  String _currentThermalMode = '';
  final Duration _refreshInternal = const Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _handleBatteryStateUpdate(ApiBattery.batteryState);
    _handleCCTKStateUpdate(ApiCCTK.cctkState);
    ApiBattery.addCallbacksStateChanged(_handleBatteryStateUpdate);
    ApiBattery.addQueryDuration(_refreshInternal);
    ApiCCTK.addQueryParameter(CCTK.thermalManagement);
    ApiCCTK.addQueryParameter(CCTK.primaryBattChargeCfg);
    ApiCCTK.addCallbacksStateChanged(_handleCCTKStateUpdate);
  }
  @override
  void dispose() {
    ApiBattery.removeCallbacksStateChanged(_handleBatteryStateUpdate);
    ApiBattery.removeQueryDuration(_refreshInternal);
    ApiCCTK.removeQueryParameter(CCTK.thermalManagement);
    ApiCCTK.removeQueryParameter(CCTK.primaryBattChargeCfg);
    ApiCCTK.removeCallbacksStateChanged(_handleCCTKStateUpdate);
    super.dispose();
  }
  void _handleBatteryStateUpdate(BatteryState? batteryState) {
    setState(() {
      _batteryState = batteryState;
    });
  }
  void _handleCCTKStateUpdate(CCTKState cctkState) {
    if (cctkState.parameters.containsKey(CCTK.thermalManagement)) {
      String param = cctkState.parameters[CCTK.thermalManagement];
      if (param.isNotEmpty) {
        setState(() {
          _currentThermalMode = param.split(':')[0];
        });
      }
    }
    if (cctkState.parameters.containsKey(CCTK.primaryBattChargeCfg)) {
      String param = cctkState.parameters[CCTK.primaryBattChargeCfg];
      if (param.isNotEmpty) {
        setState(() {
          _currentBatteryMode = param.split(':')[0];
          _currentBatteryModeExtended = "";
        });
        if (param.contains(CCTK.primaryBattChargeCfg.args.custom) && param.split(':').length >= 2) {
          // custom battery mode state has paremeters, parse them
          int startValue = int.parse(param.split(':')[1].split("-")[0]);
          int stopValue  = int.parse(param.split(':')[1].split("-")[1]);
          setState(() {
            _currentBatteryModeExtended = " ($startValue..$stopValue%)";
          });
        }
      }
    }
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
  Widget _getBatteryManagementInkwell(BuildContext context, {var onPress, double padding = 25}) {
    return InkWell(
      onTap: onPress,
      child: Padding(
        padding: EdgeInsets.only(left: padding-5, right: padding, top: padding, bottom: padding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.battery_3_bar_rounded,
              size: 25,
              color: Theme.of(context).colorScheme.primary,
            ),
            Text('  Battery Mode',
              style: TextStyle(fontSize: Theme.of(context).textTheme.titleMedium!.fontSize),
            ),
            _currentBatteryMode.isNotEmpty ?
              Row(children: [
                Text(
                  ":  ",
                  style: TextStyle(fontSize: Theme.of(context).textTheme.titleMedium!.fontSize),
                ),
                Text(
                  CCTK.primaryBattChargeCfgStrings.containsKey(_currentBatteryMode) ? CCTK.primaryBattChargeCfgStrings[_currentBatteryMode]![indexTitle].replaceAllMapped(RegExp(r'\((.*?)\)'), (match) => "") + _currentBatteryModeExtended : "",
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary),
                ),
              ],) : const SizedBox(),
          ],
        ),
      ),
    );
  }
  Widget _getThermalManagementInkwell(BuildContext context, {var onPress, double padding = 25}) {
    return InkWell(
      onTap: onPress,
      child: Padding(
        padding: EdgeInsets.only(left: padding-5, right: padding, top: padding, bottom: padding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.thermostat_rounded,
              size: 25,
              color: Theme.of(context).colorScheme.primary,
            ),
            Text('  Thermal Mode',
              style: TextStyle(fontSize: Theme.of(context).textTheme.titleMedium!.fontSize),
            ),
            _currentThermalMode.isNotEmpty ?
              Row(children: [
                Text(
                  ":  ",
                  style: TextStyle(fontSize: Theme.of(context).textTheme.titleMedium!.fontSize),
                ),
                Text(
                  CCTK.thermalManagementStrings.containsKey(_currentThermalMode) ? CCTK.thermalManagementStrings[_currentThermalMode]![indexTitle] : "",
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary),
                ),
              ],) : const SizedBox(),
          ],
        ),
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
              Card(
                clipBehavior: Clip.antiAlias,
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 25, right: 25),
                child: _currentBatteryMode.isEmpty ?
                  SkeletonAnimation(
                    curve: Curves.easeInOutCirc,
                    shimmerColor: Theme.of(context).colorScheme.secondaryContainer,
                    gradientColor: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0),
                    child: _getBatteryManagementInkwell(context),
                  ) :
                  _getBatteryManagementInkwell(context, onPress: () { widget.menuCallback(MenuItems.battery); }),
              ),
              Card(
                clipBehavior: Clip.antiAlias,
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 25, right: 25),
                child: _currentThermalMode.isEmpty ?
                  SkeletonAnimation(
                    curve: Curves.easeInOutCirc,
                    shimmerColor: Theme.of(context).colorScheme.secondaryContainer,
                    gradientColor: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0),
                    child: _getThermalManagementInkwell(context),
                  ) :
                  _getThermalManagementInkwell(context, onPress: () { widget.menuCallback(MenuItems.thermals); }),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
