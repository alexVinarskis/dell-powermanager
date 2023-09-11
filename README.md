[![Build](https://github.com/alexVinarskis/dell-powermanager/actions/workflows/build.yml/badge.svg?branch=master)](https://github.com/alexVinarskis/dell-powermanager/actions/workflows/build.yml)

# Dell Power Manager
Cross-Platform Dell Power Manager re-implementation in Flutter

## Why
Dell machines (XPS and Precision series laptops, potentially others) offer advanced in-bios configurable options, such as multiple thermal profiles, battery charging thresholds, etc. It may be very desirable to adjust these on the go, and there is no way to configure it from OS without Dell's proprietary tools (which are luckily provided). Settings can be changed via:
* BIOS directly, requires reboot
* [Dell Command | Configure](https://www.dell.com/support/kbdoc/en-us/000178000/dell-command-configure) CLI, available for both Windows and Linux, with impressive [list of capabilities](https://dl.dell.com/topicspdf/command-configure_reference-guide4_en-us.pdf).
* [Dell Power Manager](https://www.dell.com/support/contents/en-au/article/product-support/self-support-knowledgebase/software-and-downloads/dell-power-manager) GUI, available for Windows only. On top of that, it is ridiculously slow to start, and (subjectively) ugly.

This app is a modern, Flutter based GUI on top of Dell Command | Configure CLI, with main goal to replicate behavior of Dell Power Manager for Linux users. If it proves to be useful, I may add support for Windows as well.

## Features
* Implement control via 'Dell Command | Configure CLI', installed separately or via integrated installer
* Supports Dark Mode
* Packaged to .deb, with Desktop shortcuts etc.

Control features:
* Battery charging control (w/o advanced/daily timing mode for now)
* Thermal profiles control

Planned TODOs:
* Summary page
* Detect non-dell machines, act accordingly
* Auto-detect current settings
* Add detecting OS's power mode
* Add OTA capabilities from Github releases
* Add Windows support

Potential future features to consider:
* Add monitoring service for auto switching thermal profiles based on CPU load

## Credits
* Dell for providing 'Dell Command | Configure CLI'
* Google for creating Flutter :)

## License
This application is licensed under GPLv3. In short, this means you use/copy/modify/distribute it for free, but you must provide source code of your modifications, and keep the same license. You cannot sell it as proprietary software. See [LICENSE](LICENSE) for details.
