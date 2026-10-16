<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { configured, supabase, formatDate, isoDate, dayShort, cloneDraft, message, statusLabels, sides, type Membership, type Patient, type Exercise, type ExerciseItem, type Draft, type Plan, type Training, type Template } from './lib'

type View = 'dashboard' | 'patients' | 'exercises' | 'templates' | 'plans' | 'today' | 'schedule' | 'history' | 'account'
type UserIdentity = { id: string; email: string }

const user = ref<UserIdentity | null>(null)
const memberships = ref<Membership[]>([])
const clinicId = ref('')
const clinicName = ref('')
const role = ref<'owner' | 'therapist' | 'patient' | ''>('')
const loading = ref(true)
const busy = ref(false)
const alert = ref('')
const alertKind = ref<'success' | 'error'>('success')
const view = ref<View>('dashboard')
const patients = ref<Patient[]>([])
const exercises = ref<Exercise[]>([])
const templates = ref<Template[]>([])
const plans = ref<Plan[]>([])
const sessions = ref<Training[]>([])
const myPatient = ref<Patient | null>(null)
const selectedPatientId = ref('')
const selectedSessionId = ref('')
const videoPath = ref('')
const videoUrl = ref('')
const videoTitle = ref('')
const videoLoading = ref(false)
const authMode = ref<'login' | 'signup' | 'reset'>('login')
const authEmail = ref('')
const authPassword = ref('')
const ownerOnSignup = ref(false)
const authNotice = ref('')
const passwordRecovery = ref(false)
const recoveryPassword = ref('')
const invitationToken = ref('')
const inviteLink = ref('')
const newPatient = reactive({ name: '', email: '' })
const patientSearch = ref('')
const exerciseSearch = ref('')
const exerciseEditor = ref(false)
const exerciseEditId = ref('')
const exerciseForm = reactive({ name: '', description: '', equipment: '', tags: '', file: null as File | null, video_path: '' as string | null })
const editingPlan = ref(false)
const editingPlanId = ref('')
const planForm = reactive({ patient_id: '', title: '', start_date: '', end_date: '', draft: {} as Draft })
const editingDay = ref('1')
const addExerciseId = ref('')
const newTemplateName = ref('')
const selectedSession = computed(() => sessions.value.find(s => s.id === selectedSessionId.value) || null)
const feedbackForm = reactive({ status: 'completed', difficulty: '', pain: '', comment: '', completed_exercises: [] as string[] })
const nowDate = ref(isoDate())
const staff = computed(() => role.value === 'owner' || role.value === 'therapist')
const selectedPatient = computed(() => patients.value.find(p => p.id === selectedPatientId.value) || null)
const selectedPlan = computed(() => plans.value.find(p => p.patient_id === selectedPatientId.value && p.status === 'active') || null)
const activePlan = computed(() => plans.value.find(p => p.status === 'active') || null)
const todaySession = computed(() => sessions.value.find(s => s.day === nowDate.value && s.status !== 'cancelled') || null)
const nextSession = computed(() => sessions.value.find(s => s.day > nowDate.value && s.status !== 'cancelled') || null)
const completedCount = computed(() => sessions.value.filter(s => s.status === 'completed').length)
const pendingFeedback = computed(() => sessions.value.filter(s => s.feedback && s.submitted_at && !s.reviewed_at).length)
const filteredPatients = computed(() => patients.value.filter(p => `${p.name} ${p.email}`.toLowerCase().includes(patientSearch.value.toLowerCase())))
const filteredExercises = computed(() => exercises.value.filter(e => !e.archived && `${e.name} ${e.equipment} ${(e.tags || []).join(' ')}`.toLowerCase().includes(exerciseSearch.value.toLowerCase())))
const patientSessions = computed(() => sessions.value.filter(s => s.patient_id === selectedPatientId.value && s.status !== 'cancelled'))
const pastSessions = computed(() => sessions.value.filter(s => s.day <= nowDate.value && s.status !== 'cancelled'))
const authReady = computed(() => !!user.value && !!role.value)
const activeDays = computed(() => Object.entries(planForm.draft).filter(([, items]) => items.length > 0).length)
const weekdays = [{ key: '1', label: 'Poniedziałek' }, { key: '2', label: 'Wtorek' }, { key: '3', label: 'Środa' }, { key: '4', label: 'Czwartek' }, { key: '5', label: 'Piątek' }, { key: '6', label: 'Sobota' }, { key: '0', label: 'Niedziela' }]
const navStaff: { id: View; label: string }[] = [{ id: 'dashboard', label: 'Pulpit' }, { id: 'patients', label: 'Klienci' }, { id: 'exercises', label: 'Biblioteka ćwiczeń' }, { id: 'templates', label: 'Szablony' }, { id: 'plans', label: 'Plany treningowe' }, { id: 'account', label: 'Ustawienia' }]
const navPatient: { id: View; label: string }[] = [{ id: 'today', label: 'Dzisiaj' }, { id: 'schedule', label: 'Mój plan' }, { id: 'history', label: 'Historia' }, { id: 'account', label: 'Konto' }]

function notify(text: string, kind: 'success' | 'error' = 'success') { alert.value = text; alertKind.value = kind }
function errorNotice(error: unknown) { notify(message(error), 'error') }
function firstName(name: string) { return name.trim().split(' ')[0] || name }
function dateOffset(days: number) { const d = new Date(`${isoDate()}T12:00:00Z`); d.setUTCDate(d.getUTCDate() + days); return d.toISOString().slice(0,10) }
function itemSummary(i: ExerciseItem) { return `${i.sets} × ${i.duration ? `${i.duration} sek.` : `${i.reps} powt.`}${i.side && i.side !== 'none' ? ` · ${sides[i.side]}` : ''}` }
function titleForPatient(id: string) { return patients.value.find(p => p.id === id)?.name || 'Klient' }
function statusLabel(status: string) { return statusLabels[status] || status }
function getDraftDay(day: string): ExerciseItem[] { return planForm.draft[day] || [] }
function selectView(next: View) { view.value = next; alert.value = ''; editingPlan.value = false; exerciseEditor.value = false; selectedSessionId.value = ''; inviteLink.value = '' }
function selectPatient(id: string) { selectedPatientId.value = id; view.value = 'patients' }

function resolveActiveMembership(): Membership | null {
  if (!memberships.value.length) return null
  const orderedMemberships = [...memberships.value].sort((a, b) => {
    const aRole = a.role === 'owner' ? 2 : a.role === 'therapist' ? 1 : 0
    const bRole = b.role === 'owner' ? 2 : b.role === 'therapist' ? 1 : 0
    if (aRole !== bRole) return bRole - aRole
    const aTime = new Date(a.created_at || '1970-01-01T00:00:00Z').getTime()
    const bTime = new Date(b.created_at || '1970-01-01T00:00:00Z').getTime()
    return bTime - aTime
  })
  return orderedMemberships[0] || null
}

