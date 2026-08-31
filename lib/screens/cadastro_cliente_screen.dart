import 'package:flutter/material.dart';

import '../models/cliente_model.dart';
import '../repositories/cliente_repository.dart';
import '../theme/app_theme.dart';

class CadastroClienteScreen extends StatefulWidget {
  final Cliente? clienteParaEditar;

  const CadastroClienteScreen({super.key, this.clienteParaEditar});

  @override
  State<CadastroClienteScreen> createState() => _CadastroClienteScreenState();
}

class _CadastroClienteScreenState extends State<CadastroClienteScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _pontosController;
  late String _categoriaSelecionada;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(
      text: widget.clienteParaEditar?.nome ?? '',
    );
    _pontosController = TextEditingController(
      text: widget.clienteParaEditar?.pontos.toString() ?? '',
    );
    _categoriaSelecionada = widget.clienteParaEditar?.categoria ?? 'comum';
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _pontosController.dispose();
    super.dispose();
  }

  void _salvarCliente() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final client = Cliente(
      id: widget.clienteParaEditar?.id ?? Cliente.gerarId(),
      nome: _nomeController.text.trim(),
      pontos: int.parse(_pontosController.text.trim()),
      categoria: _categoriaSelecionada,
    );

    Navigator.pop(context, client);
  }

  @override
  Widget build(BuildContext context) {
    final isEdicao = widget.clienteParaEditar != null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          isEdicao ? 'Editar cliente' : 'Novo cliente',
          style: const TextStyle(
            color: AppTheme.neutral,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primarySoft,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.person_add_alt_1_outlined,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isEdicao
                                  ? 'Atualizar cadastro'
                                  : 'Adicionar novo cliente',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nomeController,
                        textInputAction: TextInputAction.next,
                        validator: ClienteRepository.validarNome,
                        decoration: const InputDecoration(
                          hintText: 'Nome completo',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _pontosController,
                        keyboardType: TextInputType.number,
                        validator: ClienteRepository.validarPontos,
                        decoration: const InputDecoration(
                          hintText: 'Quantidade de pontos',
                          prefixIcon: Icon(Icons.stars_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _categoriaSelecionada,
                        decoration: const InputDecoration(
                          labelText: 'Categoria',
                          prefixIcon: Icon(Icons.workspace_premium_outlined),
                        ),
                        items: Cliente.categoriasDisponiveis
                            .map(
                              (categoria) => DropdownMenuItem(
                                value: categoria,
                                child: Text(
                                  Cliente(
                                    nome: 'Teste',
                                    pontos: 0,
                                    categoria: categoria,
                                  ).categoriaLabel,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (valor) {
                          if (valor != null) {
                            setState(() => _categoriaSelecionada = valor);
                          }
                        },
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _salvarCliente,
                          icon: Icon(
                            isEdicao ? Icons.save_alt : Icons.add_circle_outline,
                          ),
                          label: Text(
                            isEdicao ? 'Atualizar cliente' : 'Salvar cliente',
                          ),
                        ),
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
