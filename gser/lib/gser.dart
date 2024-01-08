import 'dart:io';
import 'dart:convert';
import 'dart:isolate';

import 'package:hotreloader/hotreloader.dart';
import 'package:logging/logging.dart' as logging;

import 'package:path/path.dart' as path;

final repos = [
  {'url': 'git@bitbucket.org:retailtrend/face.tracer.git', 'server': 'dev', 'branch': 'main'}
];

String repoFolder(String url, String branch, String server) {
  final parts = url.split('/');
  final name = parts[parts.length - 1];
  final nn = '$name-$server-$branch';
  return path.join('./repos', nn);
}

void main() async {
  logging.hierarchicalLoggingEnabled = true;
  // print log messages to stdout/stderr
  logging.Logger.root.onRecord.listen((msg) {
    final fp = msg.level < logging.Level.SEVERE ? stdout : stderr;
    fp.write('${msg.time} ${msg.level.name} [${Isolate.current.debugName}] ${msg.loggerName}: ${msg.message}\n');
  });
  HotReloader.logLevel = logging.Level.CONFIG;

  // 디버거랑도 잘 도는거 같은데?
  // ignore: unused_local_variable
  HotReloader? reloader;
  // if (isInDebugMode && profile != 'unittest') {
  reloader = await HotReloader.create(
    debounceInterval: Duration(seconds: 2),
    // onAfterReload: (ctx) {
    //   print('Hot-reload result: ${ctx.result}');
    // },
  );
  // }

  while (true) {
    for (final repo in repos) {
      final url = repo['url']!;
      final branch = repo['branch']!;
      final server = repo['server']!;

      final folder = repoFolder(url, branch, server);
      print('folder: $folder');
      final fp = Directory(folder);
      if (!fp.existsSync()) {
        print('clonning $url');
        final result = await Process.run('git', ['clone', url, folder]);
        print('out: ${result.stdout}');
        if (result.exitCode != 0) {
          print('clone failed with error: ${result.exitCode}. ${result.stderr}');
          continue;
        }
      }

      // get revision current local branch
      final result = Process.runSync('git', ['rev-parse', '--verify', branch], workingDirectory: folder);
      final localRev = result.stdout.trim();

      // remote revision
      final result2 = Process.runSync('git', ['ls-remote', url, branch]);
      final remoteRev = result2.stdout.split('\t')[0].trim();

      if (localRev == remoteRev) {
        print('deploy skip');
      } else {
        print('deploy - local:$localRev ->> remote:$remoteRev');
        // 디플로이하자
        print('git fetch..');
        Process.runSync('git', ['fetch'], workingDirectory: folder);
        print('git reset..');
        Process.runSync('git', ['reset', '--hard', 'origin/$branch'], workingDirectory: folder);
        print('git submodule update..');
        Process.runSync('git', ['submodule', 'update', '--init'], workingDirectory: folder);

        // final p = await Process.start('gat', [server, 'run', '--git']);
        final p = await Process.start('gat', [server, 'run'], workingDirectory: folder);
        p.stdout.transform(utf8.decoder).listen((data) {
          print('out: $data');
        });
        p.stderr.transform(utf8.decoder).listen((data) {
          print('err: $data');
        });

        final code = await p.exitCode;
        print('exit code: $code');

        // if failed?
      }
    }

    await Future.delayed(Duration(seconds: 60));
  }
}
