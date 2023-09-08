import 'package:flutter/material.dart';
import '../classes/api.dart';
import '../components/mode_item.dart';
import '../configs/cctk.dart';

const indexTitle = 0;
const indexDescription = 1;
final Map<String, List<String>> batteryModesStrings = {
  // cctkCmd : Tile, Description, Extended Description
  CCTK.primaryBattChargeCfg.args.standard  : ["Standard", "Recommended for users who switch between battery power and an external power source.", "Fully charges your battery at an standard rate (not as fast ExpressCharge™). Charge time varies by model.",],
  CCTK.primaryBattChargeCfg.args.express   : ["ExpressCharge™", "Recommended for users who need the battery charged over a short period of time.", "",],
  CCTK.primaryBattChargeCfg.args.primAcUse : ["Primarily AC Use", "Recommended for users who operate their system while plugged in to an external power source.", "This setting may extend your battery's lifespan by lowering the charge threshold.",],
  CCTK.primaryBattChargeCfg.args.adaptive  : ["Adaptive (Recommended)", "Recommended for users who want to 'set it and forget it'.", "Lets the system adaptively optimize your battery settings based on your typical battery usage pattern.",],
  // Warning: You cannot select a 'stop charging' value less tahn 55% (c) Dell
  CCTK.primaryBattChargeCfg.args.custom    : ["Custom", "Recommended for advanced users that desire greater control over when their battery starts and stops charging.", "",],
};

class ScreenBattery extends StatefulWidget {
  const ScreenBattery({super.key});

  @override
  State<StatefulWidget> createState() {
    return ScreenBatteryState();
  }
}

class ScreenBatteryState extends State<ScreenBattery> {
  String currentMode = '';
  bool currentlyLoading = false;

  Future<bool> changeMode(mode) async {
    return await Api.requestAction(CCTK.primaryBattChargeCfg.cmd, mode);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, top: 20),
      child: Column(children: [
        for (var mode in batteryModesStrings.keys) 
          ModeItem(batteryModesStrings[mode]![indexTitle],
            description: batteryModesStrings[mode]![indexDescription],
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
