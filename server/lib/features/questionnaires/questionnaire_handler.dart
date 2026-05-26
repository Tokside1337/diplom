import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'questionnaire_repository.dart';
import 'questionnaire_model.dart';
import '../../core/utils/response_helper.dart';

class QuestionnaireHandler {
  final QuestionnaireRepository _repo;
  QuestionnaireHandler(this._repo);

  Router get router {
    final router = Router();

    router.get('/questionnaires/<id>', (Request req, String id) async {
      final list = await _repo.findByPatientId(int.parse(id));
      return ResponseHelper.ok(list.map((q) => q.toMap()).toList());
    });

    router.post('/questionnaires', (Request req) async {
      final body = jsonDecode(await req.readAsString());
      await _repo.create(QuestionnaireModel.fromMap(body));
      return Response.ok('Saved');
    });

    router.delete('/questionnaires/<id>', (Request req, String id) async {
      await _repo.delete(int.parse(id));
      return Response.ok('Deleted');
    });

    return router;
  }
}
