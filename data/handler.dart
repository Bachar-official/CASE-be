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
import '../domain/entity/user.dart';
import '../utils/jwt_utils.dart';
import '../utils/parse_file.dart';
import 'db_repository.dart';

class Handler {
  late final RouterPlus router;
  late final PostgreSQLConnection connection;
  late final DBRepository repository;
  final Env env;

  Handler({required this.env}) {
    router = Router().plus;
    connection = PostgreSQLConnection(env.pgHost, env.pgPortInt, env.dbName,
        username: env.dbUsername, password: env.dbPassword, useSSL: true);
    repository = DBRepository(connection: connection);
  }

  Future<void> init() async {
    router
      ..get('/apps', _getAppsHandler)
      ..get('/apps/<package>/<arch>/download', _downloadFileHandler)
      ..get('/apps/<package>/icon', _downloadImageHandler)
      ..post('/apps/<package>/upload', _uploadAPKHandler)
      ..post('/apps/<package>/info', _infoHandler)
      ..post('/auth', _authHandler)
      ..post('/auth/add', _createUserHandler)
      ..patch('/apps/<package>/info', _updateInfoHandler);

    await connection.open();
    var isMigrated = await repository.migrate();
    if (isMigrated) {
      print('Migration done!\nDon\'t forget to update password!');
    } else {
      print('Migration don\'t needed.');
    }
  }

  /// Ответчик на POST запрос в каталог /auth
  Future<Response> _authHandler(Request req) async {
    print('Request to authenticate');
    final String query = await req.readAsString();
    Map queryParams = jsonDecode(query);
    String? username = queryParams['username'];
    String? password = queryParams['password'];
    if (username == null || password == null) {
      return Response.badRequest(body: 'Missed username or password');
    }
    User? user = await repository.getUserCredentials(username, password);
    if (user == null) {
      return Response.unauthorized('Invalid username or password');
    }
    return Response.ok(generateJWT(user, env.passPhrase));
  }

  Future<Response> _createUserHandler(Request req) async {
    print('Request to create new user');
    final String query = await req.readAsString();
    Map queryParams = jsonDecode(query);
    String? token = queryParams['token'];
    String? username = queryParams['username'];
    String? password = queryParams['password'];
    String? permission = queryParams['permission'];

    if (token == null) {
      return Response.unauthorized('Missed token');
    }
    if (username == null || password == null || permission == null) {
      return Response.forbidden('Missed parameters');
    }

    try {
      Map<String, dynamic> tokenPayload = parseJWT(token, env.passPhrase);
      String? permissionStr = tokenPayload['permission'];

      if (permissionStr == null) {
        return Response.internalServerError(body: 'Something went wrong');
      }

      if (!parsePermission(tokenPayload).canManageUsers) {
        return Response.forbidden('You don\'t have enough permissions!');
      }

      var result = await repository.addUser(
          username, password, getPermissionFromString(permission));

      return Response.ok('User added with code $result');
    } on JWTExpiredException catch (e) {
      print(e.message);
      return Response.badRequest(body: 'Token expired');
    } on Exception catch (e) {
      print(e);
      return Response.badRequest(body: e);
    }
  }

  /// Ответчик на GET запрос в каталог /apps
  Future<Response> _getAppsHandler(Request req) async {
    print('Request of all apps');
    try {
      var result = await repository.getApps();
      return Response.ok(json.encode(result));
    } catch (e) {
      print(e.toString());
      return Response.internalServerError();
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

  /// Ответчик на POST /apps/<package>/info
  Future<Response> _infoHandler(Request request) async {
    String? package = request.params['package'];
    print('Request to upload an info about package $package');
    final String query = await request.readAsString();
    try {
      Map queryParams = jsonDecode(query);
      String? icon = queryParams['icon'];
      String? version = queryParams['version'];
      String? name = queryParams['name'];
      String? description = queryParams['description'];
      if (icon == null || version == null || name == null || package == null) {
        return Response.badRequest(body: 'Missed query parameters');
      }
      App? app = await repository.findApp(name);
      if (app != null) {
        return Response(409, body: 'App $package already exist');
      }
      File iconFile =
          parseAndSaveIcon(iconBase64: icon, package: package, env: env);
      App newApp = App(
          description: description,
          iconPath: iconFile.path,
          name: name,
          package: package,
          version: version);
      var dbResult = await repository.insertApp(newApp);
      return Response.ok('App created with code $dbResult');
    } on FormatException catch (e) {
      return Response.badRequest(body: e.message);
    } on Exception catch (e) {
      return Response.internalServerError(body: e.toString());
    }
  }

  /// Ответчик на PATCH /apps/<package>/info
  Future<Response> _updateInfoHandler(Request request) async {
    String? package = request.params['package'];
    print('Request to update an info about package $package');
    final String query = await request.readAsString();
    try {
      Map queryParams = jsonDecode(query);
      String? icon = queryParams['icon'];
      String? version = queryParams['version'];
      String? name = queryParams['name'];
      String? description = queryParams['description'];
      if ((icon == null ||
              version == null ||
              name == null ||
              description == null) &&
          package == null) {
        return Response.badRequest(body: 'Missed query parameters');
      }
      App? app = await repository.findAppByPackage(package!);
      if (app == null) {
        return Response(404, body: 'App $name not found');
      }
      File? iconFile = icon != null
          ? parseAndSaveIcon(iconBase64: icon, package: app.package, env: env)
          : null;
      App newApp = app.copyWith(
          iconPath: iconFile?.path,
          version: version,
          name: name,
          description: description);
      var dbResult = await repository.updateApp(newApp);
      return Response.ok('App created with code $dbResult');
    } on FormatException catch (e) {
      return Response.badRequest(body: e.message);
    } on Exception catch (e) {
      return Response.internalServerError(body: e.toString());
    }
  }
}
