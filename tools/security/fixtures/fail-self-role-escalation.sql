-- Fixture: self-role escalation (should FAIL)
update public.profiles
set role = 'admin'
where id = auth.uid();