-- Fixture: SECURITY DEFINER with dynamic SQL missing allowlist marker (should FAIL)
-- WDSO_ALLOW_SECURITY_DEFINER: test fixture
create or replace function public.fixture_secdef_dynamic_sql()
returns void
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  execute 'select 1';
end;
$$;