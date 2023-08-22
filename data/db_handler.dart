import 'package:shelf_plus/shelf_plus.dart';

class Handler {
  late final RouterPlus router;

  Handler() {
    router = Router().plus;
  }

  Future<void> init() async {
    router.get('/', _rootHandler);
  }

  Response _rootHandler(Request req) {
    return Response.ok('Hello, world!\n');
  }
}
