import 'package:dell_powermanager/components/menu_item.dart';
import 'package:flutter/material.dart';

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
                MenuItem('Battery Information',
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
                ),
              ),
            ),
          ]
        ),
      ),
    );
  }
}
