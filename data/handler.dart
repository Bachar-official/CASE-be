import 'package:shelf_plus/shelf_plus.dart';
import 'package:postgres/postgres.dart';
import '../domain/entity/env.dart';
import 'apk_handler.dart';
import 'app_handler.dart';
import 'auth_handler.dart';
import 'db_repository.dart';

class Handler {
  late final RouterPlus router;
  late final PostgreSQLConnection connection;
  late final DBRepository repository;
  late final AuthHandler authHandler;
  late final AppHandler appHandler;
  late final ApkHandler apkHandler;
  final Env env;

  Handler({required this.env}) {
    router = Router().plus;
    connection = PostgreSQLConnection(env.pgHost, env.pgPortInt, env.dbName,
        username: env.dbUsername, password: env.dbPassword, useSSL: true);
    repository = DBRepository(connection: connection);

    authHandler = AuthHandler(repository: repository, env: env);
    appHandler = AppHandler(repository: repository, env: env);
    apkHandler = ApkHandler(repository: repository, env: env);
  }

  Future<void> init() async {
    router
      // Управление запросами к сущностям приложения
      ..get('/apps', appHandler.getApps)
      ..post('/apps/<package>/info', appHandler.createApp)
      ..patch('/apps/<package>/info', appHandler.updateApp)
      ..delete('/apps/<package>', appHandler.deleteApp)
      // Управление запросами к артефактам
      ..get('/apps/<package>/<arch>/download', apkHandler.downloadFile)
      ..get('/apps/<package>/icon', apkHandler.downloadIcon)
      ..post('/apps/<package>/upload', apkHandler.uploadAPK)
      // Управление запросами аутентификации
      ..post('/auth', authHandler.authenticate)
      ..post('/auth/add', authHandler.createUser)
      ..delete('/auth/delete', authHandler.deleteUser)
      ..post('/auth/password', authHandler.updatePassword);

    await connection.open();
    var isMigrated = await repository.migrate();
    if (isMigrated) {
      print('Migration done!\nDon\'t forget to update password!');
    } else {
      print('Migration don\'t needed.');
    }
  }
}
