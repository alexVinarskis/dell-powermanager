import 'package:dell_powermanager/screens/screen_parent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:window_manager/window_manager.dart';
import 'components/window_caption.dart' as window_caption;

Future<void> main() async {
  const String title      = "Dell Power Manager by VA";
  const Size minSize      = Size(1280, 720);
  const Size currentSize  = Size(1280, 720);

  WidgetsFlutterBinding.ensureInitialized();
  WindowManager.instance.ensureInitialized();
  Window.setEffect(effect: WindowEffect.transparent);

  WindowOptions windowOptions = const WindowOptions(
    size: currentSize,
    minimumSize: minSize,
    windowButtonVisibility: false,
    titleBarStyle: TitleBarStyle.hidden,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setHasShadow(false);
    windowManager.show();
  });

  runApp(const MyApp(title: title));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      color: Colors.transparent,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(scrolledUnderElevation: 0),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(scrolledUnderElevation: 0),
      ),
      themeMode: ThemeMode.system,
      home: ClipRRect(
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
        child: MyHomePage(title: title),
      ),
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
          const DragToResizeArea(
            enableResizeEdges: [
              ResizeEdge.topLeft,
              ResizeEdge.top,
              ResizeEdge.topRight,
              ResizeEdge.left,
              ResizeEdge.right,
              ResizeEdge.bottomLeft,
              ResizeEdge.bottomLeft,
              ResizeEdge.bottomRight,
            ],
            child: SizedBox(),
          ),
        ],
      ),
    );
  }
}
