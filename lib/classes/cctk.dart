import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; 

class CCTK {
  static const thermalManagement = (cmd: 'ThermalManagement',
    args: (
      optimized: 'Optimized',
      quiet: 'Quiet',
      cool: 'Cool',
      ultra: 'UltraPerformance',
  ));
  static Map<String, List<String>> thermalManagementStrings(BuildContext context) {
    return {
      // cctkCmd : Tile, Description
      thermalManagement.args.optimized : [S.of(context)!.cctkThermalOptimizedTitle, S.of(context)!.cctkThermalOptimizedDescription],
      thermalManagement.args.quiet     : [S.of(context)!.cctkThermalQuietTitle, S.of(context)!.cctkThermalQuietDescription],
      thermalManagement.args.cool      : [S.of(context)!.cctkThermalCoolTitle, S.of(context)!.cctkThermalCoolDescription],
      thermalManagement.args.ultra     : [S.of(context)!.cctkThermalUltraTitle, S.of(context)!.cctkThermalUltraDescription],
    };
  }
  static const primaryBattChargeCfg = (cmd: 'PrimaryBattChargeCfg',
    args: (
      standard: 'Standard',
      express: 'Express',
      primAcUse: 'PrimAcUse',
      adaptive: 'Adaptive',
      custom: 'Custom',
  ));
  static Map<String, List<String>> primaryBattChargeCfgStrings(BuildContext context) {
    return {
      // cctkCmd : Tile, Description, Extended Description
      primaryBattChargeCfg.args.standard  : [S.of(context)!.cctkBatteryStandardTitle, S.of(context)!.cctkBatteryStandardDescription, S.of(context)!.cctkBatteryStandardDescriptionExt],
      primaryBattChargeCfg.args.express   : [S.of(context)!.cctkBatteryExpressTitle, S.of(context)!.cctkBatteryExpressDescription, S.of(context)!.cctkBatteryExpressDescriptionExt],
      primaryBattChargeCfg.args.primAcUse : [S.of(context)!.cctkBatteryPrimAcUseTitle, S.of(context)!.cctkBatteryPrimAcUseDescription, S.of(context)!.cctkBatteryPrimAcUseDescriptionExt],
      primaryBattChargeCfg.args.adaptive  : [S.of(context)!.cctkBatteryAdaptiveTitle, S.of(context)!.cctkBatteryAdaptiveDescription, S.of(context)!.cctkBatteryAdaptiveDescriptionExt],
      // The start value range should be 50-95 percentage, the stop value range should be 55-100 percentage, and the difference between the start and stop values should be greater than or equal to 5.
      // Example: Custom:start-end
      primaryBattChargeCfg.args.custom    : [S.of(context)!.cctkBatteryCustomTitle, S.of(context)!.cctkBatteryCustomDescription, S.of(context)!.cctkBatteryCustomDescriptionExt],
    };
  }
  //   Syntax:
  // cctk --AdvBatteryChargeCfg=Disabled
  // cctk --AdvBatteryChargeCfg=Enabled,[day]-[Beginning Of Day in HH:MM format]/[Work Period in HH:MM format],
  static const advBatteryChargeCfg = (cmd: 'AdvBatteryChargeCfg',
    args: (
      disabled: 'Disabled',
      enabled: 'Enabled',
  ));
}
