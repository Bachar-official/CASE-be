import 'package:postgres/postgres.dart';

import '../domain/entity/apk.dart';
import '../domain/entity/app.dart';
import '../domain/entity/arch.dart';
import '../domain/entity/permission.dart';
import '../domain/entity/user.dart';
import '../utils/hash_string.dart';

class DBRepository {
  final PostgreSQLConnection connection;

  DBRepository({required this.connection});

  /// Импровизированная миграция
  Future<bool> migrate() async {
    PostgreSQLResult queryResult = await connection.query('SELECT * FROM user');
    if (queryResult.isEmpty) {
      await connection.execute(
          'INSERT INTO user (name, password, permission) '
          'VALUES (@name, @password, @permission)',
          substitutionValues: {
            'name': 'admin',
            'password': hashString('password'),
            'permission': Permission.full.name,
          });
      return true;
    }
    return false;
  }

  /// Получение списка всех пользователей
  Future<List<Map<String, dynamic>>?> getUsers() async {
    var queryResult = await connection.query('SELECT * from user');
    if (queryResult.isEmpty) {
      return null;
    }
    List<User> users =
        queryResult.map((row) => User.fromPostgreSQL(row)).toList();
    return users.map((user) => user.toJson()).toList();
  }

  /// Добавление нового пользователя
  Future<int> addUser(
      String username, String password, Permission permission) async {
    return await connection.execute(
        'INSERT INTO user (name, password, permission) '
        'VALUES (@name, @password, @permission)',
        substitutionValues: {
          'name': username,
          'password': hashString(password),
          'permission': permission.name
        });
  }

  /// Обновление пароля у пользователя
  Future<int> updateUserPassword(String username, String password) async {
    return await connection.execute(
        'UPDATE user SET password = @password'
        'WHERE name = @username',
        substitutionValues: {
          'username': username,
          'password': hashString(password),
        });
  }

  /// Удаление пользователя
  Future<int> deleteUser(String username) async {
    return await connection.execute('DELETE FROM user WHERE name = @username',
        substitutionValues: {'name': username});
  }

  /// Запросить все приложения
  Future<List<Map<String, dynamic>>?> getApps() async {
    PostgreSQLResult queryResult = await connection.query('SELECT * FROM app');
    if (queryResult.isEmpty) {
      return null;
    }
    List<App> apps = queryResult.map((row) => App.fromPostgreSQL(row)).toList();
    return apps.map((app) => app.toJson()).toList();
  }

  /// Найти id приложения по package
  Future<int?> getAppId(String package) async {
    PostgreSQLResult queryResult = await connection.query(
        'SELECT id FROM app WHERE LOWER (package) = @package',
        substitutionValues: {"package": package.toLowerCase()});
    if (queryResult.isEmpty) {
      return null;
    }
    return queryResult.first.first;
  }

  /// Вставить новое приложение
  Future<int> insertApp(App app) async {
    return await connection.execute(
        'INSERT INTO app (name, package, description, iconPath, version) '
        'VALUES (@name, @package, @description, @iconPath, @version)',
        substitutionValues: {
          "name": app.name,
          "package": app.package,
          "description": app.description,
          "iconPath": app.iconPath,
          "version": app.version
        });
  }

  /// Вставить новый установочный файл
  Future<int> insertApk(APK apk) async {
    return await connection.execute(
        'INSERT INTO apk (app_id, arch, size, path)'
        'VALUES (@app_id, @arch, @size, @path)',
        substitutionValues: {
          "app_id": apk.appId,
          "arch": apk.arch.name,
          "size": apk.size,
          "path": apk.path
        });
  }

  /// Обновить существующее приложение
  Future<int> updateApp(App app) async {
    return await connection.execute(
        'UPDATE app SET name = @name, description = @description, icon_path = @iconPath'
        'WHERE package = @package',
        substitutionValues: {
          "name": app.name,
          "description": app.description,
          "iconPath": app.iconPath,
          "package": app.package
        });
  }

  /// Обновить существующий APK
  Future<int?> updateAPK(String package, APK apk) async {
    int? appId = await getAppId(package);
    if (appId == null) {
      return null;
    }
    return await connection.execute(
        'UPDATE apk SET size = @size, path = @path, arch = @arch WHERE app_id = @appId',
        substitutionValues: {
          "size": apk.size,
          "path": apk.path,
          "arch": apk.arch.name,
          "appId": appId
        });
  }

  /// Обновить иконку приложения
  Future<int> updateAppIcon(App app) async {
    return await connection.execute(
        'UPDATE app SET icon_path = @iconPath WHERE package = @package',
        substitutionValues: {"iconPath": app.iconPath, "package": app.package});
  }

  /// Найти приложение по имени
  Future<App?> findApp(String name) async {
    PostgreSQLResult queryResult = await connection.query(
        'SELECT * from app WHERE LOWER (name) = @name',
        substitutionValues: {"name": name.toLowerCase()});
    if (queryResult.isEmpty) {
      return null;
    }
    return App.fromPostgreSQL(queryResult.first);
  }

  /// Найти приложение по package
  Future<App?> findAppByPackage(String package) async {
    PostgreSQLResult queryResult = await connection.query(
        'SELECT * from app WHERE LOWER (package) = @package',
        substitutionValues: {"package": package.toLowerCase()});
    return App.fromPostgreSQL(queryResult.first);
  }

  /// Найти APK по package и arch
  Future<APK?> findApkByPackage(String package, Arch arch) async {
    PostgreSQLResult queryResult = await connection.query(
        'select a.* from apk a join app b on a.app_id = b.id '
        'where a.arch = @arch and b.package = @package',
        substitutionValues: {'arch': arch.name, 'package': package});
    if (queryResult.isEmpty) {
      return null;
    }
    return APK.fromPostgreSQL(queryResult.first);
  }
}
