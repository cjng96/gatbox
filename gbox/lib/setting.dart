// import 'package:codart/utils.dart';
import 'package:flutter/foundation.dart';

class Setting {
  // static final Setting g = Setting._internal();
  // factory Setting() => g;
  // Setting._internal();
  static Setting? _g;
  static Setting get g => _g!;
  static void clearG() {
    _g = null;
  }

  Setting() {
    assert(_g == null);
    _g = this;
  }

  Future init() async {
    isDev = Uri.base.queryParameters['dev'] == '1';
    isDevServer = Uri.base.host.startsWith('kotet.');

    if (kDebugMode) {
      isDevServer = true;
    }
  }

  bool isDev = true; // 개발 모드 - query에 dev=1주면
  bool isDevServer = false; // 개발서버로 접속 - url로 판단한다

  String? token;
}
