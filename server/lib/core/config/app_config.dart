import 'package:dotenv/dotenv.dart';

class AppConfig {
  static final DotEnv _env = DotEnv();

  static void load() => _env.load();

  static String get dbHost => _env['DB_HOST'] ?? 'localhost';
  static int get dbPort => int.parse(_env['DB_PORT'] ?? '5432');
  static String get dbName => _env['DB_NAME'] ?? 'rehab_db';
  static String get dbUser => _env['DB_USER'] ?? 'postgres';
  static String get dbPass => _env['DB_PASS'] ?? '1337';
  static String get aiApiKey => _env['AI_API_KEY'] ?? '';
  static String get jwtSecret => _env['JWT_SECRET'] ?? 'default_secret';
  static const int serverPort = 8080;
}
