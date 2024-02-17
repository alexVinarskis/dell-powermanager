import 'package:dell_powermanager/classes/api_cctk.dart';

import '../configs/environment.dart';

class BiosProtectionManager {

  static void loadPassword(String password) {
    Environment.biosPwd = password;
    ApiCCTK.sourceEnvironment();
  }
}
