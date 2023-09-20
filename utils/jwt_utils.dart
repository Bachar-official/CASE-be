import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

import '../domain/entity/permission.dart';
import '../domain/entity/user.dart';

/// Генерация JWT токена, протухающего через 10 минут
String generateJWT(User user, String passPhrase, {bool onlyToken = false}) {
  var jwt = JWT(user.toJWT());
  if (!onlyToken) {
    return jsonEncode({
      'token': jwt.sign(SecretKey(passPhrase), expiresIn: Duration(minutes: 10))
    });
  }
  return jwt.sign(SecretKey(passPhrase), expiresIn: Duration(minutes: 10));
}

/// Парсинг JWT токена
Map<String, dynamic> parseJWT(String token, String passPhrase) {
  return JWT.verify(token, SecretKey(passPhrase)).payload;
}

Permission parsePermission(Map<String, dynamic> payload) {
  return getPermissionFromString(payload['permission']);
}

String getUsername(Map<String, dynamic> payload) {
  return payload['username'];
}
