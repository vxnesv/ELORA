import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  Stream<User?> get authStateChanges => _firebaseAuth.userChanges();
  User? get currentUser => _firebaseAuth.currentUser;

  Future<void> entrar({required String email, required String senha}) async {
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: senha,
    );
  }

  Future<void> cadastrar({
    required String nome,
    required String email,
    required String senha,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: senha,
    );
    await credential.user?.updateDisplayName(nome.trim());
    await credential.user?.reload();
  }

  Future<void> enviarRecuperacao(String email) =>
      _firebaseAuth.sendPasswordResetEmail(email: email.trim());

  Future<void> sair() => _firebaseAuth.signOut();
}

String mensagemAuth(Object error) {
  if (error is! FirebaseAuthException) {
    return 'Não foi possível concluir a operação. Tente novamente.';
  }
  return switch (error.code) {
    'invalid-email' => 'Informe um e-mail válido.',
    'invalid-credential' ||
    'user-not-found' ||
    'wrong-password' => 'E-mail ou senha incorretos.',
    'email-already-in-use' => 'Já existe uma conta com este e-mail.',
    'weak-password' => 'Escolha uma senha mais forte.',
    'user-disabled' => 'Esta conta está desativada.',
    'too-many-requests' =>
      'Muitas tentativas em pouco tempo. Aguarde e tente novamente.',
    'network-request-failed' => 'Verifique sua conexão com a internet.',
    _ => 'Não foi possível concluir a operação. Tente novamente.',
  };
}
