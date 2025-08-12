import 'package:dell_powermanager/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class CCTK {
  /*
   * Exit codes of the CLI
   * Used premarily for BIOS password requests handling
   * 
   */
  static const exitCodes = (
    ok:               0,
    sysPwdRequired:   66,
    sysPwdInvalid:    67,
    setupPwdRequired: 65,
    setupPwdInvalid:  58,
    ownerPwdSet:      112,
  );

  /*
   * Thermal Management
   * 
   * Configures fan speeds, and (un)caps maximum CPU performance
   * 
   */
  static const thermalManagement = (
    cmd: 'ThermalManagement',
    modes: (
      optimized: 'Optimized',
      quiet: 'Quiet',
      cool: 'Cool',
      ultra: 'UltraPerformance',
    ),
    strings: _thermalManagementStrings,
  );
  static Map<String, List<String>> _thermalManagementStrings(BuildContext context) {
    return {
      // cctkCmd : Tile, Description
      thermalManagement.modes.optimized : [S.of(context)!.cctkThermalOptimizedTitle, S.of(context)!.cctkThermalOptimizedDescription],
      thermalManagement.modes.quiet     : [S.of(context)!.cctkThermalQuietTitle, S.of(context)!.cctkThermalQuietDescription],
      thermalManagement.modes.cool      : [S.of(context)!.cctkThermalCoolTitle, S.of(context)!.cctkThermalCoolDescription],
      thermalManagement.modes.ultra     : [S.of(context)!.cctkThermalUltraTitle, S.of(context)!.cctkThermalUltraDescription],
    };
  }

  /*
   * Primary Battery Configuration
   *
   * Configures charging speed and thresholds for custom % range
   * 
   */
  static const primaryBattChargeCfg = (
    cmd: 'PrimaryBattChargeCfg',
    modes: (
      standard: 'Standard',
      express: 'Express',
      primAcUse: 'PrimAcUse',
      adaptive: 'Adaptive',
      custom: 'Custom',
    ),
    strings: _primaryBattChargeCfgStrings,
  );
  static Map<String, List<String>> _primaryBattChargeCfgStrings(BuildContext context) {
    return {
      // cctkCmd : Tile, Description, Extended Description
      primaryBattChargeCfg.modes.standard  : [S.of(context)!.cctkBatteryStandardTitle, S.of(context)!.cctkBatteryStandardDescription, S.of(context)!.cctkBatteryStandardDescriptionExt],
      primaryBattChargeCfg.modes.express   : [S.of(context)!.cctkBatteryExpressTitle, S.of(context)!.cctkBatteryExpressDescription, S.of(context)!.cctkBatteryExpressDescriptionExt],
      primaryBattChargeCfg.modes.primAcUse : [S.of(context)!.cctkBatteryPrimAcUseTitle, S.of(context)!.cctkBatteryPrimAcUseDescription, S.of(context)!.cctkBatteryPrimAcUseDescriptionExt],
      primaryBattChargeCfg.modes.adaptive  : [S.of(context)!.cctkBatteryAdaptiveTitle, S.of(context)!.cctkBatteryAdaptiveDescription, S.of(context)!.cctkBatteryAdaptiveDescriptionExt],
      // The start value range should be 50-95 percentage, the stop value range should be 55-100 percentage, and the difference between the start and stop values should be greater than or equal to 5.
      // Example: Custom:start-end
      primaryBattChargeCfg.modes.custom    : [S.of(context)!.cctkBatteryCustomTitle, S.of(context)!.cctkBatteryCustomDescription, S.of(context)!.cctkBatteryCustomDescriptionExt],
    };
  }

  /*
   * Advanced Battery Configuration
   *
   * Configured charging periods to follow custom day/time schedule
   * 
   *
   * Syntax:
   *    cctk --AdvBatteryChargeCfg=Disabled
   *    cctk --AdvBatteryChargeCfg=Enabled,[day]-[Beginning Of Day in HH:MM format]/[Work Period in HH:MM format],
   * 
   */
  static const advBatteryChargeCfg = (
    cmd: 'AdvBatteryChargeCfg',
    modes: (
      disabled: 'Disabled',
      enabled: 'Enabled',
  ));
}
