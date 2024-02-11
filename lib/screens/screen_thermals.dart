import 'package:flutter/material.dart';
import 'package:skeleton_text/skeleton_text.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; 
import '../classes/api_cctk.dart';
import '../classes/api_powermode.dart';
import '../classes/powermode_state.dart';
import '../classes/powermode.dart';
import '../components/mode_item.dart';
import '../classes/cctk.dart';
import '../classes/cctk_state.dart';
import '../configs/constants.dart';

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
  ParameterState? _currentState;
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
    ParameterState? state = cctkState.parameters[CCTK.thermalManagement];
    if (state == null || (state.supported?.isEmpty ?? true)) {
      return;
    }
    setState(() {
      _currentState = ParameterState(
        mode: state.mode.split(':')[0],
        supported: state.supported,
      );
    });
  }
  void _handlePowermodeStateUpdate(PowermodeState? powermodeState) {
    setState(() {
      _powermodeState = powermodeState;
    });
  }

  bool _isDataMissing() {
    if ((_currentState?.supported?.isEmpty ?? true)) {
      return true;
    }
    if (((_currentState?.supported?.containsValue(true) ?? false)) && (_currentState?.mode.isEmpty ?? true)) {
      return true;
    }
    return false;
  }

  Future<bool> changeMode(mode) async {
    return await ApiCCTK.request(CCTK.thermalManagement.cmd, mode);
  }

  Widget _getPowermodeBadge(BuildContext context, {double paddingH = 0, double paddingV = 0,}) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: Constants.animationMs),
      child: ApiPowermode.powermodeSupported ? Card(
        key: const Key("powermodeSupported"),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.0),
        ),
        color: Colors.amber.withOpacity(0.4),
        elevation: 0,
        margin: EdgeInsets.symmetric(vertical: paddingV, horizontal: paddingH),
        child: _powermodeState == null ?
          SkeletonAnimation(
            curve: Curves.easeInOutCirc,
            shimmerColor: Theme.of(context).colorScheme.secondaryContainer,
            gradientColor: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0),
            child: _getPowermodeContent(context),
          ) :
          _getPowermodeContent(context),
      ) : const SizedBox(
        key: Key("powermodeUnsupported"),
      ),
    );
  }
  Widget _getPowermodeContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      width: 260,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            S.of(context)!.powermodeTitle,
            style: TextStyle(fontSize: Theme.of(context).textTheme.titleSmall!.fontSize),
          ),
          Row(children: [
            Text(
              ":  ",
              style: TextStyle(fontSize: Theme.of(context).textTheme.titleSmall!.fontSize),
            ),
            Text(
              Powermode.profileInfoStrings(context)[_powermodeState?.profileInfo]?? S.of(context)!.powermodeCustom,
              style: Theme.of(context).textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w700),
            ),
          ],)
        ]
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, top: 20),
      child: Column(children: [
        Align(
          alignment: Alignment.centerRight,
          child: _getPowermodeBadge(
            context,
            paddingH: 20,
            paddingV: 10,
          ),
        ),
        for (var mode in CCTK.thermalManagement.strings(context).keys) 
          ModeItem(CCTK.thermalManagement.strings(context)[mode]![indexTitle],
            description: CCTK.thermalManagement.strings(context)[mode]![indexDescription],
            onPress: () async {
              if (!currentlyLoading) {
                setState(() {
                  _currentState?.mode = mode;
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
            isSelected: _currentState?.mode == mode,
            isSupported: _currentState?.supported?[mode] ?? false,
            isLoading:  _currentState?.mode == mode && currentlyLoading,
            isDataMissing: _isDataMissing(),
          ),
      ]),
    );
  }
}
