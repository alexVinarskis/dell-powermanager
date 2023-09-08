import 'package:flutter/material.dart';
import '../components/menu_item.dart';
import '../components/info_button.dart';
import '../components/menu_dependencies.dart';
import '../configs/constants.dart';
import '../screens/screen_battery.dart';
import '../screens/screen_summary.dart';
import '../screens/screen_thermals.dart';

class ScreenParent extends StatefulWidget {
  const ScreenParent({super.key, required this.title, this.appBarHeight=45});

  final String title;
  final double appBarHeight;

  @override
  State<StatefulWidget> createState() {
    return ScreenParentState();
  }
}

class ScreenParentState extends State<ScreenParent> {
  int currentMenu = 0;

  Widget _getRHSScreen(int index) {
    switch (index) {
      case 1: return const ScreenBattery(key: Key("screenBattery"));
      case 2: return const ScreenThermals(key: Key("screenThermals"));
      default: return const ScreenSummary(key: Key("ScreenSummary"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      body: Padding(
        padding: EdgeInsets.only(top: widget.appBarHeight),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(children: [
                const SizedBox(height: 40,),
                MenuItem('System Information',
                  description: 'Charge level, state and battery health',
                  Icons.info_outline_rounded,
                  onPress: () {setState(() {
                    currentMenu = 0;
                  });},
                  paddingV: 10,
                  paddingH: 20,
                  isSelected: currentMenu == 0,
                ),
                MenuItem('Battery Settings', 
                  description: 'Set charging modes for different use cases',
                  Icons.battery_3_bar_rounded,
                  onPress: () {setState(() {
                    currentMenu = 1;
                  });},
                  paddingV: 10,
                  paddingH: 20,
                  isSelected: currentMenu == 1,
                ),
                MenuItem('Thermal Managment', 
                  description: 'Customize system thermal and fan settings',
                  Icons.thermostat_rounded,
                  onPress: () {setState(() {
                    currentMenu = 2;
                  });},
                  paddingV: 10,
                  paddingH: 20,
                  isSelected: currentMenu == 2,
                ),
                const Expanded(child: SizedBox(),),
                const MenuDependencies(
                  paddingV: 0,
                  paddingH: 20,
                ),
                const InfoButton(
                  title: 'Misc',
                  paddingV: 20,
                  paddingH: 20,
                ),
              ]),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(40)),
                    color: Theme.of(context).colorScheme.background,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: Constants.animationMs),
                    child: Column(children: [_getRHSScreen(currentMenu)]),
                  ),
                ),
              ),
            ),
          ]
        ),
      ),
    );
  }
}
