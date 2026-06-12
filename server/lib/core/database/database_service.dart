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
        
        try {
          // The postgres driver's pool.execute() might not support multiple statements 
          // in a single string if it's using prepared statements under the hood.
          // However, we can use a connection directly or ensure we use the right method.
          await pool.withConnection((conn) async {
            // Using a raw query on the connection often allows multi-statement strings.
            // But to be safest with the 'postgres' package, we should split 
            // by a custom delimiter or use a more robust splitting logic 
            // that respects 'DO $$' blocks.
            
            // For simplicity and reliability, let's use a regex that splits by semicolon
            // but ignores semicolons inside $$-quoted blocks.
            final statements = sqlContent
                .split(';')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList();

            // We need a way to group statements that belong to a block.
            // But actually, the most robust way in Dart's postgres package is to 
            // NOT split when inside a $$ block.
            
            List<String> realStatements = [];
            String buffer = '';
            bool insideDollars = false;
            
            for (var stmt in statements) {
              buffer += (buffer.isEmpty ? '' : ';') + stmt;
              
              // Count occurrences of $$
              int dollarCount = 0;
              int pos = 0;
              while ((pos = stmt.indexOf('\$\$', pos)) != -1) {
                dollarCount++;
                pos += 2;
              }
              
              if (dollarCount % 2 != 0) {
                insideDollars = !insideDollars;
              }
              
              if (!insideDollars) {
                realStatements.add(buffer);
                buffer = '';
              }
            }

            for (var stmt in realStatements) {
              await conn.execute(stmt);
            }
          });
        } catch (e) {
          final error = e.toString();
          if (!error.contains('already exists') && 
              !error.contains('already a member') &&
              !error.contains('already exist')) {
            print('Migration failed in ${file.path}: $e');
          }
        }
      }
    }
  }

  Future<void> _ensureAdminUser() async {
    final adminCheck = await pool.execute(
      Sql.named('SELECT id, password_hash FROM users WHERE login = @login'),
      parameters: {'login': 'admin'},
    );

    const String adminPass = '1337';
    if (adminCheck.isEmpty) {
      final hashedPassword = BCrypt.hashpw(adminPass, BCrypt.gensalt());
      await pool.execute(
        Sql.named('INSERT INTO users (login, password_hash, role) VALUES (@login, @password, @role)'),
        parameters: {'login': 'admin', 'password': hashedPassword, 'role': 'admin'},
      );
      print('Default admin created.');
    } else {
      final currentPass = adminCheck.first[1] as String;
      if (currentPass.length < 30) {
        final hashedPassword = BCrypt.hashpw(currentPass, BCrypt.gensalt());
        await pool.execute(
          Sql.named('UPDATE users SET password_hash = @p WHERE login = @l'),
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
