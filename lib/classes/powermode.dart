import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; 

enum PowermodeProfile {
  powerSaving,
  balanced,
  performance,
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
    // ToDo Windows integration;
    cmd: '',
    args: (),
  );

  static Map<PowermodeProfile, String> profileInfoStrings(BuildContext context) {
    return {
      // cctkCmd : Tile, Description
      PowermodeProfile.powerSaving : S.of(context)!.powermodePowersaving,
      PowermodeProfile.balanced    : S.of(context)!.powermodeBalanced,
      PowermodeProfile.performance : S.of(context)!.powermodePerformance,
    };
  }
}
