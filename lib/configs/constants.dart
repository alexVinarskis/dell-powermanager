class Constants {
  static const animationMs = 250;
  static const animationFastMs = 150;

  static const authorName = 'alexVinarskis';
  static const applicationLegalese = '\u{a9} 2025 ${Constants.authorName}';
  static const urlHomepage = 'https://github.com/${Constants.authorName}/dell-powermanager';
  static const urlBugReport = 'https://github.com/${Constants.authorName}/dell-powermanager/issues/new/choose';
  static const urlApi = 'https://api.github.com/repos/${Constants.authorName}/dell-powermanager';

  static const urlDellCommandConfigure = "https://www.dell.com/support/kbdoc/en-us/000178000/dell-command-configure";

  static const packagesLinux = ['command-configure', 'srvadmin-hapi', 'libssl3'];
  static const packagesWindows = ['Dell Command | Configure'];

  // [link, filename]
  static const packagesLinuxUrlDell = ['https://dl.dell.com/FOLDER12705845M/1/command-configure_5.1.0-6.ubuntu24_amd64.tar.gz', 'command-configure_5.1.0-6.ubuntu24_amd64.tar.gz'];
  static const packagesLinuxDownloadPath = '/tmp/dell-powermanager';

  static const packagesWindowsUrlDell = ['https://dl.dell.com/FOLDER13914977M/1/Dell-Command-Configure-Application_5RNW8_WIN64_5.2.1.16_A00.EXE', 'Dell-Command-Configure-Application_5RNW8_WIN64_5.2.1.16_A00.EXE'];
  // CMD variables notation!
  // Windows may have either CMD or PowerShell as default shell. Revert to using CMD, as it is always there
  static const packagesWindowsDownloadPath ="%TEMP%\\dell-powermanager";
  static const apiPathWindows =  "%ProgramFiles(x86)%\\Dell\\Command Configure\\X86_64\\cctk.exe";

  // These string shall also be hardcoded to ./package!
  static const apiPathLinux = '/opt/dell/dcc';
  static const applicationName = 'Dell Power Manager by VA';
  static const applicationPackageName = 'dell-powermanager';
  static const applicationVersion = '0.1.0';

  static const githubApiReleases = '${Constants.urlApi}/releases/latest';
  static const githubApiRequest = 'curl -L -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28"';
  static const githubApiFieldTagname = 'tag_name';
  static const githubApiFieldAssets = 'assets';
  static const githubApiFieldBrowserDownloadUrl = 'browser_download_url';
  static const githubApiFieldHtmlUrl = 'html_url';

  static const varnameBiosPwd = 'BIOS_PWD';
  static const varnamePowermanagerDebug = 'POWERMANAGER_DEBUG';

  /// Launch argument to force Dell Command | Configure (CCTK) instead of DellBIOSProvider on Windows.
  static const argUseCctk = '--use-cctk';

  /// Timeout in seconds for a single BIOS read (query). Prevents UI from hanging if backend hangs.
  static const backendQueryTimeoutSec = 90;
  /// Timeout in seconds for a single BIOS write (request). Prevents "loading forever" if PowerShell/CCTK hangs.
  static const backendRequestTimeoutSec = 45;
  /// Timeout for backend ensureReady (e.g. first-time DellBIOSProvider install).
  static const backendEnsureReadyTimeoutSec = 120;
}
