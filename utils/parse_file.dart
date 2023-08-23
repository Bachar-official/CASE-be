import 'dart:convert';
import 'dart:io';

File? parseAndSaveFile(
    String fileBase64, String fileName, String package, String arch) {
  String? path = Platform.environment['APKPATH'];
  if (path == null) {
    return null;
  }
  final List<int> decodedBytes = base64Decode(fileBase64);

  if (!Directory('$path/$package').existsSync()) {
    Directory('$path/$package').createSync(recursive: true);
  }

  File result = File('$path/$package/$fileName-$arch.apk');
  result.writeAsBytesSync(decodedBytes);
  return result;
}
