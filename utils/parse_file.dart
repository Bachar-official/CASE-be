import 'dart:convert';
import 'dart:io';

File parseAndSaveFile(
    String fileBase64, String fileName, String package, String arch) {
  final List<int> decodedBytes = base64Decode(fileBase64);
  File result = File('A:\\apk\\$package\\$fileName-$arch.apk');
  result.writeAsBytesSync(decodedBytes);
  return result;
}
