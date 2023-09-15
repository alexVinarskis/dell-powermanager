class Battery {
  static const batteryInfoLinux = (
    cmd: '/bin/sh -c "cat /sys/class/power_supply/*/uevent"',
    args: (
      // parameters                  linux variable names                    sample values for XPS 9530
      powerSupplyPresent:           'POWER_SUPPLY_ONLINE',                // 1/0, whether AC is connected
      batteryName:                  'POWER_SUPPLY_NAME',                  // BAT0
      batteryType:                  'POWER_SUPPLY_TYPE',                  // Battery
      batteryStatus:                'POWER_SUPPLY_STATUS',                // Charging/Discharging/Not charging
      batteryPresent:               'POWER_SUPPLY_PRESENT',               // 1/0, whether battery is present
      batteryTechnology:            'POWER_SUPPLY_TECHNOLOGY',            // Li-poly
      batteryCycleCount:            'POWER_SUPPLY_CYCLE_COUNT',           // 99
      batteryVoltageMinDesign:      'POWER_SUPPLY_VOLTAGE_MIN_DESIGN',    // 11400000
      batteryVoltageNow:            'POWER_SUPPLY_VOLTAGE_NOW',           // 11049000
      batteryCurrentNow:            'POWER_SUPPLY_CURRENT_NOW',           // 1675000
      batteryChargeFullDesign:      'POWER_SUPPLY_CHARGE_FULL_DESIGN',    // 7393000
      batteryChargeFull:            'POWER_SUPPLY_CHARGE_FULL',           // 6439000
      batteryChargeNow:             'POWER_SUPPLY_CHARGE_NOW',            // 2119000
      batteryCapacity:              'POWER_SUPPLY_CAPACITY',              // 32
      batteryCapacityLevel:         'POWER_SUPPLY_CAPACITY_LEVEL',        // Normal
      batteryModelName:             'POWER_SUPPLY_MODEL_NAME',            // DELL 70N2F34
      batteryManufacturer:          'POWER_SUPPLY_MANUFACTURER',          // SMP
      batterySerialNumber:          'POWER_SUPPLY_SERIAL_NUMBER',         // 625
    ),
  );
  static const batteryInfoWindows = (
    // ToDo Windows integration;
    cmd: '',
    args: (),
  );
}