async function refreshIdentity() {
  loading.value = true
  try {
    const { data, error } = await supabase.auth.getUser()
    if (error && error.name !== 'AuthSessionMissingError') throw error
    user.value = data.user ? { id: data.user.id, email: data.user.email || '' } : null
    if (!user.value) { memberships.value = []; role.value = ''; return }
    const token = invitationToken.value || sessionStorage.getItem('physioplan-invite') || ''
    if (token) {
      const { error: claimError } = await supabase.rpc('claim_patient_invite', { p_token: token })
      if (!claimError) {
        invitationToken.value = ''; sessionStorage.removeItem('physioplan-invite')
        history.replaceState(null, '', location.pathname)
        notify('Zaproszenie przyjęte. Twoje konto jest gotowe.')
      } else {
        errorNotice(claimError)
      }
    }
    const result = await supabase.from('memberships').select('clinic_id, role, created_at, clinics(name)').eq('user_id', user.value.id)
    if (result.error) throw result.error
    memberships.value = (result.data || []) as unknown as Membership[]
    const membership = resolveActiveMembership()
    if (!membership) { role.value = ''; clinicId.value = ''; clinicName.value = ''; return }
    clinicId.value = membership.clinic_id
    clinicName.value = membership.clinics?.name || 'PhysioPlan'
    role.value = membership.role
    await loadData()
    if (!staff.value) view.value = 'today'
  } catch (error) { errorNotice(error) }
  finally { loading.value = false }
}

async function loadData() {
  if (!clinicId.value) return
  if (staff.value) {
    const [p, e, t, pl, s] = await Promise.all([
      supabase.from('patients').select('*').eq('clinic_id', clinicId.value).order('created_at', { ascending: false }),
      supabase.from('exercises').select('*').eq('clinic_id', clinicId.value).order('name'),
      supabase.from('workout_templates').select('*').eq('clinic_id', clinicId.value).order('name'),
      supabase.from('plans').select('*').eq('clinic_id', clinicId.value).order('created_at', { ascending: false }),
      supabase.from('training_sessions').select('*').eq('clinic_id', clinicId.value).order('day', { ascending: false }).limit(1000)
    ])
    for (const result of [p, e, t, pl, s]) if (result.error) throw result.error
    patients.value = (p.data || []) as Patient[]
    exercises.value = (e.data || []) as Exercise[]
    templates.value = (t.data || []) as Template[]
    plans.value = (pl.data || []) as Plan[]
    sessions.value = (s.data || []) as Training[]
    if (!selectedPatientId.value && patients.value.length) selectedPatientId.value = patients.value[0].id
  } else {
    const p = await supabase.from('patients').select('*').eq('user_id', user.value!.id).eq('clinic_id', clinicId.value).maybeSingle()
    if (p.error) throw p.error
    myPatient.value = (p.data || null) as Patient | null
    const [s, pl] = await Promise.all([
      supabase.from('training_sessions').select('*').eq('patient_id', myPatient.value?.id || '00000000-0000-0000-0000-000000000000').order('day', { ascending: true }),
      supabase.rpc('get_my_active_plans')
    ])
    if (s.error) throw s.error
    if (pl.error) throw pl.error
    sessions.value = (s.data || []) as Training[]
    plans.value = (pl.data || []) as Plan[]
  }
}
async function reload() { try { await loadData() } catch (error) { errorNotice(error) } }

async function ensureOwnerMembership() {
  const { error } = await supabase.rpc('ensure_owner_membership', { p_clinic_name: 'My Physio Studio' })
  if (error) throw error
}

async function createOwnerClinic() {
  if (!user.value) return
  busy.value = true
  try {
    await ensureOwnerMembership()
    await refreshIdentity()
    notify('Gabinet został utworzony. Możesz teraz zarządzać klientami.')
  } catch (error) { errorNotice(error) }
  finally { busy.value = false }
}

async function logIn() {
  if (busy.value) return
  busy.value = true; authNotice.value = ''
  try {
    if (authMode.value === 'reset') {
      const { error } = await supabase.auth.resetPasswordForEmail(authEmail.value.trim(), { redirectTo: location.origin })
      if (error) throw error
      authNotice.value = 'Jeśli konto istnieje, otrzymasz wiadomość z linkiem.'
    } else if (authMode.value === 'signup') {
      const { error } = await supabase.auth.signUp({
        email: authEmail.value.trim(),
        password: authPassword.value,
        options: {
          emailRedirectTo: location.origin,
          data: { is_owner: ownerOnSignup.value }
        }
      })
      if (error) throw error

      if (ownerOnSignup.value) {
        const { data: userData, error: userError } = await supabase.auth.getUser()
        if (userError && userError.name !== 'AuthSessionMissingError') throw userError
        if (userData.user) {
          await ensureOwnerMembership()
          authNotice.value = 'Konto właściciela utworzone. Teraz możesz korzystać z aplikacji.'
        } else {
          authNotice.value = 'Konto utworzone. Potwierdź e-mail, zaloguj się, a konto właściciela zostanie przypisane automatycznie.'
        }
      } else {
        authNotice.value = 'Sprawdź pocztę i potwierdź adres e-mail, następnie zaloguj się.'
      }
    } else {
      const { data, error } = await supabase.auth.signInWithPassword({ email: authEmail.value.trim(), password: authPassword.value })
      if (error) throw error
      if (data.user?.user_metadata?.is_owner === true) {
        await ensureOwnerMembership()
      }
      await refreshIdentity()
    }
  } catch (error) { errorNotice(error) }
  finally { busy.value = false }
}
async function updatePassword() {
  if (recoveryPassword.value.length < 8) { notify('Hasło musi mieć co najmniej 8 znaków.', 'error'); return }
  busy.value = true
  try { const { error } = await supabase.auth.updateUser({ password: recoveryPassword.value }); if (error) throw error; passwordRecovery.value = false; recoveryPassword.value = ''; notify('Hasło zostało zmienione.') }
  catch (error) { errorNotice(error) } finally { busy.value = false }
}
async function logOut() { await supabase.auth.signOut(); user.value = null; role.value = ''; clinicId.value = ''; view.value = 'dashboard'; selectedSessionId.value = ''; sessionStorage.removeItem('physioplan-invite'); notify('Wylogowano') }
async function sendPasswordReset() {
  if (!user.value?.email) return
  busy.value = true
  try { const { error } = await supabase.auth.resetPasswordForEmail(user.value.email, { redirectTo: location.origin }); if (error) throw error; notify('Wysłaliśmy wiadomość z instrukcją zmiany hasła.') }
  catch (error) { errorNotice(error) } finally { busy.value = false }
}

async function createPatient() {
  if (!newPatient.name.trim() || !newPatient.email.trim() || !user.value) return
  const selectedMembership = resolveActiveMembership()
  if (!selectedMembership) {
    notify('Brak przypisanego gabinetu. Utwórz gabinet jako właściciel.', 'error')
    return
  }
  if (!['owner', 'therapist'].includes(selectedMembership.role)) {
    notify('Twoje konto nie ma uprawnień do dodawania klientów.', 'error')
    return
  }
  clinicId.value = selectedMembership.clinic_id
  clinicName.value = selectedMembership.clinics?.name || clinicName.value || 'PhysioPlan'

  busy.value = true
  try {
    const { data, error } = await supabase.rpc('create_patient_for_clinic', {
      p_clinic_id: clinicId.value,
      p_name: newPatient.name.trim(),
      p_email: newPatient.email.trim().toLowerCase()
    })
    if (error) throw error

    const patient = data as Patient
    await generateInvite(patient)
    newPatient.name = ''; newPatient.email = ''
    await loadData()
    selectedPatientId.value = patient.id
    notify('Klient dodany. Skopiuj link zaproszenia i wyślij go klientowi.')
  } catch (error) { errorNotice(error) }
  finally { busy.value = false }
}
async function generateInvite(patient: Patient) {
  if (patient.user_id) { notify('Ten klient ma już aktywne konto.', 'error'); return }
  const { data, error } = await supabase.from('invitations').insert({ clinic_id: clinicId.value, patient_id: patient.id, email: patient.email.toLowerCase(), created_by: user.value!.id }).select('token').single()
  if (error) throw error
  inviteLink.value = `${location.origin}/?invite=${data.token}`
}
async function renewInvite(patient: Patient) { try { await generateInvite(patient); notify('Nowy link zaproszenia jest gotowy.') } catch (error) { errorNotice(error) } }
async function copyInvite() { if (!inviteLink.value) return; try { await navigator.clipboard.writeText(inviteLink.value); notify('Link skopiowany.') } catch { notify('Zaznacz link i skopiuj ręcznie.', 'error') } }

