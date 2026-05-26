import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:rehab_server/core/config/app_config.dart';
import 'package:rehab_server/core/database/database_service.dart';
import 'package:rehab_server/core/middleware/cors_middleware.dart';
import 'package:rehab_server/core/middleware/error_middleware.dart';
import 'package:rehab_server/core/middleware/auth_middleware.dart';
import 'package:rehab_server/routes/app_router.dart';

void main() async {
  // 0. Load Configuration
  AppConfig.load();

  // 1. Initialize Database
  final dbService = DatabaseService();
  try {
    await dbService.initialize();
    stdout.writeln('Сервер подключен к PostgreSQL (Connection Pool)');
  } catch (e) {
    stderr.writeln('Ошибка БД: $e');
    return;
  }

  // 2. Setup Router
  final appRouter = AppRouter(dbService);
  final router = appRouter.router;

  // 3. Setup Pipeline (CORS must be FIRST)
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsMiddleware())  // Сначала CORS
      .addMiddleware(errorMiddleware()) // Потом обработка ошибок
      .addMiddleware(authMiddleware())  // В конце авторизация
      .addHandler(router.call);

  // 4. Start Server
  final server = await serve(handler, InternetAddress.anyIPv4, AppConfig.serverPort);
  stdout.writeln('API сервер РеСтарт запущен на: http://${server.address.address}:${server.port}');
}
