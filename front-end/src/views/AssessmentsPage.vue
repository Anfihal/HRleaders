<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ApiError } from '../api'
import { api } from '../session'
import type { AssessmentAssignment, AssessmentAttempt, AssessmentTest } from '../types'

const router = useRouter()
const tests = ref<AssessmentTest[]>([])
const assignments = ref<AssessmentAssignment[]>([])
const attempts = ref<AssessmentAttempt[]>([])
const error = ref('')
const loading = ref(true)
const starting = ref('')

onMounted(async () => {
  try { [tests.value, assignments.value, attempts.value] = await Promise.all([api.assessmentCatalog(), api.assignments(), api.attempts()]) }
  catch (cause) { error.value = cause instanceof ApiError ? cause.message : 'Не удалось загрузить оценки.' }
  finally { loading.value = false }
})

async function start(test: AssessmentTest, assignmentId?: string) {
  starting.value = assignmentId ?? test.id
  try {
    const attempt = assignmentId ? await api.startAssignment(assignmentId) : await api.startAssessment(test.id)
    await router.push(`/candidate/assessments/${encodeURIComponent(attempt.id)}`)
  } catch (cause) { error.value = cause instanceof ApiError ? cause.message : 'Не удалось начать тест.' }
  finally { starting.value = '' }
}

function matching(assignment: AssessmentAssignment) {
  return tests.value.find((test) => test.discipline === assignment.disciplineCode && test.grade === assignment.targetGrade)
}
</script>

<template>
  <div class="page-wrap">
    <header class="page-heading"><div><div class="eyebrow">КАНДИДАТ / ОЦЕНКА НАВЫКОВ</div><h1>Тесты и результаты</h1><p>Покажите знания и сохраните результат в своём профиле.</p></div><span class="header-illustration"><UIcon name="i-lucide-brain" /></span></header>
    <UAlert v-if="error" color="error" variant="subtle" :description="error" class="mb-5" />
    <div v-if="loading" class="loading-state"><UIcon name="i-lucide-loader-circle" class="spin" />Загружаем тесты…</div>
    <template v-else>
      <section v-if="assignments.length" class="section-block">
        <div class="section-heading"><div><span class="eyebrow">ОТ HR-КОМАНДЫ</span><h2>Назначенные оценки</h2></div><UBadge color="warning" variant="subtle">{{ assignments.filter(x => x.status === 'assigned').length }} ожидают</UBadge></div>
        <div class="test-grid">
          <UCard v-for="assignment in assignments" :key="assignment.id" class="test-card assigned-test">
            <div class="test-card-top"><span class="step-icon lavender"><UIcon name="i-lucide-clipboard-list" /></span><UBadge :color="assignment.status === 'scored' ? 'success' : assignment.status === 'assigned' ? 'warning' : 'primary'" variant="subtle">{{ assignment.status }}</UBadge></div>
            <h3>{{ matching(assignment)?.title || `${assignment.disciplineCode} · ${assignment.targetGrade}` }}</h3>
            <p>Назначено {{ new Date(assignment.assignedAt).toLocaleDateString('ru-RU') }}</p>
            <div class="test-meta"><span><UIcon name="i-lucide-clock-3" /> {{ matching(assignment)?.durationMinutes ?? 20 }} мин</span><span><UIcon name="i-lucide-target" /> {{ assignment.targetGrade }}</span></div>
            <UButton v-if="assignment.status === 'assigned' && matching(assignment)" block :loading="starting === assignment.id" @click="start(matching(assignment)!, assignment.id)">Начать назначенный тест</UButton>
            <UButton v-else-if="assignment.attemptId" block color="neutral" variant="outline" :to="`/candidate/assessments/${encodeURIComponent(assignment.attemptId)}/report`">Открыть результат</UButton>
            <UButton v-else block color="neutral" variant="outline" disabled>Выполняется</UButton>
          </UCard>
        </div>
      </section>
      <section class="section-block">
        <div class="section-heading"><div><span class="eyebrow">КАТАЛОГ HRLEADERS</span><h2>Выберите тест</h2></div></div>
        <div v-if="!tests.length" class="empty-state"><span class="empty-icon"><UIcon name="i-lucide-clipboard-x" /></span><h3>Пока нет доступных тестов</h3><p>Попробуйте позже — новые оценки появятся в каталоге.</p></div>
        <div v-else class="test-grid">
          <UCard v-for="test in tests" :key="test.id" class="test-card">
            <div class="test-card-top"><span class="step-icon"><UIcon name="i-lucide-brain" /></span><UBadge color="primary" variant="subtle">{{ test.grade }}</UBadge></div>
            <h3>{{ test.title }}</h3><p>{{ test.description }}</p>
            <div class="test-meta"><span><UIcon name="i-lucide-clock-3" /> {{ test.durationMinutes }} мин</span><span><UIcon name="i-lucide-list-ordered" /> {{ test.questions.length }} вопроса</span></div>
            <UButton block :loading="starting === test.id" @click="start(test)">Начать тест <UIcon name="i-lucide-arrow-right" /></UButton>
          </UCard>
        </div>
      </section>
      <section v-if="attempts.length" class="section-block">
        <div class="section-heading"><div><span class="eyebrow">ИСТОРИЯ</span><h2>Мои результаты</h2></div></div>
        <div class="plain-card result-list">
          <div v-for="attempt in attempts" :key="attempt.id" class="compact-row">
            <span class="step-icon lavender"><UIcon name="i-lucide-chart-no-axes-column-increasing" /></span>
            <div class="row-main"><strong>{{ tests.find(t => t.id === attempt.testId)?.title || 'Оценочный тест' }}</strong><span>{{ new Date(attempt.startedAt).toLocaleDateString('ru-RU') }}</span></div>
            <UBadge :color="attempt.status === 'scored' ? 'success' : 'neutral'" variant="subtle">{{ attempt.status === 'scored' ? `${attempt.percent}%` : attempt.status }}</UBadge>
            <UButton v-if="attempt.status === 'scored'" :to="`/candidate/assessments/${encodeURIComponent(attempt.id)}/report`" variant="link">Отчёт</UButton>
            <UButton v-else :to="`/candidate/assessments/${encodeURIComponent(attempt.id)}`" variant="link">Продолжить</UButton>
          </div>
        </div>
      </section>
    </template>
  </div>
</template>
