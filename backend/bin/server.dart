import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:backend/services/feed_service.dart';

void main(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests.
  final handler = Pipeline().addMiddleware(logRequests()).addHandler(_router);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');

  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}

final _feedService = FeedService();

final _router = Router()
  ..get('/', _rootHandler)
  ..get('/echo/<message>', _echoHandler)
  ..get('/news', _newsHandler);

Response _rootHandler(Request req) {
  return Response.ok('Google Tech News Backend Running\n');
}

Response _echoHandler(Request request) {
  final message = request.params['message'];
  return Response.ok('$message\n');
}

Future<Response> _newsHandler(Request request) async {
  try {
    final articles = await _feedService.fetchAllFeeds();
    final jsonList = articles.map((a) => a.toJson()).toList();
    return Response.ok(
      jsonEncode({'articles': jsonList}),
      headers: {'content-type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(body: 'Failed to fetch news: $e');
  }
}
