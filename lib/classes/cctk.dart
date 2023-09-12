class CCTK {
  static const thermalManagement = (cmd: 'ThermalManagement',
    args: (
      optimized: 'Optimized',
      quiet: 'Quiet',
      cool: 'Cool',
      ultra: 'UltraPerformance',
  ));
  static const primaryBattChargeCfg = (cmd: 'PrimaryBattChargeCfg',
    args: (
      standard: 'Standard',
      express: 'Express',
      primAcUse: 'PrimAcUse',
      adaptive: 'Adaptive',
      custom: 'Custom',
  ));
  //   Syntax:
  // cctk --AdvBatteryChargeCfg=Disabled
  // cctk --AdvBatteryChargeCfg=Enabled,[day]-[Beginning Of Day in HH:MM format]/[Work Period in HH:MM format],
  static const advBatteryChargeCfg = (cmd: 'AdvBatteryChargeCfg',
    args: (
      disabled: 'Disabled',
      enabled: 'Enabled',
  ));
}
