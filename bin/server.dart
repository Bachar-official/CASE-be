import 'dart:io';

import 'package:logger/logger.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_plus/shelf_plus.dart' hide Handler;

import '../data/db_handler.dart';

void main(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;
  Logger logger = Logger();
  Handler requestHandler = Handler(logger: logger);
  requestHandler.init();
  // Configure a pipeline that logs requests.
  final handler =
      Pipeline().addMiddleware(logRequests()).addHandler(requestHandler.router);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '1337');
  final server = await serve(handler, ip, port);
  logger.i('Server listening on port ${server.port}');
}
