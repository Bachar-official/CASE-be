import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../domain/entity/arch.dart';
import '../domain/entity/env.dart';

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

/// Сохранение APK файла, используя [b64file].
///
/// Кидает [FormatException], если формат файла неправильный.
/// Возвращает [File], если всё прошло успешно.
File parseAndSaveAPK(
    {required Uint8List b64file,
    required String package,
    required Arch arch,
    required Env env}) {
  if (!isAPK(b64file)) {
    throw FormatException('Wrong APK format');
  }

  if (!Directory('${env.workPath}/$package').existsSync()) {
    Directory('${env.workPath}/$package').createSync(recursive: true);
  }

  File result = File('${env.workPath}/$package/${arch.name}.apk');
  result.writeAsBytesSync(b64file);
  return result;
}

/// Сохранение иконки
File? checkAndSaveIcon(
    {required String package, Uint8List? list, required Env env}) {
  if (list == null) {
    return null;
  }
  if (!isPNG(list)) {
    throw FormatException('Wrong PNG file');
  }
  if (!Directory('${env.workPath}/$package').existsSync()) {
    Directory('${env.workPath}/$package').createSync(recursive: true);
  }
  File result = File('${env.workPath}/$package/icon.png');
  result.writeAsBytesSync(list);
  return result;
}

/// Сохранение иконки в папку [app], используя [iconBase64]
///
/// Кидает [FormatException], если картинка неподходящего формата.
/// Возвращает [File], если всё прошло успешно.
File? parseAndSaveIcon(
    {String? iconBase64, required String package, required Env env}) {
  if (!Directory('${env.workPath}/$package').existsSync()) {
    Directory('${env.workPath}/$package').createSync(recursive: true);
  }

  if (iconBase64 == null) {
    return null;
  }

  final List<int> bytes = base64Decode(iconBase64);

  if (!isPNG(bytes)) {
    throw FormatException('Wrong icon format');
  }

  File result = File('${env.workPath}/$package/icon.png');
  result.writeAsBytesSync(bytes);
  return result;
}

/// Удаление папки с артефактами
///
/// Возвращает [bool] - результат удаления папки
bool deleteApk({required String package, required Env env}) {
  try {
    Directory('${env.workPath}/$package').delete(recursive: true);
    return true;
  } catch (e) {
    return false;
  }
}
