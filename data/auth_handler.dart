import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shelf_plus/shelf_plus.dart';

import '../domain/entity/env.dart';
import '../domain/entity/permission.dart';
import '../domain/entity/user.dart';
import '../utils/jwt_utils.dart';
import 'db_repository.dart';

class AuthHandler {
  final DBRepository repository;
  final Env env;

  final String _missedToken = 'Missed token';
  final String _tokenExpired = 'Token expired';
  final String _noPermissions = 'You don\'t have enough permissions';
  final String _missedParams = 'Missed query parameters';

  AuthHandler({required this.repository, required this.env});

  /// Ответчик на POST /auth
  Future<Response> authenticate(Request req) async {
    print('Request to authenticate');
    try {
      final String query = await req.readAsString();
      Map queryParams = jsonDecode(query);
      String? username = queryParams['username'];
      String? password = queryParams['password'];
      if (username == null || password == null) {
        return Response.badRequest(body: 'Missed username or password');
      }
      User? user = await repository.getUserCredentials(username, password);
      if (user == null) {
        return Response.unauthorized('Invalid username or password');
      }
      return Response.ok(generateJWT(user, env.passPhrase));
    } catch (e) {
      return Response.internalServerError(body: e);
    }
  }

  /// Ответчик на POST /auth/add
  Future<Response> createUser(Request req) async {
    print('Request to create new user');

    try {
      final String query = await req.readAsString();
      Map queryParams = jsonDecode(query);
      String? token = queryParams['token'];
      String? username = queryParams['username'];
      String? password = queryParams['password'];
      String? permission = queryParams['permission'];

      if (token == null) {
        return Response.unauthorized(_missedToken);
      }
      if (username == null || password == null || permission == null) {
        return Response.forbidden(_missedParams);
      }
      Map<String, dynamic> tokenPayload = parseJWT(token, env.passPhrase);
      String? permissionStr = tokenPayload['permission'];

      if (permissionStr == null) {
        return Response.internalServerError();
      }

      if (!parsePermission(tokenPayload).canManageUsers) {
        return Response.forbidden(_noPermissions);
      }

      var result = await repository.addUser(
          username, password, getPermissionFromString(permission));

      return Response.ok('User added with code $result');
    } on JWTExpiredException catch (e) {
      print(e.message);
      return Response.badRequest(body: _tokenExpired);
    } on Exception catch (e) {
      print(e);
      return Response.badRequest(body: e);
    }
  }

  /// Ответчик на DELETE /auth/delete
  Future<Response> deleteUser(Request req) async {
    print('Request to delete user');

    try {
      final String query = await req.readAsString();
      Map queryParams = jsonDecode(query);
      String? token = queryParams['token'];
      String? username = queryParams['username'];

      if (token == null) {
        return Response.unauthorized(_missedToken);
      }
      if (username == null) {
        return Response.forbidden(_missedParams);
      }

      Map<String, dynamic> tokenPayload = parseJWT(token, env.passPhrase);
      String? permissionStr = tokenPayload['permission'];

      if (permissionStr == null) {
        return Response.internalServerError();
      }

      if (!parsePermission(tokenPayload).canManageUsers) {
        return Response.forbidden(_noPermissions);
      }

      var result = repository.deleteUser(username);
      return Response.ok('User deleted with code $result');
    } on JWTExpiredException catch (e) {
      print(e.message);
      return Response.badRequest(body: _tokenExpired);
    } on Exception catch (e) {
      print(e);
      return Response.badRequest(body: e);
    }
  }

  /// Ответчик на PATCH /auth/password
  Future<Response> updatePassword(Request req) async {
    print('Request to update password');

    try {
      final String query = await req.readAsString();
      Map queryParams = jsonDecode(query);
      String? token = queryParams['token'];
      String? password = queryParams['password'];
      String? oldPassword = queryParams['oldPassword'];

      if (token == null) {
        return Response.unauthorized(_missedToken);
      }
      if (password == null || oldPassword == null) {
        return Response.forbidden(_missedParams);
      }

      Map<String, dynamic> tokenPayload = parseJWT(token, env.passPhrase);
      String? permissionStr = tokenPayload['permission'];
      String? username = tokenPayload['username'];

      if (permissionStr == null || username == null) {
        return Response.internalServerError(body: 'Wrong token provided');
      }

      bool check = await repository.isPasswordMatch(username, oldPassword);
      if (!check) {
        return Response.badRequest(body: 'Old password don\'t match');
      }

      var result = await repository.updateUserPassword(username, password);
      return Response.ok('Password updated with code $result');
    } on JWTExpiredException catch (e) {
      print(e.message);
      return Response.badRequest(body: 'Token expired');
    } on Exception catch (e) {
      print(e);
      return Response.badRequest(body: e);
    }
  }
}
