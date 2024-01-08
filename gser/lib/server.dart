import 'dart:convert';

import 'package:codart/cl.dart';
import 'package:codart/coShelf.dart';

import 'gser.dart';
import 'pk.dart';

class MyServer {
  static MyServer? _g;
  static MyServer get g => _g!;
  MyServer() {
    assert(_g == null);
    _g = this;
    // Timer.periodic(Duration(seconds: 1), (t) => dodo());
  }

  ClLogger ll = ClLogger('server');

  Future onList(ShelfContext ctx, Map<String, dynamic> pk) async {
    final cmd = CmdList.fromJson(pk);

    final repos = Main.g.repos;
    final res = ResList(
        repos: repos
            .map((e) => RepoItem(name: e.name, server: e.server, branch: e.branch, deployDt: e.deployDt))
            .toList());
    ctx.json(ll, res.toJson());
  }

  Future doPacket(ShelfContext ctx, Map<String, dynamic> pk) async {
    final type = pk['type'];

    ll.w('doPacket - ${jsonEncode(pk)}');
    switch (type) {
      case CmdList.type:
        await onList(ctx, pk);
      default:
        throw 'unknown type: $type';
    }
  }
}
