-- PhysioPlan database schema and security policies.
-- Run once in the Supabase SQL Editor on a new project.
-- Never expose the service role or secret key in the browser.
create extension if not exists pgcrypto;

create table public.clinics (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 2 and 150),
  created_at timestamptz not null default now()
);

create table public.memberships (
  clinic_id uuid not null references public.clinics(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('owner','therapist','patient')),
  created_at timestamptz not null default now(),
  primary key (clinic_id, user_id)
);

create table public.patients (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id),
  user_id uuid references auth.users(id) on delete set null,
  therapist_id uuid not null references auth.users(id),
  name text not null check (char_length(name) between 2 and 150),
  email text not null check (char_length(email) between 3 and 320),
  created_at timestamptz not null default now(),
  unique(clinic_id, email),
  unique(clinic_id, user_id)
);
create index patients_therapist_idx on public.patients(therapist_id);

create table public.invitations (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id),
  patient_id uuid not null references public.patients(id) on delete cascade,
  token uuid not null unique default gen_random_uuid(),
  email text not null,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '14 days',
  claimed_at timestamptz,
  created_by uuid not null references auth.users(id)
);

create table public.exercises (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id),
  name text not null check (char_length(name) between 2 and 120),
  description text not null default '',
  equipment text not null default '',
  tags text[] not null default '{}',
  video_path text,
  archived boolean not null default false,
  created_at timestamptz not null default now()
);
create index exercises_clinic_idx on public.exercises(clinic_id);

create table public.workout_templates (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id),
  name text not null check (char_length(name) between 2 and 120),
  workout jsonb not null default '[]'::jsonb check (jsonb_typeof(workout) = 'array'),
  created_at timestamptz not null default now()
);

create table public.plans (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id),
  patient_id uuid not null references public.patients(id),
  title text not null check (char_length(title) between 2 and 120),
  start_date date not null,
  end_date date not null,
  draft jsonb not null default '{}'::jsonb check (jsonb_typeof(draft) = 'object'),
  status text not null default 'draft' check (status in ('draft','active','paused','completed')),
  current_version integer not null default 0,
  created_at timestamptz not null default now(),
  check (end_date >= start_date and end_date <= start_date + 83)
);
create index plans_patient_idx on public.plans(patient_id);

create table public.plan_versions (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.plans(id),
  clinic_id uuid not null references public.clinics(id),
  version integer not null,
  snapshot jsonb not null,
  published_by uuid not null references auth.users(id),
  published_at timestamptz not null default now(),
  unique(plan_id, version)
);

create table public.training_sessions (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id),
  plan_id uuid not null references public.plans(id),
  plan_version_id uuid not null references public.plan_versions(id),
  patient_id uuid not null references public.patients(id),
  day date not null,
  workout jsonb not null check (jsonb_typeof(workout) = 'array'),
  status text not null default 'scheduled' check (status in ('scheduled','in_progress','completed','partial','skipped','cancelled')),
  revision integer not null default 0,
  feedback jsonb,
  submitted_at timestamptz,
  reviewed_at timestamptz,
  updated_at timestamptz not null default now()
);
create unique index sessions_one_per_day_idx on public.training_sessions(patient_id, day) where status <> 'cancelled';
create index sessions_patient_day_idx on public.training_sessions(patient_id, day desc);

create table public.audit_events (
  id bigint generated always as identity primary key,
  clinic_id uuid not null references public.clinics(id),
  actor_id uuid references auth.users(id),
  action text not null,
  entity_id uuid,
  happened_at timestamptz not null default now()
);

-- SECURITY DEFINER helpers avoid recursive RLS while checking permissions.
create function public.is_staff(p_clinic uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.memberships m
    where m.clinic_id = p_clinic and m.user_id = (select auth.uid())
      and m.role in ('owner','therapist')
  );
$$;
create function public.is_owner(p_clinic uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.memberships m
    where m.clinic_id = p_clinic and m.user_id = (select auth.uid()) and m.role = 'owner'
  );
