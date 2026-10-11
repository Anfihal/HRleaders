<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ApiError } from '../api'
import { signUp } from '../session'
import RedFlagGame from '../components/RedFlagGame.vue'

const route = useRoute()
const router = useRouter()
const form = reactive({
  name: '', email: '', password: '', role: route.query.role === 'hr' ? 'hr' as const : 'candidate' as const, company: ''
})
const error = ref('')
const loading = ref(false)
const gameOpen = ref(false)

function toggleGame(event: Event) {
  gameOpen.value = (event.currentTarget as HTMLDetailsElement).open
}
const needsCompany = computed(() => form.role === 'hr')

async function submit() {
  error.value = ''
  loading.value = true
  try {
    const user = await signUp(form)
    await router.replace(user?.role === 'candidate' ? '/candidate/profile' : '/hr')
  } catch (cause) {
    error.value = cause instanceof ApiError ? cause.message : 'Не удалось создать аккаунт.'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <main class="auth-page">
    <RouterLink to="/" class="brand"><span class="brand-mark">h</span><span>hrleaders</span></RouterLink>
    <UCard class="auth-card">
      <div class="auth-heading">
        <div class="auth-icon"><UIcon name="i-lucide-user-plus" /></div>
        <h1>Создать аккаунт</h1>
        <p>Начните свой путь к подходящему знакомству</p>
      </div>
      <UAlert v-if="error" color="error" variant="subtle" :description="error" class="mb-5" />
      <form class="form-stack" @submit.prevent="submit">
        <UFormField label="Я регистрируюсь как">
          <USelect v-model="form.role" :items="[{ label: 'Кандидат', value: 'candidate' }, { label: 'HR-рекрутёр', value: 'hr' }]" size="lg" class="w-full" />
        </UFormField>
        <UFormField label="Имя и фамилия">
          <UInput v-model="form.name" autocomplete="name" placeholder="Например, Анна Иванова" size="lg" required minlength="2" class="w-full" />
        </UFormField>
        <UFormField label="Электронная почта">
          <UInput v-model="form.email" type="email" autocomplete="email" placeholder="name@example.com" size="lg" required class="w-full" />
        </UFormField>
        <UFormField v-if="needsCompany" label="Компания">
          <UInput v-model="form.company" placeholder="Название компании" size="lg" required class="w-full" />
        </UFormField>
        <UFormField label="Пароль">
          <UInput v-model="form.password" type="password" autocomplete="new-password" placeholder="Не менее 8 символов" size="lg" required minlength="8" class="w-full" />
        </UFormField>
        <UButton type="submit" size="lg" block :loading="loading">Создать аккаунт <UIcon name="i-lucide-arrow-right" /></UButton>
      </form>
      <details v-if="form.role === 'candidate'" class="game-disclosure" @toggle="toggleGame">
        <summary><UIcon name="i-lucide-gamepad-2" /> Небольшая пауза: перепрыгните красные флаги <UIcon name="i-lucide-chevron-down" /></summary>
        <RedFlagGame v-if="gameOpen" />
      </details>
      <p class="auth-switch">Уже есть аккаунт? <RouterLink to="/login">Войти</RouterLink></p>
    </UCard>
  </main>
</template>
