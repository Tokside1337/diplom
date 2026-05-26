import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'json_helper.dart';

class ResponseHelper {
  static Response ok(dynamic data) {
    return Response.ok(
      jsonEncode(data, toEncodable: JsonHelper.toJson),
      headers: {'Content-Type': 'application/json'},
    );
  }

  static Response error(String message, {int statusCode = 500}) {
    return Response(
      statusCode,
      body: jsonEncode({'error': message}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  static Response notFound(String message) => error(message, statusCode: 404);
  static Response forbidden(String message) => error(message, statusCode: 403);
}
