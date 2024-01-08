import 'package:codart/coNet.dart';

class CmdList extends CmdBase {
  CmdList();
  factory CmdList.fromJson(Map json) {
    assert(json['type'] == type);
    return CmdList();
  }
  @override
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['type'] = type;
    return map;
  }

  static const String type = 'list';
}

class RepoItem {
  RepoItem({required this.name, required this.server, required this.branch, required this.deployDt});
  String name;
  String server;
  String branch;
  DateTime deployDt;

  factory RepoItem.fromJson(Map json) {
    return RepoItem(
      name: json['name'] as String,
      server: json['server'] as String,
      branch: json['branch'] as String,
      deployDt: DateTime.parse(json['deployDt'] as String),
    );
  }
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
      'server': server,
      'branch': branch,
      'deployDt': deployDt.toIso8601String(),
    };
    return map;
  }
}

class ResList extends ResBase {
  ResList({required this.repos});

  factory ResList.fromJson(Map json) {
    return ResList(
      repos: (json['repos'] as List).map((e) => RepoItem.fromJson(e)).toList(),
    );
  }
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'repos': repos.map((e) => e.toJson()).toList(),
    };
    return map;
  }

  List<RepoItem> repos;
}
