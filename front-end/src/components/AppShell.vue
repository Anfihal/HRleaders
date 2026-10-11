<script setup lang="ts">
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { currentUser, roleHome, signOut } from '../session'

const route = useRoute()
const router = useRouter()
const hrNav = [
  { label: 'Обзор', icon: 'i-lucide-layout-dashboard', to: '/hr' },
  { label: 'Кандидаты', icon: 'i-lucide-users-round', to: '/hr/candidates' },
  { label: 'Отслеживание', icon: 'i-lucide-bookmark-check', to: '/hr/tracking' },
  { label: 'Вакансии', icon: 'i-lucide-briefcase-business', to: '/hr/vacancies' },
  { label: 'Предложения', icon: 'i-lucide-send', to: '/hr/offers' },
  { label: 'Аналитика', icon: 'i-lucide-chart-no-axes-combined', to: '/hr/analytics' },
  { label: 'AI Assistant', icon: 'i-lucide-sparkles', to: '/hr/assistant' }
]
const candidateNav = [
  { label: 'Обзор', icon: 'i-lucide-layout-dashboard', to: '/candidate' },
  { label: 'Мой профиль', icon: 'i-lucide-user-round', to: '/candidate/profile' },
  { label: 'Тесты и отчёты', icon: 'i-lucide-clipboard-check', to: '/candidate/assessments' },
  { label: 'Предложения', icon: 'i-lucide-mail', to: '/candidate/offers' },
  { label: 'Совпадения', icon: 'i-lucide-heart-handshake', to: '/candidate/matches' }
]
const navigation = computed(() => currentUser.value?.role === 'candidate' ? candidateNav : hrNav)

async function logout() {
  await signOut()
  await router.replace('/')
}
</script>

<template>
  <div class="app-frame">
    <aside class="sidebar">
      <RouterLink to="/" class="brand">
        <span class="brand-mark">h</span>
        <span>hrleaders</span>
      </RouterLink>
      <div class="workspace-label">{{ currentUser?.role === 'candidate' ? 'Кабинет кандидата' : 'Рабочее пространство' }}</div>
      <nav class="side-nav" aria-label="Основная навигация">
        <RouterLink
          v-for="item in navigation"
          :key="item.to"
          :to="item.to"
          class="nav-link"
          :class="{ active: route.path === item.to || (item.to !== roleHome && route.path.startsWith(`${item.to}/`)) }"
        >
          <UIcon :name="item.icon" />
          <span>{{ item.label }}</span>
          <UIcon v-if="route.path === item.to" name="i-lucide-chevron-right" class="nav-tail" />
        </RouterLink>
      </nav>
      <div class="sidebar-bottom">
        <RouterLink to="/messages" class="nav-link">
          <UIcon name="i-lucide-message-square" /><span>Сообщения</span>
        </RouterLink>
        <div class="user-card">
          <UAvatar :alt="currentUser?.name" size="sm" />
          <div class="user-meta">
            <strong>{{ currentUser?.name }}</strong>
            <span>{{ currentUser?.company || (currentUser?.role === 'candidate' ? 'Кандидат' : 'HR-команда') }}</span>
          </div>
          <UButton aria-label="Выйти" icon="i-lucide-log-out" color="neutral" variant="ghost" size="sm" @click="logout" />
        </div>
      </div>
    </aside>

    <main class="main-pane">
      <header class="mobile-header">
        <RouterLink :to="roleHome" class="brand"><span class="brand-mark">h</span><span>hrleaders</span></RouterLink>
        <UButton aria-label="Выйти" icon="i-lucide-log-out" color="neutral" variant="ghost" @click="logout" />
      </header>
      <div class="mobile-nav">
        <RouterLink v-for="item in navigation.slice(0, 5)" :key="item.to" :to="item.to" :aria-label="item.label" :class="{ active: route.path === item.to }">
          <UIcon :name="item.icon" />
        </RouterLink>
      </div>
      <RouterView />
    </main>
  </div>
</template>
