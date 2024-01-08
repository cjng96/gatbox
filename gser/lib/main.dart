import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:codart/utils.dart';
import 'package:hotreloader/hotreloader.dart';
import 'package:logging/logging.dart' as logging;
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'package:path/path.dart' as path;

import 'package:codart/cl.dart';
import 'package:codart/coShelf.dart';

import 'config.dart';
import 'server.dart';

String repoFolder(String url, String branch, String server) {
  final parts = url.split('/');
  final name = parts[parts.length - 1];
  final nn = '$name-$server-$branch';
  return path.join('./repos', nn);
}

class RepoNode {
  RepoNode(this.name, this.url, this.branch, this.server);
  String name;
  String url;
  String branch;
  String server;

  DateTime deployDt = DateTime.fromMillisecondsSinceEpoch(0);
  String rev = '';
}

late DateTime g_startupDt;

Future monAction() async {
  final rnd = Random();
  final now = DateTime.now();
  final st = <String, dynamic>{'ts': time2ts(now)};

  // final tot = Server.g.conns.length;
  // st['cnt'] = {'v': tot * 10 + rnd.nextInt(10)};

  var ws = 0;
  // final timeoutConns = <Conn>[];
  // for (final conn in Server.g.conns.values) {
  //   if (conn.timeout.isBefore(now)) {
  //     // 종료 시킨다
  //     timeoutConns.add(conn);
  //   }
  //   if (conn.ws != null) {
  //     ws++;
  //   }
  // }
  st['ws'] = {'v': ws * 10 + rnd.nextInt(10)};

  final v = duration2strSimple(now.difference(g_startupDt));
  st['startup'] = {'v': v};

  final ss = json.encode(st);
  // await File('${Config.g.monPath}/${Config.g.name}.st').writeAsString(ss);
  await File('/tmp/gser.st').writeAsString(ss);

  // 타임 아웃 처리를 여기서라도 한다
  // for (final conn in timeoutConns) {
  //   unawaited(conn.lock.protect(() async {
  //     conn.clear();
  //   }));
  // }
}

class MyCl extends Cl {
  MyCl() : super();

  @override
  void d(String title, String msg) {
    final ss = '$title: $msg';
    printLog(ss);
    save(ss);
  }
}

class Main {
  static Main? _g;
  static Main get g => _g!;
  Main() {
    assert(_g == null);
    _g = this;
    // Timer.periodic(Duration(seconds: 1), (t) => dodo());
  }
  List<RepoNode> repos = [];
  final cl = MyCl();
  final ll = ClLogger('main');

  final server = MyServer();
  final config = Config();

  Future init(String? profile) async {
    await config.init(profile);

    await config.reposInit(repos);

    final route = ShelfRouter(log: true);

    route.get('/api/version', (req) async {
      // return shelfJson({'version': '0.0.2'},
      //     headers: {'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Methods': 'POST,GET,DELETE,PUT,OPTIONS'});
      req.allowOrigin();
      req.json(ll, {'version': '0.0.2'});
    });

    route.all('/api/cmd', handleCmd);

    // final serverBind = await HttpServer.bind(InternetAddress.anyIPv4, Config.g!.port);
    final serverBind = await shelf_io.serve(route.rootHandler, InternetAddress.anyIPv4, Config.g.port);
    // https://stackoverflow.com/questions/18672578/dart-how-to-serve-gzip-encoded-html-page
    //server.autoCompress = true; // 이거 켜면 app에서 HttpXmlRequest 에러가 자꾸 나온다.
    //server.defaultResponseHeaders.chunkedTransferEncoding = true;
    ll.w('Listening on ${serverBind.port}');

    Timer.periodic(Duration(seconds: 5), (timer) async {
      try {
        await monAction();
      } catch (e, st) {
        ll.ex('monAction', e, st);
      }
    });
  }

  Future handleCmd(ShelfContext ctx) async {
    ctx.allowOrigin();

    final body = await ctx.bodyStr();

    late Map<String, dynamic> pk;
    // query style support
    if (body.isEmpty) {
      if (ctx.queryParameters.isEmpty) {
        ctx.json(ll, {'err': 'body is empty'}, status: 500);
        return;
      }

      pk = ctx.queryParameters;
      ll.w('cmd(query) - ${ctx.query}');
    } else {
      pk = jsonDecode(body) as Map<String, dynamic>;
    }

    // if (!server.active) {
    //   ctx.json(ll, {'err': 'try again in a few seconds'}, status: 500);
    //   return;
    // }
    await wrapCmdHandler(server.ll, ctx, pk, server.doPacket);
  }

  Future loop() async {
    while (true) {
      for (final repo in repos) {
        final folder = repoFolder(repo.url, repo.branch, repo.server);
        print('folder: $folder');
        final fp = Directory(folder);
        if (!fp.existsSync()) {
          print('clonning ${repo.url}');
          final result = await Process.run('git', ['clone', repo.url, folder]);
          print('out: ${result.stdout}');
          if (result.exitCode != 0) {
            print('clone failed with error: ${result.exitCode}. ${result.stderr}');
            continue;
          }
        }

        // get revision current local branch
        final result = Process.runSync('git', ['rev-parse', '--verify', repo.branch], workingDirectory: folder);
        final localRev = result.stdout.trim();

        repo.rev = localRev;

        // remote revision
        final result2 = Process.runSync('git', ['ls-remote', repo.url, repo.branch]);
        final remoteRev = result2.stdout.split('\t')[0].trim();

        if (localRev == remoteRev) {
          print('deploy skip');
        } else {
          print('deploy - local:$localRev ->> remote:$remoteRev');
          // 디플로이하자
          print('git fetch..');
          Process.runSync('git', ['fetch'], workingDirectory: folder);
          print('git reset..');
          Process.runSync('git', ['reset', '--hard', 'origin/${repo.branch}'], workingDirectory: folder);
          print('git submodule update..');
          Process.runSync('git', ['submodule', 'update', '--init'], workingDirectory: folder);

          // final p = await Process.start('gat', [server, 'run', '--git']);
          final p = await Process.start('gat', [repo.server, 'run'], workingDirectory: folder);
          p.stdout.transform(utf8.decoder).listen((data) {
            print('out: $data');
          });
          p.stderr.transform(utf8.decoder).listen((data) {
            print('err: $data');
          });

          final code = await p.exitCode;
          print('exit code: $code');

          repo.deployDt = DateTime.now();
          // if failed?
        }
      }

      await Future.delayed(Duration(seconds: 60));
    }
  }
}

void main(List<String> args) async {
  g_startupDt = DateTime.now();

  logging.hierarchicalLoggingEnabled = true;
  // print log messages to stdout/stderr
  logging.Logger.root.onRecord.listen((msg) {
    final fp = msg.level < logging.Level.SEVERE ? stdout : stderr;
    fp.write('${msg.time} ${msg.level.name} [${Isolate.current.debugName}] ${msg.loggerName}: ${msg.message}\n');
  });
  HotReloader.logLevel = logging.Level.CONFIG;

  String? profile;
  if (args.isNotEmpty) {
    profile = args[0];
  }

  // 디버거랑도 잘 도는거 같은데?
  // ignore: unused_local_variable
  HotReloader? reloader;
  if (isInDebugMode && profile != 'unittest') {
    reloader = await HotReloader.create(
      debounceInterval: Duration(seconds: 2),
      // onAfterReload: (ctx) {
      //   print('Hot-reload result: ${ctx.result}');
      // },
    );
  }

  final m = Main();
  await m.init(profile);
  await m.loop();
}
