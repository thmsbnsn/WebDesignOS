-- Fixture: RLS USING (true) on sensitive table (should FAIL)
create policy "rls_true_footgun"
on public.memberships
for select
using (true);