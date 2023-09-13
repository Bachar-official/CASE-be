import 'dart:io';

import 'package:shelf/shelf_io.dart';
import 'package:shelf_plus/shelf_plus.dart' hide Handler;

import '../data/handler.dart';
import '../domain/entity/env.dart';
import '../utils/check_env.dart';

final Map<String, String> _headers = {
  'Access-Control-Allow-Origin': '*',
  'Content-Type': 'text/html'
};

Response? _options(Request request) =>
    (request.method == 'OPTIONS') ? Response.ok(null, headers: _headers) : null;

Response _cors(Response response) => response.change(headers: _headers);

Middleware _fixCORS =
    createMiddleware(requestHandler: _options, responseHandler: _cors);

void main(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;
  Env env = checkEnviromnemt();
  Handler requestHandler = Handler(env: env);
  requestHandler.init();
  // Configure a pipeline that logs requests.
  final handler = Pipeline()
      .addMiddleware(_fixCORS)
      .addMiddleware(logRequests())
      .addHandler(requestHandler.router);

  // For running in containers, we respect the PORT environment variable.
  final port = env.hostPort;
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}
