import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'doctor_repository.dart';
import 'doctor_model.dart';
import '../../core/utils/response_helper.dart';

class DoctorHandler {
  final DoctorRepository _repo;
  DoctorHandler(this._repo);

  Router get router {
    final router = Router();

    router.get('/doctors', (Request req) async {
      final doctors = await _repo.findAll();
      return ResponseHelper.ok(doctors.map((d) => d.toMap()).toList());
    });

    router.get('/doctors/<id>', (Request req, String id) async {
      final doctor = await _repo.findById(int.parse(id));
      if (doctor == null) return ResponseHelper.notFound('Not found');
      return ResponseHelper.ok(doctor.toMap());
    });

    router.post('/doctors', (Request req) async {
      final body = jsonDecode(await req.readAsString());
      final id = await _repo.create(DoctorModel.fromMap(body));
      return ResponseHelper.ok({'id': id});
    });

    router.put('/doctors', (Request req) async {
      final body = jsonDecode(await req.readAsString());
      await _repo.update(DoctorModel.fromMap(body));
      return Response.ok('Updated');
    });

    router.delete('/doctors/<id>', (Request req, String id) async {
      await _repo.delete(int.parse(id));
      return Response.ok('Deleted');
    });

    return router;
  }
}
