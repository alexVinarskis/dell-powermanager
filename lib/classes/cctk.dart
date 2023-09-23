class CCTK {
  static const thermalManagement = (cmd: 'ThermalManagement',
    args: (
      optimized: 'Optimized',
      quiet: 'Quiet',
      cool: 'Cool',
      ultra: 'UltraPerformance',
  ));
  static final Map<String, List<String>> thermalManagementStrings = {
    // cctkCmd : Tile, Description
    thermalManagement.args.optimized : ["Optimized", "This is the standard setting for cooling fan and processor heat management. This setting is a balance of performance., noise and temperature.",],
    thermalManagement.args.quiet     : ["Quiet", "Processor and cooling fan speed are adjusted to reduce fan noise. This may mean a higher system surface temperature and reduced performance.",],
    thermalManagement.args.cool      : ["Cool", "Processor and cooling fan speed are adjusted to help maintain a cooler system surface temperature. This may mean reduced system performance and more noise.",],
    thermalManagement.args.ultra     : ["Ultra Performance", "Processor and cooling fan speed is increased for more performance. This may mean higher system suface temperature and more noise.",],
  };
  static const primaryBattChargeCfg = (cmd: 'PrimaryBattChargeCfg',
    args: (
      standard: 'Standard',
      express: 'Express',
      primAcUse: 'PrimAcUse',
      adaptive: 'Adaptive',
      custom: 'Custom',
  ));
  static final Map<String, List<String>> primaryBattChargeCfgStrings = {
    // cctkCmd : Tile, Description, Extended Description
    primaryBattChargeCfg.args.standard  : ["Standard", "Recommended for users who switch between battery power and an external power source.", "Fully charges your battery at an standard rate (not as fast ExpressCharge™). Charge time varies by model.",],
    primaryBattChargeCfg.args.express   : ["ExpressCharge™", "Recommended for users who need the battery charged over a short period of time.", "",],
    primaryBattChargeCfg.args.primAcUse : ["Primarily AC Use", "Recommended for users who operate their system while plugged in to an external power source.", "This setting may extend your battery's lifespan by lowering the charge threshold.",],
    primaryBattChargeCfg.args.adaptive  : ["Adaptive (Recommended)", "Recommended for users who want to 'set it and forget it'.", "Lets the system adaptively optimize your battery settings based on your typical battery usage pattern.",],
    // The start value range should be 50-95 percentage, the stop value range should be 55-100 percentage, and the difference between the start and stop values should be greater than or equal to 5.
    // Example: Custom:start-end
    primaryBattChargeCfg.args.custom    : ["Custom", "Recommended for advanced users that desire greater control over when their battery starts and stops charging.", "Set Start and Stop range.",],
  };
  //   Syntax:
  // cctk --AdvBatteryChargeCfg=Disabled
  // cctk --AdvBatteryChargeCfg=Enabled,[day]-[Beginning Of Day in HH:MM format]/[Work Period in HH:MM format],
  static const advBatteryChargeCfg = (cmd: 'AdvBatteryChargeCfg',
    args: (
      disabled: 'Disabled',
      enabled: 'Enabled',
  ));
}
