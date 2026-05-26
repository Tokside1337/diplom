import 'package:bcrypt/bcrypt.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import '../../core/config/app_config.dart';
import 'user_model.dart';
import 'user_repository.dart';
import '../patients/patient_repository.dart';
import '../doctors/doctor_repository.dart';

class UserService {
  final UserRepository _userRepo;
  final PatientRepository _patientRepo;
  final DoctorRepository _doctorRepo;

  UserService(this._userRepo, this._patientRepo, this._doctorRepo);

  Future<Map<String, dynamic>?> login(String login, String password) async {
    final user = await _userRepo.findByLogin(login);
    if (user == null) return null;

    // Verify password
    final bool isPasswordValid = BCrypt.checkpw(password, user.password);
    if (!isPasswordValid) return null;

    // Generate JWT
    final jwt = JWT(
      {
        'id': user.id,
        'role': user.role,
      },
      issuer: 'rehab_server',
    );

    final token = jwt.sign(SecretKey(AppConfig.jwtSecret), expiresIn: const Duration(days: 7));

    return {
      'accessToken': token,
      'user': user.toMap()..remove('password'),
    };
  }

  Future<List<UserModel>> getAll() async {
    return await _userRepo.findAll();
  }

  Future<void> register(UserModel user) async {
    // Hash password before saving
    final hashedPassword = BCrypt.hashpw(user.password, BCrypt.gensalt());
    final newUser = UserModel(
      login: user.login,
      password: hashedPassword,
      role: user.role,
      patientId: user.patientId,
      doctorId: user.doctorId,
    );
    await _userRepo.create(newUser);
  }

  Future<void> update(UserModel user) async {
    // If password is changed, hash it. 
    // For now, assuming the client sends either new hashed password or we check if it's already a hash.
    // Simpler logic: if password length is < 30, it's likely not a bcrypt hash.
    String passwordToSave = user.password;
    if (user.password.length < 30) {
      passwordToSave = BCrypt.hashpw(user.password, BCrypt.gensalt());
    }

    final updatedUser = UserModel(
      id: user.id,
      login: user.login,
      password: passwordToSave,
      role: user.role,
      patientId: user.patientId,
      doctorId: user.doctorId,
    );
    await _userRepo.update(updatedUser);
  }

  Future<void> deleteUser(int id) async {
    final info = await _userRepo.findRoleInfo(id);
    if (info != null) {
      final String role = info['role'];
      final int? pId = info['patient_id'];
      final int? dId = info['doctor_id'];

      if (role == 'patient' && pId != null) {
        await _patientRepo.delete(pId);
      } else if (role == 'doctor' && dId != null) {
        await _doctorRepo.delete(dId);
      }
    }
    await _userRepo.delete(id);
  }
}
