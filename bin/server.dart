import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf_io.dart';
import 'package:shelf_plus/shelf_plus.dart' hide Handler;

import '../data/db_handler.dart';
import '../utils/parse_file.dart';

// Configure routes.
final _router = Router().plus
  ..get('/', _rootHandler)
  ..get('/echo/<message>', _echoHandler)
  ..get('/file', _downloadFile);

Response _rootHandler(Request req) {
  return Response.ok('Hello, World!\n');
}

Response _echoHandler(Request request) {
  final message = request.params['message'];
  return Response.ok('$message\n');
}

_downloadFile() {
  File result = File('A:\\merCi.apk');
  return download(filename: 'merci_latest.apk') >> result;
}

void main(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;
  Handler requestHandler = Handler();
  requestHandler.init();
  // Configure a pipeline that logs requests.
  final handler =
      Pipeline().addMiddleware(logRequests()).addHandler(requestHandler.router);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '1337');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}
