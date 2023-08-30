import 'dart:io';

import 'package:shelf/shelf_io.dart';
import 'package:shelf_plus/shelf_plus.dart' hide Handler;

import '../data/db_handler.dart';
import '../domain/entity/env.dart';

/// Проверка переменных окружения
/// Возвращает [Env], если всё установлено
/// Кидает [Exception], если чего-то не хватает
Env checkEnviromnemt() {
  print('Checking environment variables:');
  var env = Platform.environment;

  String? port = env['PORT'];
  String? workPath = env['WORKPATH'];
  String? pgHost = env['PGHOST'];
  String? pgPort = env['PGPORT'];
  String? dbName = env['DBNAME'];
  String? dbUsername = env['DBUSERNAME'];
  String? dbPassword = env['DBPASSWORD'];

  Map<String, String?> envMap = {
    'workPath': workPath,
    'pgHost': pgHost,
    'pgPort': pgPort,
    'dbName': dbName,
    'dbUsername': dbUsername,
    'dbPassword': dbPassword
  };

  for (var entry in envMap.entries) {
    if (entry.value != null) {
      print('${entry.key}: ${entry.value}');
    } else {
      print('FATAL: ENV ${entry.key} is null!');
      throw Exception('ENV ${entry.key} not set!');
    }
  }

  print('Environment variables check OK');

  return Env(
      port: port,
      workPath: envMap['workPath']!,
      pgHost: envMap['pgHost']!,
      pgPort: envMap['pgPort']!,
      dbName: envMap['dbName']!,
      dbUsername: envMap['dbUsername']!,
      dbPassword: envMap['dbPassword']!);
}

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
