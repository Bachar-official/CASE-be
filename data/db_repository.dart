import 'package:postgres/postgres.dart';

import '../domain/entity/app.dart';

class DBRepository {
  final PostgreSQLConnection connection;

  DBRepository({required this.connection});

  Future<int> insertApp(App app) async {
    return await connection.execute(
        'INSERT INTO apps (name, version, path, arch, size, package, date) '
        'VALUES (@name, @version, @path, @arch, @size, @package, @date)',
        substitutionValues: {
          "name": app.name,
          "version": app.version,
          "path": app.path,
          "arch": app.arch,
          "size": app.size,
          "package": app.package,
          "date": app.date.toUtc().toIso8601String()
        });
  }

  Future<int> updateApp(App app) async {
    return await connection.execute(
        'UPDATE apps SET version = @version, size = @size, date = @date '
        'WHERE name = @name',
        substitutionValues: {
          "version": app.version,
          "size": app.size,
          "date": app.date.toUtc().toIso8601String(),
          "name": app.name
        });
  }

  Future<PostgreSQLResult> searchAppName(String name) async {
    return await connection.query(
        'SELECT * from apps WHERE LOWER (name) = @name',
        substitutionValues: {"name": name.toLowerCase()});
  }

  Future<List<App>?> searchApp(String name) async {
    PostgreSQLResult searchResult = await searchAppName(name);
    if (searchResult.isNotEmpty) {
      return searchResult.map((row) => App.fromPostgreSQL(row)).toList();
    }
    return null;
  }
}
