[![Build](https://github.com/alexVinarskis/dell-powermanager/actions/workflows/build.yml/badge.svg?branch=master)](https://github.com/alexVinarskis/dell-powermanager/actions/workflows/build.yml)

# Dell Power Manager
Cross-Platform Dell Power Managmer re-implementation in Flutter

## Why
Dell laptops (XPS and Precision series, potentially others) offer advanced in-bios configurable options, such as multiple thermal profiles, battery charging thresholds, etc. It may be very desirable to adjust these on the go, and there is no way to configure it from OS without Dell's proprietary tools (which are luckily provided). Settings can be changed via:
* BIOS directly, requires reboot
* [Dell Command | Configure](https://www.dell.com/support/kbdoc/en-us/000178000/dell-command-configure) CLI, available for both Windows and Linux, with impressive [list of capabilities](https://dl.dell.com/topicspdf/command-configure_reference-guide4_en-us.pdf).
* [Dell Power Manager](https://www.dell.com/support/contents/en-au/article/product-support/self-support-knowledgebase/software-and-downloads/dell-power-manager) GUI, available for Windows only. On top of that, it is ridiculously slow to start, and (subjectively) ugly.

This app is a modern, Flutter based GUI on top of Dell Command | Configure CLI, with main goal to replicate behavior of Dell Power Manager for Linux users. If it proves to be useful, I may add support for Windows as well.

## Features
* Supports Dark Mode
* Packaged to .deb, with Desktop shortcuts etc.

Minimum TODOs before public release:
* Implement CLI (baked in binaries or pre-requirement?)
* Battery info page
* Battery charging control (w/o custom mode for now)
* Thermal profiles control

Secondary TODOs:
* Add OTA capabilities from Github releases

Potential future features to consider:
* Add Windows support
* Add monitoring service for auto switching thermal profiles based on CPU load

## Credits
* Dell for providing 'Dell Command | Configure CLI'
* Google for creating Flutter :)

## License
This application is licensed under GPLv3. In short, this means you use/copy/modify/distribute it for free, but you must provide source code of your modifications, and keep the same license. You cannot sell it as proprietary software. See [LICENSE](LICENSE) for details.
