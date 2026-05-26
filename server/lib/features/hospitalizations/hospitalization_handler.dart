import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'hospitalization_repository.dart';
import 'hospitalization_model.dart';
import '../../core/utils/response_helper.dart';

class HospitalizationHandler {
  final HospitalizationRepository _repo;
  HospitalizationHandler(this._repo);

  Router get router {
    final router = Router();

    router.get('/hospitalizations/<id>', (Request req, String id) async {
      final list = await _repo.findByPatientId(int.parse(id));
      return ResponseHelper.ok(list.map((h) => h.toMap()).toList());
    });

    router.post('/hospitalizations', (Request req) async {
      final body = jsonDecode(await req.readAsString());
      await _repo.create(HospitalizationModel.fromMap(body));
      return Response.ok('Saved');
    });

    return router;
  }
}
