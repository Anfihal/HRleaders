<script setup lang="ts">
import { onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import AppShell from './components/AppShell.vue'
import { currentUser, isDemo, restoreSession, restoringSession, sessionError } from './session'

const route = useRoute()
const router = useRouter()
onMounted(async () => {
  await restoreSession()
  if (currentUser.value && ['/', '/login', '/register'].includes(route.path)) {
    await router.replace(currentUser.value.role === 'candidate' ? '/candidate' : '/hr')
  }
})
</script>

<template>
  <UApp>
    <div v-if="restoringSession" class="boot-screen">
      <UIcon name="i-lucide-loader-circle" class="spin" />
      <span>Загружаем HRleaders…</span>
    </div>
    <AppShell v-else-if="currentUser && !route.meta.public" />
    <RouterView v-else />
    <UAlert v-if="sessionError" class="session-error" color="error" variant="subtle" :description="sessionError" />
    <div v-if="isDemo" class="demo-ribbon">
      <UIcon name="i-lucide-flask-conical" />
      <span>Демо · вымышленные данные</span>
    </div>
  </UApp>
</template>
