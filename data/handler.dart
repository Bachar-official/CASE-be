import 'dart:convert';
import 'dart:io';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shelf_plus/shelf_plus.dart';
import 'package:postgres/postgres.dart';

import '../domain/entity/apk.dart';
import '../domain/entity/app.dart';
import '../domain/entity/arch.dart';
import '../domain/entity/env.dart';
import '../domain/entity/permission.dart';
import '../utils/jwt_utils.dart';
import '../utils/parse_file.dart';
import 'app_handler.dart';
import 'auth_handler.dart';
import 'db_repository.dart';

class Handler {
  late final RouterPlus router;
  late final PostgreSQLConnection connection;
  late final DBRepository repository;
  late final AuthHandler authHandler;
  late final AppHandler appHandler;
  final Env env;

  Handler({required this.env}) {
    router = Router().plus;
    connection = PostgreSQLConnection(env.pgHost, env.pgPortInt, env.dbName,
        username: env.dbUsername, password: env.dbPassword, useSSL: true);
    repository = DBRepository(connection: connection);

    authHandler = AuthHandler(repository: repository, env: env);
    appHandler = AppHandler(repository: repository, env: env);
  }

  Future<void> init() async {
    router
      // Управление запросами к сущностям приложения
      ..get('/apps', appHandler.getApps)
      ..post('/apps/<package>/info', appHandler.createApp)
      ..patch('/apps/<package>/info', appHandler.updateApp)
      ..delete('/apps/<package>', appHandler.deleteApp)
      // Управление запросами к артефактам
      ..get('/apps/<package>/<arch>/download', _downloadFileHandler)
      ..get('/apps/<package>/icon', _downloadImageHandler)
      ..post('/apps/<package>/upload', _uploadAPKHandler)
      // Управление запросами аутентификации
      ..post('/auth', authHandler.authenticate)
      ..post('/auth/add', authHandler.createUser)
      ..delete('/auth/delete', authHandler.deleteUser)
      ..patch('/auth/password', authHandler.updatePassword);

    await connection.open();
    var isMigrated = await repository.migrate();
    if (isMigrated) {
      print('Migration done!\nDon\'t forget to update password!');
    } else {
      print('Migration don\'t needed.');
    }
  }

  /// Ответчик на GET запрос /apps/<package>/<arch>/download
  Future<dynamic> _downloadFileHandler(Request request) async {
    String? package = request.params['package'];
    String? architectire = request.params['arch'];
    print(
        'Request of downloading file with package $package and arch $architectire');
    if (package == null || architectire == null) {
      print('Empty name of arch field');
      return Response.badRequest(body: 'Name of arch is empty');
    }
    APK? apk = await repository.findApkByPackage(
        package, getArchFromString(architectire));
    if (apk == null) {
      return Response.notFound('APK not found');
    }
    File apkFile = File(apk.path);
    return download(filename: '$package-$architectire.apk') >> apkFile;
  }

  /// Ответчик на GET запрос /image/<name>
  Future<dynamic> _downloadImageHandler(Request request) async {
    String? package = request.params['package'];
    print('Request of downloading file with package $package');
    if (package == null) {
      print('Empty name field');
      return Response.badRequest(body: 'Package is empty');
    }
    App? app = await repository.findAppByPackage(package);
    if (app == null) {
      print('Records with package $package not found');
      return Response.notFound('Name not found');
    }
    String? iconPath = app.iconPath;
    if (iconPath == null) {
      return Response.notFound('App does not provide icon');
    }
    File iconFile = File(iconPath);
    print('Image sent to download');
    return download(filename: 'icon-${app.name}.png') >> iconFile;
  }

  /// Ответчик на POST запрос /apps/<package>/upload
  Future<Response> _uploadAPKHandler(Request request) async {
    print('Request of uploading new file');
    final String query = await request.readAsString();
    try {
      String? package = request.params['package'];
      Map queryParams = jsonDecode(query);
      String? body = queryParams['body'];
      String? arch = queryParams['arch'];
      String? token = queryParams['token'];

      if (token == null) {
        return Response.unauthorized('Missed authorization');
      }
      if (body == null || arch == null || package == null) {
        return Response.badRequest(body: 'Missed required fields');
      }

      Map<String, dynamic> tokenPayload = parseJWT(token, env.passPhrase);
      String? permissionStr = tokenPayload['permission'];
      if (permissionStr == null) {
        return Response.internalServerError(body: 'Something went wrong');
      }

      if (!parsePermission(tokenPayload).canUpload) {
        return Response.forbidden('You don\'t have enough permissions!');
      }

      final Arch architecture = getArchFromString(arch);

      int? appId = await repository.getAppId(package);
      if (appId == null) {
        return Response.notFound('App with package $package not found');
      }

      File savedFile = parseAndSaveAPK(
          b64file: body, package: package, arch: architecture, env: env);

      APK apk = APK(
          appId: appId,
          arch: architecture,
          size: savedFile.lengthSync(),
          path: savedFile.path);
      int code = await repository.insertApk(apk);
      return Response.ok('File saved with code $code');
    } on JWTExpiredException catch (e) {
      print(e.message);
      return Response.unauthorized('Token expired!');
    } on FormatException catch (e) {
      print(e.message);
      return Response.badRequest(body: e.message);
    } on Exception catch (e) {
      print(e.toString());
      return Response.badRequest(body: e.toString());
    }
  }
}
