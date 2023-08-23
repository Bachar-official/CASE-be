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
    connection = PostgreSQLConnection('apk.cmx.ru', 5432, 'template1',
        username: 'postgres', password: 'apk', useSSL: true);
    repository = DBRepository(connection: connection);
  }

  Future<void> init() async {
    router
      ..get('/', _rootHandler)
      ..get('/search/<package>', _searchHandler)
      ..post('/upload', _uploadFileHandler);
    await connection.open();
  }

  Response _rootHandler(Request req) {
    return Response.ok('Hello, world!\n');
  }

  Future<Response> _searchHandler(Request request) async {
    List<dynamic> result =
        await repository.searchPackage(request.params['package'] ?? '');
    print(result);
    return Response.ok('Found ${result.length} packages');
  }

  Future<Response> _uploadFileHandler(Request request) async {
    final String query = await request.readAsString();
    try {
      Map queryParams = jsonDecode(query);
      String body = queryParams['body'];
      String fileName = queryParams['fileName'];
      String version = queryParams['version'];
      String arch = queryParams['arch'];
      String package = queryParams['package'];
      File savedFile = parseAndSaveFile(body, fileName, package, arch);
      App app = App(
          name: fileName,
          package: package,
          version: version,
          path: savedFile.absolute.path,
          date: await savedFile.lastModified(),
          arch: arch,
          size: savedFile.lengthSync());
      var searchResult = await repository.searchPackage(package);
      if (searchResult.isEmpty) {
        await repository.insertApp(app);
      } else {
        await repository.updateApp(app);
      }
    } on FormatException catch (e) {
      return Response.badRequest(body: e.message);
    } on Exception catch (e) {
      return Response.badRequest(body: e.toString());
    }
    return Response.ok('File received');
  }
}
