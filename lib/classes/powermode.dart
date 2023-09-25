enum PowermodeProfile {
  powerSaving,
  balanced,
  performance,
}

class Powermode {
  static const profileInfoLinux = (
    cmd: 'powerprofilesctl get',
    map: <String, PowermodeProfile> {
      'power-saver' : PowermodeProfile.powerSaving,
      'balanced'    : PowermodeProfile.balanced,
      'performance' : PowermodeProfile.performance,
    },
  );
  static const profileInfoWindows = (
    // ToDo Windows integration;
    cmd: '',
    args: (),
  );
}
