import 'dart:math';
import 'package:flutter/material.dart';
import '../classes/api_cctk.dart';
import '../components/mode_item.dart';
import '../classes/cctk.dart';
import '../classes/cctk_state.dart';

const indexTitle = 0;
const indexDescription = 1;
const indexDescriptionExt = 2;

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
  RangeValues customChargeRange = const RangeValues(0.50, 0.85);
  bool customChargeRangeChanging = false;

  @override
  void initState() {
    super.initState();
    _handleStateUpdate(ApiCCTK.cctkState);
    ApiCCTK.addQueryParameter(CCTK.primaryBattChargeCfg);
    ApiCCTK.addCallbacksStateChanged(_handleStateUpdate);
    ApiCCTK.requestUpdate();
  }
  @override
  void dispose() {
    ApiCCTK.removeQueryParameter(CCTK.primaryBattChargeCfg);
    ApiCCTK.removeCallbacksStateChanged(_handleStateUpdate);
    super.dispose();
  }
  void _handleStateUpdate(CCTKState cctkState) {
    if (currentlyLoading) {
      return;
    }
    if (!cctkState.parameters.containsKey(CCTK.primaryBattChargeCfg)) {
      return;
    }
    String param = cctkState.parameters[CCTK.primaryBattChargeCfg]?.mode ?? "";
    if (param.isEmpty) {
      return;
    }
    setState(() {
      currentMode = param.split(':')[0];
    });
    if (param.contains(CCTK.primaryBattChargeCfg.modes.custom) && param.split(':').length >= 2) {
      // custom battery mode state has paremeters, parse them
      double startValue = double.parse(param.split(':')[1].split("-")[0])/100;
      double stopValue  = double.parse(param.split(':')[1].split("-")[1])/100;
      setState(() {
        customChargeRange = RangeValues(startValue, stopValue);
      });
    }
  }

  Future<bool> _changeMode(mode) async {
    return await ApiCCTK.request(CCTK.primaryBattChargeCfg.cmd, mode);
  }

  void _handlePress(mode) async {
    if (currentlyLoading) {
      return;
    }
    setState(() {
      currentMode = mode;
      currentlyLoading = true;
    });
    if (mode != CCTK.primaryBattChargeCfg.modes.custom) {
      await _changeMode(mode);
    } else {
      await _changeMode("$mode:${(customChargeRange.start*100).round()}-${(customChargeRange.end*100).round()}");
    }
    if (mounted) {
      setState(() {
        currentlyLoading = false;
      });
    }
  }

  Widget _getPercentageIndicator(String value, mode) {
    return Container(
      height: 20,
      width: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: currentMode == mode || customChargeRangeChanging ?
          Theme.of(context).colorScheme.primary.withOpacity(0.25) :
          Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: const BorderRadius.all(Radius.circular(20))
      ),
      child: Text(value, style: Theme.of(context).textTheme.labelMedium,),
    );
  }

  Widget? _getBottomBar(mode) {
    if (mode != CCTK.primaryBattChargeCfg.modes.custom) {
      return null;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _getPercentageIndicator("${(customChargeRange.start*100).round()}", mode),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackShape: const RoundedRectSliderTrackShape(),
                trackHeight: 20.0,
                rangeThumbShape: const RoundRangeSliderThumbShape(elevation: 0.001, pressedElevation: 0.001, enabledThumbRadius: 11),
                thumbColor: currentMode == mode || customChargeRangeChanging ?
                  SliderTheme.of(context).activeTrackColor :
                  Theme.of(context).colorScheme.onSurfaceVariant,
                activeTrackColor: currentMode == mode || customChargeRangeChanging ?
                  SliderTheme.of(context).activeTrackColor :
                  Theme.of(context).colorScheme.onSurfaceVariant,
                inactiveTrackColor: currentMode == mode || customChargeRangeChanging?
                  SliderTheme.of(context).inactiveTrackColor :
                  Theme.of(context).colorScheme.surfaceVariant,
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 20.0),
              ),
              child: RangeSlider(
                min: 0.45,
                values: customChargeRange,
                onChanged: (RangeValues newRange) {
                  setState(() {
                    customChargeRange = RangeValues(
                      min(max(newRange.start, 0.5), min(0.95, customChargeRange.end-0.05)),  // start 0.50...0.95, stop-start >= 0.05
                      max(max(newRange.end, 0.55), customChargeRange.start+0.05),            // end   0.55...1.00, stop-start >= 0.05
                    );
                  });
                },
                onChangeEnd: (value) => {
                  setState(() {
                    customChargeRangeChanging = false;
                  }),
                  _handlePress(CCTK.primaryBattChargeCfg.modes.custom)
                },
                onChangeStart: (value) => {
                  setState(() {
                    customChargeRangeChanging = true;
                  }),
                },
              ),
            ),
          ),
          _getPercentageIndicator("${(customChargeRange.end*100).round()}", mode),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, top: 20),
      child: Column(children: [
        for (var mode in CCTK.primaryBattChargeCfg.strings(context).keys) 
          ModeItem(CCTK.primaryBattChargeCfg.strings(context)[mode]![indexTitle],
            description: "${CCTK.primaryBattChargeCfg.strings(context)[mode]![indexDescription]}${CCTK.primaryBattChargeCfg.strings(context)[mode]![indexDescriptionExt] != "" ? "\n" : ""}${CCTK.primaryBattChargeCfg.strings(context)[mode]![indexDescriptionExt]}",
            onPress: () {_handlePress(mode);},
            paddingV: 10,
            paddingH: 20,
            isSelected: currentMode == mode,
            isLoading:  currentMode == mode && currentlyLoading,
            bottomItem: _getBottomBar(mode),
            isDataMissing: currentMode.isEmpty,
          ),
      ]),
    );
  }
}