$$;
create function public.can_manage_patient(p_patient uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.patients p
    where p.id = p_patient and (public.is_owner(p.clinic_id) or (
      p.therapist_id = (select auth.uid()) and public.is_staff(p.clinic_id)
    ))
  );
$$;
create function public.can_view_patient(p_patient uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.patients p
    where p.id = p_patient and (p.user_id = (select auth.uid()) or public.can_manage_patient(p.id))
  );
$$;
create function public.can_read_video(p_path text)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.exercises e
    where e.video_path = p_path and public.is_staff(e.clinic_id)
  ) or exists (
    select 1 from public.training_sessions s
    join public.patients p on p.id = s.patient_id
    where p.user_id = (select auth.uid()) and s.status <> 'cancelled'
      and exists (select 1 from jsonb_array_elements(s.workout) item
                  where item->>'video_path' = p_path)
  );
$$;

alter table public.clinics enable row level security;
alter table public.memberships enable row level security;
alter table public.patients enable row level security;
alter table public.invitations enable row level security;
alter table public.exercises enable row level security;
alter table public.workout_templates enable row level security;
alter table public.plans enable row level security;
alter table public.plan_versions enable row level security;
alter table public.training_sessions enable row level security;
alter table public.audit_events enable row level security;

create policy clinics_read on public.clinics for select to authenticated
  using (exists (select 1 from public.memberships m where m.clinic_id = id and m.user_id = (select auth.uid())));
create policy memberships_read on public.memberships for select to authenticated
  using (user_id = (select auth.uid()) or public.is_owner(clinic_id));
create policy patients_read on public.patients for select to authenticated using (public.can_view_patient(id));
create policy patients_insert on public.patients for insert to authenticated
  with check (public.is_owner(clinic_id) or (public.is_staff(clinic_id) and therapist_id = (select auth.uid())));
create policy invitations_read on public.invitations for select to authenticated using (public.can_manage_patient(patient_id));
create policy invitations_insert on public.invitations for insert to authenticated
  with check (public.can_manage_patient(patient_id) and created_by = (select auth.uid())
    and exists(select 1 from public.patients p where p.id = patient_id and p.clinic_id = clinic_id and lower(p.email) = lower(email) and p.user_id is null));
create policy exercises_read on public.exercises for select to authenticated using (public.is_staff(clinic_id));
create policy exercises_insert on public.exercises for insert to authenticated with check (public.is_staff(clinic_id));
create policy exercises_update on public.exercises for update to authenticated using (public.is_staff(clinic_id)) with check (public.is_staff(clinic_id));
create policy templates_read on public.workout_templates for select to authenticated using (public.is_staff(clinic_id));
create policy templates_insert on public.workout_templates for insert to authenticated with check (public.is_staff(clinic_id));
create policy templates_update on public.workout_templates for update to authenticated using (public.is_staff(clinic_id)) with check (public.is_staff(clinic_id));
create policy templates_delete on public.workout_templates for delete to authenticated using (public.is_staff(clinic_id));
create policy plans_read on public.plans for select to authenticated using (public.can_manage_patient(patient_id));
create policy plans_insert on public.plans for insert to authenticated
  with check (public.can_manage_patient(patient_id) and exists(select 1 from public.patients p where p.id=patient_id and p.clinic_id=clinic_id));
create policy plans_update on public.plans for update to authenticated using (public.can_manage_patient(patient_id))
  with check (public.can_manage_patient(patient_id) and exists (select 1 from public.patients p where p.id=patient_id and p.clinic_id=clinic_id));
create policy versions_read on public.plan_versions for select to authenticated using (
  exists (select 1 from public.plans p where p.id = plan_id and public.can_view_patient(p.patient_id))
);
create policy sessions_read on public.training_sessions for select to authenticated using (public.can_view_patient(patient_id));
create policy audit_read on public.audit_events for select to authenticated using (public.is_owner(clinic_id));

-- Explicit privileges on newly created application tables.
-- RLS policies additionally determine which specific rows can be accessed.
grant select on public.clinics, public.memberships, public.patients,
  public.invitations, public.exercises, public.workout_templates,
  public.plans, public.plan_versions, public.training_sessions,
  public.audit_events to authenticated;
