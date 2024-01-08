import 'package:codart/cl.dart';
import 'package:codart/single.dart';
import 'package:coflutter/conUtils.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:kote/loginDlg.dart';

import 'package:gser/pk.dart';

// import 'data.dart';
import 'main.dart';
import 'net.dart';
import 'routes.dart';
import 'setting.dart';

class AppKey {
  static AppKey g = AppKey._();
  late GlobalKey<MyAppState> app;
  late GlobalKey<MyMainState> main;
  late GlobalKey<ScaffoldState> scaffoldKey;
  late GlobalKey<ScaffoldMessengerState> scaffoldMsgKey;
  List<GlobalKey> popupList = <GlobalKey>[];
  FluroRouter? router;

  AppKey._();

  void initKey() {
    app = GlobalKey<MyAppState>(debugLabel: 'app');
    main = GlobalKey<MyMainState>(debugLabel: 'main');

    scaffoldKey = GlobalKey<ScaffoldState>(debugLabel: 'mainScaffold');
    scaffoldMsgKey = GlobalKey<ScaffoldMessengerState>(debugLabel: 'scaffoldMsgKey');
    // simple = GlobalKey(debugLabel: 'simple');
  }

  ScaffoldMessengerState get scaffoldMsg {
    return scaffoldMsgKey.currentState!;
  }

  void showSnackBar(SnackBar bar) {
    scaffoldMsg.removeCurrentSnackBar();
    scaffoldMsg.showSnackBar(bar);
  }

  BuildContext topContext() {
    // 현재 최상위 창?
    return main.currentContext!;
  }
}

class MyCl extends Cl {
  MyCl() : super();
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.runType});

  final RunType runType;

  @override
  State<MyApp> createState() => MyAppState();
}

late MyAppState gApp;

class MyAppState extends State<MyApp> with UiRefresh {
  final ll = ClLogger('app');

  final cl = MyCl();
  final setting = Setting();
  // final data = Data();
  final net = Net();

  var inited = false;

  @override
  void initState() {
    gApp = this;

    super.initState();

    // core.setting.test = widget.test;
    Single.runType = widget.runType;
    //_initState();

    // String myurl = Uri.base.toString();
    final token = Uri.base.queryParameters['token'];
    setting.token = token;

    final router = FluroRouter();
    Routes.configureRoutes(router);
    //Application.router = router;
    AppKey.g.router = router;

    initApp();
    // sbeInit();
  }

  Future initApp() async {
    await initCore();
  }

  Future initCore() async {
    await setting.init();
    // await data.init();

    inited = true;
    AppKey.g.app.currentState?.uiRefresh();

    net.init();

    await net.initConn();

    // if (setting.token == null) {
    //   if (!mounted) return;
    //   // /를 리플랙스 해야하는듯
    //   await Navigator.pushNamed(AppKey.g.main.currentContext!, LoginDlg.routeName);
    // }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    var initRoute = MyMain.routeName;
    // if (kIsWeb && kDebugMode) {
    //   initRoute = '/publish/ssLUI1cJGct9gH2wNF07';
    // }

    // This is the theme of your application.
    //
    // TRY THIS: Try running your application with "flutter run". You'll see
    // the application has a blue toolbar. Then, without quitting the app,
    // try changing the seedColor in the colorScheme below to Colors.green
    // and then invoke "hot reload" (save your changes or press the "hot
    // reload" button in a Flutter-supported IDE, or press "r" if you used
    // the command line to start the app).
    //
    // Notice that the counter didn't reset back to zero; the application
    // state is not lost during the reload. To reset the state, use hot
    // restart instead.
    //
    // This works for code too, not just values: Most code changes can be
    // tested with just a hot reload.
    // fontFamily나 textTheme로 지정하면 안깨진다 - 글자 크기를 키우면 장단점 있어서 애매
    // 여튼 기본 폰트가 그래도 덜 흐리다
    // 기본 폰트 roboto고, fallback이 notoSansKR인거 같은데.. 왜 다르지?
    // final noto = GoogleFonts.notoSansKrTextTheme();
    final baseTheme = ThemeData(
      useMaterial3: true,
      // fontFamily: 'Malgun Gothic',
      // fontFamily: 'NotoSansKR2',
      fontFamily: GoogleFonts.notoSansKr().fontFamily,
      // fontFamily: GoogleFonts.roboto().fontFamily,
      // fontFamily: 'NotoSansKR_regular', // googleFonts
      // textTheme: noto.copyWith(
      //     bodyMedium: noto.bodyMedium!.copyWith(
      //       fontSize: 15,
      //       fontWeight: FontWeight.w400, // 100~500까지 동일, 600은 bold
      //     ),
      //     ),
    ).copyWith(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
    );

    // print(baseTheme.textTheme.bodyMedium?.fontSize);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kote',
      theme: baseTheme,
      // darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.dark,
      home: MyMain(key: AppKey.g.main),
      // home: MyMain(),
      initialRoute: initRoute, // 신기한게 /splash로 지정해도 /를 거쳐서 이동한다.
      onGenerateRoute: (setting) {
        ll.w('generateRoute - $setting');
        return AppKey.g.router!.generator(setting);
      },
    );
  }
}
