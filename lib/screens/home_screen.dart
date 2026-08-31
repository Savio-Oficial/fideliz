import 'package:flutter/material.dart';

import '../models/cliente_model.dart';
import '../models/movimentacao_model.dart';
import '../models/usuario_model.dart';
import '../repositories/cliente_repository.dart';
import '../repositories/movimentacao_repository.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'cadastro_cliente_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final Usuario usuario;

  const HomeScreen({super.key, required this.usuario});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _buscaController = TextEditingController();
  List<Cliente> _clientes = [];
  List<Movimentacao> _historico = [];
  String _filtroHistorico = 'todos';
  String _periodoHistorico = 'all';

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    final clientes = await ClienteRepository.carregar();
    final historico = await MovimentacaoRepository.carregar();
    if (!mounted) return;

    setState(() {
      _clientes = clientes;
      _historico = historico;
    });
  }

  Future<void> _salvarDados() async {
    await ClienteRepository.salvar(_clientes);
    await MovimentacaoRepository.salvar(_historico);
  }

  List<Cliente> get _clientesFiltrados {
    final termo = _buscaController.text.trim().toLowerCase();
    final clientes = termo.isEmpty
        ? List<Cliente>.from(_clientes)
        : _clientes.where((cliente) {
            final nome = cliente.nome.toLowerCase();
            return nome.contains(termo);
          }).toList();

    clientes.sort((a, b) => b.pontos.compareTo(a.pontos));
    return clientes;
  }

  List<Movimentacao> get _historicoFiltrado {
    Iterable<Movimentacao> lista = _historico;

    if (_filtroHistorico != 'todos') {
      lista = lista.where((movimentacao) => movimentacao.tipo == _filtroHistorico);
    }

    if (_periodoHistorico == '7d') {
      final limite = DateTime.now().subtract(const Duration(days: 7));
      lista = lista.where((movimentacao) => movimentacao.data.isAfter(limite));
    } else if (_periodoHistorico == '30d') {
      final limite = DateTime.now().subtract(const Duration(days: 30));
      lista = lista.where((movimentacao) => movimentacao.data.isAfter(limite));
    }

    final ordenada = lista.toList();
    ordenada.sort((a, b) => b.data.compareTo(a.data));
    return ordenada;
  }

  List<Cliente> get _rankingClientes {
    final clientesOrdenados = List<Cliente>.from(_clientes)
      ..sort((a, b) => b.pontos.compareTo(a.pontos));
    return clientesOrdenados.take(3).toList();
  }

  int get _totalPontos {
    return (ClienteRepository.resumo(_clientes)['totalPontos'] as int?) ?? 0;
  }

  int get _clientesVip {
    return (ClienteRepository.resumo(_clientes)['clientesVip'] as int?) ?? 0;
  }

  String get _categoriaMaisAtiva {
    final categoria = ClienteRepository.resumo(_clientes)['categoriaMaisAtiva'];
    if (categoria == null) {
      return 'Nenhuma';
    }

    return Cliente(
      nome: 'Teste',
      pontos: 0,
      categoria: categoria.toString(),
    ).categoriaLabel;
  }

  int get _totalCompras {
    final resumo = MovimentacaoRepository.resumo(_historico);
    return (resumo['totalCompras'] as int?) ?? 0;
  }

  double get _valorTotalCompras {
    final resumo = MovimentacaoRepository.resumo(_historico);
    return (resumo['valorTotalCompras'] as num?)?.toDouble() ?? 0;
  }

  double get _ticketMedio {
    final resumo = MovimentacaoRepository.resumo(_historico);
    return (resumo['ticketMedio'] as num?)?.toDouble() ?? 0;
  }

  Map<String, double> get _relatorioPeriodo {
    final agora = DateTime.now();
    final ultimos7 = _historico
        .where(
          (item) => item.tipo == 'compra' &&
              item.data.isAfter(agora.subtract(const Duration(days: 7))),
        )
        .fold<double>(0, (soma, item) => soma + item.valor);
    final ultimos30 = _historico
        .where(
          (item) => item.tipo == 'compra' &&
              item.data.isAfter(agora.subtract(const Duration(days: 30))),
        )
        .fold<double>(0, (soma, item) => soma + item.valor);

    return {
      '7d': ultimos7,
      '30d': ultimos30,
    };
  }

  Cliente? get _melhorCliente {
    final resumo = ClienteRepository.resumo(_clientes);
    return resumo['maiorPontuador'] as Cliente?;
  }

  String _formatarValor(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  Future<void> _abrirCadastro({Cliente? clienteParaEditar, int? index}) async {
    final resultado = await Navigator.push<Cliente>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CadastroClienteScreen(clienteParaEditar: clienteParaEditar),
      ),
    );

    if (!mounted || resultado == null) {
      return;
    }

    setState(() {
      if (clienteParaEditar == null) {
        _clientes.add(resultado);
      } else if (index != null) {
        _clientes[index] = resultado;
      }
    });

    await _salvarDados();
  }

  Future<void> _registrarCompra() async {
    if (_clientes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastre um cliente antes de registrar uma compra.'),
        ),
      );
      return;
    }

    final valorController = TextEditingController();
    final observacaoController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String clienteSelecionadoId = _clientes.first.id;

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Registrar compra'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: clienteSelecionadoId,
                  decoration: const InputDecoration(labelText: 'Cliente'),
                  items: _clientes
                      .map(
                        (cliente) => DropdownMenuItem(
                          value: cliente.id,
                          child: Text(cliente.nome),
                        ),
                      )
                      .toList(),
                  onChanged: (valor) =>
                      clienteSelecionadoId = valor ?? clienteSelecionadoId,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: valorController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    final numero = double.tryParse(
                      (value ?? '').replaceAll(',', '.'),
                    );
                    if (numero == null || numero <= 0) {
                      return 'Informe um valor válido.';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Valor da compra',
                    hintText: 'Ex.: 149.90',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: observacaoController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Observação (opcional)',
                    hintText: 'Ex.: compra de aniversário',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    if (confirmou != true) {
      return;
    }

    final valor =
        double.tryParse(valorController.text.replaceAll(',', '.')) ?? 0;
    final observacao = observacaoController.text.trim();
    final cliente = _clientes.firstWhere(
      (item) => item.id == clienteSelecionadoId,
      orElse: () => _clientes.first,
    );
    final pontos = ClienteRepository.calcularPontosPorCompra(cliente, valor);
    final clienteAtualizado = ClienteRepository.adicionarPontos(
      cliente,
      pontos,
    );
    final indexCliente = _clientes.indexWhere((item) => item.id == cliente.id);

    if (indexCliente >= 0) {
      setState(() {
        _clientes[indexCliente] = clienteAtualizado;
        _historico.insert(
          0,
          Movimentacao(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            clienteId: cliente.id,
            clienteNome: cliente.nome,
            tipo: 'compra',
            pontos: pontos,
            valor: valor,
            data: DateTime.now(),
            descricao: observacao.isEmpty
                ? 'Compra de ${_formatarValor(valor)}'
                : 'Compra de ${_formatarValor(valor)} • $observacao',
            categoriaCliente: cliente.categoria,
          ),
        );
      });
      await _salvarDados();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Compra registrada para ${cliente.nome}: +$pontos pontos.',
          ),
        ),
      );
    }
  }

  Future<void> _ajustarPontos(
    Cliente cliente, {
    required int index,
    required bool adicionar,
  }) async {
    final controller = TextEditingController(text: '50');
    final formKey = GlobalKey<FormState>();

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(adicionar ? 'Adicionar pontos' : 'Resgatar pontos'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              validator: (value) => ClienteRepository.validarMovimentoPontos(
                value,
                eDebito: !adicionar,
              ),
              decoration: InputDecoration(
                labelText: adicionar
                    ? 'Quantidade a adicionar'
                    : 'Quantidade a resgatar',
                hintText: 'Ex.: 50',
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (confirmado != true) {
      return;
    }

    final quantidade = int.tryParse(controller.text.trim()) ?? 0;

    if (!adicionar && quantidade > cliente.pontos) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${cliente.nome} não tem saldo suficiente para resgatar $quantidade pontos.',
          ),
        ),
      );
      return;
    }

    final clienteAtualizado = adicionar
        ? ClienteRepository.adicionarPontos(cliente, quantidade)
        : ClienteRepository.debitarPontos(cliente, quantidade);

    setState(() {
      _clientes[index] = clienteAtualizado;
      _historico.insert(
        0,
        Movimentacao(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          clienteId: cliente.id,
          clienteNome: cliente.nome,
          tipo: adicionar ? 'bonus' : 'resgate',
          pontos: adicionar ? quantidade : -quantidade,
          valor: 0,
          data: DateTime.now(),
          descricao: adicionar ? 'Bônus manual' : 'Resgate manual',
          categoriaCliente: cliente.categoria,
        ),
      );
    });
    await _salvarDados();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          adicionar
              ? 'Adicionados $quantidade pontos para ${cliente.nome}.'
              : 'Resgatados $quantidade pontos de ${cliente.nome}.',
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final clientesFiltrados = _clientesFiltrados;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Olá, ${widget.usuario.nomeExibicao}'),
        actions: [
          IconButton(
            onPressed: _logout,
            tooltip: 'Sair',
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirCadastro(),
        icon: const Icon(Icons.add),
        label: const Text('Novo cliente'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, Color(0xFF7A6CFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Resumo do programa',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_clientes.length} clientes ativos',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _melhorCliente == null
                                ? 'Ainda não há vencedor'
                                : 'Líder: ${_melhorCliente!.nome}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      title: 'Clientes',
                      value: _clientes.length.toString(),
                      icon: Icons.people_outline,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      title: 'Pontos',
                      value: _totalPontos.toString(),
                      icon: Icons.stars_outlined,
                      color: AppTheme.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      title: 'VIPs',
                      value: _clientesVip.toString(),
                      subtitle: 'Clientes premium',
                      icon: Icons.workspace_premium_outlined,
                      color: AppTheme.neutral,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      title: 'Categoria',
                      value: _categoriaMaisAtiva,
                      subtitle: 'Mais ativa',
                      icon: Icons.category_outlined,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      title: 'Compras',
                      value: _totalCompras.toString(),
                      subtitle: _valorTotalCompras == 0
                          ? 'Sem vendas'
                          : _formatarValor(_valorTotalCompras),
                      icon: Icons.shopping_bag_outlined,
                      color: AppTheme.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      title: 'Ticket médio',
                      value: _totalCompras == 0 ? 'R\$ 0,00' : _formatarValor(_ticketMedio),
                      icon: Icons.receipt_long_outlined,
                      color: AppTheme.neutral,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Ranking',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.neutral,
                      ),
                    ),
                  ),
                  if (_rankingClientes.isNotEmpty)
                    Text(
                      '${_rankingClientes.length} líderes',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.muted,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (_rankingClientes.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Ainda não há clientes para ranking.',
                    style: TextStyle(color: AppTheme.muted),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < _rankingClientes.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: i == 0
                                      ? AppTheme.accent
                                      : i == 1
                                          ? AppTheme.primary
                                          : AppTheme.neutral,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    '#${i + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _rankingClientes[i].nome,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.neutral,
                                  ),
                                ),
                              ),
                              Text(
                                '${_rankingClientes[i].pontos} pts',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Relatório executivo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.neutral,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _MiniReportCard(
                            title: '7 dias',
                            value: _formatarValor(_relatorioPeriodo['7d'] ?? 0),
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MiniReportCard(
                            title: '30 dias',
                            value: _formatarValor(_relatorioPeriodo['30d'] ?? 0),
                            color: AppTheme.accent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _registrarCompra,
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: const Text('Registrar compra'),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _buscaController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Buscar cliente',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 20),
              if (_historico.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Histórico recente',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.neutral,
                      ),
                    ),
                    Text(
                      '${_historicoFiltrado.length} itens',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Todos'),
                      selected: _filtroHistorico == 'todos',
                      onSelected: (_) => setState(() => _filtroHistorico = 'todos'),
                    ),
                    ChoiceChip(
                      label: const Text('Compras'),
                      selected: _filtroHistorico == 'compra',
                      onSelected: (_) => setState(() => _filtroHistorico = 'compra'),
                    ),
                    ChoiceChip(
                      label: const Text('Bônus'),
                      selected: _filtroHistorico == 'bonus',
                      onSelected: (_) => setState(() => _filtroHistorico = 'bonus'),
                    ),
                    ChoiceChip(
                      label: const Text('Resgates'),
                      selected: _filtroHistorico == 'resgate',
                      onSelected: (_) => setState(() => _filtroHistorico = 'resgate'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Todo período'),
                      selected: _periodoHistorico == 'all',
                      onSelected: (_) => setState(() => _periodoHistorico = 'all'),
                    ),
                    ChoiceChip(
                      label: const Text('Últimos 7 dias'),
                      selected: _periodoHistorico == '7d',
                      onSelected: (_) => setState(() => _periodoHistorico = '7d'),
                    ),
                    ChoiceChip(
                      label: const Text('Últimos 30 dias'),
                      selected: _periodoHistorico == '30d',
                      onSelected: (_) => setState(() => _periodoHistorico = '30d'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 150,
                  child: _historicoFiltrado.isEmpty
                      ? const Center(
                          child: Text(
                            'Nenhuma movimentação neste filtro.',
                            style: TextStyle(color: AppTheme.muted),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _historicoFiltrado.take(6).length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = _historicoFiltrado[index];
                            final sinal = item.pontos > 0 ? '+' : '';

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.clienteNome,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          item.descricao,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '$sinal${item.pontos} pts',
                                    style: TextStyle(
                                      color: item.pontos >= 0
                                          ? AppTheme.accent
                                          : Colors.red,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 20),
              ],
              SizedBox(
                height: 320,
                child: clientesFiltrados.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 44,
                              color: AppTheme.muted,
                            ),
                            SizedBox(height: 12),
                            Text('Nenhum cliente encontrado.'),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: clientesFiltrados.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final cliente = clientesFiltrados[index];
                          final originalIndex = _clientes.indexWhere(
                            (item) => item.id == cliente.id,
                          );

                          return Dismissible(
                            key: ValueKey(cliente.id.isNotEmpty ? cliente.id : cliente.nome),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(
                                Icons.delete_forever,
                                color: Colors.white,
                              ),
                            ),
                            confirmDismiss: (_) async {
                              final confirmou = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Confirmar exclusão'),
                                  content: Text(
                                    'Deseja excluir $cliente.nome?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Excluir'),
                                    ),
                                  ],
                                ),
                              );
                              return confirmou ?? false;
                            },
                            onDismissed: (_) async {
                              if (originalIndex >= 0) {
                                setState(() {
                                  _clientes.removeAt(originalIndex);
                                });
                                await _salvarDados();
                              }
                            },
                            child: Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.primarySoft,
                                  child: Text(
                                    cliente.nome.isNotEmpty
                                        ? cliente.nome[0].toUpperCase()
                                        : 'C',
                                    style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  cliente.nome,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${cliente.pontos} pontos acumulados'),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Categoria: ${cliente.categoriaLabel}',
                                      style: const TextStyle(
                                        color: AppTheme.muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Adicionar pontos',
                                      onPressed: () => _ajustarPontos(
                                        cliente,
                                        index: originalIndex,
                                        adicionar: true,
                                      ),
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Resgatar pontos',
                                      onPressed: () => _ajustarPontos(
                                        cliente,
                                        index: originalIndex,
                                        adicionar: false,
                                      ),
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Editar cliente',
                                      onPressed: () => _abrirCadastro(
                                        clienteParaEditar: cliente,
                                        index: originalIndex,
                                      ),
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.neutral,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: const TextStyle(fontSize: 12, color: AppTheme.muted),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniReportCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _MiniReportCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
