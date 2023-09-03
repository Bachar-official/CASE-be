import 'dart:convert';
import 'dart:io';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shelf_plus/shelf_plus.dart';

import '../domain/entity/apk.dart';
import '../domain/entity/app.dart';
import '../domain/entity/arch.dart';
import '../domain/entity/env.dart';
import '../domain/entity/permission.dart';
import '../utils/jwt_utils.dart';
import '../utils/parse_file.dart';
import 'db_repository.dart';

class ApkHandler {
  final DBRepository repository;
  final Env env;

  final String _token = 'token';
  final String _package = 'package';
  final String _permission = 'permission';
  final String _arch = 'arch';

  final String _missedToken = 'Missed token';
  final String _tokenExpired = 'Token expired';
  final String _noPermissions = 'You don\'t have enough permissions';
  final String _missedParams = 'Missed query parameters';

  ApkHandler({required this.repository, required this.env});

  /// GET /apps/package/arch/download
  Future<dynamic> downloadFile(Request req) async {
    print('Request to download APK');
    String? package = req.params[_package];
    String? architectire = req.params[_arch];

    if (package == null || architectire == null) {
      return Response.badRequest(body: _missedParams);
    }

    try {
      APK? apk = await repository.findApkByPackage(
          package, getArchFromString(architectire));
      if (apk == null) {
        return Response.notFound('APK not found');
      }

      File apkFile = File(apk.path);
      return download(filename: '$package-$architectire.apk') >> apkFile;
    } catch (e) {
      print(e);
      return Response.internalServerError(body: e);
    }
  }

  /// GET /apps/package/icon
  Future<dynamic> downloadIcon(Request req) async {
    print('Request to download app icon');
    String? package = req.params[_package];
    if (package == null) {
      return Response.badRequest(body: _missedParams);
    }

    try {
      App? app = await repository.findAppByPackage(package);
      if (app == null) {
        print('Records with package $package not found');
        return Response.notFound('Package not found');
      }
      String? iconPath = app.iconPath;
      if (iconPath == null) {
        return Response.notFound('App does not provide icon');
      }
      File iconFile = File(iconPath);
      return download(filename: 'icon-${app.name}.png') >> iconFile;
    } catch (e) {
      print(e);
      return Response.internalServerError(body: e);
    }
  }

  /// POST /apps/package/upload
  Future<Response> uploadAPK(Request req) async {
    print('Request to upload an APK');
    String? package = req.params[_package];
    final String query = await req.readAsString();
    Map queryParams = jsonDecode(query);
    String? body = queryParams['body'];
    String? arch = queryParams[_arch];
    String? token = queryParams[_token];

    if (token == null) {
      return Response.unauthorized(_missedToken);
    }

    if (body == null || package == null || arch == null) {
      return Response.badRequest(body: _missedParams);
    }

    try {
      Map<String, dynamic> tokenPayload = parseJWT(token, env.passPhrase);
      String? permissionStr = tokenPayload[_permission];

      if (permissionStr == null) {
        return Response.internalServerError();
      }

      if (!parsePermission(tokenPayload).canUpload) {
        return Response.forbidden(_noPermissions);
      }

      final Arch architecture = getArchFromString(arch);

      int? appId = await repository.getAppId(package);
      if (appId == null) {
        return Response.notFound('App with package $package not found');
      }

      File savedFile = parseAndSaveAPK(
          b64file: body, package: package, arch: architecture, env: env);

      APK apk = APK(
          appId: appId,
          arch: architecture,
          size: savedFile.lengthSync(),
          path: savedFile.path);
      int code = await repository.insertApk(apk);
      return Response.ok('File saved with code $code');
    } on JWTExpiredException catch (e) {
      print(e.message);
      return Response.unauthorized(_tokenExpired);
    } on FormatException catch (e) {
      print(e.message);
      return Response.badRequest(body: e.message);
    } on Exception catch (e) {
      print(e);
      return Response.internalServerError(body: e);
    }
  }
}
