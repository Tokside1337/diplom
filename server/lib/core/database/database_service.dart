import 'dart:io';
import 'package:bcrypt/bcrypt.dart';
import 'package:postgres/postgres.dart';
import '../config/app_config.dart';

class DatabaseService {
  late final Pool pool;

  Future<void> initialize() async {
    pool = Pool.withEndpoints(
      [
        Endpoint(
          host: AppConfig.dbHost,
          port: AppConfig.dbPort,
          database: AppConfig.dbName,
          username: AppConfig.dbUser,
          password: AppConfig.dbPass,
        )
      ],
      settings: PoolSettings(
        maxConnectionCount: 10,
        sslMode: SslMode.disable,
      ),
    );
    
    await _runMigrations();
    await _ensureAdminUser();
  }

  Future<void> _runMigrations() async {
    final migrationDir = Directory('lib/core/database/migrations');
    if (!await migrationDir.exists()) return;

    final files = await migrationDir.list().toList();
    files.sort((a, b) => a.path.compareTo(b.path));

    for (var file in files) {
      if (file is File && file.path.endsWith('.sql')) {
        final sqlContent = await file.readAsString();
        print('Executing migration: ${file.path}');
        
        // Split SQL content into individual statements by semicolon
        final statements = sqlContent
            .split(';')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

        for (var stmt in statements) {
          try {
            await pool.execute(stmt);
          } catch (e) {
            final error = e.toString();
            // Ignore "already exists" errors during initial setup
            if (!error.contains('already exists') && !error.contains('already a member')) {
              print('Migration statement failed: $e\nStatement: $stmt');
            }
          }
        }
      }
    }
  }

  Future<void> _ensureAdminUser() async {
    final adminCheck = await pool.execute(
      Sql.named('SELECT id, password FROM users WHERE login = @login'),
      parameters: {'login': 'admin'},
    );

    const String adminPass = '1337';
    if (adminCheck.isEmpty) {
      final hashedPassword = BCrypt.hashpw(adminPass, BCrypt.gensalt());
      await pool.execute(
        Sql.named('INSERT INTO users (login, password, role) VALUES (@login, @password, @role)'),
        parameters: {'login': 'admin', 'password': hashedPassword, 'role': 'admin'},
      );
      print('Default admin created.');
    } else {
      final currentPass = adminCheck.first[1] as String;
      if (currentPass.length < 30) {
        final hashedPassword = BCrypt.hashpw(currentPass, BCrypt.gensalt());
        await pool.execute(
          Sql.named('UPDATE users SET password = @p WHERE login = @l'),
          parameters: {'l': 'admin', 'p': hashedPassword},
        );
        print('Admin password secured with BCrypt.');
      }
    }
  }

  Future<Result> execute(String fmt, {Map<String, dynamic>? parameters}) async {
    return await pool.execute(Sql.named(fmt), parameters: parameters);
  }
}
