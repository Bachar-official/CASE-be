import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

import '../domain/entity/user.dart';

/// Генерация JWT токена, протухающего через 10 минут
String generateJWT(User user, String passPhrase) {
  var jwt = JWT(user.toJWT());
  return jwt.sign(SecretKey(passPhrase), expiresIn: Duration(minutes: 10));
}

/// Парсинг JWT токена
Map<String, dynamic> parseJWT(String token, String passPhrase) {
  return JWT.verify(token, SecretKey(passPhrase)).payload;
}
