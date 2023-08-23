import 'dart:convert';
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:shelf_plus/shelf_plus.dart';
import 'package:postgres/postgres.dart';

import '../domain/entity/app.dart';
import '../utils/parse_file.dart';
import 'db_repository.dart';

class Handler {
  late final RouterPlus router;
  late final PostgreSQLConnection connection;
  late final DBRepository repository;
  final Logger logger;

  Handler({required this.logger}) {
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
      ..post('/upload', _uploadFileHandler);
    await connection.open();
  }

  Future<Response> _rootHandler(Request req) async {
    logger.d('Request of all apps');
    try {
      var result = await repository.getApps();
      if (result == null) {
        return Response.internalServerError();
      }
      return Response.ok(json.encode(result));
    } catch (e) {
      logger.e(e.toString());
      return Response.internalServerError();
    }
  }

  Future<dynamic> _downloadFileHandler(Request request) async {
    String? name = request.params['name'];
    logger.d('Request of downloading file with name $name');
    if (name == null) {
      logger.e('Empty name field');
      return Response.notFound('Name is empty');
    }
    List<App>? searchResult = await repository.searchApp(name);
    if (searchResult == null || searchResult.isEmpty) {
      logger.e('Records with name $name not found');
      return Response.badRequest(body: 'Name not found');
    }
    File apkFile = File(searchResult.first.path);
    logger.i('File sent to download');
    return download(filename: '${searchResult.first.name}-latest.apk') >>
        apkFile;
  }

  Future<Response> _uploadFileHandler(Request request) async {
    logger.d('Request of uploading new file');
    final String query = await request.readAsString();
    try {
      Map queryParams = jsonDecode(query);
      String body = queryParams['body'];
      String fileName = queryParams['fileName'];
      String version = queryParams['version'];
      String arch = queryParams['arch'];
      String package = queryParams['package'];
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
          size: savedFile.lengthSync());
      var searchResult = await repository.searchAppName(app.name);
      print(searchResult);
      if (searchResult.isEmpty) {
        logger.d('App name is new, saving');
        await repository.insertApp(app);
      } else {
        logger.d('App update found, replacing');
        await repository.updateApp(app);
      }
    } on FormatException catch (e) {
      logger.e(e.message);
      return Response.badRequest(body: e.message);
    } on Exception catch (e) {
      logger.e(e.toString());
      return Response.badRequest(body: e.toString());
    }
    logger.i('File upload successfully');
    return Response.ok('File upload successfully');
  }
}
