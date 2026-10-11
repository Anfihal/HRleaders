<script setup lang="ts">
import { reactive, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ApiError } from '../api'
import { isDemo, signIn } from '../session'

const route = useRoute()
const router = useRouter()
const form = reactive({ email: '', password: '' })
const error = ref('')
const loading = ref(false)

async function submit() {
  error.value = ''
  loading.value = true
  try {
    const user = await signIn(form.email, form.password)
    const destination = typeof route.query.from === 'string' && route.query.from.startsWith('/') ? route.query.from : undefined
    await router.replace(destination ?? (user?.role === 'candidate' ? '/candidate' : '/hr'))
  } catch (cause) {
    error.value = cause instanceof ApiError ? cause.message : 'Не удалось выполнить вход.'
  } finally {
    loading.value = false
  }
}

async function demoLogin(role: 'candidate' | 'hr') {
  form.email = `${role}@demo.hrleaders.example`
  form.password = 'Demo12345'
  await submit()
}
</script>

<template>
  <main class="auth-page">
    <RouterLink to="/" class="brand"><span class="brand-mark">h</span><span>hrleaders</span></RouterLink>
    <UCard class="auth-card">
      <div class="auth-heading">
        <div class="auth-icon"><UIcon name="i-lucide-sparkles" /></div>
        <h1>С возвращением</h1>
        <p>Войдите в свой аккаунт HRleaders</p>
      </div>
      <UAlert v-if="error" color="error" variant="subtle" :description="error" class="mb-5" />
      <form class="form-stack" @submit.prevent="submit">
        <UFormField label="Электронная почта">
          <UInput v-model="form.email" type="email" autocomplete="email" placeholder="name@example.com" icon="i-lucide-mail" size="lg" required class="w-full" />
        </UFormField>
        <UFormField label="Пароль">
          <UInput v-model="form.password" type="password" autocomplete="current-password" placeholder="Введите пароль" icon="i-lucide-lock-keyhole" size="lg" required class="w-full" />
        </UFormField>
        <UButton type="submit" size="lg" block :loading="loading">Войти в аккаунт <UIcon name="i-lucide-arrow-right" /></UButton>
      </form>
      <template v-if="isDemo">
        <div class="divider-label"><span>или демо-вход</span></div>
        <div class="demo-login">
          <UButton block color="neutral" variant="outline" icon="i-lucide-user-round" @click="demoLogin('candidate')">Продолжить как кандидат</UButton>
          <UButton block color="neutral" variant="outline" icon="i-lucide-briefcase-business" @click="demoLogin('hr')">Продолжить как HR</UButton>
        </div>
        <p class="demo-hint">Для ручного входа: <code>hr@demo.hrleaders.example</code> · <code>Demo12345</code></p>
      </template>
      <p class="auth-switch">Нет аккаунта? <RouterLink to="/register">Создать аккаунт</RouterLink></p>
    </UCard>
    <p class="auth-footnote"><UIcon name="i-lucide-shield-check" /> Ваши данные защищены</p>
  </main>
</template>
