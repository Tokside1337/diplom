import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'note_repository.dart';
import 'note_model.dart';
import '../../core/utils/response_helper.dart';

class NoteHandler {
  final NoteRepository _repo;
  NoteHandler(this._repo);

  Router get router {
    final router = Router();

    router.get('/notes/<id>', (Request req, String id) async {
      final list = await _repo.findByPatientId(int.parse(id));
      return ResponseHelper.ok(list.map((n) => n.toMap()).toList());
    });

    router.post('/notes', (Request req) async {
      final body = jsonDecode(await req.readAsString());
      await _repo.create(NoteModel.fromMap(body));
      return Response.ok('Saved');
    });

    return router;
  }
}
