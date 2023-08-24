import 'dart:convert';
import 'dart:io';

import 'package:shelf_plus/shelf_plus.dart';
import 'package:postgres/postgres.dart';

import '../domain/entity/app.dart';
import '../utils/parse_file.dart';
import 'db_repository.dart';

class Handler {
  late final RouterPlus router;
  late final PostgreSQLConnection connection;
  late final DBRepository repository;

  Handler() {
    router = Router().plus;

    var env = Platform.environment;

    String? host = env['PSHOST'];
    int? port = int.parse(env['PSPORT'] ?? '0');
    String? dbName = env['PSDBNAME'];
    String? username = env['PSLOGIN'];
    String? password = env['PSPASSWORD'];

    if (host == null ||
        port == 0 ||
        dbName == null ||
        username == null ||
        password == null) {
      throw Exception('Exception: Platform environments did not set');
    }

    connection = PostgreSQLConnection(host, port, dbName,
        username: username, password: password, useSSL: true);
    repository = DBRepository(connection: connection);
  }

  Future<void> init() async {
    router
      ..get('/', _rootHandler)
      ..get('/download/<name>', _downloadFileHandler)
      ..get('/image/<name>', _downloadImageHandler)
      ..post('/upload', _uploadFileHandler)
      ..post('/icon', _uploadIconHandler);
    await connection.open();
  }

  Future<Response> _rootHandler(Request req) async {
    print('Request of all apps');
    try {
      var result = await repository.getApps();
      if (result == null) {
        return Response.internalServerError();
      }
      return Response.ok(json.encode(result));
    } catch (e) {
      print(e.toString());
      return Response.internalServerError();
    }
  }

  Future<dynamic> _downloadFileHandler(Request request) async {
    String? name = request.params['name'];
    print('Request of downloading file with name $name');
    if (name == null) {
      print('Empty name field');
      return Response.notFound('Name is empty');
    }
    App? app = await repository.findApp(name);
    if (app == null) {
      print('Records with name $name not found');
      return Response.badRequest(body: 'Name not found');
    }
    File apkFile = File(app.path);
    print('File sent to download');
    return download(filename: '${app.name}-latest.apk') >> apkFile;
  }

  Future<dynamic> _downloadImageHandler(Request request) async {
    String? name = request.params['name'];
    print('Request of downloading file with name $name');
    if (name == null) {
      print('Empty name field');
      return Response.notFound('Name is empty');
    }
    App? app = await repository.findApp(name);
    if (app == null) {
      print('Records with name $name not found');
      return Response.badRequest(body: 'Name not found');
    }
    String? iconPath = app.iconPath;
    if (iconPath == null) {
      return Response.notFound('App does not provide icon');
    }
    File iconFile = File(iconPath);
    print('Image sent to download');
    return download(filename: 'icon-${app.name}.png') >> iconFile;
  }

  Future<Response> _uploadIconHandler(Request request) async {
    print('Request to upload an icon');
    final String query = await request.readAsString();
    try {
      Map queryParams = jsonDecode(query);
      String? appName = queryParams['name'];
      String? body = queryParams['body'];
      if (appName == null || body == null) {
        print('Missed query parameters');
        return Response.badRequest(body: 'Missed query parameters');
      }
      App? app = await repository.findApp(appName);
      if (app == null) {
        return Response.notFound('App with name $appName not found');
      }
      File iconFile = parseAndSaveIcon(body, app);
      app = app.copyWith(iconPath: iconFile.path);
      repository.updateAppIcon(app);
    } catch (e) {
      print(e.toString());
      return Response.badRequest(body: e.toString());
    }
    print('Icon update successfully');
    return Response.ok('Icon updated successfully');
  }

  Future<Response> _uploadFileHandler(Request request) async {
    print('Request of uploading new file');
    final String query = await request.readAsString();
    try {
      Map queryParams = jsonDecode(query);
      String? body = queryParams['body'];
      String? fileName = queryParams['fileName'];
      String? version = queryParams['version'];
      String? arch = queryParams['arch'];
      String? package = queryParams['package'];
      String? description = queryParams['description'];
      if (body == null ||
          fileName == null ||
          version == null ||
          arch == null ||
          package == null) {
        return Response.badRequest(body: 'Missed required fields');
      }
      File? savedFile = parseAndSaveFile(body, fileName, package, arch);
      if (savedFile == null) {
        return Response.internalServerError(body: 'Wrong platform settings');
      }
      App app = App(
          name: fileName,
          package: package,
          version: version,
          path: savedFile.absolute.path,
          date: await savedFile.lastModified(),
          arch: arch,
          description: description,
          size: savedFile.lengthSync());
      var searchResult = await repository.searchAppName(app.name);
      if (searchResult.isEmpty) {
        print('App name is new, saving');
        await repository.insertApp(app);
      } else {
        print('App update found, replacing');
        await repository.updateApp(app);
      }
    } on FormatException catch (e) {
      print(e.message);
      return Response.badRequest(body: e.message);
    } on Exception catch (e) {
      print(e.toString());
      return Response.badRequest(body: e.toString());
    }
    print('File upload successfully');
    return Response.ok('File upload successfully');
  }
}
