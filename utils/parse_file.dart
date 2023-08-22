import 'dart:convert';
import 'dart:io';

File parseAndSaveFile(String fileBase64, String fileName) {
  final List<int> decodedBytes = base64Decode(fileBase64);
  File result = File('A:\\$fileName');
  result.writeAsBytesSync(decodedBytes);
  return result;
}
