import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'patient_repository.dart';
import 'patient_model.dart';
import '../../core/utils/response_helper.dart';

class PatientHandler {
  final PatientRepository _repo;
  PatientHandler(this._repo);

  Router get router {
    final router = Router();

    router.get('/patients', (Request req) async {
      final params = req.url.queryParameters;
      final limit = int.tryParse(params['limit'] ?? '100') ?? 100;
      final offset = int.tryParse(params['offset'] ?? '0') ?? 0;

      final patients = await _repo.findAll(limit: limit, offset: offset);
      return ResponseHelper.ok(patients.map((p) => p.toMap()).toList());
    });

    router.get('/patients/<id>', (Request req, String id) async {
      final patient = await _repo.findById(int.parse(id));
      if (patient == null) return ResponseHelper.notFound('Not found');
      return ResponseHelper.ok(patient.toMap());
    });

    router.post('/patients', (Request req) async {
      final body = jsonDecode(await req.readAsString());
      final id = await _repo.create(PatientModel.fromMap(body));
      return ResponseHelper.ok({'id': id});
    });

    router.put('/patients', (Request req) async {
      final Map<String, dynamic> p = jsonDecode(await req.readAsString());
      // The snake_case conversion logic was in the original handler
      final Map<String, dynamic> params = {};
      p.forEach((key, value) {
        String snakeKey = key.replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => '_${match.group(1)!.toLowerCase()}',
        );
        params[snakeKey] = value;
      });
      params
        ..remove('diagnosis')
        ..remove('contraindications')
        ..remove('treatment_goals')
        ..remove('dynamics')
        ..remove('final_recommendations');
      await _repo.update(PatientModel.fromMap(params));
      return Response.ok('Updated');
    });

    router.delete('/patients/<id>', (Request req, String id) async {
      await _repo.delete(int.parse(id));
      return Response.ok('Deleted');
    });

    return router;
  }
}
