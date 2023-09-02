import 'dart:io';

import 'package:shelf/shelf_io.dart';
import 'package:shelf_plus/shelf_plus.dart' hide Handler;

import '../data/handler.dart';
import '../domain/entity/env.dart';
import '../utils/check_env.dart';

void main(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;
  Env env = checkEnviromnemt();
  Handler requestHandler = Handler(env: env);
  requestHandler.init();
  // Configure a pipeline that logs requests.
  final handler =
      Pipeline().addMiddleware(logRequests()).addHandler(requestHandler.router);

  // For running in containers, we respect the PORT environment variable.
  final port = env.hostPort;
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}
