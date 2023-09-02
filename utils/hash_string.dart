import 'dart:convert';
import 'package:crypto/crypto.dart';

String hashString(String hashed) {
  var bytes = utf8.encode(hashed);
  return sha256.convert(bytes).toString();
}
