import 'package:postgres/postgres.dart';

import 'permission.dart';

class User {
  final int? id;
  final String name;
  final Permission permission;

  User({this.id, required this.name, required this.permission});

  factory User.fromStringPermission(
          {required String name, required String perm}) =>
      User(name: name, permission: getPermissionFromString(perm));

  factory User.fromPostgreSQL(PostgreSQLResultRow row) {
    Map<String, dynamic> map = row.toColumnMap();
    return User.fromStringPermission(
        name: map['name'], perm: map['permission']);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'permission': permission.name,
      };

  Map<String, dynamic> toJWT() => {
        'username': name,
        'permission': permission.name,
      };
}