grant insert on public.patients, public.invitations, public.exercises,
  public.workout_templates, public.plans to authenticated;
grant delete on public.workout_templates to authenticated;

-- Normal browser roles can update only permitted fields. Status and version are controlled by RPCs.
revoke update on public.plans from authenticated;
grant update (title,start_date,end_date,draft) on public.plans to authenticated;
revoke update on public.exercises from authenticated;
grant update (name,description,equipment,tags,video_path,archived) on public.exercises to authenticated;
revoke update on public.workout_templates from authenticated;
grant update (name,workout) on public.workout_templates to authenticated;
revoke update on public.patients from authenticated;

-- Validate media ownership even when a malicious client bypasses the UI.
alter table public.exercises add constraint video_belongs_to_clinic
  check (video_path is null or left(video_path, length(clinic_id::text)+1) = clinic_id::text || '/');

-- Public patient API deliberately excludes editable/unpublished draft content.
create function public.get_my_active_plans()
returns table (id uuid, patient_id uuid, title text, start_date date, end_date date, status text)
language sql stable security definer set search_path = '' as $$
  select p.id,p.patient_id,p.title,p.start_date,p.end_date,p.status
  from public.plans p join public.patients pat on pat.id = p.patient_id
  where pat.user_id = (select auth.uid()) and p.status = 'active'
  order by p.start_date desc;
$$;

create function public.create_patient_for_clinic(p_clinic_id uuid, p_name text, p_email text)
returns public.patients
language plpgsql security definer set search_path = '' as $$
declare v_user_id uuid := auth.uid(); v_patient public.patients%rowtype;
begin
  if v_user_id is null then
    raise exception 'User is not authenticated';
  end if;

  if not (
    exists (
      select 1 from public.memberships m
      where m.clinic_id = p_clinic_id and m.user_id = v_user_id and m.role = 'owner'
    ) or exists (
      select 1 from public.memberships m
      where m.clinic_id = p_clinic_id and m.user_id = v_user_id and m.role = 'therapist'
    )
  ) then
    raise exception 'You do not have permission to add patients to this clinic';
  end if;

  insert into public.patients (clinic_id, therapist_id, name, email)
  values (p_clinic_id, v_user_id, trim(p_name), lower(trim(p_email)))
  returning * into v_patient;

  return v_patient;
end;
$$;

grant execute on function public.create_patient_for_clinic(uuid, text, text) to authenticated;

-- The bucket is private; storage policies are authorization checks, not just UI checks.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('exercise-videos','exercise-videos',false,52428800,array['video/mp4'])
on conflict(id) do update set public=false, file_size_limit=52428800, allowed_mime_types=array['video/mp4'];
create policy exercise_video_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'exercise-videos' and
    public.is_staff((storage.foldername(name))[1]::uuid) and lower(storage.extension(name)) = 'mp4');
create policy exercise_video_select on storage.objects for select to authenticated
  using (bucket_id = 'exercise-videos' and public.can_read_video(name));

-- Invitations require both possession of the token AND verified ownership of the invited email.
create function public.claim_patient_invite(p_token uuid)
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_inv public.invitations%rowtype; v_user auth.users%rowtype; v_patient public.patients%rowtype;
begin
  select * into v_user from auth.users where id = auth.uid();
  if v_user.id is null then
    raise exception 'User must be signed in to accept the invitation';
  end if;
  select * into v_inv from public.invitations where token = p_token and claimed_at is null and expires_at > now() for update;
  if v_inv.id is null then raise exception 'Invitation expired or already used'; end if;
  if lower(v_inv.email) <> lower(v_user.email) then raise exception 'Sign in with the invited email address'; end if;
  select * into v_patient from public.patients where id = v_inv.patient_id for update;
  if v_patient.id is null or v_patient.clinic_id <> v_inv.clinic_id or v_patient.user_id is not null then
    raise exception 'Patient profile is unavailable';
  end if;
  update public.patients set user_id = v_user.id where id = v_patient.id;
  insert into public.memberships(clinic_id,user_id,role) values(v_inv.clinic_id,v_user.id,'patient')
    on conflict(clinic_id,user_id) do nothing;
  update public.invitations set claimed_at = now() where id = v_inv.id;
  insert into public.audit_events(clinic_id,actor_id,action,entity_id)
    values(v_inv.clinic_id,v_user.id,'patient.invitation_accepted',v_patient.id);
  return v_patient.id;
