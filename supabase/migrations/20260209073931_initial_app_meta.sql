create table public.app_meta (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  key text not null unique,
  value jsonb not null default '{}'::jsonb
);

alter table public.app_meta enable row level security;
