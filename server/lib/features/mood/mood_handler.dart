import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'mood_repository.dart';
import 'mood_model.dart';
import '../../core/utils/response_helper.dart';

class MoodHandler {
  final MoodRepository _repo;
  MoodHandler(this._repo);

  Router get router {
    final router = Router();

    router.get('/mood/<id>', (Request req, String id) async {
      final list = await _repo.findByPatientId(int.parse(id));
      return ResponseHelper.ok(list.map((m) => m.toMap()).toList());
    });

    router.post('/mood', (Request req) async {
      final body = jsonDecode(await req.readAsString());
      await _repo.create(MoodModel.fromMap(body));
      return Response.ok('Saved');
    });

    router.delete('/mood/<id>', (Request req, String id) async {
      await _repo.delete(int.parse(id));
      return Response.ok('Deleted');
    });

    return router;
  }
}
