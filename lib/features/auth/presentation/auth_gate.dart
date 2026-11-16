import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app.dart' show AppShell;
import '../../../core/data/elora_store.dart';
import '../data/auth_service.dart';
import 'login_screen.dart';

class AuthGate extends StatefulWidget {
  AuthGate({super.key, required this.store, AuthService? authService})
    : authService = authService ?? AuthService();

  final EloraStore store;
  final AuthService authService;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _uid;
  Future<void>? _preparacao;

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: widget.authService.authStateChanges,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final user = snapshot.data;
      if (user == null) {
        _uid = null;
        _preparacao = null;
        return LoginScreen(authService: widget.authService);
      }
      if (_uid != user.uid) {
        _uid = user.uid;
        _preparacao = widget.store.conectarUsuario(user.uid);
      }
      return FutureBuilder<void>(
        future: _preparacao,
        builder: (context, preparation) {
          if (preparation.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final displayName = user.displayName?.trim();
          if (displayName != null &&
              displayName.isNotEmpty &&
              widget.store.name != displayName) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (widget.store.name != displayName) {
                widget.store.definirNome(displayName);
              }
            });
          }
          return AppShell(store: widget.store);
        },
      );
    },
  );
}
