import 'package:material_ui/material_ui.dart';

import '../../../core/presentation/componentes_elora.dart';
import '../../../core/presentation/tema_elora.dart';
import '../data/auth_service.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _enviando = false;
  bool _ocultarSenha = true;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enviando = true);
    try {
      await widget.authService.entrar(
        email: _emailController.text,
        senha: _senhaController.text,
      );
    } catch (error) {
      if (mounted) _mostrarErro(mensagemAuth(error));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _recuperarSenha() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _mostrarErro('Digite seu e-mail para recuperar a senha.');
      return;
    }
    try {
      await widget.authService.enviarRecuperacao(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enviamos as instruções de recuperação por e-mail.'),
          ),
        );
      }
    } catch (error) {
      if (mounted) _mostrarErro(mensagemAuth(error));
    }
  }

  void _mostrarErro(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = CoresElora.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.85, -0.85),
            radius: 1.2,
            colors: [colors.accentSoft, colors.background],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 36, 24, 36),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: LogoCircular(size: 126)),
                      const SizedBox(height: 18),
                      Text(
                        'E L O R A',
                        textAlign: TextAlign.center,
                        style: Theme.of(
                          context,
                        ).textTheme.headlineMedium?.copyWith(letterSpacing: 6),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Mais clareza para cuidar, se preparar e agir.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Entrar',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                        ),
                        validator: (value) =>
                            value == null || !value.trim().contains('@')
                            ? 'Informe um e-mail válido.'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _senhaController,
                        obscureText: _ocultarSenha,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            tooltip: _ocultarSenha
                                ? 'Mostrar senha'
                                : 'Ocultar senha',
                            onPressed: () =>
                                setState(() => _ocultarSenha = !_ocultarSenha),
                            icon: Icon(
                              _ocultarSenha
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Informe sua senha.'
                            : null,
                        onFieldSubmitted: (_) => _enviando ? null : _entrar(),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _enviando ? null : _recuperarSenha,
                          child: const Text('Esqueci minha senha'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: _enviando ? null : _entrar,
                        icon: _enviando
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.login_rounded),
                        label: const Text('Entrar'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _enviando
                            ? null
                            : () => Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => SignupScreen(
                                    authService: widget.authService,
                                  ),
                                ),
                              ),
                        child: const Text('Criar minha conta'),
                      ),
                      const SizedBox(height: 22),
                      const AvisoDiscreto(
                        icon: Icons.health_and_safety_outlined,
                        text:
                            'A ELORA oferece orientação preventiva e não substitui profissionais de saúde ou serviços de emergência.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
