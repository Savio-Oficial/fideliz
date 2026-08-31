# Fideliz

Aplicação Flutter de fidelização de clientes para gestão de clientes, pontos, compras e histórico operacional.

## Visão geral

Este projeto foi estruturado como um MVP local-first para validar a lógica de negócio de um programa de fidelidade:

- cadastro e edição de clientes
- cálculo de pontos por compra
- dashboard com métricas operacionais
- histórico de movimentações
- autenticação local com sessão persistida
- arquitetura preparada para migração para Supabase/PostgreSQL

## Stack atual

- Flutter
- Dart
- SharedPreferences para persistência local
- Tema centralizado e arquitetura por modelos/repositories
- Supabase preparado para futuro backend real

## Como executar

1. Instale o Flutter e as ferramentas do SDK.
2. No diretório do projeto, rode:

```bash
flutter pub get
flutter run
```

Para web local:

```bash
flutter run -d chrome
```

Se estiver usando Edge no ambiente atual:

```bash
flutter run -d web-server --web-port 8080
```

## Variáveis de ambiente para Supabase

Quando a migração para o backend real for ativada, configure:

```bash
SUPABASE_URL=your_project_url
SUPABASE_ANON_KEY=your_anon_key
```

## Estrutura principal

- `lib/models/` — modelos tipados
- `lib/repositories/` — regra de negócio e persistência
- `lib/services/` — autenticação e integração externa
- `lib/screens/` — telas da aplicação
- `lib/theme/` — tokens e estilo visual centralizado
- `supabase/schema.sql` — base de dados recomendada para evolução

## Status

- MVP funcional local com autenticação, clientes, pontos e histórico
- Base visual e lógica de negócio reorganizadas
- Preparado para evolução para backend real com Supabase
