import 'package:codart/cl.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';

import 'app.dart';
// import 'loginDlg.dart';
import 'main.dart';

class Routes {
  static void configureRoutes(FluroRouter router) {
    router.notFoundHandler = Handler(handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
      Cl.g.w('routes', 'ROUTE WAS NOT FOUND !!! $params');
      return;
      //return MyMain(key: AppKey.g!.main);
    });
    //router.define('startup', handler: mainHandler); // /main으로하면 /가 트리에 들어가버린다..
    router.define(MyMain.routeName, handler: mainHandler);
    // router.define(LoginDlg.routeName, handler: loginHandler);
    // router.define(SettingDlg.routeName, handler: settingHandler);
    // router.define(ReportDlg.routeName, handler: supportHandler);
  }
}

// final rootHandler = Handler(handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
//   // 이게 시작할때 3번 온다 근데 키를 동일하게 사용해서 괜찬음... App.setState()해서 인듯..
//   //return MyMain(key: AppKey.g!.main);
// });

final mainHandler = Handler(handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
  return MyMain(key: AppKey.g.main);
});

// final loginHandler = Handler(handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
//   return LoginDlg();
// });

// final settingHandler = Handler(handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
//   return SettingDlg();
// });

// final supportHandler = Handler(handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
//   return ReportDlg();
// });

