import 'package:shelf_router/shelf_router.dart';
import '../core/database/database_service.dart';
import '../features/auth/user_repository.dart';
import '../features/auth/user_service.dart';
import '../features/auth/user_handler.dart';
import '../features/doctors/doctor_repository.dart';
import '../features/doctors/doctor_handler.dart';
import '../features/patients/patient_repository.dart';
import '../features/patients/patient_handler.dart';
import '../features/measurements/measurement_repository.dart';
import '../features/measurements/measurement_handler.dart';
import '../features/mood/mood_repository.dart';
import '../features/mood/mood_handler.dart';
import '../features/notes/note_repository.dart';
import '../features/notes/note_handler.dart';
import '../features/appointments/appointment_repository.dart';
import '../features/appointments/appointment_handler.dart';
import '../features/reminders/reminder_repository.dart';
import '../features/reminders/reminder_handler.dart';
import '../features/emk/emk_repository.dart';
import '../features/emk/emk_handler.dart';
import '../features/questionnaires/questionnaire_repository.dart';
import '../features/questionnaires/questionnaire_handler.dart';
import '../features/hospitalizations/hospitalization_repository.dart';
import '../features/hospitalizations/hospitalization_handler.dart';
import '../features/ai/ai_service.dart';
import '../features/ai/ai_handler.dart';

class AppRouter {
  final DatabaseService _db;

  AppRouter(this._db);

  Router get router {
    final router = Router();

    // Repositories
    final userRepo = UserRepository(_db);
    final patientRepo = PatientRepository(_db);
    final doctorRepo = DoctorRepository(_db);
    final measurementRepo = MeasurementRepository(_db);
    final moodRepo = MoodRepository(_db);
    final noteRepo = NoteRepository(_db);
    final appointmentRepo = AppointmentRepository(_db);
    final reminderRepo = ReminderRepository(_db);
    final emkRepo = EmkRepository(_db);
    final questionnaireRepo = QuestionnaireRepository(_db);
    final hospitalizationRepo = HospitalizationRepository(_db);

    // Services
    final userService = UserService(userRepo, patientRepo, doctorRepo);
    final aiService = AiService(patientRepo, emkRepo, measurementRepo, moodRepo);

    // Handlers
    final userHandler = UserHandler(userService);
    final doctorHandler = DoctorHandler(doctorRepo);
    final patientHandler = PatientHandler(patientRepo);
    final measurementHandler = MeasurementHandler(measurementRepo);
    final moodHandler = MoodHandler(moodRepo);
    final noteHandler = NoteHandler(noteRepo);
    final appointmentHandler = AppointmentHandler(appointmentRepo);
    final reminderHandler = ReminderHandler(reminderRepo);
    final emkHandler = EmkHandler(emkRepo);
    final questionnaireHandler = QuestionnaireHandler(questionnaireRepo);
    final hospitalizationHandler = HospitalizationHandler(hospitalizationRepo);
    final aiHandler = AiHandler(aiService);

    // Mounting
    router.mount('/', userHandler.router);
    router.mount('/', doctorHandler.router);
    router.mount('/', patientHandler.router);
    router.mount('/', measurementHandler.router);
    router.mount('/', moodHandler.router);
    router.mount('/', noteHandler.router);
    router.mount('/', appointmentHandler.router);
    router.mount('/', reminderHandler.router);
    router.mount('/', emkHandler.router);
    router.mount('/', questionnaireHandler.router);
    router.mount('/', hospitalizationHandler.router);
    router.mount('/', aiHandler.router);

    return router;
  }
}