function openExercise(exercise?: Exercise) {
  exerciseEditId.value = exercise?.id || ''
  exerciseForm.name = exercise?.name || ''
  exerciseForm.description = exercise?.description || ''
  exerciseForm.equipment = exercise?.equipment || ''
  exerciseForm.tags = (exercise?.tags || []).join(', ')
  exerciseForm.video_path = exercise?.video_path || null
  exerciseForm.file = null
  exerciseEditor.value = true
}
function setVideoFile(event: Event) { exerciseForm.file = (event.target as HTMLInputElement).files?.[0] || null }
async function saveExercise() {
  if (!exerciseForm.name.trim()) return
  busy.value = true
  try {
    const id = exerciseEditId.value || crypto.randomUUID()
    let path = exerciseForm.video_path
    if (exerciseForm.file) {
      const file = exerciseForm.file
      if (file.type !== 'video/mp4' || !file.name.toLowerCase().endsWith('.mp4')) throw new Error('Wybierz film MP4 (H.264/AAC).')
      if (file.size > 50 * 1024 * 1024) throw new Error('Film może mieć maksymalnie 50 MB.')
      path = `${clinicId.value}/${id}/${crypto.randomUUID()}.mp4`
      const result = await supabase.storage.from('exercise-videos').upload(path, file, { contentType: 'video/mp4', upsert: false })
      if (result.error) throw result.error
    }
    const payload = { id, clinic_id: clinicId.value, name: exerciseForm.name.trim(), description: exerciseForm.description.trim(), equipment: exerciseForm.equipment.trim(), tags: exerciseForm.tags.split(',').map(t => t.trim()).filter(Boolean), video_path: path }
    const result = exerciseEditId.value ? await supabase.from('exercises').update({ name: payload.name, description: payload.description, equipment: payload.equipment, tags: payload.tags, video_path: payload.video_path }).eq('id', id) : await supabase.from('exercises').insert(payload)
    if (result.error) throw result.error
    exerciseEditor.value = false
    notify('Ćwiczenie zapisane.')
    await loadData()
  } catch (error) { errorNotice(error) }
  finally { busy.value = false }
}
async function archiveExercise(exercise: Exercise) {
  if (!window.confirm(`Zarchiwizować ćwiczenie „${exercise.name}”?`)) return
  try { const { error } = await supabase.from('exercises').update({ archived: true }).eq('id', exercise.id); if (error) throw error; await loadData() } catch (error) { errorNotice(error) }
}
async function openVideo(path: string | null | undefined, title: string) {
  if (!path) { notify('Do tego ćwiczenia nie dodano filmu.', 'error'); return }
  videoPath.value = path; videoTitle.value = title; videoUrl.value = ''; videoLoading.value = true
  try {
    const { data, error } = await supabase.storage.from('exercise-videos').createSignedUrl(path, 600)
    if (error) throw error
    videoUrl.value = data.signedUrl
  } catch (error) { errorNotice(error); videoPath.value = '' }
  finally { videoLoading.value = false }
}

function resetPlan(patientId = selectedPatientId.value) {
  editingPlanId.value = ''; editingPlan.value = true
  planForm.patient_id = patientId
  planForm.title = 'Mój plan ćwiczeń'
  planForm.start_date = nowDate.value
  planForm.end_date = dateOffset(27)
  planForm.draft = {}
  editingDay.value = '1'
  view.value = 'plans'
}
function editExistingPlan(plan: Plan) {
  editingPlanId.value = plan.id; editingPlan.value = true; view.value = 'plans'
  planForm.patient_id = plan.patient_id
  planForm.title = plan.title
  planForm.start_date = plan.start_date
  planForm.end_date = plan.end_date
  planForm.draft = cloneDraft(plan.draft)
  editingDay.value = Object.keys(plan.draft).find(k => plan.draft[k]?.length) || '1'
}
function createItem(exercise: Exercise): ExerciseItem {
  return { exercise_id: exercise.id, name: exercise.name, description: exercise.description, equipment: exercise.equipment, video_path: exercise.video_path, sets: 3, reps: 10, duration: null, rest: 30, side: 'none', note: '' }
}
function addExerciseToDay() {
  const exercise = exercises.value.find(e => e.id === addExerciseId.value)
  if (!exercise) return
  if (!planForm.draft[editingDay.value]) planForm.draft[editingDay.value] = []
  planForm.draft[editingDay.value].push(createItem(exercise))
  addExerciseId.value = ''
}
function removeItem(index: number) { planForm.draft[editingDay.value]?.splice(index, 1) }
function moveItem(index: number, direction: number) {
  const items = planForm.draft[editingDay.value]
  const next = index + direction
  if (!items || next < 0 || next >= items.length) return
  ;[items[index], items[next]] = [items[next], items[index]]
}
async function savePlan(publish = false) {
  if (!planForm.patient_id || !planForm.title.trim()) return
  if (planForm.end_date < planForm.start_date) { notify('Data zakończenia musi być późniejsza niż początek.', 'error'); return }
  busy.value = true
  try {
    const normalizedDraft = cloneDraft(planForm.draft)
    for (const items of Object.values(normalizedDraft)) {
      for (const item of items) {
        item.sets = Number(item.sets)
        item.rest = Number(item.rest || 0)
        item.duration = item.duration ? Number(item.duration) : null
        item.reps = item.duration ? null : (item.reps ? Number(item.reps) : null)
      }
    }
    const payload = { clinic_id: clinicId.value, patient_id: planForm.patient_id, title: planForm.title.trim(), start_date: planForm.start_date, end_date: planForm.end_date, draft: normalizedDraft }
    const result = editingPlanId.value ? await supabase.from('plans').update({ title: payload.title, start_date: payload.start_date, end_date: payload.end_date, draft: payload.draft }).eq('id', editingPlanId.value).select('id').single() : await supabase.from('plans').insert(payload).select('id').single()
    if (result.error) throw result.error
    editingPlanId.value = result.data.id
    if (publish) {
      const rpc = await supabase.rpc('publish_plan', { p_plan_id: result.data.id })
      if (rpc.error) throw rpc.error
    }
    editingPlan.value = false
    selectedPatientId.value = planForm.patient_id
    await loadData()
    notify(publish ? 'Plan opublikowany. Klient może zobaczyć treningi.' : 'Wersja robocza zapisana.')
  } catch (error) { errorNotice(error) }
  finally { busy.value = false }
}
async function pausePlan(plan: Plan) {
  if (!window.confirm('Wstrzymać plan i anulować przyszłe treningi?')) return
  busy.value = true
  try { const { error } = await supabase.rpc('pause_plan', { p_plan_id: plan.id }); if (error) throw error; await loadData(); notify('Plan wstrzymany.') }
  catch (error) { errorNotice(error) } finally { busy.value = false }
}
async function saveTemplate() {
  if (!newTemplateName.value.trim() || !getDraftDay(editingDay.value).length) { notify('Podaj nazwę i dodaj ćwiczenia.', 'error'); return }
  try {
    const { error } = await supabase.from('workout_templates').insert({ clinic_id: clinicId.value, name: newTemplateName.value.trim(), workout: cloneDraft({ workout: getDraftDay(editingDay.value) }).workout })
    if (error) throw error
    newTemplateName.value = ''; await loadData(); notify('Szablon zapisany.')
  } catch (error) { errorNotice(error) }
}
function insertTemplate(id: string) {
  const template = templates.value.find(t => t.id === id)
  if (!template) return
  planForm.draft[editingDay.value] = JSON.parse(JSON.stringify(template.workout)) as ExerciseItem[]
  notify('Szablon wstawiony do wybranego dnia.')
}
async function deleteTemplate(id: string) {
  if (!window.confirm('Usunąć szablon?')) return
  try { const { error } = await supabase.from('workout_templates').delete().eq('id', id); if (error) throw error; await loadData() } catch (error) { errorNotice(error) }
}

