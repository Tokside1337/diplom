import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'ai_service.dart';
import '../../core/utils/response_helper.dart';

class AiHandler {
  final AiService _aiService;
  AiHandler(this._aiService);

  Router get router {
    final router = Router();

    router.post('/ai/chat', (Request req) async {
      final body = jsonDecode(await req.readAsString());
      final text = await _aiService.chat(
        body['message'],
        body['patientId'],
        body['isDoctor'] ?? false,
      );
      return ResponseHelper.ok({'text': text});
    });

    router.post('/ai/analyze-health', (Request req) async {
      final body = jsonDecode(await req.readAsString());
      final result = await _aiService.analyzeHealth(body['patientId']);
      return ResponseHelper.ok(result);
    });

    return router;
  }
}
