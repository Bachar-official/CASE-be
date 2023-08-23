import 'package:postgres/postgres.dart';

import '../domain/entity/app.dart';

class DBRepository {
  final PostgreSQLConnection connection;

  DBRepository({required this.connection});

  Future<int> insertApp(App app) async {
    return await connection
        .execute('INSERT INTO apps ${app.toInsertSQLValues()}');
  }

  Future<int> updateApp(App app) async {
    return await connection.execute('UPDATE apps ${app.toUpdateSQLValues()}');
  }

  Future<PostgreSQLResult> searchPackage(String package) async {
    return await connection
        .query('SELECT * from apps WHERE package = \'$package\'');
  }
}