function openSession(session: Training) {
  selectedSessionId.value = session.id
  feedbackForm.status = ['completed','partial','skipped'].includes(session.status) ? session.status : 'completed'
  feedbackForm.difficulty = session.feedback?.difficulty || ''
  feedbackForm.pain = session.feedback?.pain === 0 || session.feedback?.pain ? String(session.feedback.pain) : ''
  feedbackForm.comment = session.feedback?.comment || ''
  feedbackForm.completed_exercises = [...(session.feedback?.completed_exercises || [])]
}
function toggleCompletedExercise(id: string, checked: boolean) {
  if (checked && !feedbackForm.completed_exercises.includes(id)) feedbackForm.completed_exercises.push(id)
  if (!checked) feedbackForm.completed_exercises = feedbackForm.completed_exercises.filter(i => i !== id)
}
async function submitTraining() {
  if (!selectedSession.value) return
  busy.value = true
  try {
    const feedback: Record<string, unknown> = { comment: feedbackForm.comment.trim() }
    if (feedbackForm.difficulty) feedback.difficulty = feedbackForm.difficulty
    if (feedbackForm.pain !== '') feedback.pain = Number(feedbackForm.pain)
    if (feedbackForm.status === 'partial') feedback.completed_exercises = feedbackForm.completed_exercises
    const { error } = await supabase.rpc('submit_session_result', { p_session_id: selectedSession.value.id, p_status: feedbackForm.status, p_feedback: feedback, p_revision: selectedSession.value.revision })
    if (error) throw error
    selectedSessionId.value = ''; await loadData(); notify('Trening zapisany. Dziękujemy za informację zwrotną.')
  } catch (error) { errorNotice(error); await reload() }
  finally { busy.value = false }
}
async function reviewSession(session: Training) {
  busy.value = true
  try { const { error } = await supabase.rpc('review_session', { p_session_id: session.id }); if (error) throw error; await loadData(); notify('Feedback oznaczony jako przejrzany.') }
  catch (error) { errorNotice(error) } finally { busy.value = false }
}
const displaySessions = computed(() => staff.value ? patientSessions.value : sessions.value.filter(s => s.status !== 'cancelled'))

onMounted(async () => {
  const token = new URLSearchParams(location.search).get('invite')
  if (token && /^[0-9a-f-]{36}$/i.test(token)) { invitationToken.value = token; sessionStorage.setItem('physioplan-invite',token) }
  if (configured) {
    if (location.hash.includes('type=recovery')) passwordRecovery.value = true
    supabase.auth.onAuthStateChange((event) => {
      if (event === 'PASSWORD_RECOVERY') passwordRecovery.value = true
      if (event === 'SIGNED_OUT') { user.value = null; role.value = ''; clinicId.value = ''; passwordRecovery.value = false }
      // Allow the initial load or explicit sign-in to do the database work.
    })
    await refreshIdentity()
  } else loading.value = false
})
watch(selectedPatientId, () => { selectedSessionId.value = '' })
</script>

