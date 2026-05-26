import 'dart:convert';
import 'package:shelf/shelf.dart';

Middleware errorMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      try {
        return await innerHandler(request);
      } catch (e, stackTrace) {
        print('Error: $e\n$stackTrace');
        return Response.internalServerError(
          body: jsonEncode({'error': e.toString()}),
          headers: {'Content-Type': 'application/json'},
        );
      }
    };
  };
}
