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

  App(
      {this.id,
      required this.arch,
      required this.name,
      required this.path,
      required this.size,
      required this.version,
      required this.package,
      required this.date});

  App.fromPostgreSQL(PostgreSQLResultRow row)
      : id = row[0],
        name = row[1],
        version = row[2],
        path = row[3],
        arch = row[4],
        size = row[5],
        package = row[6],
        date = DateTime.parse(row[7]);

  @override
  String toString() => 'App $name, version $version';

  String toUpdateSQLValues() =>
      'SET version = \'$version\', size = \'$size\', date = \'${date.toUtc().toIso8601String()}\' WHERE package = \'$package\'';

  String toInsertSQLValues() =>
      '(name, version, path, arch, size, package, date) '
      'VALUES (\'$name\', \'$version\', \'$path\', \'$arch\', \'$size\', \'$package\', \'${date.toUtc().toIso8601String()}\')';
}