end; $$;

-- All future sessions are materialized transactionally on publishing a version.
create function public.publish_plan(p_plan_id uuid)
returns integer language plpgsql security definer set search_path = '' as $$
declare v_plan public.plans%rowtype; v_version_id uuid; v_new_version integer;
        v_day date; v_workout jsonb; v_today date := (now() at time zone 'Europe/Warsaw')::date;
        v_start date; v_item jsonb; v_key text;
begin
  select * into v_plan from public.plans where id=p_plan_id for update;
  if v_plan.id is null or not public.can_manage_patient(v_plan.patient_id) then raise exception 'Not authorized'; end if;
  if v_plan.status = 'paused' or v_plan.status = 'completed' then raise exception 'Plan cannot be published'; end if;
  if v_plan.end_date < v_today then raise exception 'Plan end date must not be in the past'; end if;
  if not exists (select 1 from jsonb_each(v_plan.draft) d where jsonb_typeof(d.value) = 'array' and jsonb_array_length(d.value)>0)
  then raise exception 'Add at least one workout day'; end if;
  for v_key in select jsonb_object_keys(v_plan.draft) loop
    if v_key not in ('0','1','2','3','4','5','6') or jsonb_typeof(v_plan.draft->v_key) <> 'array'
    then raise exception 'Invalid workout day'; end if;
    for v_item in select value from jsonb_array_elements(v_plan.draft->v_key) loop
      if coalesce((nullif(v_item->>'sets',''))::int,0) < 1 or coalesce((nullif(v_item->>'sets',''))::int,0) > 20
        or (coalesce((nullif(v_item->>'reps',''))::int,0) <= 0 and coalesce((nullif(v_item->>'duration',''))::int,0) <= 0)
        or not exists(select 1 from public.exercises e where e.id=(v_item->>'exercise_id')::uuid and e.clinic_id=v_plan.clinic_id and not e.archived)
      then raise exception 'Invalid exercise parameters'; end if;
    end loop;
  end loop;
  if exists(select 1 from public.plans p where p.patient_id=v_plan.patient_id and p.id<>v_plan.id
    and p.status='active' and daterange(p.start_date,p.end_date,'[]') && daterange(v_plan.start_date,v_plan.end_date,'[]'))
  then raise exception 'Another active plan overlaps the selected dates'; end if;
  v_new_version := v_plan.current_version + 1;
  insert into public.plan_versions(plan_id,clinic_id,version,snapshot,published_by)
    values(v_plan.id,v_plan.clinic_id,v_new_version,
      jsonb_build_object('title',v_plan.title,'start_date',v_plan.start_date,'end_date',v_plan.end_date,'draft',v_plan.draft),auth.uid())
    returning id into v_version_id;
  v_start := greatest(v_plan.start_date, v_today);
  if v_plan.current_version > 0 then
    v_start := greatest(v_start, v_today + 1);
    update public.training_sessions set status='cancelled', updated_at=now()
      where plan_id=v_plan.id and day>=v_start and status='scheduled';
  end if;
  for v_day in select generate_series(v_start,v_plan.end_date,interval '1 day')::date loop
    v_workout := v_plan.draft -> (extract(dow from v_day)::int)::text;
    if v_workout is not null and jsonb_typeof(v_workout)='array' and jsonb_array_length(v_workout)>0 then
      if not exists (select 1 from public.training_sessions s where s.patient_id=v_plan.patient_id and s.day=v_day and s.status <> 'cancelled') then
        insert into public.training_sessions(clinic_id,plan_id,plan_version_id,patient_id,day,workout)
          values(v_plan.clinic_id,v_plan.id,v_version_id,v_plan.patient_id,v_day,v_workout);
      end if;
    end if;
  end loop;
  update public.plans set current_version=v_new_version,status='active' where id=v_plan.id;
  insert into public.audit_events(clinic_id,actor_id,action,entity_id)
    values(v_plan.clinic_id,auth.uid(),'plan.published',v_plan.id);
  return v_new_version;
