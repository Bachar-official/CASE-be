import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shelf_multipart/form_data.dart';
import 'package:shelf_plus/shelf_plus.dart';
import '../domain/entity/apk.dart';
import '../domain/entity/app.dart';
import '../domain/entity/env.dart';
import '../domain/entity/permission.dart';
import '../utils/jwt_utils.dart';
import '../utils/parse_file.dart';
import 'db_repository.dart';

class AppHandler {
  final DBRepository repository;
  final Env env;

  final String _token = 'token';
  final String _package = 'package';
  final String _icon = 'icon';
  final String _version = 'version';
  final String _name = 'name';
  final String _description = 'description';
  final String _permission = 'permission';

  final String _missedToken = 'Missed token';
  final String _tokenExpired = 'Token expired';
  final String _noPermissions = 'You don\'t have enough permissions';
  final String _missedParams = 'Missed query parameters';

  AppHandler({required this.repository, required this.env});

  /// GET /apps
  Future<Response> getApps(Request req) async {
    print('Request of all apps');
    try {
      var apps = await repository.getAllApps();
      return Response.ok(jsonEncode(apps.map((app) => app.toJson()).toList()));
    } catch (e) {
      print(e.toString());
      return Response.internalServerError();
    }
  }

  /// GET /apps/package/apk
  Future<Response> getAppApks(Request req) async {
    print('Request of all APKs from app');
    String? package = req.params[_package];
    if (package == null) {
      return Response.badRequest(body: 'Empty package');
    }
    try {
      final List<APK> result = await repository.findAllApkByPackage(package);
      return Response.ok(json.encode(result.map((e) => e.toJson()).toList()));
    } catch (e) {
      print(e.toString());
      return Response.internalServerError();
    }
  }

  /// POST /apps/package/info
  Future<Response> createApp(Request req) async {
    print('Request to create new app');
    String? package = req.params[_package];
    if (!req.isMultipartForm) {
      return Response.badRequest(body: 'Wrong data format');
    }
    try {
      if (package == null) {
        return Response.badRequest(body: _missedParams);
      }

      Map<String, dynamic> data = {};
      List<FormData> formData = await req.multipartFormData.toList();
      for (var d in formData) {
        if (d.name == 'icon') {
          data[d.name] = await d.part.readBytes();
        } else {
          data[d.name] = await d.part.readString();
        }
      }

      String? token = data['token'];
      String? name = data['name'];
      String? version = data['version'];
      String? description = data['description'];

      if (token == null || name == null || version == null) {
        return Response.badRequest(body: _missedParams);
      }

      Map<String, dynamic> tokenPayload =
          parseJWT(data['token'], env.passPhrase);
      String? permissionStr = tokenPayload[_permission];

      if (permissionStr == null) {
        return Response.internalServerError();
      }

      if (!parsePermission(tokenPayload).canUpdate) {
        return Response.forbidden(_noPermissions);
      }

      App? app = await repository.findApp(data['name']);
      if (app != null) {
        return Response(409, body: 'App $package already exist');
      }

      File? file =
          checkAndSaveIcon(package: package, list: data['icon'], env: env);

      App newApp = App(
          description: description,
          iconPath: file?.path,
          name: name,
          apk: [],
          package: package,
          version: version);
      var dbResult = await repository.insertApp(newApp);

      return Response.ok('App created with code $dbResult');
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

  /// PATCH /app/package/info
  Future<Response> updateApp(Request req) async {
    print('Request to update app');
    String? package = req.params[_package];

    if (!req.isMultipartForm) {
      return Response.badRequest(body: 'Wrong data format');
    }

    if (package == null) {
      return Response.badRequest(body: _missedParams);
    }

    try {
      Map<String, dynamic> data = {};
      List<FormData> formData = await req.multipartFormData.toList();
      for (var d in formData) {
        if (data[d.name] is String) {
          data[d.name] = await d.part.readString();
        } else {
          data[d.name] = await d.part.readBytes();
        }
      }

      String? token = data['token'];
      String? version = data['version'];
      String? name = data['name'];
      String? description = data['description'];
      dynamic icon = data['icon'];

      if (token == null) {
        return Response.unauthorized(_missedToken);
      }

      if (version == null) {
        return Response.badRequest(body: _missedParams);
      }

      Map<String, dynamic> tokenPayload = parseJWT(token, env.passPhrase);
      String? permissionStr = tokenPayload[_permission];

      if (permissionStr == null) {
        return Response.internalServerError();
      }

      if (!parsePermission(tokenPayload).canUpdate) {
        return Response.forbidden(_noPermissions);
      }

      App? app = await repository.findAppByPackage(package);
      if (app == null) {
        return Response(404, body: 'App not found');
      }
      File? iconFile =
          checkAndSaveIcon(package: app.package, env: env, list: icon);
      App newApp = app.copyWith(
          iconPath: iconFile?.path,
          version: version,
          name: name,
          description: description);
      print(newApp);
      var dbResult = await repository.updateApp(newApp);
      return Response.ok('App updated with code $dbResult');
    } on JWTExpiredException catch (e) {
      print(e.message);
      return Response.unauthorized(_tokenExpired);
    } on Exception catch (e) {
      print(e);
      return Response.internalServerError(body: e);
    }
  }

  /// DELETE /apps/package
  Future<Response> deleteApp(Request req) async {
    print('Request to delete app');
    String? package = req.params[_package];
    final String query = await req.readAsString();
    Map queryParams = jsonDecode(query);
    String? token = queryParams[_token];

    if (token == null) {
      return Response.unauthorized(_missedToken);
    }
    if (package == null) {
      return Response.badRequest(body: _missedParams);
    }

    try {
      Map<String, dynamic> tokenPayload = parseJWT(token, env.passPhrase);
      String? permissionStr = tokenPayload[_permission];

      if (permissionStr == null) {
        return Response.internalServerError();
      }

      if (!parsePermission(tokenPayload).canUpdate) {
        return Response.forbidden(_noPermissions);
      }

      int? appId = await repository.getAppId(package);
      if (appId == null) {
        return Response.notFound('App not found');
      }
      // Сначала удаляем запись об apk из БД
      await repository.removeApkByAppId(appId);
      // Теперь удаляем непосредственно файлы
      bool isDirRemoved = deleteApk(package: package, env: env);
      if (!isDirRemoved) {
        return Response.internalServerError(
            body: 'Apk directory don\'t removed');
      }
      // Теперь можно удалять запись о приложении в БД
      int deletedCode = await repository.deleteApp(package);
      return Response.ok('App deleted with code $deletedCode');
    } on JWTExpiredException catch (e) {
      print(e.message);
      return Response.unauthorized(_tokenExpired);
    } on Exception catch (e) {
      print(e);
      return Response.internalServerError(body: e);
    }
  }
}
