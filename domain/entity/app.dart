import 'package:postgres/postgres.dart';

class App {
  final int? id;
  final String name;
  final String package;
  final String? iconPath;
  final String? description;
  final String version;

  App(
      {this.id,
      required this.name,
      required this.version,
      required this.package,
      this.iconPath,
      this.description = 'Описания пока нет'});

  App copyWith(
          {int? id,
          String? name,
          String? version,
          String? package,
          String? iconPath,
          String? description}) =>
      App(
          id: id ?? this.id,
          name: name ?? this.name,
          version: version ?? this.version,
          package: package ?? this.package,
          iconPath: iconPath ?? this.iconPath,
          description: description ?? this.description);

  factory App.fromPostgreSQL(PostgreSQLResultRow row) {
    Map<String, dynamic> map = row.toColumnMap();
    return App(
        id: map['id'],
        name: map['name'],
        version: map['version'],
        package: map['package'],
        iconPath: map['icon_path'],
        description: map['description']);
  }

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
