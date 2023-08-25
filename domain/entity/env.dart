class Env {
  final String? port;

  final String workPath;

  final String pgHost;
  final String pgPort;

  final String dbName;
  final String dbUsername;
  final String dbPassword;

  int get pgPortInt => int.parse(pgPort);
  int get hostPort => int.parse(port ?? '1337');

  Env(
      {this.port,
      required this.workPath,
      required this.pgHost,
      required this.pgPort,
      required this.dbName,
      required this.dbUsername,
      required this.dbPassword});
}
