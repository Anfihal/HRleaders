<script setup lang="ts">
import { onMounted, reactive, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { ApiError } from '../api'
import { api } from '../session'
import type { Candidate } from '../types'

const router = useRouter()
const filters = reactive({ query: '', grade: '', skill: '' })
const candidates = ref<Candidate[]>([])
const total = ref(0)
const offset = ref(0)
const limit = 12
const trackedIds = ref(new Set<string>())
const loading = ref(false)
const error = ref('')
const notice = ref('')
const filterItems = [{ label: 'Любой уровень', value: '' }, { label: 'Junior', value: 'junior' }, { label: 'Middle', value: 'middle' }, { label: 'Senior', value: 'senior' }, { label: 'Lead', value: 'lead' }]

async function load() {
  loading.value = true
  error.value = ''
  try {
    const [page, tracked] = await Promise.all([
      api.searchCandidates({ ...filters, offset: offset.value, limit }),
      api.trackedCandidates()
    ])
    candidates.value = page.items
    total.value = page.total
    trackedIds.value = new Set(tracked.map((item) => item.id))
  } catch (cause) { error.value = cause instanceof ApiError ? cause.message : 'Не удалось выполнить поиск.' }
  finally { loading.value = false }
}

let debounceTimer: ReturnType<typeof setTimeout> | undefined
watch(() => [filters.query, filters.grade, filters.skill], () => {
  offset.value = 0
  clearTimeout(debounceTimer)
  debounceTimer = setTimeout(load, 250)
})
onMounted(load)

async function toggleTracking(candidate: Candidate) {
  try {
    if (trackedIds.value.has(candidate.id)) {
      await api.unfollow(candidate.id)
      trackedIds.value.delete(candidate.id)
      notice.value = `${candidate.name} удалён(а) из отслеживания.`
    } else {
      await api.follow(candidate.id)
      trackedIds.value.add(candidate.id)
      notice.value = `${candidate.name} добавлен(а) в отслеживание.`
    }
  } catch (cause) { error.value = cause instanceof ApiError ? cause.message : 'Не удалось обновить отслеживание.' }
}

function changePage(delta: number) {
  offset.value = Math.max(0, Math.min(total.value - 1, offset.value + delta * limit))
  load()
}
</script>

<template>
  <div class="page-wrap">
    <header class="page-heading"><div><div class="eyebrow">HR / ПОИСК ТАЛАНТОВ</div><h1>Найдите своего человека<span class="heading-spark">✳</span></h1><p>Ищите по навыкам, уровню и ожиданиям. Начните с диалога.</p></div><span class="header-illustration"><UIcon name="i-lucide-users-round" /></span></header>
    <UAlert v-if="error" color="error" variant="subtle" :description="error" class="mb-4" />
    <UAlert v-if="notice" color="success" variant="subtle" :description="notice" class="mb-4" />
    <UCard class="search-panel">
      <div class="search-fields">
        <UInput v-model="filters.query" icon="i-lucide-search" placeholder="Навык или технология" size="lg" class="search-query" />
        <USelect v-model="filters.grade" :items="filterItems" size="lg" aria-label="Уровень специалиста" />
        <UInput v-model="filters.skill" icon="i-lucide-sparkles" placeholder="Навык, например Flutter" size="lg" />
        <UButton icon="i-lucide-list-filter" color="neutral" variant="outline" @click="load">Найти</UButton>
      </div>
      <div class="search-foot"><span><UIcon name="i-lucide-shield-check" /> Только профили, открытые для предложений</span><span>{{ total }} кандидатов</span></div>
    </UCard>
    <section class="section-block">
      <div class="section-heading"><div><span class="eyebrow">ПОХОЖИ НА ВАШ ЗАПРОС</span><h2>Специалисты</h2></div><span class="muted">Страница {{ Math.floor(offset / limit) + 1 }}</span></div>
      <div v-if="loading" class="loading-state"><UIcon name="i-lucide-loader-circle" class="spin" />Ищем специалистов…</div>
      <div v-else-if="!candidates.length" class="empty-state"><span class="empty-icon"><UIcon name="i-lucide-user-search" /></span><h3>По этому запросу пока нет кандидатов</h3><p>Измените запрос или снимите часть фильтров.</p></div>
      <div v-else class="candidate-grid">
        <UCard v-for="candidate in candidates" :key="candidate.id" class="candidate-card">
          <div class="candidate-card-top"><UAvatar :alt="candidate.name" size="lg" /><UBadge v-if="candidate.verified" color="success" variant="subtle"><UIcon name="i-lucide-badge-check" /> подтверждён</UBadge></div>
          <h3>{{ candidate.name }}</h3><p class="candidate-headline">{{ candidate.headline || 'IT-специалист' }}</p>
          <div class="candidate-facts"><span><UIcon name="i-lucide-map-pin" /> {{ candidate.city || 'Локация не указана' }}</span><span><UIcon name="i-lucide-signal" /> {{ candidate.grade || 'Уровень не указан' }}</span></div>
          <div class="skill-list"><UBadge v-for="skill in candidate.skills.slice(0, 4)" :key="skill" color="neutral" variant="subtle">{{ skill }}</UBadge><UBadge v-if="candidate.skills.length > 4" color="neutral" variant="outline">+{{ candidate.skills.length - 4 }}</UBadge></div>
          <p class="candidate-about">{{ candidate.about || 'Открыт(а) к интересным предложениям.' }}</p>
          <div class="candidate-card-actions">
            <UButton class="grow" @click="router.push(`/hr/candidates/${encodeURIComponent(candidate.id)}`)">Профиль <UIcon name="i-lucide-arrow-right" /></UButton>
            <UButton :aria-label="trackedIds.has(candidate.id) ? 'Убрать из отслеживания' : 'Отслеживать'" :icon="trackedIds.has(candidate.id) ? 'i-lucide-bookmark-check' : 'i-lucide-bookmark-plus'" color="neutral" variant="outline" @click="toggleTracking(candidate)" />
          </div>
        </UCard>
      </div>
      <div v-if="total > limit" class="pagination-row"><UButton color="neutral" variant="outline" icon="i-lucide-arrow-left" :disabled="offset === 0" @click="changePage(-1)">Назад</UButton><span>{{ offset + 1 }}–{{ Math.min(offset + limit, total) }} из {{ total }}</span><UButton color="neutral" variant="outline" trailing-icon="i-lucide-arrow-right" :disabled="offset + limit >= total" @click="changePage(1)">Дальше</UButton></div>
    </section>
  </div>
</template>