end; $$;

create function public.submit_session_result(p_session_id uuid,p_status text,p_feedback jsonb,p_revision integer)
returns public.training_sessions language plpgsql security definer set search_path = '' as $$
declare v_session public.training_sessions%rowtype; v_owner uuid; v_out public.training_sessions%rowtype;
begin
  select * into v_session from public.training_sessions where id=p_session_id for update;
  select user_id into v_owner from public.patients where id=v_session.patient_id;
  if v_session.id is null or v_owner is distinct from auth.uid() then raise exception 'Not authorized'; end if;
  if v_session.status='cancelled' or p_status not in ('completed','partial','skipped') then raise exception 'Invalid training status'; end if;
  if v_session.day > (now() at time zone 'Europe/Warsaw')::date then raise exception 'Future training cannot be completed early'; end if;
  if p_revision <> v_session.revision then raise exception 'Training was updated in another session. Refresh and try again.'; end if;
  if p_feedback is not null and (
      jsonb_typeof(p_feedback)<>'object' or
      length(coalesce(p_feedback->>'comment','')) > 1000 or
      (p_feedback ? 'difficulty' and p_feedback->>'difficulty' not in ('easy','good','hard')) or
      (p_feedback ? 'pain' and (jsonb_typeof(p_feedback->'pain') <> 'number' or
           (p_feedback->>'pain')::int not between 0 and 10)))
    then raise exception 'Invalid feedback'; end if;
  update public.training_sessions set status=p_status,feedback=p_feedback,revision=revision+1,
    submitted_at=now(),reviewed_at=null,updated_at=now()
    where id=p_session_id returning * into v_out;
  insert into public.audit_events(clinic_id,actor_id,action,entity_id)
    values(v_session.clinic_id,auth.uid(),'session.result_submitted',v_session.id);
  return v_out;
end; $$;

create function public.review_session(p_session_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare v_session public.training_sessions%rowtype;
begin
  select * into v_session from public.training_sessions where id=p_session_id;
  if v_session.id is null or not public.can_manage_patient(v_session.patient_id) then raise exception 'Not authorized'; end if;
  update public.training_sessions set reviewed_at=now() where id=p_session_id and submitted_at is not null;
end; $$;

create function public.pause_plan(p_plan_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare v_plan public.plans%rowtype;
begin
  select * into v_plan from public.plans where id=p_plan_id for update;
  if v_plan.id is null or not public.can_manage_patient(v_plan.patient_id) then raise exception 'Not authorized'; end if;
  update public.plans set status='paused' where id=p_plan_id;
  update public.training_sessions set status='cancelled',updated_at=now()
    where plan_id=p_plan_id and day >= (now() at time zone 'Europe/Warsaw')::date and status='scheduled';
  insert into public.audit_events(clinic_id,actor_id,action,entity_id)
    values(v_plan.clinic_id,auth.uid(),'plan.paused',v_plan.id);
end; $$;

-- New routines are callable only by authenticated users; RLS still applies to normal CRUD.
revoke all on function public.is_staff(uuid),public.is_owner(uuid),public.can_manage_patient(uuid),public.can_view_patient(uuid),public.can_read_video(text),public.claim_patient_invite(uuid),public.publish_plan(uuid),public.submit_session_result(uuid,text,jsonb,integer),public.review_session(uuid),public.pause_plan(uuid),public.get_my_active_plans() from public, anon;
grant execute on function public.is_staff(uuid),public.is_owner(uuid),public.can_manage_patient(uuid),public.can_view_patient(uuid),public.can_read_video(text),public.claim_patient_invite(uuid),public.publish_plan(uuid),public.submit_session_result(uuid,text,jsonb,integer),public.review_session(uuid),public.pause_plan(uuid),public.get_my_active_plans() to authenticated;
