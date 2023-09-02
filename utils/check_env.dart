import 'dart:io';

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
  String? passPhrase = env['PASSPHRASE'];

  Map<String, String?> envMap = {
    'workPath': workPath,
    'pgHost': pgHost,
    'pgPort': pgPort,
    'dbName': dbName,
    'dbUsername': dbUsername,
    'dbPassword': dbPassword,
    'passPhrase': passPhrase,
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
    dbPassword: envMap['dbPassword']!,
    passPhrase: envMap['passPhrase']!,
  );
}
