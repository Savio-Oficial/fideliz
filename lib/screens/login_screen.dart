import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController(text: 'admin@fideliz.com');
  final _senhaController = TextEditingController(text: '123456');
  bool _carregando = false;
  bool _modoRegistro = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  String? _validarNome(String? value) {
    final nome = (value ?? '').trim();
    if (!_modoRegistro) {
      return null;
    }

    if (nome.isEmpty) {
      return 'Informe seu nome.';
    }

    if (nome.length < 2) {
      return 'O nome deve ter pelo menos 2 caracteres.';
    }

    return null;
  }

  String? _validarEmail(String? value) {
    final email = (value ?? '').trim();

    if (email.isEmpty) {
      return 'Informe seu e-mail.';
    }

    final regex = RegExp(
      r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+$",
    );
    if (!regex.hasMatch(email)) {
      return 'Use um e-mail válido.';
    }

    return null;
  }

  String? _validarSenha(String? value) {
    final senha = value ?? '';

    if (senha.isEmpty) {
      return 'Informe sua senha.';
    }

    if (senha.length < 6) {
      return 'A senha deve ter no mínimo 6 caracteres.';
    }

    return null;
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _carregando = true;
    });

    final usuario = await AuthService.login(
      email: _emailController.text,
      senha: _senhaController.text,
    );

    if (!mounted) {
      return;
    }

    if (usuario == null) {
      setState(() {
        _carregando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Credenciais inválidas. Use um e-mail válido e senha com 6+ caracteres.',
          ),
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomeScreen(usuario: usuario)),
    );
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _carregando = true;
    });

    final usuario = await AuthService.registrar(
      email: _emailController.text,
      senha: _senhaController.text,
      nome: _nomeController.text,
    );

    if (!mounted) {
      return;
    }

    if (usuario == null) {
      setState(() {
        _carregando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível criar este cadastro. Verifique os dados e tente novamente.',
          ),
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomeScreen(usuario: usuario)),
    );
  }

  Future<void> _submitFormulario() async {
    if (_modoRegistro) {
      await _registrar();
      return;
    }

    await _entrar();
  }

  Future<void> _recuperarSenha() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe seu e-mail para recuperar a senha.')),
      );
      return;
    }

    final enviado = await AuthService.resetarSenha(email: email);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enviado
              ? 'Se esse e-mail estiver cadastrado, você receberá instruções para redefinir a senha.'
              : 'Não foi possível enviar a recuperação de senha. Verifique o e-mail e tente novamente.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 460),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, Color(0xFF7A6CFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fideliz',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Gestão de clientes, benefícios e compras.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: const [
                          _InfoPill(icon: Icons.group, label: 'Clientes'),
                          SizedBox(width: 10),
                          _InfoPill(icon: Icons.stars, label: 'Pontos'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: AppTheme.primarySoft,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.shield_outlined,
                            size: 42,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Acesso do gestor',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.neutral,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primarySoft,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _modoRegistro ? 'Cadastro' : 'Login',
                                style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _modoRegistro
                              ? 'Crie sua conta e comece a gerenciar o programa.'
                              : 'Entre para administrar clientes, pontos e campanhas.',
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppTheme.muted,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primarySoft,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.primary.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.auto_awesome,
                                color: AppTheme.primary,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Experiência premium para gestão de fidelidade.',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: AppTheme.neutral,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        if (_modoRegistro)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: TextFormField(
                              controller: _nomeController,
                              validator: _validarNome,
                              decoration: const InputDecoration(
                                hintText: 'Nome completo',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                            ),
                          ),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: _validarEmail,
                          decoration: const InputDecoration(
                            hintText: 'E-mail',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _senhaController,
                          obscureText: true,
                          validator: _validarSenha,
                          decoration: const InputDecoration(
                            hintText: 'Senha',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _carregando ? null : _submitFormulario,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            icon: _carregando
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    _modoRegistro
                                        ? Icons.person_add_alt_1_rounded
                                        : Icons.login_rounded,
                                  ),
                            label: Text(
                              _carregando
                                  ? (_modoRegistro ? 'Criando conta...' : 'Entrando...')
                                  : (_modoRegistro ? 'Criar conta' : 'Entrar'),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        if (!_modoRegistro) ...[
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _carregando ? null : _recuperarSenha,
                              child: const Text(
                                'Esqueci minha senha',
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.primarySoft,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _modoRegistro
                                      ? 'Já possui uma conta?'
                                      : 'Novo por aqui?',
                                  style: const TextStyle(
                                    color: AppTheme.neutral,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _carregando
                                    ? null
                                    : () {
                                        setState(() {
                                          _modoRegistro = !_modoRegistro;
                                          _formKey.currentState?.reset();
                                        });
                                      },
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  _modoRegistro ? 'Entrar' : 'Criar conta',
                                  style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
