import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CampanhaModel {
  final String nome;
  final String descricao;
  final String validade;
  final double multiplicador;
  final bool ativa;
  final IconData icon;

  const CampanhaModel({
    required this.nome,
    required this.descricao,
    required this.validade,
    required this.multiplicador,
    required this.ativa,
    required this.icon,
  });
}

class CampanhasScreen extends StatelessWidget {
  const CampanhasScreen({super.key});

  static const List<CampanhaModel> _campanhas = [
    CampanhaModel(
      nome: 'VIP Week',
      descricao: 'Multiplicador de 1,5x para clientes premium na semana de aniversário.',
      validade: 'Válido até 15/09',
      multiplicador: 1.5,
      ativa: true,
      icon: Icons.auto_awesome_rounded,
    ),
    CampanhaModel(
      nome: 'Retenção Ouro',
      descricao: 'Bonificação extra para clientes ouro com compras recorrentes.',
      validade: 'Ativa agora',
      multiplicador: 1.25,
      ativa: true,
      icon: Icons.workspace_premium_rounded,
    ),
    CampanhaModel(
      nome: 'Acelera Fidelidade',
      descricao: 'Aumento de pontos para compras acima de R\$ 200.',
      validade: 'Próxima campanha',
      multiplicador: 1.1,
      ativa: false,
      icon: Icons.flash_on_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Campanhas'),
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: _campanhas.length,
          itemBuilder: (context, index) {
            final campanha = _campanhas[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
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
                        child: Icon(campanha.icon, color: AppTheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              campanha.nome,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: AppTheme.neutral,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              campanha.validade,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    campanha.descricao,
                    style: const TextStyle(
                      color: AppTheme.neutral,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: campanha.ativa
                              ? AppTheme.accent.withValues(alpha: 0.12)
                              : AppTheme.muted.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          campanha.ativa ? 'Ativa' : 'Pausada',
                          style: TextStyle(
                            color: campanha.ativa ? AppTheme.accent : AppTheme.muted,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        'x${campanha.multiplicador.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
