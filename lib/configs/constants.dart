class Constants {
  static const animationMs = 250;

  static const authorName = 'alexVinarskis';
  static const applicationLegalese = '\u{a9} 2023 ${Constants.authorName}';
  static const urlHomepage = 'https://github.com/${Constants.authorName}/dell-powermanager';
  static const urlBugReport = 'https://github.com/${Constants.authorName}/dell-powermanager/issues/new/choose';
  static const urlApi = 'https://api.github.com/repos/${Constants.authorName}/dell-powermanager';

  static const packagesLinux = ['command-configure', 'srvadmin-hapi', 'libssl1.1'];
  static const packagesWindows = ['Dell Command | Configure'];

  // [link, filename]
  static const packagesLinuxUrlDell = ['https://dl.dell.com/FOLDER09518608M/1/command-configure_4.10.0-5.ubuntu22_amd64.tar.gz', 'command-configure_4.10.0-5.ubuntu22_amd64.tar.gz'];
  static const packagesLinuxUrlLibssl = ['http://nz2.archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.19_amd64.deb', 'libssl1.1_1.1.1f-1ubuntu2.19_amd64.deb'];
  static const packagesLinuxDownloadPath = '/tmp/dell-powermanager';

  static const packagesWindowsUrlDell = ['https://dl.dell.com/FOLDER09477091M/2/Dell-Command-Configure-Application_D6VXJ_WIN_4.10.0.607_A00_01.EXE', 'Dell-Command-Configure-Application_D6VXJ_WIN_4.10.0.607_A00_01.EXE'];
  static const packagesWindowsDownloadPath ="C:\\Users\\Alex\\AppData\\Local\\Temp\\dell-powermanager";
  static const apiPathWindows =  "C:\\Program Files (x86)\\Dell\\Command Configure\\X86_64\\cctk.exe";

  // These string shall also be hardcoded to ./package!
  static const apiPathLinux = '/opt/dell/dcc/cctk';
  static const applicationName = 'Dell Power Manager by VA';
  static const applicationVersion = '0.1.0';

  static const githubApiReleases = '${Constants.urlApi}/releases/latest';
  static const githubApiRequest = 'curl -L -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28"';
  static const githubApiFieldTagname = 'tag_name';
  static const githubApiFieldAssets = 'assets';
  static const githubApiFieldBrowserDownloadUrl = 'browser_download_url';
  static const githubApiFieldHtmlUrl = 'html_url';
}
