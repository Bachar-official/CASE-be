import 'package:postgres/postgres.dart';

class App {
  final int? id;
  final String name;
  final String version;
  final String path;
  final String arch;
  final String package;
  final int size;
  final DateTime date;
  final String? iconPath;
  final String? description;

  App(
      {this.id,
      required this.arch,
      required this.name,
      required this.path,
      required this.size,
      required this.version,
      required this.package,
      required this.date,
      this.iconPath,
      this.description});

  App copyWith(
          {int? id,
          String? name,
          String? version,
          String? path,
          String? arch,
          String? package,
          int? size,
          DateTime? date,
          String? iconPath,
          String? description}) =>
      App(
          id: id ?? this.id,
          name: name ?? this.name,
          version: version ?? this.version,
          path: path ?? this.path,
          arch: arch ?? this.arch,
          package: package ?? this.package,
          size: size ?? this.size,
          date: date ?? this.date,
          iconPath: iconPath ?? this.iconPath,
          description: description ?? this.description);

  App.fromPostgreSQL(PostgreSQLResultRow row)
      : id = row[0],
        name = row[1],
        version = row[2],
        path = row[3],
        arch = row[4],
        size = row[5],
        package = row[6],
        date = row[7],
        iconPath = row[8],
        description = row[9];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'version': version,
        'path': path,
        'arch': arch,
        'size': size,
        'package': package,
        'date': date.toString()
      };

  Map<String, dynamic> toSecureJson() => {
        'id': id,
        'name': name,
        'version': version,
        'arch': arch,
        'size': size,
        'package': package,
        'date': date.toString()
      };

  @override
  String toString() => 'App $name, version $version';
}
