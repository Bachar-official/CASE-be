import 'package:postgres/postgres.dart';

import 'apk.dart';
import 'app.dart';

class AppEntity {
  final String name;
  final String version;
  final String package;
  final String? path;
  final String? iconPath;
  final String? description;
  final int? size;
  final String? arch;

  const AppEntity(
      {required this.arch,
      this.description,
      this.iconPath,
      required this.name,
      this.path,
      required this.package,
      required this.size,
      required this.version});

  AppEntity.fromJson(Map<String, dynamic> json)
      : arch = json['arch'],
        description = json['description'],
        path = json['path'],
        iconPath = json['icon_path'],
        name = json['name'],
        package = json['package'],
        size = json['size'],
        version = json['version'];

  factory AppEntity.fromPostgreSQL(PostgreSQLResultRow row) {
    Map<String, dynamic> map = row.toColumnMap();
    return AppEntity(
        arch: map['arch'],
        name: map['name'],
        description: map['description'],
        path: map['path'],
        iconPath: map['iconPath'],
        package: map['package'],
        size: map['size'],
        version: map['version']);
  }

  static List<App> toAppList(List<AppEntity> list) {
    Map<String, App> map = {};
    for (var entity in list) {
      final key = '${entity.name}-${entity.version}-${entity.package}-'
          '${entity.iconPath}-${entity.description}';
      if (!map.containsKey(key)) {
        map[key] = App(
            name: entity.name,
            version: entity.version,
            package: entity.package,
            iconPath: entity.iconPath,
            description: entity.description,
            apk: []);
      }

      if (entity.arch != null && entity.size != null && entity.path != null) {
        map[key] = map[key]!.copyWith(apk: [
          ...map[key]!.apk,
          APK.withStringArch(
              size: entity.size!, strArch: entity.arch!, path: entity.path!)
        ]);
      }
    }
    return map.values.toList();
  }
}
