import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../classes/api_cctk.dart';
import '../configs/constants.dart';
import '../configs/environment.dart';

class BiosProtectionManager {
  static const storage = FlutterSecureStorage();

  static final List<Function(String? biosPwd)> _callbacksBiosPwdChanged = [];
  static void addCallbacksBiosPwdChanged(var callback)  { _callbacksBiosPwdChanged.add(callback); }
  static void removeCallbacksBiosPwdChanged(var callback) { _callbacksBiosPwdChanged.remove(callback); }
  static void _callBiosPwdChanged(String? biosPwd) {
    var dubList = List.from(_callbacksBiosPwdChanged);
    for (var callback in dubList) {
      callback(biosPwd);
    }
  }

  static Future<void> secureReadPassword() async {
    String? pwdB64 = await storage.read(key: Constants.varnameBiosPwd);
    if (pwdB64 == null) {
      return;
    }
    String pwd = utf8.decode(base64.decode(pwdB64));
    if (pwd.isEmpty) {
      return;
    }
    loadPassword(pwd);
  }

  static Future<void> secureWritePassword(String password) async {
    await storage.write(
      key: Constants.varnameBiosPwd,
      value: base64.encode(utf8.encode(password)),
    );
    loadPassword(password);
  }

  static Future<void> secureDeletePassword() async {
    await storage.delete(key: Constants.varnameBiosPwd);
    loadPassword("");
  }

  static void loadPassword(String password) {
    Environment.biosPwd = password;
    ApiCCTK.sourceEnvironment();
    _callBiosPwdChanged(Environment.biosPwd);
  }
}
