class Constants {
  static const animationMs = 250;

  static const authorName = 'alexVinarskis';
  static const urlHomepage = 'https://github.com/alexVinarskis/dell-powermanager';
  static const urlBugReport = 'https://github.com/alexVinarskis/dell-powermanager/issues/new/choose';

  static const packagesLinux = ['command-configure', 'srvadmin-hapi', 'libssl1.1'];
  static const packagesWindows = [];

  // [link, filename]
  static const packagesLinuxUrlDell = ['https://dl.dell.com/FOLDER09518608M/1/command-configure_4.10.0-5.ubuntu22_amd64.tar.gz', 'command-configure_4.10.0-5.ubuntu22_amd64.tar.gz'];
  static const packagesLinuxUrlLibssl = ['http://nz2.archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.19_amd64.deb', 'libssl1.1_1.1.1f-1ubuntu2.19_amd64.deb'];

  static const packagesLinuxDownloadPath = '/tmp/dell-powermanager';

  // this path must also be harcoded in ./package.sh to be added to sudoers.d!
  static const apiPathLinux = '/opt/dell/dcc/cctk';
}
