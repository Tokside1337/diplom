import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'user_service.dart';
import 'user_model.dart';
import '../../core/utils/response_helper.dart';

class UserHandler {
  final UserService _userService;
  UserHandler(this._userService);

  Router get router {
    final router = Router();

    router.post('/login', (Request req) async {
      final body = jsonDecode(await req.readAsString());
      final result = await _userService.login(body['login'], body['password']);
      if (result == null) return ResponseHelper.forbidden('Invalid credentials');
      return ResponseHelper.ok(result);
    });

    router.get('/users', (Request req) async {
      final users = await _userService.getAll();
      return ResponseHelper.ok(users.map((u) => u.toMap()).toList());
    });

    router.post('/register', (Request req) async {
      final body = jsonDecode(await req.readAsString());
      await _userService.register(UserModel.fromMap(body));
      return ResponseHelper.ok({'message': 'Registered'});
    });

    router.put('/users', (Request req) async {
      final body = jsonDecode(await req.readAsString());
      await _userService.update(UserModel.fromMap(body));
      return ResponseHelper.ok({'message': 'Updated'});
    });

    router.delete('/users/<id>', (Request req, String id) async {
      await _userService.deleteUser(int.parse(id));
      return ResponseHelper.ok({'message': 'Deleted'});
    });

    return router;
  }
}
