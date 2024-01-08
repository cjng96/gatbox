// 접속되고 끊어질때 이벤트 발생

import 'package:codart/coNet.dart';

import 'package:codart/cl.dart';
import 'package:codart/single.dart';

import 'package:flutter/foundation.dart';

import 'setting.dart';

// 서버에서 오는 오류는 key값에 따라서 다르게 처리하기 위해서
class ResError extends ErrorMsg {
  ResError(Map<String, dynamic> node) : super(node['err'] as String) {
    key = node['key'] as String? ?? node['extra'] as String?;
  }
  String? key; // oauthNotFinished

  @override
  String toString() {
    switch (key) {
      case 'oauthNotFinished':
        return 'Google login is not finished. please finish login process then click the button.'.ml();
      case 'noPassword':
        return 'The password does not match.'.ml();
      case 'noUser':
        return 'The account you entered does not exist.'.ml();
      case 'invalidEmailToShare':
        return 'The email address to share is invalid.'.ml();
      case 'cantShareNoteSelf':
        return 'You can\'t share the your note with yourself.'.ml();
      case 'alreadyShared':
        return 'This email is already shared.'.ml();
      case 'changePwNotMatchPw':
        return 'The password does not match.'.ml();
      case 'inputPw':
        return 'This note is locked with a password.'.ml();
      case 'invalidPw':
        return 'The input password is invalid.'.ml();
    }

    return 'Exception: $msg';
  }
}

class Net extends CoNet {
  static Net? _g;
  static Net get g => _g!;
  static bool get initedG => _g != null;
  static void clearG() {
    _g = null;
  }

  Net() {
    assert(_g == null);
    _g = this;
  }

  String? name; // 로긴 되었다면
  bool isAdmin = false;

  @override
  void init() {
    if (Single.runType != RunType.prod) {
      lstServer.add(ServerNode('auto', 'http://192.168.1.130:59019'));
      return;
    }

    // if (Setting.g.cfgDev.mode!.localSer && (kDebugMode || Setting.g.isDev)) {
    if (kDebugMode || Setting.g.isDev) {
      // debugger mode면 로칼 아이피를 추가, 이제 dev설정되어 있으면 무조건 우선 접속
      lstServer.add(ServerNode('local', 'http://192.168.1.131:21080'));
    }
    // prod, dev
    // if (Setting.g.cfgDev.mode!.devServer) {
    if (Setting.g.isDevServer) {
      lstServer.add(ServerNode('dev', 'https://gboxt.mmx.kr'));
    } else {
      lstServer.add(ServerNode('prod', 'https://gbox.mmx.kr'));
    }
  }

  @override
  Future initConn() async {
    await super.initConn();

    // 이제 따로 저장하니까 이거 필요없음
    // if (!kIsWeb && !Setting.g.test) {
    //   if (Setting.g.cfg.serverName == null) {
    //     Setting.g.cfg.serverName = selectServer.name;
    //     await Setting.g.cfgSave();
    //   } else if (selectServer.name != Setting.g.cfg.serverName) {
    //     // 서버 모드가 바뀐 경우는 특수한 경우로 db가 바뀌기에 재시작해야한다.
    //     ll.e('server is changed - ${Setting.g.cfg.serverName} -> ${selectServer.name}');

    //     Setting.g.cfg.serverName = selectServer.name;
    //     await Setting.g.cfgSave();

    //     // db를 다시 초기화해야해서 다시 시작해야한다.
    //     await SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    //   }
    // }

    // 웹에선 의미 없다
    // if (!kIsWeb && selectServer!.name != Db.g.dbName) {
    //   ll.e('server is changed - ${Setting.g.cfgInit.serverName} -> ${selectServer!.name}');
    //   Setting.g.cfgInit.serverName = selectServer!.name;
    //   await Setting.g.cfgInitSave();
    // }

    // TODO: 이거 버튼 누르게하자
    // version up?
    // if (Setting.g.cfgDev!.mode!.dev) {
    //   if (!kIsWeb && Platform.isAndroid) {
    //     await doServerCheck();
    //     final appVer = versionName2Code(g_version);
    //     if (appVer < versionCode!) {
    //       //update here
    //       ll.e('update new version');
    //       apkPath = updateFiles[0].url;
    //       AppKey.g.app.currentState!.uiRefresh();
    //     }
    //   }
    // }
  }
}
