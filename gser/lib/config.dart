import 'dart:io';
import 'package:codart/coEmail.dart';
import 'package:codart/coYaml.dart';
import 'package:codart/coConfig.dart';

import 'main.dart';

class Config extends CoConfig {
  static Config? _g;
  static Config get g => _g!;
  Config() {
    assert(_g == null);
    _g = this;
  }

  late String name;
  late int port;
  late String monPath;
  // late String dataPath;

  // ConfigMode mode = ConfigMode();
  // ConfigGmail gmail = ConfigGmail();

  @override
  Future<Map<String, dynamic>> init(String? aprofile) async {
    final conf = await super.init(aprofile);

    name = conf['name'];
    port = conf['port'];
    monPath = conf['monPath'];
    // dataPath = conf['dataPath'];

    // gmail = ConfigGmail.fromJson(conf['gmail']);

    // final secret = await secretLoad();
    // gmail.pw = secret['gmailPw'] as String;

    // emailInit(gmail.id, gmail.pw, mode.notiEmail ? gmail.to : null);

    return conf;
  }

  final repos = <RepoNode>[];
  Future reposInit() async {
    final cfg = <String, dynamic>{};
    await yamlLoadIntoFromFile(cfg, File('./config.yml'));

    for (final repoCfg in cfg['repos']) {
      final repo = RepoNode(repoCfg['name']!, repoCfg['url']!, repoCfg['branch']!, repoCfg['server']!);
      repos.add(repo);
    }
  }

  // Future<Map<String, dynamic>> secretLoad() async {
  //   final fp = File('.secret.yml');
  //   final map = <String, dynamic>{};
  //   await yamlLoadIntoFromFile(map, fp);
  //   return map;
  // }
}
