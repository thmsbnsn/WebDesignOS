-- Fixture: SECURITY DEFINER without allowlist marker (should FAIL)
create or replace function public.fixture_secdef_missing_marker()
returns void
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  null;
end;
$$;