<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { ApiError } from '../api'
import { api } from '../session'
import type { AssessmentAssignment, TrackedCandidate } from '../types'

const candidates = ref<TrackedCandidate[]>([])
const assignments = ref<AssessmentAssignment[]>([])
const loading = ref(true)
const error = ref('')
const notice = ref('')

async function load() {
  loading.value = true
  try { [candidates.value, assignments.value] = await Promise.all([api.trackedCandidates(), api.assignments()]) }
  catch (cause) { error.value = cause instanceof ApiError ? cause.message : 'Не удалось загрузить отслеживание.' }
  finally { loading.value = false }
}
onMounted(load)
async function remove(candidate: TrackedCandidate) {
  try { await api.unfollow(candidate.id); candidates.value = candidates.value.filter((x) => x.id !== candidate.id) }
  catch (cause) { error.value = cause instanceof ApiError ? cause.message : 'Не удалось убрать кандидата.' }
}
async function startContact(candidate: TrackedCandidate) {
  notice.value = `Профиль ${candidate.name} готов к следующему шагу. Используйте предложение из раздела «Предложения».`
}
</script>

<template>
  <div class="page-wrap">
    <header class="page-heading"><div><div class="eyebrow">HR / ВАША ВОРОНКА</div><h1>Отслеживание</h1><p>Кандидаты, которых вы сохранили, и прогресс по назначенным оценкам.</p></div><UButton to="/hr/candidates" icon="i-lucide-user-round-search">Добавить кандидата</UButton></header>
    <UAlert v-if="error" color="error" variant="subtle" :description="error" class="mb-4" /><UAlert v-if="notice" color="primary" variant="subtle" :description="notice" class="mb-4" />
    <div v-if="loading" class="loading-state"><UIcon name="i-lucide-loader-circle" class="spin" />Загружаем список…</div>
    <template v-else>
      <div class="metric-strip"><div><strong>{{ candidates.length }}</strong><span>сохранено кандидатов</span></div><div><strong>{{ assignments.filter(a => a.status === 'assigned').length }}</strong><span>оценок ожидают ответа</span></div><div><strong>{{ assignments.filter(a => a.status === 'scored').length }}</strong><span>оценок завершено</span></div></div>
      <section class="section-block">
        <div class="section-heading"><div><span class="eyebrow">МОИ КАНДИДАТЫ</span><h2>Сохранённые специалисты</h2></div></div>
        <div v-if="!candidates.length" class="empty-state"><span class="empty-icon"><UIcon name="i-lucide-bookmark-x" /></span><h3>Список пока пуст</h3><p>Сохраняйте профили из поиска, чтобы вернуться к ним позже.</p><UButton to="/hr/candidates">Перейти к поиску</UButton></div>
        <div v-else class="tracked-list">
          <UCard v-for="candidate in candidates" :key="candidate.id" class="tracked-card">
            <UAvatar :alt="candidate.name" size="lg" />
            <div class="tracked-main"><div class="tracked-name"><strong>{{ candidate.name }}</strong><UBadge v-if="candidate.verified" color="success" variant="subtle">подтверждён</UBadge></div><span>{{ candidate.headline }} · {{ candidate.grade || 'уровень не указан' }}</span><div class="skill-list"><UBadge v-for="skill in candidate.skills.slice(0,3)" :key="skill" color="neutral" variant="subtle">{{ skill }}</UBadge></div></div>
            <div class="tracked-progress"><template v-if="candidate.latestScorePercent != null"><strong>{{ candidate.latestScorePercent }}%</strong><span>последний результат</span></template><template v-else><UBadge color="warning" variant="subtle">Нет оценки</UBadge><span>можно назначить тест</span></template></div>
            <div class="tracked-actions"><UButton :to="`/hr/candidates/${encodeURIComponent(candidate.id)}`" variant="outline" color="neutral">Профиль</UButton><UButton icon="i-lucide-send" aria-label="Подготовить предложение" @click="startContact(candidate)" /><UButton icon="i-lucide-bookmark-x" aria-label="Убрать из списка" variant="ghost" color="error" @click="remove(candidate)" /></div>
          </UCard>
        </div>
      </section>
      <section class="section-block">
        <div class="section-heading"><div><span class="eyebrow">ПРОГРЕСС</span><h2>Назначенные оценки</h2></div></div>
        <div v-if="!assignments.length" class="empty-inline">Назначений пока нет. Откройте профиль кандидата и предложите пройти оценку.</div>
        <div v-else class="plain-card result-list">
          <div v-for="assignment in assignments" :key="assignment.id" class="compact-row">
            <span class="step-icon lavender"><UIcon name="i-lucide-clipboard-check" /></span><div class="row-main"><strong>{{ assignment.candidateName }}</strong><span>{{ assignment.disciplineCode }} · {{ assignment.targetGrade }} · {{ new Date(assignment.assignedAt).toLocaleDateString('ru-RU') }}</span></div>
            <UBadge :color="assignment.status === 'scored' ? 'success' : assignment.status === 'assigned' ? 'warning' : 'primary'" variant="subtle">{{ assignment.status }}</UBadge>
            <strong v-if="assignment.scorePercent != null">{{ assignment.scorePercent }}%</strong>
          </div>
        </div>
      </section>
    </template>
  </div>
</template>
