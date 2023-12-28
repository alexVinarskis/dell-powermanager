import '../classes/cctk.dart';

class ParameterState {
  Map <String, bool>? supported;
  String mode = "";

  ParameterState({this.mode = "", this.supported});
}

class CCTKState {
  bool? cctkCompatible;
  Map <dynamic, ParameterState> parameters = {
    CCTK.thermalManagement: ParameterState(),
    CCTK.primaryBattChargeCfg: ParameterState(),
    CCTK.advBatteryChargeCfg: ParameterState(),
  };
}
