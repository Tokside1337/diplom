import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'appointment_repository.dart';
import 'appointment_model.dart';
import '../../core/utils/response_helper.dart';

class AppointmentHandler {
  final AppointmentRepository _repo;
  AppointmentHandler(this._repo);

  Router get router {
    final router = Router();

    router.get('/appointments/<id>', (Request req, String id) async {
      final list = await _repo.findByPatientId(int.parse(id));
      return ResponseHelper.ok(list.map((a) => a.toMap()).toList());
    });

    router.post('/appointments', (Request req) async {
      final body = jsonDecode(await req.readAsString());
      await _repo.create(AppointmentModel.fromMap(body));
      return Response.ok('Saved');
    });

    router.delete('/appointments/<id>', (Request req, String id) async {
      await _repo.delete(int.parse(id));
      return Response.ok('Deleted');
    });

    router.put('/appointments/status', (Request req) async {
      final body = jsonDecode(await req.readAsString());
      await _repo.updateStatus(body['id'], body['status']);
      return Response.ok('Updated');
    });

    router.get('/schedule/<name>', (Request req, String name) async {
      final decodedName = Uri.decodeComponent(name);
      final list = await _repo.findByDoctorName(decodedName);
      return ResponseHelper.ok(list.map((a) => a.toMap()).toList());
    });

    return router;
  }
}
