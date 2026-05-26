import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'emk_repository.dart';
import 'emk_model.dart';
import '../../core/utils/response_helper.dart';

class EmkHandler {
  final EmkRepository _repo;
  EmkHandler(this._repo);

  Router get router {
    final router = Router();

    router.get('/emk/<patientId>', (Request req, String patientId) async {
      final emk = await _repo.findByPatientId(int.parse(patientId));
      if (emk == null) return ResponseHelper.notFound('Not found');
      return ResponseHelper.ok(emk.toMap());
    });

    router.post('/emk', (Request req) async {
      final body = jsonDecode(await req.readAsString());
      await _repo.create(EmkModel.fromMap(body));
      return ResponseHelper.ok({'id': 1}); // Simple stub to maintain contract
    });

    router.put('/emk', (Request req) async {
      final body = jsonDecode(await req.readAsString());
      await _repo.update(EmkModel.fromMap(body));
      return Response.ok('Updated');
    });

    return router;
  }
}
