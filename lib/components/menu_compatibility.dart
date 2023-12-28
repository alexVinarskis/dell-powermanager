import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../classes/api_cctk.dart';
import '../classes/cctk_state.dart';
import '../configs/constants.dart';

enum CompatibilityState {
  hidden,
  incompatible,
}

class MenuCompatibility extends StatefulWidget {
  const MenuCompatibility({super.key, this.paddingH = 0, this.paddingV = 0, this.backgroundColor = Colors.transparent});

  final double paddingH;
  final double paddingV;
  final Color backgroundColor;

  @override
  State<MenuCompatibility> createState() => MenuCompatibilityState();
}

class MenuCompatibilityState extends State<MenuCompatibility> {
  CompatibilityState _compatibilityState = CompatibilityState.hidden;
  late Map<CompatibilityState, String> _compatibilityStateTitles;

  @override
  void initState() {
    super.initState();
    _handleCCTKStateUpdate(ApiCCTK.cctkState);
    ApiCCTK.addCallbacksStateChanged(_handleCCTKStateUpdate);
  }
  @override
  void dispose() {
    ApiCCTK.removeCallbacksStateChanged(_handleCCTKStateUpdate);
    super.dispose();
  }

  void _handleCCTKStateUpdate(CCTKState cctkState) {
    if (cctkState.cctkCompatible == null) {
      return;
    }
    if (cctkState.cctkCompatible == false) {
      setState(() {
        _compatibilityState = CompatibilityState.incompatible;
      });
    }
    ApiCCTK.removeCallbacksStateChanged(_handleCCTKStateUpdate);
  }

  @override
  Widget build(BuildContext context) {
    _compatibilityStateTitles = {
      CompatibilityState.hidden           : "",
      CompatibilityState.incompatible     : S.of(context)!.compatibilityCardSubtitle,
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: Constants.animationMs),
      child:  _compatibilityState != CompatibilityState.hidden ? Card(
        key: const Key("compatibilityShownTrue"),
        clipBehavior: Clip.antiAlias,
        color: Colors.red.withOpacity(0.4),
        elevation: 0,
        margin: EdgeInsets.symmetric(vertical: widget.paddingV, horizontal: widget.paddingH),
        child: InkWell(
          onTap: () {},
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 15, right: 15),
                    child: Icon(Icons.warning_amber_rounded),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          S.of(context)!.compatibilityCardTitle,
                          style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 5,),
                        Text(_compatibilityStateTitles[_compatibilityState].toString(), textAlign: TextAlign.justify,),
                      ],
                    ),
                  ),
                ],
              ),
              const Align(alignment: Alignment.bottomCenter, child: LinearProgressIndicator(backgroundColor: Colors.transparent, color: Colors.transparent,),),
            ],
          ),
        ),
      ) : const SizedBox(
        key: Key("compatibilityShownFalse"),
      ),
    );
  }
}
