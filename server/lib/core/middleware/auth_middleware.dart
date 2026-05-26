import 'package:shelf/shelf.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import '../config/app_config.dart';
import '../utils/response_helper.dart';

Middleware authMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      final path = request.url.path;
      
      // Allow auth routes and root
      if (path == 'login' || path == 'register' || path == '' || path == '/') {
        return await innerHandler(request);
      }

      final authHeader = request.headers['Authorization'] ?? request.headers['authorization'];
      
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        print('Auth Blocked: Missing token for path /$path');
        return ResponseHelper.error('Missing or invalid Authorization header', statusCode: 401);
      }

      final token = authHeader.substring(7);

      try {
        final jwt = JWT.verify(token, SecretKey(AppConfig.jwtSecret));
        
        final updatedRequest = request.change(context: {
          'userId': jwt.payload['id'],
          'userRole': jwt.payload['role'],
        });

        return await innerHandler(updatedRequest);
      } on JWTExpiredException {
        print('Auth Error: Token expired');
        return ResponseHelper.error('Token expired', statusCode: 401);
      } on JWTException catch (e) {
        print('Auth Error: ${e.message}');
        return ResponseHelper.error('Invalid token: ${e.message}', statusCode: 401);
      } catch (e) {
        print('Auth Error: Unknown error');
        return ResponseHelper.error('Unauthorized', statusCode: 401);
      }
    };
  };
}
