create extension if not exists pgcrypto;

create table if not exists profiles (
  id uuid primary key default gen_random_uuid(),
  email text not null unique,
  full_name text,
  role text not null default 'admin',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists clientes (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles(id) on delete cascade,
  nome text not null,
  email text,
  telefone text,
  categoria text not null default 'comum' check (categoria in ('comum', 'ouro', 'premium')),
  pontos integer not null default 0,
  total_compras numeric(12,2) not null default 0,
  ultima_compra_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists compras (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles(id) on delete cascade,
  cliente_id uuid not null references clientes(id) on delete cascade,
  valor numeric(12,2) not null check (valor >= 0),
  pontos_ganhos integer not null default 0,
  observacao text,
  created_at timestamptz not null default now()
);

create table if not exists movimentacoes (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles(id) on delete cascade,
  cliente_id uuid not null references clientes(id) on delete cascade,
  tipo text not null check (tipo in ('compra', 'bonus', 'resgate', 'ajuste')),
  pontos integer not null,
  descricao text,
  metadata jsonb default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists campanhas (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles(id) on delete cascade,
  nome text not null,
  descricao text,
  multiplicador numeric(4,2) not null default 1,
  ativa boolean not null default true,
  data_inicio timestamptz not null default now(),
  data_fim timestamptz,
  created_at timestamptz not null default now()
);

create or replace function update_updated_at_column()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger set_updated_at_profiles
before update on profiles
for each row
execute function update_updated_at_column();

create trigger set_updated_at_clientes
before update on clientes
for each row
execute function update_updated_at_column();

alter table profiles enable row level security;
alter table clientes enable row level security;
alter table compras enable row level security;
alter table movimentacoes enable row level security;
alter table campanhas enable row level security;

create policy "profiles are viewable by owner"
on profiles for select
using (auth.uid() = id);

create policy "profiles are editable by owner"
on profiles for update
using (auth.uid() = id);

create policy "clientes are viewable by owner"
on clientes for select
using (profile_id = auth.uid());

create policy "clientes are editable by owner"
on clientes for all
using (profile_id = auth.uid())
with check (profile_id = auth.uid());

create policy "compras are viewable by owner"
on compras for select
using (profile_id = auth.uid());

create policy "compras are editable by owner"
on compras for all
using (profile_id = auth.uid())
with check (profile_id = auth.uid());

create policy "movimentacoes are viewable by owner"
on movimentacoes for select
using (profile_id = auth.uid());

create policy "movimentacoes are editable by owner"
on movimentacoes for all
using (profile_id = auth.uid())
with check (profile_id = auth.uid());

create policy "campanhas are viewable by owner"
on campanhas for select
using (profile_id = auth.uid());

create policy "campanhas are editable by owner"
on campanhas for all
using (profile_id = auth.uid())
with check (profile_id = auth.uid());
