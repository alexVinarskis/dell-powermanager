import '../classes/cctk.dart';

class ParameterState {
  Map <String, bool>? supported;
  String mode = "";

  ParameterState({this.mode = "", this.supported});
}

class ExitState {
  int exitCode;
  String cctkType;
  String mode;

  ExitState(this.exitCode, this.cctkType, this.mode);
}

class CCTKState {
  bool? cctkCompatible;
  int? exitCodeRead;
  ExitState? exitStateWrite;
  Map <dynamic, ParameterState> parameters = {
    CCTK.thermalManagement: ParameterState(),
    CCTK.primaryBattChargeCfg: ParameterState(),
    CCTK.advBatteryChargeCfg: ParameterState(),
  };
}
