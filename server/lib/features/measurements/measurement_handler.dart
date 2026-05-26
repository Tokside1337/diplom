import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'measurement_repository.dart';
import 'measurement_model.dart';
import '../../core/utils/response_helper.dart';

class MeasurementHandler {
  final MeasurementRepository _repo;
  MeasurementHandler(this._repo);

  Router get router {
    final router = Router();

    router.get('/measurements/<id>', (Request req, String id) async {
      final list = await _repo.findByPatientId(int.parse(id));
      return ResponseHelper.ok(list.map((m) => m.toMap()).toList());
    });

    router.post('/measurements', (Request req) async {
      final body = jsonDecode(await req.readAsString());
      await _repo.create(MeasurementModel.fromMap(body));
      return Response.ok('Saved');
    });

    return router;
  }
}
