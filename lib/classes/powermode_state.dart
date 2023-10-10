import '../classes/powermode.dart';

class PowermodeState {
  PowermodeProfile? profileInfo;

  PowermodeState.fromLinuxResponse(String response) {
    profileInfo = _setIfPresent(response, (var x) => Powermode.profileInfoLinux.map.containsKey(x) ? Powermode.profileInfoLinux.map[x] : null);
  }
  PowermodeState.fromWindowsResponse(String response) {
    if (response.isEmpty) {
      return;
    }
    // power scheme's GUID is 4th element in the string
    if (response.split(" ").length < 4) {
      return;
    }
    profileInfo = _setIfPresent(response.split(" ")[3], (var x) => Powermode.profileInfoWindows.map.containsKey(x) ? Powermode.profileInfoWindows.map[x] : null);
  }

  _setIfPresent(var source, var transformation) {
    if (source == null || source.isEmpty) {
      return null;
    }
    return transformation(source);
  }
}
