import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; 
import '../components/menu_item.dart';
import '../components/info_button.dart';
import '../components/menu_dependencies.dart';
import '../configs/constants.dart';
import '../screens/screen_battery.dart';
import '../screens/screen_summary.dart';
import '../screens/screen_thermals.dart';

enum MenuItems {
  summary,
  battery,
  thermals,
}

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
  MenuItems currentMenu = MenuItems.summary;

  Widget _getRHSScreen(MenuItems menuMode) {
    switch (menuMode) {
      case MenuItems.battery: return const ScreenBattery(key: Key("screenBattery"));
      case MenuItems.thermals: return const ScreenThermals(key: Key("screenThermals"));
      default: return ScreenSummary(key: const Key("screenSummary"), menuCallback: _handleMenuCallback,);
    }
  }

  void _handleMenuCallback(MenuItems menuItem) {
    setState(() {
      currentMenu = menuItem;
    });
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
                MenuItem(S.of(context)!.parentMenuTitleSummary,
                  description: S.of(context)!.parentMenuDescriptionSummary,
                  Icons.info_outline_rounded,
                  onPress: () {setState(() {
                    currentMenu = MenuItems.summary;
                  });},
                  paddingV: 10,
                  paddingH: 20,
                  isSelected: currentMenu == MenuItems.summary,
                ),
                MenuItem(S.of(context)!.parentMenuTitleBattery, 
                  description: S.of(context)!.parentMenuDescriptionBattery,
                  Icons.battery_3_bar_rounded,
                  onPress: () {setState(() {
                    currentMenu = MenuItems.battery;
                  });},
                  paddingV: 10,
                  paddingH: 20,
                  isSelected: currentMenu == MenuItems.battery,
                ),
                MenuItem(S.of(context)!.parentMenuTitleThermal, 
                  description: S.of(context)!.parentMenuDescriptionThermal,
                  Icons.thermostat_rounded,
                  onPress: () {setState(() {
                    currentMenu = MenuItems.thermals;
                  });},
                  paddingV: 10,
                  paddingH: 20,
                  isSelected: currentMenu == MenuItems.thermals,
                ),
                const Expanded(child: SizedBox(),),
                const MenuDependencies(
                  paddingV: 0,
                  paddingH: 20,
                ),
                InfoButton(
                  title: S.of(context)!.infoButtonTitle,
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
