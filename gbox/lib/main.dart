import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'package:codart/single.dart';
import 'package:gser/pk.dart';
import 'package:intl/intl.dart';

import 'app.dart';
import 'net.dart';

void main() {
  // https://docs.flutter.dev/ui/navigation/url-strategies
  usePathUrlStrategy();

  AppKey.g.initKey();

  var app = MyApp(runType: RunType.prod);
  runApp(app);
}

class MyMain extends StatefulWidget {
  const MyMain({super.key});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  static const routeName = '/';

  @override
  State<MyMain> createState() => MyMainState();
}

class MyMainState extends State<MyMain> {
  List<RepoItem>? repoList;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future init() async {
    while (Net.g.selectServer == null) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    final cmd = CmdList();
    final res = await Net.g.sendCmd(cmd, ResList.fromJson);
    repoList = res.repos;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

    final dtFmt = DateFormat('yyyy-MM-dd HH:mm:ss');

    Widget body = const Text('Loading...');
    if (repoList != null) {
      final lst = <Widget>[];
      for (final repo in repoList!) {
        lst.add(Text('${repo.name} - ${dtFmt.format(repo.deployDt)}'));
      }

      body = Column(children: lst);
    }

    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: const Text('gat box'),
      ),
      body: body,
    );
  }
}
