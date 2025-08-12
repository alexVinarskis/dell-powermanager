import 'package:dell_powermanager/components/notification_item.dart';
import 'package:dell_powermanager/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../classes/api_cctk.dart';
import '../classes/cctk_state.dart';

enum CompatibilityState {
  hidden,
  incompatible,
}

final Map<CompatibilityState, NotificationState> mapStates = {
  CompatibilityState.hidden : NotificationState.hidden,
  CompatibilityState.incompatible : NotificationState.failedNotification,
};

class NotificationCompatibility extends StatefulWidget {
  const NotificationCompatibility({super.key});

  @override
  State<NotificationCompatibility> createState() => NotificationCompatibilityState();
}

class NotificationCompatibilityState extends State<NotificationCompatibility> {
  CompatibilityState _compatibilityState = CompatibilityState.hidden;

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
    return NotificationItem(
      S.of(context)!.compatibilityCardTitle,
      S.of(context)!.compatibilityCardSubtitle,
      Icons.warning_amber_rounded,
      state: mapStates[_compatibilityState]!,
    );
  }
}
