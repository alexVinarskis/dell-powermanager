import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; 

enum PowermodeProfile {
  powerSaving,
  balanced,
  performance,
  custom,
}

class Powermode {
  static const profileInfoLinux = (
    cmd: 'powerprofilesctl get',
    map: <String, PowermodeProfile> {
      'power-saver' : PowermodeProfile.powerSaving,
      'balanced'    : PowermodeProfile.balanced,
      'performance' : PowermodeProfile.performance,
    },
  );
  static const profileInfoWindows = (
    cmd: 'powercfg /GetActiveScheme',
    map: <String, PowermodeProfile> {
      '381b4222-f694-41f0-9685-ff5bb260df2e'  : PowermodeProfile.balanced,    // balanced
      '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'  : PowermodeProfile.performance, // high performance
      'e9a42b02-d5df-448d-aa08-03f14749eb61'  : PowermodeProfile.performance, // ultimate performance
      '599de865-6fac-4960-aba9-c6ae6181a8b8'  : PowermodeProfile.performance, // max
      'a1841308-3541-4fab-bc81-f71556f20b4a'  : PowermodeProfile.powerSaving, // power saving
      '49ef8fce-bb7f-488e-b6a0-f1fc77ec649b'  : PowermodeProfile.custom,      // dell
    },
  );

  static Map<PowermodeProfile, String> profileInfoStrings(BuildContext context) {
    return {
      // cctkCmd : Tile, Description
      PowermodeProfile.powerSaving : S.of(context)!.powermodePowersaving,
      PowermodeProfile.balanced    : S.of(context)!.powermodeBalanced,
      PowermodeProfile.performance : S.of(context)!.powermodePerformance,
      PowermodeProfile.custom      : S.of(context)!.powermodeCustom,
    };
  }
}
