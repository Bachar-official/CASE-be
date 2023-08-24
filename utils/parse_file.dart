import 'dart:convert';
import 'dart:io';

import '../domain/entity/app.dart';

/// Проверка, является ли файл из массива [bytes] картинкой PNG
bool isPNG(List<int> bytes) {
  return bytes[0] == 0x89 && bytes[1] == 0x50;
}

/// Проверка, является ли файл из массива [bytes] файлом APK
bool isAPK(List<int> bytes) {
  return bytes.length >= 4 &&
      bytes[0] == 0x50 &&
      bytes[1] == 0x4B &&
      bytes[2] == 0x03 &&
      bytes[3] == 0x04;
}

/// Сохранение APK файла, используя [fileBase64].
///
/// Кидает [FormatException], если формат файла неправильный.
/// Возвращает [Null], если не проставлена переменная окружения.
/// Возвращает [File], если всё прошло успешно.
File? parseAndSaveFile(
    String fileBase64, String fileName, String package, String arch) {
  String? path = Platform.environment['APKPATH'];
  if (path == null) {
    return null;
  }
  final List<int> decodedBytes = base64Decode(fileBase64);

  if (!isAPK(decodedBytes)) {
    throw FormatException('Wrong APK format');
  }

  if (!Directory('$path/$package').existsSync()) {
    Directory('$path/$package').createSync(recursive: true);
  }

  File result = File('$path/$package/$fileName-$arch.apk');
  result.writeAsBytesSync(decodedBytes);
  return result;
}

/// Сохранение иконки в папку [app], используя [iconBase64]
///
/// Кидает [FormatException], если картинка неподходящего формата.
/// Возвращает [File], если всё прошло успешно.
File parseAndSaveIcon(String iconBase64, App app) {
  final List<int> bytes = base64Decode(iconBase64);

  if (!isPNG(bytes)) {
    throw FormatException('Wrong icon format');
  }

  File result = File('${File(app.path).parent.toString()}/icon.png');
  result.writeAsBytesSync(bytes);
  return result;
}
