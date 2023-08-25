import 'package:postgres/postgres.dart';

class App {
  final int? id;
  final String name;
  final String package;
  final String? iconPath;
  final String description;
  final String version;

  App(
      {this.id,
      required this.name,
      required this.version,
      required this.package,
      this.iconPath,
      required this.description});

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
          package: package ?? this.package,
          iconPath: iconPath ?? this.iconPath,
          description: description ?? this.description);

  App.fromPostgreSQL(PostgreSQLResultRow row)
      : id = row[0],
        name = row[1],
        version = row[2],
        package = row[3],
        iconPath = row[4],
        description = row[5];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'version': version,
        'package': package,
        'iconPath': iconPath,
        'description': description
      };

  @override
  String toString() => 'App $name, version $version';
}
