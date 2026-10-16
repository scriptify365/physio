-- Optional: Add sample exercise descriptions to the first clinic owned by this email.
-- Replace the email with the confirmed owner's email. No patient data is created.
do $$
declare v_clinic uuid;
begin
  select m.clinic_id into v_clinic
  from public.memberships m join auth.users u on u.id=m.user_id
  where m.role='owner' and lower(u.email)=lower('YOUR_EMAIL@example.com') limit 1;
  if v_clinic is null then raise exception 'Clinic not found for owner'; end if;
  insert into public.exercises(clinic_id,name,description,equipment,tags) values
    (v_clinic,'Most biodrowy','Przykład testowy: unoszenie bioder w leżeniu na plecach. Opis wymaga weryfikacji fizjoterapeuty.','Mata',array['Biodra','Stabilizacja']),
    (v_clinic,'Ruchomość obręczy barkowej','Przykładowe ćwiczenie testowe. Specjalista powinien dopisać właściwe instrukcje.','Bez sprzętu',array['Barki','Mobilność']),
    (v_clinic,'Aktywacja mięśni brzucha','Przykładowy opis do testów aplikacji. Nie jest indywidualnym zaleceniem.','Mata',array['Tułów','Stabilizacja']),
    (v_clinic,'Wspięcia na palce','Przykładowe ćwiczenie testowe. Parametry ustala prowadzący fizjoterapeuta.','Bez sprzętu',array['Kończyna dolna','Siła']);
end $$;
