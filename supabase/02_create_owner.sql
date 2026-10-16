-- Run AFTER signing up and confirming the owner's email in the application.
-- Replace the address with the exact owner's confirmed email.
do $$
declare v_user_id uuid; v_clinic_id uuid;
begin
  select id into v_user_id from auth.users
  where lower(email) = lower('YOUR_EMAIL@example.com');
  if v_user_id is null then raise exception 'Confirmed owner account was not found'; end if;
  insert into public.clinics(name) values('My Physio Studio') returning id into v_clinic_id;
  insert into public.memberships(clinic_id,user_id,role) values(v_clinic_id,v_user_id,'owner');
end $$;
