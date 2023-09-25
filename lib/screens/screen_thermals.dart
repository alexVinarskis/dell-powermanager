import 'package:dell_powermanager/classes/api_powermode.dart';
import 'package:dell_powermanager/classes/powermode_state.dart';
import 'package:flutter/material.dart';
import '../classes/api_cctk.dart';
import '../components/mode_item.dart';
import '../classes/cctk.dart';
import '../classes/cctk_state.dart';

const indexTitle = 0;
const indexDescription = 1;

class ScreenThermals extends StatefulWidget {
  const ScreenThermals({super.key});

  @override
  State<StatefulWidget> createState() {
    return ScreenThermalsState();
  }
}

class ScreenThermalsState extends State<ScreenThermals> {
  PowermodeState? _powermodeState;
  String currentMode = '';
  bool currentlyLoading = false;
  final Duration _refreshInternalPowermode = const Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _handlePowermodeStateUpdate(ApiPowermode.powermodeState);
    _handleCCTKStateUpdate(ApiCCTK.cctkState);
    ApiPowermode.addCallbacksStateChanged(_handlePowermodeStateUpdate);
    ApiPowermode.addQueryDuration(_refreshInternalPowermode);
    ApiCCTK.addQueryParameter(CCTK.thermalManagement);
    ApiCCTK.addCallbacksStateChanged(_handleCCTKStateUpdate);
    ApiCCTK.requestUpdate();
  }
  @override
  void dispose() {
    ApiPowermode.removeCallbacksStateChanged(_handlePowermodeStateUpdate);
    ApiPowermode.removeQueryDuration(_refreshInternalPowermode);
    ApiCCTK.removeQueryParameter(CCTK.thermalManagement);
    ApiCCTK.removeCallbacksStateChanged(_handleCCTKStateUpdate);
    super.dispose();
  }
  void _handleCCTKStateUpdate(CCTKState cctkState) {
    if (currentlyLoading) {
      return;
    }
    if (!cctkState.parameters.containsKey(CCTK.thermalManagement)) {
      return;
    }
    String param = cctkState.parameters[CCTK.thermalManagement];
    if (param.isEmpty) {
      return;
    }
    setState(() {
      currentMode = param.split(':')[0];
    });
  }
  void _handlePowermodeStateUpdate(PowermodeState? powermodeState) {
    setState(() {
      _powermodeState = powermodeState;
    });
  }

  Future<bool> changeMode(mode) async {
    return await ApiCCTK.request(CCTK.thermalManagement.cmd, mode);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, top: 20),
      child: Column(children: [
        for (var mode in CCTK.thermalManagementStrings(context).keys) 
          ModeItem(CCTK.thermalManagementStrings(context)[mode]![indexTitle],
            description: CCTK.thermalManagementStrings(context)[mode]![indexDescription],
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
            isDataMissing: currentMode.isEmpty,
          ),
      ]),
    );
  }
}
