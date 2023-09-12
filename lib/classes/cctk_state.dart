import 'package:dell_powermanager/classes/cctk.dart';

class CCTKState {
  static final List _initialQueryParameters = [CCTK.thermalManagement, CCTK.primaryBattChargeCfg];
  static final List _additionalQueryParameters = [];
  static List queryParameters = _initialQueryParameters;

  static void addQueryParameter(var parameter) {
    _additionalQueryParameters.add(parameter);
    queryParameters = {..._initialQueryParameters, ..._additionalQueryParameters}.toList();
  }
  static void removeQueryParameter(var parameter) {
    _additionalQueryParameters.remove(parameter);
    queryParameters = {..._initialQueryParameters, ..._additionalQueryParameters}.toList();
  }

  Map parameters = {
    CCTK.thermalManagement: "",
    CCTK.primaryBattChargeCfg: "",
    CCTK.advBatteryChargeCfg: "",
  };
}
