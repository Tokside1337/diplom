import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'reminder_repository.dart';
import 'reminder_model.dart';
import '../../core/utils/response_helper.dart';

class ReminderHandler {
  final ReminderRepository _repo;
  ReminderHandler(this._repo);

  Router get router {
    final router = Router();

    router.get('/reminders/unread/<id>', (Request req, String id) async {
      final list = await _repo.findUnreadByPatientId(int.parse(id));
      return ResponseHelper.ok(list.map((r) => r.toMap()).toList());
    });

    router.put('/reminders/read/<id>', (Request req, String id) async {
      await _repo.markAsRead(int.parse(id));
      return Response.ok('Read');
    });

    router.post('/reminders', (Request req) async {
      final body = jsonDecode(await req.readAsString());
      await _repo.create(ReminderModel.fromMap(body));
      return Response.ok('Sent');
    });

    return router;
  }
}
