import { computed, ref } from 'vue'
import { ApiError, HttpHrApi, type HrApi } from './api'
import { DemoHrApi } from './demo'
import type { User } from './types'

const demoEnabled = import.meta.env.VITE_DEMO !== 'false'
export const api: HrApi = demoEnabled ? new DemoHrApi() : new HttpHrApi()
export const currentUser = ref<User | null>(null)
export const restoringSession = ref(true)
export const sessionError = ref('')
export const isDemo = demoEnabled
export const roleHome = computed(() => currentUser.value?.role === 'candidate' ? '/candidate' : '/hr')

let restorePromise: Promise<void> | undefined
export function restoreSession() {
  if (!restorePromise) {
    restorePromise = api.me()
      .then((user) => { currentUser.value = user })
      .catch((error: unknown) => {
        sessionError.value = error instanceof ApiError ? error.message : 'Не удалось восстановить сессию.'
        currentUser.value = null
      })
      .finally(() => { restoringSession.value = false })
  }
  return restorePromise
}

export async function signIn(email: string, password: string) {
  currentUser.value = await api.login(email, password)
  sessionError.value = ''
  return currentUser.value
}

export async function signUp(input: {
  email: string
  password: string
  name: string
  role: 'candidate' | 'hr'
  company?: string
}) {
  currentUser.value = await api.register(input)
  sessionError.value = ''
  return currentUser.value
}

export async function signOut() {
  await api.logout()
  currentUser.value = null
}