<template>
  <div class="site-shell">
    <div v-if="alert" class="toast" :class="alertKind" role="status"><span>{{ alert }}</span><button aria-label="Zamknij komunikat" @click="alert = ''">Zamknij</button></div>
    <div v-if="loading" class="center-stage"><div class="brand-logo">p<span>.</span></div><p>Ładowanie PhysioPlan...</p></div>

    <div v-else-if="!configured" class="center-stage setup-screen">
      <div class="brand-logo">p<span>.</span></div>
      <div class="eyebrow">PHYSIOPLAN</div>
      <h1>Twoja aplikacja<br>jest gotowa do podłączenia.</h1>
      <p>Skonfiguruj bezpłatny projekt Supabase i dwie zmienne środowiskowe. Instrukcja znajduje się w pliku <code>README.md</code>.</p>
      <div class="setup-steps"><span>1. Supabase</span><span>2. GitHub</span><span>3. Cloudflare Pages</span></div>
    </div>

    <div v-else-if="!user" class="auth-layout">
      <section class="auth-brand">
        <div class="brand-lockup"><div class="brand-logo">p<span>.</span></div><span>physioplan</span></div>
        <div class="auth-intro"><div class="eyebrow light">ZADBAJ O KAŻDY RUCH</div><h1>Lepsza rehabilitacja zaczyna się od planu.</h1><p>Ćwiczenia, nagrania i postępy. Wszystko w jednym, prostym miejscu.</p></div>
        <div class="auth-footer">Przestrzeń fizjoterapeuty i jego klientów</div>
      </section>
      <section class="auth-panel">
        <div class="auth-box">
          <div class="eyebrow">WITAJ W PHYSIOPLAN</div>
          <h2>{{ authMode === 'login' ? 'Zaloguj się' : authMode === 'signup' ? 'Utwórz konto' : 'Odzyskaj hasło' }}</h2>
          <p class="muted">{{ invitationToken ? 'Otrzymano zaproszenie. Użyj adresu e-mail, na który zostało wystawione.' : 'Twój plan, Twój rytm, Twoje postępy.' }}</p>
          <form class="form-stack" @submit.prevent="logIn">
            <label>Adres e-mail<input v-model="authEmail" type="email" placeholder="name@example.com" required autocomplete="email"></label>
            <label v-if="authMode !== 'reset'">Hasło<input v-model="authPassword" type="password" placeholder="Minimum 8 znaków" required minlength="8" :autocomplete="authMode === 'signup' ? 'new-password' : 'current-password'"></label>
            <label v-if="authMode === 'signup'" class="check-row"><input v-model="ownerOnSignup" type="checkbox"> Jestem właścicielem i chcę od razu utworzyć gabinet</label>
            <p v-if="authNotice" class="note success-note">{{ authNotice }}</p>
            <button type="submit" class="btn primary full" :disabled="busy">{{ busy ? 'Proszę czekać...' : authMode === 'login' ? 'Zaloguj się' : authMode === 'signup' ? 'Załóż konto' : 'Wyślij link' }}</button>
          </form>
          <div class="auth-links">
            <button v-if="authMode !== 'login'" @click="authMode = 'login'; authNotice = ''">Mam konto. Zaloguj się</button>
            <button v-if="authMode === 'login'" @click="authMode = 'signup'; authNotice = ''">Załóż konto</button>
            <button v-if="authMode === 'login'" @click="authMode = 'reset'; authNotice = ''">Nie pamiętam hasła</button>
          </div>
          <p class="small-muted">Utworzenie konta nie przyznaje dostępu do danych gabinetu. Dostęp otrzymasz po zaproszeniu.</p>
        </div>
      </section>
    </div>

    <div v-else-if="passwordRecovery" class="center-stage onboarding"><div class="brand-logo">p<span>.</span></div><h1>Ustaw nowe hasło</h1><form class="form-stack" style="width:min(350px,100%)" @submit.prevent="updatePassword"><label>Nowe hasło<input v-model="recoveryPassword" type="password" required minlength="8" autocomplete="new-password"></label><button class="btn primary full" :disabled="busy">Zapisz nowe hasło</button></form></div>

    <div v-else-if="!authReady" class="center-stage onboarding">
      <div class="brand-logo">p<span>.</span></div>
      <h1>Twoje konto jest aktywne.</h1>
      <p>Nie masz jeszcze przypisanego gabinetu. Jeśli jesteś klientem, otwórz link z zaproszenia na tym urządzeniu. Jeśli zakładasz gabinet, utwórz go od razu poniżej.</p>
      <p class="small-muted">Zalogowano jako {{ user.email }}</p>
      <div class="row-actions">
        <button class="btn primary" :disabled="busy" @click="createOwnerClinic">Utwórz gabinet jako właściciel</button>
        <button class="btn outline" @click="refreshIdentity">Sprawdź ponownie</button>
        <button class="btn subtle" @click="logOut">Wyloguj się</button>
      </div>
    </div>

    <div v-else class="app-layout">
      <aside class="sidebar">
        <button class="brand-lockup sidebar-brand" @click="selectView(staff ? 'dashboard' : 'today')"><div class="brand-logo">p<span>.</span></div><span>physioplan</span></button>
        <div class="sidebar-clinic"><div class="clinic-avatar">{{ clinicName.slice(0, 2).toUpperCase() }}</div><div><strong>{{ clinicName }}</strong><small>{{ staff ? 'Panel fizjoterapeuty' : 'Strefa klienta' }}</small></div></div>
        <div class="sidebar-menu-label">MENU GŁÓWNE</div>
        <nav class="sidebar-nav" aria-label="Menu główne">
          <button v-for="item in (staff ? navStaff : navPatient)" :key="item.id" class="nav-link" :class="{ active: view === item.id }" @click="selectView(item.id)"><span>{{ item.label }}</span><span v-if="item.id === 'dashboard' && pendingFeedback" class="nav-count">{{ pendingFeedback }}</span></button>
        </nav>
        <div class="sidebar-bottom"><div class="profile-avatar">{{ (user.email[0] || 'U').toUpperCase() }}</div><div class="profile-info"><strong>{{ user.email.split('@')[0] }}</strong><small>{{ role === 'owner' ? 'Właściciel' : role === 'therapist' ? 'Fizjoterapeuta' : 'Klient' }}</small></div><button class="text-button" @click="logOut">Wyjdź</button></div>
      </aside>
      <main class="main-content">
        <header class="topbar"><div class="breadcrumb">PHYSIOPLAN <span>/</span> {{ (staff ? navStaff : navPatient).find(n => n.id === view)?.label || 'Trening' }}</div><div class="topbar-right"><span class="live-indicator"></span><span>{{ clinicName }}</span></div></header>

        <template v-if="staff">
          <section v-if="view === 'dashboard'" class="content-page">
            <div class="page-heading"><div><div class="eyebrow">PANEL FIZJOTERAPEUTY</div><h1>Dzień dobry!</h1><p>Zobacz, co dzieje się z planami Twoich klientów.</p></div><button class="btn primary" @click="selectView('patients')">Przejdź do klientów</button></div>
            <div class="stat-grid"><div class="stat-card"><span>Aktywni klienci</span><strong>{{ patients.length }}</strong><small>W Twojej opiece</small></div><div class="stat-card"><span>Plany aktywne</span><strong>{{ plans.filter(p => p.status === 'active').length }}</strong><small>Opublikowane plany</small></div><div class="stat-card"><span>Wykonane treningi</span><strong>{{ completedCount }}</strong><small>Potwierdzone przez klientów</small></div><div class="stat-card highlight"><span>Feedback do sprawdzenia</span><strong>{{ pendingFeedback }}</strong><small>Wpisy wymagające przeglądu</small></div></div>
            <div class="two-col"><section class="panel"><div class="panel-heading"><h2>Ostatnia aktywność</h2><span class="small-muted">Aktualizacje od klientów</span></div><div v-if="!sessions.filter(s => s.submitted_at).length" class="empty-inline">Nie ma jeszcze aktywności klientów.</div><div v-for="s in sessions.filter(s => s.submitted_at).slice(0, 7)" :key="s.id" class="activity-row"><div class="circle-initial">{{ titleForPatient(s.patient_id).slice(0,1) }}</div><div class="activity-copy"><strong>{{ titleForPatient(s.patient_id) }}</strong><span>{{ statusLabel(s.status) }} · {{ formatDate(s.day) }}</span></div><span class="status-pill" :class="s.status">{{ statusLabel(s.status) }}</span></div></section>
            <section class="panel"><div class="panel-heading"><h2>Nowy feedback</h2><span class="small-muted">Warto sprawdzić</span></div><div v-if="!pendingFeedback" class="empty-inline">Wszystkie zgłoszenia są przejrzane.</div><div v-for="s in sessions.filter(s => s.feedback && s.submitted_at && !s.reviewed_at).slice(0, 6)" :key="s.id" class="feedback-tile"><div><strong>{{ titleForPatient(s.patient_id) }}</strong><span>{{ formatDate(s.day) }} · Ból: {{ s.feedback?.pain ?? 'brak danych' }}/10</span><p>{{ s.feedback?.comment || 'Bez komentarza' }}</p></div><button class="btn small outline" :disabled="busy" @click="reviewSession(s)">Przejrzano</button></div></section></div>
          </section>

          <section v-else-if="view === 'patients'" class="content-page">
            <div class="page-heading"><div><div class="eyebrow">TWOJA PRAKTYKA</div><h1>Klienci</h1><p>Zarządzaj klientami, ich planami i postępami.</p></div></div>
            <div class="two-col patient-grid"><section class="panel"><div class="panel-heading"><h2>Lista klientów</h2><span class="number-chip">{{ patients.length }}</span></div><input v-model="patientSearch" class="search-input" placeholder="Szukaj po imieniu lub e-mailu..."><div v-if="!filteredPatients.length" class="empty-inline">Brak klientów. Dodaj pierwszą osobę poniżej.</div><button v-for="p in filteredPatients" :key="p.id" class="patient-list-item" :class="{ selected: p.id === selectedPatientId }" @click="selectedPatientId = p.id"><span class="circle-initial">{{ p.name.slice(0, 1).toUpperCase() }}</span><span><strong>{{ p.name }}</strong><small>{{ p.email }}</small></span><span class="tiny-arrow">Szczegóły</span></button><div class="panel-subsection"><h3>Dodaj klienta</h3><form class="form-stack compact" @submit.prevent="createPatient"><label>Imię i nazwisko<input v-model="newPatient.name" required minlength="2" placeholder="Anna Nowak"></label><label>Adres e-mail<input v-model="newPatient.email" required type="email" placeholder="anna@example.com"></label><button class="btn primary full" :disabled="busy">Utwórz i wygeneruj zaproszenie</button></form></div></section>
            <section class="panel" v-if="selectedPatient"><div class="profile-head"><div class="profile-big-avatar">{{ selectedPatient.name.slice(0,1).toUpperCase() }}</div><div><div class="eyebrow">PROFIL KLIENTA</div><h2>{{ selectedPatient.name }}</h2><p>{{ selectedPatient.email }}</p></div></div><div class="info-line"><span>Stan konta</span><span class="status-pill" :class="selectedPatient.user_id ? 'completed' : 'scheduled'">{{ selectedPatient.user_id ? 'Aktywne' : 'Oczekuje na zaproszenie' }}</span></div><div class="info-line"><span>Plan</span><strong>{{ selectedPlan?.title || 'Brak aktywnego planu' }}</strong></div><div class="info-line"><span>Wykonane treningi</span><strong>{{ patientSessions.filter(s => s.status === 'completed').length }}</strong></div><div class="row-actions"><button class="btn primary" @click="resetPlan(selectedPatientId)">Nowy plan</button><button v-if="selectedPlan" class="btn outline" @click="editExistingPlan(selectedPlan)">Edytuj plan</button><button v-if="!selectedPatient.user_id" class="btn subtle" @click="renewInvite(selectedPatient)">Nowe zaproszenie</button></div><div v-if="inviteLink" class="invite-box"><h3>Link zaproszenia</h3><p>Wyślij ten link na przypisany adres klienta. Link działa przez 14 dni.</p><input readonly :value="inviteLink"><button class="btn primary small" @click="copyInvite">Kopiuj link</button></div><div class="panel-subsection"><h3>Ostatnie treningi</h3><div v-if="!patientSessions.length" class="empty-inline">Brak zapisanych treningów.</div><div v-for="s in patientSessions.slice(0,8)" :key="s.id" class="session-list-row"><span>{{ formatDate(s.day) }}</span><span class="status-pill" :class="s.status">{{ statusLabel(s.status) }}</span><span class="small-muted">{{ s.feedback?.comment || '' }}</span></div></div></section><section v-else class="panel empty-panel"><h2>Wybierz klienta</h2><p>Jego szczegóły pojawią się tutaj.</p></section></div>
          </section>

          <section v-else-if="view === 'exercises'" class="content-page">
            <div class="page-heading"><div><div class="eyebrow">BAZA WIEDZY</div><h1>Biblioteka ćwiczeń</h1><p>Twoje nagrania i instrukcje gotowe do użycia w planach.</p></div><button class="btn primary" @click="openExercise()">Dodaj ćwiczenie</button></div>
            <div v-if="exerciseEditor" class="panel editor-panel"><div class="panel-heading"><h2>{{ exerciseEditId ? 'Edytuj ćwiczenie' : 'Nowe ćwiczenie' }}</h2><button class="text-button" @click="exerciseEditor = false">Zamknij</button></div><form class="form-grid" @submit.prevent="saveExercise"><label>Nazwa ćwiczenia<input v-model="exerciseForm.name" required minlength="2" placeholder="Most biodrowy"></label><label>Sprzęt<input v-model="exerciseForm.equipment" placeholder="Mata, guma"></label><label class="wide">Opis wykonania<textarea v-model="exerciseForm.description" rows="4" placeholder="Pozycja początkowa, ruch, na co zwrócić uwagę..."></textarea></label><label>Tagi (oddziel przecinkami)<input v-model="exerciseForm.tags" placeholder="biodra, stabilizacja"></label><label>Film MP4, maksymalnie 50 MB<input type="file" accept="video/mp4,.mp4" @change="setVideoFile"></label><p class="small-muted wide">Używaj wideo H.264/AAC. Nowe nagranie nie nadpisuje starszego pliku w opublikowanych planach.</p><div class="row-actions wide"><button class="btn primary" :disabled="busy">{{ busy ? 'Zapisywanie...' : 'Zapisz ćwiczenie' }}</button><button type="button" class="btn outline" @click="exerciseEditor = false">Anuluj</button></div></form></div>
            <div class="search-row"><input v-model="exerciseSearch" class="search-input" placeholder="Szukaj ćwiczenia..."><span class="small-muted">{{ filteredExercises.length }} ćwiczeń</span></div><div class="exercise-grid"><div v-for="e in filteredExercises" :key="e.id" class="exercise-card"><div class="exercise-cover"><div class="cover-monogram">{{ e.name.slice(0,1).toUpperCase() }}</div><span class="media-label">{{ e.video_path ? 'WIDEO MP4' : 'BEZ FILMU' }}</span></div><div class="exercise-card-body"><div class="tag-row"><span v-for="tag in (e.tags || []).slice(0,2)" :key="tag" class="tag">{{ tag }}</span></div><h3>{{ e.name }}</h3><p>{{ e.description || 'Brak opisu ćwiczenia.' }}</p><small>{{ e.equipment || 'Bez sprzętu' }}</small><div class="exercise-actions"><button v-if="e.video_path" class="btn subtle small" @click="openVideo(e.video_path, e.name)">Odtwórz</button><button class="btn outline small" @click="openExercise(e)">Edytuj</button><button class="text-button danger" @click="archiveExercise(e)">Archiwizuj</button></div></div></div><div v-if="!filteredExercises.length" class="panel empty-panel"><h2>Twoja biblioteka jest pusta</h2><p>Dodaj pierwsze ćwiczenie wraz z nagraniem.</p></div></div>
          </section>

          <section v-else-if="view === 'templates'" class="content-page"><div class="page-heading"><div><div class="eyebrow">GOTOWE ZESTAWY</div><h1>Szablony treningów</h1><p>Zapisuj zestawy podczas edycji planu i używaj ich ponownie.</p></div><button class="btn primary" @click="resetPlan()">Utwórz plan</button></div><div class="template-grid"><div v-for="t in templates" :key="t.id" class="panel template-card"><div class="eyebrow">SZABLON TRENINGU</div><h2>{{ t.name }}</h2><p>{{ t.workout.length }} ćwiczeń</p><ol><li v-for="i in t.workout.slice(0,5)" :key="i.exercise_id">{{ i.name }} · {{ itemSummary(i) }}</li></ol><button class="text-button danger" @click="deleteTemplate(t.id)">Usuń szablon</button></div><div v-if="!templates.length" class="panel empty-panel"><h2>Brak szablonów</h2><p>Przygotuj dzień treningowy w edytorze planu i zapisz go jako szablon.</p></div></div></section>

          <section v-else-if="view === 'plans'" class="content-page"><div class="page-heading"><div><div class="eyebrow">INDYWIDUALNE ZALECENIA</div><h1>{{ editingPlan ? 'Edytor planu' : 'Plany treningowe' }}</h1><p>{{ editingPlan ? 'Ułóż zestawy na wybrane dni tygodnia.' : 'Twórz i publikuj programy dla klientów.' }}</p></div><button v-if="editingPlan" class="btn outline" @click="editingPlan = false">Wróć do listy</button><button v-else class="btn primary" @click="resetPlan()">Nowy plan</button></div>
            <div v-if="!editingPlan" class="panel"><div v-if="!plans.length" class="empty-inline">Nie ma jeszcze planów. Utwórz pierwszy plan dla klienta.</div><div v-for="p in plans" :key="p.id" class="plan-list-item"><div><div class="eyebrow">{{ titleForPatient(p.patient_id) }}</div><h3>{{ p.title }}</h3><p>{{ formatDate(p.start_date) }} – {{ formatDate(p.end_date) }} · Wersja {{ p.current_version }}</p></div><div class="row-actions"><span class="status-pill" :class="p.status === 'active' ? 'completed' : 'scheduled'">{{ p.status === 'active' ? 'Aktywny' : p.status === 'draft' ? 'Roboczy' : 'Wstrzymany' }}</span><button v-if="p.status !== 'paused'" class="btn outline small" @click="editExistingPlan(p)">Edytuj</button><button v-if="p.status === 'active'" class="text-button danger" @click="pausePlan(p)">Wstrzymaj</button></div></div></div>
            <div v-else class="plan-editor"><div class="panel form-section"><h2>Informacje o planie</h2><div class="form-grid"><label>Klient<select v-model="planForm.patient_id" :disabled="!!editingPlanId" required><option value="">Wybierz klienta</option><option v-for="p in patients" :key="p.id" :value="p.id">{{ p.name }}</option></select></label><label>Nazwa planu<input v-model="planForm.title" required minlength="2"></label><label>Od kiedy<input v-model="planForm.start_date" type="date" required :disabled="Boolean(editingPlanId) && Boolean(plans.find(p => p.id === editingPlanId)?.current_version)"></label><label>Do kiedy<input v-model="planForm.end_date" type="date" required></label></div><p class="small-muted">Maksymalnie 12 tygodni. Jedna sesja dziennie. Zmiana planu nie zmienia zapisanych historycznych treningów.</p></div>
            <div class="panel"><div class="panel-heading"><div><h2>Harmonogram tygodniowy</h2><p class="small-muted">{{ activeDays }} dni z ćwiczeniami</p></div></div><div class="weekday-tabs"><button v-for="day in weekdays" :key="day.key" class="weekday" :class="{ active: editingDay === day.key, filled: getDraftDay(day.key).length > 0 }" @click="editingDay = day.key"><span>{{ day.label.slice(0, 3) }}</span><small>{{ getDraftDay(day.key).length }} ćw.</small></button></div><div class="day-heading"><h3>{{ weekdays.find(d => d.key === editingDay)?.label }}</h3><span class="small-muted">Zestaw do wykonania</span></div>
            <div v-for="(item, index) in getDraftDay(editingDay)" :key="`${item.exercise_id}-${index}`" class="plan-exercise"><div class="plan-exercise-header"><span class="number-chip">{{ index + 1 }}</span><strong>{{ item.name }}</strong><div class="plan-exercise-actions"><button class="text-button" :disabled="index === 0" @click="moveItem(index,-1)">W górę</button><button class="text-button" :disabled="index === getDraftDay(editingDay).length-1" @click="moveItem(index,1)">W dół</button><button class="text-button danger" @click="removeItem(index)">Usuń</button></div></div><div class="parameter-grid"><label>Serie<input v-model.number="item.sets" type="number" min="1" max="20"></label><label>Powtórzenia<input v-model.number="item.reps" type="number" min="1" max="1000" :disabled="!!item.duration"></label><label>Czas (sek.)<input v-model.number="item.duration" type="number" min="1" max="3600" placeholder="Opcjonalnie"></label><label>Przerwa (sek.)<input v-model.number="item.rest" type="number" min="0" max="3600"></label><label>Strona<select v-model="item.side"><option value="none">Nie dotyczy</option><option value="left">Lewa</option><option value="right">Prawa</option><option value="both">Obie</option></select></label><label class="note-field">Wskazówka indywidualna<input v-model="item.note" placeholder="Opcjonalnie"></label></div></div>
            <div class="add-exercise"><select v-model="addExerciseId"><option value="">Wybierz ćwiczenie z biblioteki</option><option v-for="e in filteredExercises" :key="e.id" :value="e.id">{{ e.name }}</option></select><button class="btn primary" :disabled="!addExerciseId" @click="addExerciseToDay">Dodaj do dnia</button></div><div class="template-toolbar"><select id="template-choose" @change="insertTemplate(($event.target as HTMLSelectElement).value); ($event.target as HTMLSelectElement).value = ''"><option value="">Wstaw zestaw z szablonu</option><option v-for="t in templates" :key="t.id" :value="t.id">{{ t.name }}</option></select><input v-model="newTemplateName" placeholder="Nazwa nowego szablonu"><button class="btn outline small" @click="saveTemplate">Zapisz jako szablon</button></div></div>
            <div class="save-bar"><div><strong>Twój plan jest gotowy?</strong><p>Możesz zapisać wersję roboczą lub opublikować.</p></div><div class="row-actions"><button class="btn outline" :disabled="busy" @click="savePlan(false)">Zapisz szkic</button><button class="btn primary" :disabled="busy" @click="savePlan(true)">{{ busy ? 'Zapisywanie...' : 'Opublikuj plan' }}</button></div></div></div>
          </section>
        </template>

        <template v-else>
          <section v-if="view === 'today'" class="content-page patient-today"><div class="eyebrow">TWOJA PRZESTRZEŃ</div><div class="page-heading"><div><h1>Cześć, {{ firstName(myPatient?.name || 'Ty') }}!</h1><p>{{ formatDate(nowDate) }} · Każdy ruch ma znaczenie.</p></div></div><div class="welcome-banner"><div><div class="eyebrow light">TWÓJ PLAN</div><h2>{{ activePlan?.title || 'Czas zadbać o siebie' }}</h2><p>{{ activePlan ? `${formatDate(activePlan.start_date)} – ${formatDate(activePlan.end_date)}` : 'Twój fizjoterapeuta jeszcze przygotowuje program.' }}</p></div><div class="welcome-mark">p<span>.</span></div></div>
            <div class="patient-stat-grid"><div class="mini-stat"><strong>{{ completedCount }}</strong><span>Wykonane treningi</span></div><div class="mini-stat"><strong>{{ sessions.filter(s => s.status === 'partial').length }}</strong><span>Częściowo wykonane</span></div><div class="mini-stat"><strong>{{ sessions.filter(s => s.day > nowDate && s.status === 'scheduled').length }}</strong><span>Przed Tobą</span></div></div>
            <div class="section-title"><h2>Dzisiejszy trening</h2><span class="date-chip">{{ formatDate(nowDate) }}</span></div><div v-if="todaySession" class="today-workout"><div class="today-icon"><span>{{ todaySession.workout.length }}</span><small>ĆW.</small></div><div class="today-body"><div class="eyebrow">{{ todaySession.status === 'completed' ? 'UKOŃCZONO' : 'PRZYGOTOWANE DLA CIEBIE' }}</div><h3>{{ activePlan?.title || 'Twój zestaw' }}</h3><p>{{ todaySession.workout.map(i => i.name).slice(0, 3).join(' · ') }}</p><button class="btn primary" @click="openSession(todaySession)">{{ ['completed','partial','skipped'].includes(todaySession.status) ? 'Zobacz / popraw wynik' : 'Rozpocznij trening' }}</button></div></div>
            <div v-else class="rest-day"><div class="rest-title">Dziś odpoczywasz.</div><p>W planie nie ma treningu na dzisiaj. Odpoczynek też jest częścią procesu.</p><div v-if="nextSession" class="next-session">Następny trening: <strong>{{ formatDate(nextSession.day) }}</strong></div></div>
            <p class="disclaimer">Aplikacja nie służy do zgłaszania nagłych problemów zdrowotnych. W razie niepokojących objawów skontaktuj się z fizjoterapeutą lub odpowiednią pomocą medyczną.</p>
          </section>
          <section v-else-if="view === 'schedule'" class="content-page"><div class="page-heading"><div><div class="eyebrow">TWOJE ZALECENIA</div><h1>Mój plan</h1><p>Przeglądaj najbliższe treningi i ćwiczenia.</p></div></div><div v-if="activePlan" class="panel plan-info"><div class="eyebrow">AKTYWNY PLAN</div><h2>{{ activePlan.title }}</h2><p>{{ formatDate(activePlan.start_date) }} – {{ formatDate(activePlan.end_date) }}</p></div><div v-if="!displaySessions.length" class="panel empty-panel"><h2>Brak zaplanowanych treningów</h2><p>Fizjoterapeuta jeszcze nie opublikował planu.</p></div><div class="panel"><div v-for="s in displaySessions" :key="s.id" class="schedule-row"><div><strong>{{ formatDate(s.day) }}</strong><span>{{ s.workout.length }} ćwiczeń · {{ s.workout.map(i=>i.name).slice(0,2).join(', ') }}</span></div><span class="status-pill" :class="s.status">{{ statusLabel(s.status) }}</span><button class="btn outline small" @click="openSession(s)">Otwórz</button></div></div></section>
          <section v-else-if="view === 'history'" class="content-page"><div class="page-heading"><div><div class="eyebrow">MAŁE KROKI, DUŻE POSTĘPY</div><h1>Historia treningów</h1><p>Zobacz, co już udało Ci się zrobić.</p></div></div><div class="panel"><div v-if="!pastSessions.length" class="empty-inline">Nie ma jeszcze treningów w historii.</div><div v-for="s in [...pastSessions].reverse()" :key="s.id" class="schedule-row"><div><strong>{{ formatDate(s.day) }}</strong><span>{{ s.feedback?.comment || `${s.workout.length} ćwiczeń` }}</span></div><span class="status-pill" :class="s.status">{{ statusLabel(s.status) }}</span><button class="btn outline small" @click="openSession(s)">Szczegóły</button></div></div></section>
        </template>

        <section v-if="view === 'account'" class="content-page"><div class="page-heading"><div><div class="eyebrow">USTAWIENIA</div><h1>Twoje konto</h1><p>Zarządzaj dostępem i informacjami o profilu.</p></div></div><div class="panel account-panel"><div class="profile-big-avatar">{{ user.email[0].toUpperCase() }}</div><div><h2>{{ user.email }}</h2><p>Gabinet: {{ clinicName }}</p><p>Rola: {{ role === 'owner' ? 'Właściciel' : staff ? 'Fizjoterapeuta' : 'Klient' }}</p><div class="row-actions"><button class="btn outline" :disabled="busy" @click="sendPasswordReset">Wyślij link zmiany hasła</button><button class="btn subtle" @click="logOut">Wyloguj się</button></div></div></div><p class="small-muted account-note">Dane i filmy są dostępne wyłącznie użytkownikom upoważnionym w aplikacji. Jeśli korzystasz z wersji demonstracyjnej, nie wprowadzaj prawdziwych danych zdrowotnych.</p></section>
      </main>
    </div>

    <div v-if="selectedSession && !staff" class="modal-backdrop" @click.self="selectedSessionId = ''"><div class="modal training-modal" role="dialog" aria-modal="true" aria-label="Szczegóły treningu"><div class="modal-top"><div><div class="eyebrow">TWÓJ TRENING</div><h2>{{ formatDate(selectedSession.day) }}</h2><p>{{ selectedSession.workout.length }} ćwiczeń</p></div><button class="modal-close" @click="selectedSessionId = ''">Zamknij</button></div><div class="training-scroll"><div v-for="(item,index) in selectedSession.workout" :key="index" class="training-exercise"><span class="step-number">{{ index+1 }}</span><div><h3>{{ item.name }}</h3><div class="exercise-prescription">{{ itemSummary(item) }} · przerwa {{ item.rest }} sek.</div><p>{{ item.description }}</p><p v-if="item.note" class="note"><strong>Wskazówka:</strong> {{ item.note }}</p><button v-if="item.video_path" class="video-open" @click="openVideo(item.video_path, item.name)">Obejrzyj instruktaż wideo</button></div></div><div class="feedback-form"><div class="eyebrow">ZAPISZ SWÓJ POSTĘP</div><h3>Jak poszedł trening?</h3><div class="result-options"><button v-for="option in [{key:'completed',label:'Całość'},{key:'partial',label:'Częściowo'},{key:'skipped',label:'Pominięty'}]" :key="option.key" class="result-choice" :class="{ selected: feedbackForm.status === option.key }" @click="feedbackForm.status=option.key">{{ option.label }}</button></div><div v-if="feedbackForm.status === 'partial'" class="partial-choices"><div class="field-title">Udało mi się wykonać:</div><label v-for="(item,index) in selectedSession.workout" :key="index" class="check-row"><input type="checkbox" :checked="feedbackForm.completed_exercises.includes(item.exercise_id)" @change="toggleCompletedExercise(item.exercise_id, ($event.target as HTMLInputElement).checked)">{{ item.name }}</label></div><div class="form-grid feedback-grid"><label>Trudność<select v-model="feedbackForm.difficulty"><option value="">Nie podaję</option><option value="easy">Za łatwo</option><option value="good">Odpowiednio</option><option value="hard">Za trudno</option></select></label><label>Ból lub dyskomfort po treningu (0–10)<select v-model="feedbackForm.pain"><option value="">Nie podaję</option><option v-for="n in 11" :key="n" :value="String(n-1)">{{ n-1 }}</option></select></label><label class="wide">Komentarz (opcjonalnie)<textarea v-model="feedbackForm.comment" rows="3" maxlength="1000" placeholder="Co było łatwe, a co sprawiło trudność?"></textarea></label></div><p class="small-muted">Twój fizjoterapeuta przejrzy odpowiedź w swoim czasie. To nie jest kanał pomocy w nagłych przypadkach.</p><button class="btn primary full" :disabled="busy" @click="submitTraining">{{ busy ? 'Zapisywanie...' : 'Zapisz wynik treningu' }}</button></div></div></div></div>
    <div v-if="videoPath" class="modal-backdrop video-backdrop" @click.self="videoPath = ''; videoUrl = ''"><div class="modal video-modal" role="dialog" aria-modal="true" aria-label="Film instruktażowy"><div class="modal-top"><div><div class="eyebrow">INSTRUKCJA WIDEO</div><h2>{{ videoTitle }}</h2></div><button class="modal-close" @click="videoPath = ''; videoUrl = ''">Zamknij</button></div><div v-if="videoLoading" class="empty-inline">Ładowanie filmu...</div><video v-else-if="videoUrl" :key="videoUrl" :src="videoUrl" controls playsinline preload="metadata" class="player"></video><p class="small-muted">Film jest dostępny tylko dla uprawnionych użytkowników. Dostęp czasowy.</p></div></div>
  </div>
</template>
