import 'package:shelf/shelf.dart';

Middleware corsMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      final corsHeaders = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization, X-Requested-With, Accept',
        'Access-Control-Max-Age': '86400',
      };

      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: corsHeaders);
      }

      final response = await innerHandler(request);
      return response.change(headers: corsHeaders);
    };
  };
}
