import 'battery.dart';

class BatteryState {
  // Values given in SI units (Voltage in V, Current in A, Capacity in Ah, Power in W, Percentage in %)
  bool?     powerSupplyPresent;
  bool?     batteryPresent;
  bool?     batteryCharging;
  String?   batteryType;
  String?   batteryTechnology;
  int?      batteryCycleCount;
  double?   batteryVoltageMinDesign;    // V
  double?   batteryVoltageNow;          // V
  double?   batteryCurrentNow;          // A
  double?   batteryChargeFullDesign;    // Ah
  double?   batteryChargeFull;          // Ah
  double?   batteryChargeNow;           // Ah
  int?      batteryPercentage;          // %
  bool?     batteryPercentageLow;
  String?   batteryModelName;
  String?   batteryManufacturer;
  String?   batterySerialNumber;
  double?   batteryHealth;              // % of original capacity
  double?   batteryDesignCapacity;      // Wh
  double?   batteryCurrentPower;        // W, charing/discharing power, depends on status

  BatteryState.fromLinuxMap(Map<String, dynamic> map) {
    // populate data from Linux String
    powerSupplyPresent      = _setIfPresent(map[Battery.batteryInfoLinux.args.powerSupplyPresent],      (var x) => x == "1");
    batteryPresent          = _setIfPresent(map[Battery.batteryInfoLinux.args.batteryPresent],          (var x) => x == "1");
    batteryCharging         = _setIfPresent(map[Battery.batteryInfoLinux.args.batteryStatus],           (var x) => x == "Charging");
    batteryType             = _setIfPresent(map[Battery.batteryInfoLinux.args.batteryType],             (var x) => x);
    batteryTechnology       = _setIfPresent(map[Battery.batteryInfoLinux.args.batteryTechnology],       (var x) => x);
    batteryCycleCount       = _setIfPresent(map[Battery.batteryInfoLinux.args.batteryCycleCount],       (var x) => int.parse(x));
    batteryVoltageMinDesign = _setIfPresent(map[Battery.batteryInfoLinux.args.batteryVoltageMinDesign], (var x) => double.parse(x) / 1000000);
    batteryVoltageNow       = _setIfPresent(map[Battery.batteryInfoLinux.args.batteryVoltageNow],       (var x) => double.parse(x) / 1000000);
    batteryCurrentNow       = _setIfPresent(map[Battery.batteryInfoLinux.args.batteryCurrentNow],       (var x) => double.parse(x) / 1000000);
    batteryChargeFullDesign = _setIfPresent(map[Battery.batteryInfoLinux.args.batteryChargeFullDesign], (var x) => double.parse(x) / 1000000);
    batteryChargeFull       = _setIfPresent(map[Battery.batteryInfoLinux.args.batteryChargeFull],       (var x) => double.parse(x) / 1000000);
    batteryChargeNow        = _setIfPresent(map[Battery.batteryInfoLinux.args.batteryChargeNow],        (var x) => double.parse(x) / 1000000);
    batteryPercentage       = _setIfPresent(map[Battery.batteryInfoLinux.args.batteryCapacity],         (var x) => int.parse(x));
    batteryPercentageLow    = _setIfPresent(map[Battery.batteryInfoLinux.args.batteryCapacityLevel],    (var x) => x != 'Normal');
    batteryModelName        = _setIfPresent(map[Battery.batteryInfoLinux.args.batteryModelName],        (var x) => x);
    batteryManufacturer     = _setIfPresent(map[Battery.batteryInfoLinux.args.batteryManufacturer],     (var x) => x);
    batterySerialNumber     = _setIfPresent(map[Battery.batteryInfoLinux.args.batterySerialNumber],     (var x) => x);

    batteryHealth           = _setIfPresent(map[Battery.batteryInfoLinux.args.batteryChargeFull],       (var x) => double.parse(x) / double.parse(map[Battery.batteryInfoLinux.args.batteryChargeFullDesign]) * 100);
    batteryDesignCapacity   = _setIfPresent(map[Battery.batteryInfoLinux.args.batteryChargeFullDesign], (var x) => double.parse(x) / 1000000 * double.parse(map[Battery.batteryInfoLinux.args.batteryVoltageMinDesign]) / 1000000);
    batteryCurrentPower     = _setIfPresent(map[Battery.batteryInfoLinux.args.batteryCurrentNow],       (var x) => double.parse(x) / 1000000 * double.parse(map[Battery.batteryInfoLinux.args.batteryVoltageNow]) / 1000000);

    // Some battery types use different parameters, if previous methods failed, attempt to use alt parameters
    batteryHealth         ??= _setIfPresent(map[Battery.batteryInfoLinux.args.batteryEnergyFull],       (var x) => double.parse(x) / double.parse(map[Battery.batteryInfoLinux.args.batteryEnergyFullDesign]) * 100);
    batteryDesignCapacity ??= _setIfPresent(map[Battery.batteryInfoLinux.args.batteryEnergyFullDesign], (var x) => double.parse(x) / 1000000);
    batteryCurrentPower   ??= _setIfPresent(map[Battery.batteryInfoLinux.args.batteryPowerNow], (var x) => double.parse(x) / 1000000);
  }
  BatteryState.fromWindowsMap(Map<String, dynamic> map) {
    powerSupplyPresent      = _setIfPresent(map[Battery.batteryInfoWindows.args.powerSupplyPresent],    (var x) => x == "True");
    batteryCharging         = _setIfPresent(map[Battery.batteryInfoWindows.args.batteryCharging],       (var x) => x == "True");
    batteryCycleCount       = _setIfPresent(map[Battery.batteryInfoWindows.args.batteryCycleCount],     (var x) => int.parse(x));
    batteryVoltageNow       = _setIfPresent(map[Battery.batteryInfoWindows.args.batteryVoltageNow],     (var x) => double.parse(x) / 1000);
    batteryDesignCapacity   = _setIfPresent(map[Battery.batteryInfoWindows.args.batteryCapacityFullDesign], (var x) => double.parse(x) / 1000);
    batteryPercentageLow    = _setIfPresent(map[Battery.batteryInfoWindows.args.batteryCapacityLevel],  (var x) => x == 'True');
    batteryModelName        = _setIfPresent(map[Battery.batteryInfoWindows.args.batteryModelName],      (var x) => x);
    batteryManufacturer     = _setIfPresent(map[Battery.batteryInfoWindows.args.batteryManufacturer],   (var x) => x);
    batterySerialNumber     = _setIfPresent(map[Battery.batteryInfoWindows.args.batterySerialNumber],   (var x) => x);

    batteryPercentage       = _setIfPresent(map[Battery.batteryInfoWindows.args.batteryCapacityNow],    (var x) => (int.parse(x) / double.parse(map[Battery.batteryInfoWindows.args.batteryCapacityFull]) * 100).toInt());
    batteryHealth           = _setIfPresent(map[Battery.batteryInfoWindows.args.batteryCapacityFull],   (var x) => double.parse(x) / double.parse(map[Battery.batteryInfoWindows.args.batteryCapacityFullDesign]) * 100);
    batteryCurrentPower     = _setIfPresent(map[batteryCharging! ? Battery.batteryInfoWindows.args.batteryChargeRate : Battery.batteryInfoWindows.args.batteryDischargeRate],  (var x) => double.parse(x) / 1000);
  }

  _setIfPresent(var source, var transformation) {
    if (source == null || source.isEmpty) {
      return null;
    }
    return transformation(source);
  }
}
