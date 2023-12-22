import '../classes/cctk.dart';

class ParameterState {
  late final Map <String, bool> supported = {};
  String mode = "";
}

class CCTKState {
  Map <dynamic, ParameterState> parameters = {
    CCTK.thermalManagement: ParameterState(),
    CCTK.primaryBattChargeCfg: ParameterState(),
    CCTK.advBatteryChargeCfg: ParameterState(),
  };
}
