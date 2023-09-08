import 'package:flutter/material.dart';
import '../classes/api.dart';
import '../components/thermal_mode_item.dart';
import '../configs/cctk.dart';

const indexTitle = 0;
const indexDescription = 1;
final Map<String, List<String>> thermalModesStrings = {
  // cctkCmd : Tile, Description
  CCTK.thermalManagement.args.optimized : ["Optimized", "This is the standard setting for cooling fan and processor heat management. This setting is a balance of performance., noise and temperature.",],
  CCTK.thermalManagement.args.quiet     : ["Quiet", "Processor and cooling fan speed are adjusted to reduce fan noise. This may mean a higher system surface temperature and reduced performance.",],
  CCTK.thermalManagement.args.cool      : ["Cool", "Processor and cooling fan speed are adjusted to help maintain a cooler system surface temperature. This may mean reduced system performance and more noise.",],
  CCTK.thermalManagement.args.ultra     : ["Ultra Performance", "Processor and cooling fan speed is increased for more performance. This may mean higher system suface temperature and more noise.",],
};

class ScreenThermals extends StatefulWidget {
  const ScreenThermals({super.key});

  @override
  State<StatefulWidget> createState() {
    return ScreenThermalsState();
  }
}

class ScreenThermalsState extends State<ScreenThermals> {
  String currentMode = '';
  bool currentlyLoading = false;

  Future<bool> changeMode(mode) async {
    return await Api.requestAction(CCTK.thermalManagement.cmd, mode);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, top: 20),
      child: Column(children: [
        for (var mode in thermalModesStrings.keys) 
          ThermalModeItem(thermalModesStrings[mode]![indexTitle],
            description: thermalModesStrings[mode]![indexDescription],
            onPress: () async {
              if (!currentlyLoading) {
                setState(() {
                  currentMode = mode;
                  currentlyLoading = true;
                });
                await changeMode(mode);
                if (mounted) {
                  setState(() {
                    currentlyLoading = false;
                  });
                }
              }
            },
            paddingV: 10,
            paddingH: 20,
            isSelected: currentMode == mode,
            isLoading:  currentMode == mode && currentlyLoading,
          ),
      ]),
    );
  }
}
