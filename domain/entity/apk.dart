import 'package:postgres/postgres.dart';

import 'arch.dart';

class APK {
  final int? id;
  final int size;
  final String path;
  final Arch arch;
  final int? appId;

  APK(
      {this.id,
      required this.size,
      this.appId,
      required this.path,
      required this.arch});

  APK.withStringArch(
      {this.id,
      required this.size,
      required this.path,
      required String strArch,
      this.appId})
      : arch = getArchFromString(strArch);

  factory APK.fromPostgreSQL(PostgreSQLResultRow row) {
    Map<String, dynamic> map = row.toColumnMap();
    return APK(
        id: map['id'],
        size: map['size'],
        path: map['path'],
        appId: map['appId'],
        arch: getArchFromString(map['arch']));
  }

  Map<String, dynamic> toJson() => {"size": size, "arch": arch.name};

  @override
  String toString() => 'APK with appId $appId and path $path';
}
