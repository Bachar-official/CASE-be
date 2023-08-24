import 'package:postgres/postgres.dart';

import '../domain/entity/app.dart';

class DBRepository {
  final PostgreSQLConnection connection;

  DBRepository({required this.connection});

  /// Запросить все приложения
  Future<List<Map<String, dynamic>>?> getApps() async {
    PostgreSQLResult queryResult = await connection.query('SELECT * FROM apps');
    if (queryResult.isEmpty) {
      return null;
    }
    List<App> apps = queryResult.map((row) => App.fromPostgreSQL(row)).toList();
    return apps.map((app) => app.toSecureJson()).toList();
  }

  /// Вставить новое приложение
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

  /// Обновить существующее приложение
  Future<int> updateApp(App app) async {
    return await connection.execute(
        'UPDATE apps SET version = @version, size = @size, date = @date, arch=@arch '
        'WHERE name = @name',
        substitutionValues: {
          "version": app.version,
          "size": app.size,
          "date": app.date.toUtc().toIso8601String(),
          "arch": app.arch,
          "name": app.name
        });
  }

  /// Обновить иконку приложения
  Future<int> updateAppIcon(App app) async {
    return await connection.execute(
        'UPDATE apps SET icon_path = @iconPath WHERE name = @name',
        substitutionValues: {"iconPath": app.iconPath, "name": app.name});
  }

  /// Найти приложение по имени
  Future<App?> findApp(String name) async {
    PostgreSQLResult queryResult = await connection.query(
        'SELECT * from apps WHERE LOWER (name) = @name',
        substitutionValues: {"name": name.toLowerCase()});
    if (queryResult.isEmpty) {
      return null;
    }
    return App.fromPostgreSQL(queryResult.first);
  }
}
