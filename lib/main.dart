import 'package:dell_powermanager/classes/api_powermode.dart';
import 'package:dell_powermanager/classes/bios_protection_manager.dart';
import 'package:dell_powermanager/configs/environment.dart';
import 'package:dell_powermanager/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'components/window_caption.dart' as window_caption;
import 'dart:io' show Platform;
import '../classes/api_battery.dart';
import '../classes/api_cctk.dart';
import '../screens/screen_parent.dart';
import '../configs/constants.dart';

const Size minSize      = Size(1280, 860);
Size currentSize  = Size(minSize.width-52, minSize.height-52);  // hack, since currentSize & minSize representations don't match

Future<void> main() async {
  const String title      = Constants.applicationName;

  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = WindowOptions(
    titleBarStyle: TitleBarStyle.hidden,
    minimumSize: minSize,
    size: currentSize,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['assets/fonts'], license);
  });

  if (kDebugMode) {
    Environment.runningDebug = true;
  }
  if (Platform.environment[Constants.varnamePowermanagerDebug]?.toLowerCase() == 'true') {
    Environment.runningDebug = true;
  }
  if ((Platform.environment[Constants.varnameBiosPwd]?? "").isNotEmpty) {
    BiosProtectionManager.loadPassword(Platform.environment[Constants.varnameBiosPwd]!);
  }

  ApiCCTK.initPreload();
  ApiCCTK.ensureBackend();
  ApiCCTK(const Duration(seconds: 30));
  ApiBattery(const Duration(milliseconds: 10000));
  ApiPowermode(const Duration(milliseconds: 10000));
  runApp(const MyApp(title: title));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      color: Colors.transparent,
      supportedLocales: S.supportedLocales,
      localizationsDelegates: S.localizationsDelegates,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(scrolledUnderElevation: 0),
        popupMenuTheme: PopupMenuThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(scrolledUnderElevation: 0),
        popupMenuTheme: PopupMenuThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      ),
      themeMode: ThemeMode.system,
      home: Platform.isLinux ? ClipRRect(
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
        child: MyHomePage(title: title),
      ) : MyHomePage(title: title),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    setState(() {
      windowManager.setMinimumSize(minSize);
      windowManager.setSize(currentSize);
    });
  }
  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }
  @override
  void onWindowFocus() {
    // Make sure to call once.
    setState(() {});
  }

  Widget getAppBarTitle(String title) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Row(
          children: [
            Icon(Icons.power_outlined, size: 30, color: Theme.of(context).colorScheme.primary,),
            const SizedBox(width: 10,),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        );
    });
  }

  @override
  Widget build(BuildContext context) {
    const double appBarHeight = 45;

    return Scaffold(
      // As per https://github.com/foamify/rounded_corner_example
      body: Stack(
        children: [
          ScreenParent(title: widget.title, appBarHeight: appBarHeight + 25),
          SizedBox(
            width: double.infinity,
            height: appBarHeight,
            child: window_caption.WindowCaption(
              backgroundColor: Colors.transparent,
              brightness: Theme.of(context).brightness,
              title: getAppBarTitle(widget.title),
            ),
          ),
        ],
      ),
    );
  }
}
