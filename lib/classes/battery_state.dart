import 'battery.dart';

class BatteryState {
  // Values given in SI units (Voltage in V, Current in A, Capacity in Ah, Power in W, Percentage in %)
  bool?     powerSupplyPresent;
  bool?     batteryPresent;
  bool?     batteryCharging;
  String?   batteryType;
  String?   batteryTechnology;
  int?      batteryCycleCount;
  double?   batteryVoltageMinDesign;
  double?   batteryVoltageNow;
  double?   batteryCurrentNow;
  double?   batteryChargeFullDesign;
  double?   batteryChargeFull;
  double?   batteryChargeNow;
  int?      batteryPercentage;
  String?   batteryPercentageStatus;
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
    batteryPercentageStatus = _setIfPresent(map[Battery.batteryInfoLinux.args.batteryCapacityLevel],    (var x) => x);
    batteryModelName        = _setIfPresent(map[Battery.batteryInfoLinux.args.batteryModelName],        (var x) => x);
    batteryManufacturer     = _setIfPresent(map[Battery.batteryInfoLinux.args.batteryManufacturer],     (var x) => x);
    batterySerialNumber     = _setIfPresent(map[Battery.batteryInfoLinux.args.batterySerialNumber],     (var x) => x);
    batteryHealth           = _setIfPresent(map[Battery.batteryInfoLinux.args.batteryChargeFull],       (var x) => double.parse(x) / double.parse(map[Battery.batteryInfoLinux.args.batteryChargeFullDesign]) * 100);
    batteryDesignCapacity   = _setIfPresent(map[Battery.batteryInfoLinux.args.batteryChargeFullDesign], (var x) => double.parse(x) / 1000000 * double.parse(map[Battery.batteryInfoLinux.args.batteryVoltageMinDesign]) / 1000000);
    batteryCurrentPower     = _setIfPresent(map[Battery.batteryInfoLinux.args.batteryCurrentNow],       (var x) => double.parse(x) / 1000000 * double.parse(map[Battery.batteryInfoLinux.args.batteryVoltageNow]) / 1000000);
  }
  BatteryState.fromWindowsMap(Map<String, dynamic> map) {
    // ToDo Windows integration;
  }

  _setIfPresent(var source, var transformation) {
    if (source == null || source.isEmpty) {
      return null;
    }
    return transformation(source);
  }
}
