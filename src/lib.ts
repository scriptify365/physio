import { createClient } from '@supabase/supabase-js'

const normalizeSupabaseUrl = (value: string | undefined) => {
  if (!value) return ''
  const trimmed = value.trim().replace(/\/+$/, '')
  return trimmed.replace(/\/rest\/v1\/?$/i, '')
}

const url = normalizeSupabaseUrl(import.meta.env.VITE_SUPABASE_URL as string | undefined)
const key = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY as string | undefined
export const configured = Boolean(url && key && !url.includes('YOUR_PROJECT') && !url.includes('/rest/v1'))
export const supabase = createClient(url || 'https://placeholder.supabase.co', key || 'placeholder', {
  auth: { autoRefreshToken: true, persistSession: true, detectSessionInUrl: true }
})
export const formatDate = (value: string) => new Intl.DateTimeFormat('pl-PL', { day: 'numeric', month: 'long', year: 'numeric', timeZone: 'UTC' }).format(new Date(`${value}T12:00:00Z`))
export const dayShort = (value: string) => new Intl.DateTimeFormat('pl-PL', { weekday: 'short', timeZone: 'UTC' }).format(new Date(`${value}T12:00:00Z`))
export const isoDate = (date = new Date()) => new Intl.DateTimeFormat('en-CA', { timeZone: 'Europe/Warsaw', year: 'numeric', month: '2-digit', day: '2-digit' }).format(date)
export type Membership = { clinic_id: string; role: 'owner' | 'therapist' | 'patient'; created_at?: string; clinics?: { name: string } | null }
export type Patient = { id: string; name: string; email: string; clinic_id: string; user_id: string | null; therapist_id: string; created_at: string }
export type Exercise = { id: string; name: string; description: string; equipment: string; tags: string[]; video_path: string | null; clinic_id: string; archived: boolean; created_at: string }
export type ExerciseItem = { exercise_id: string; name: string; description: string; equipment: string; video_path: string | null; sets: number; reps: number | null; duration: number | null; rest: number; side: string; note: string }
export type Draft = Record<string, ExerciseItem[]>
export type Plan = { id: string; patient_id: string; clinic_id: string; title: string; start_date: string; end_date: string; draft: Draft; status: string; current_version: number; created_at: string }
export type Training = { id: string; patient_id: string; clinic_id: string; plan_id: string; day: string; workout: ExerciseItem[]; status: string; revision: number; feedback: { difficulty?: string | null; pain?: number | null; comment?: string; completed_exercises?: string[] } | null; reviewed_at: string | null; submitted_at: string | null; updated_at: string }
export type Template = { id: string; name: string; clinic_id: string; workout: ExerciseItem[] }
export const statusLabels: Record<string, string> = { scheduled: 'Zaplanowany', in_progress: 'Rozpoczęty', completed: 'Wykonany', partial: 'Częściowo', skipped: 'Pominięty', cancelled: 'Anulowany' }
export const sides: Record<string, string> = { none: 'Nie dotyczy', left: 'Lewa', right: 'Prawa', both: 'Obie' }
export function message(error: unknown): string {
  if (error instanceof Error) return error.message
  if (typeof error === 'string') return error
  if (error && typeof error === 'object') {
    const obj = error as Record<string, unknown>
    if (typeof obj.message === 'string' && obj.message.trim()) return obj.message
    const details = [obj.details, obj.hint, obj.code].filter((value) => typeof value === 'string' && value.trim()).join(' | ')
    if (details) return details
    try { return JSON.stringify(error) } catch { return 'Wystąpił błąd.' }
  }
  return String(error)
}
export function cloneDraft(draft: Draft): Draft { return JSON.parse(JSON.stringify(draft || {})) as Draft }
