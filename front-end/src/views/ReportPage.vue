<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRoute } from 'vue-router'
import { ApiError } from '../api'
import { api } from '../session'
import type { AssessmentAttempt, AssessmentTest } from '../types'

const route = useRoute()
const attempt = ref<AssessmentAttempt | null>(null)
const test = ref<AssessmentTest | null>(null)
const error = ref('')
const percent = computed(() => attempt.value?.percent ?? 0)
const correctCount = computed(() => {
  const currentTest = test.value
  const currentAttempt = attempt.value
  if (!currentTest || !currentAttempt) return 0
  return currentTest.questions.reduce((count, _question, index) => (
    count + Number(currentAttempt.answerCorrectness?.[index] === true)
  ), 0)
})
function isCorrect(index: number) {
  return attempt.value?.answerCorrectness?.[index] ?? null
}

onMounted(async () => {
  try {
    attempt.value = await api.attempt(String(route.params.id))
    test.value = (await api.assessmentCatalog()).find((item) => item.id === attempt.value?.testId) ?? null
  } catch (cause) { error.value = cause instanceof ApiError ? cause.message : 'Не удалось загрузить отчёт.' }
})
</script>

<template>
  <div class="page-wrap">
    <header class="page-heading compact-heading"><div><div class="eyebrow">КАНДИДАТ / РЕЗУЛЬТАТ</div><h1>Отчёт по оценке</h1><p>Результат — часть вашего профессионального профиля.</p></div><UButton to="/candidate/assessments" color="neutral" variant="outline" icon="i-lucide-arrow-left">Все тесты</UButton></header>
    <UAlert v-if="error" color="error" variant="subtle" :description="error" class="mb-5" />
    <template v-if="attempt && test">
      <UCard class="report-hero">
        <div class="report-score"><strong>{{ percent }}</strong><span>%</span></div>
        <div class="report-copy"><UBadge color="success" variant="subtle"><UIcon name="i-lucide-badge-check" /> ОЦЕНКА ЗАВЕРШЕНА</UBadge><h2>{{ test.title }}</h2><p>Тест завершён {{ attempt.completedAt ? new Date(attempt.completedAt).toLocaleDateString('ru-RU') : '' }}. Результат сохранён в вашем профиле.</p></div>
      </UCard>
      <section class="section-block">
        <div class="section-heading"><div><span class="eyebrow">РАЗБОР ОТВЕТОВ</span><h2>Ваши ответы</h2></div><UBadge color="primary" variant="subtle">{{ correctCount }} / {{ test.questions.length }} верно</UBadge></div>
        <div class="report-questions">
          <UCard v-for="(question, index) in test.questions" :key="question.id" class="report-question">
            <div class="report-q-heading"><span>ВОПРОС {{ index + 1 }}</span><UBadge :color="isCorrect(index) === true ? 'success' : isCorrect(index) === false ? 'error' : 'neutral'" variant="subtle">{{ isCorrect(index) === true ? 'Верно' : isCorrect(index) === false ? 'Проверьте тему' : 'Оценка недоступна' }}</UBadge></div>
            <h3>{{ question.prompt }}</h3>
            <p>Ваш ответ: <strong>{{ question.options[attempt.answers[index] ?? -1] ?? 'Нет ответа' }}</strong></p>
            <div class="skill-list"><UBadge v-for="skill in question.skills" :key="skill" color="neutral" variant="subtle">{{ skill }}</UBadge></div>
          </UCard>
        </div>
      </section>
      <UCard class="action-banner"><div><UBadge color="primary" variant="subtle">СЛЕДУЮЩИЙ ШАГ</UBadge><h3>Добавьте результат в историю профиля</h3><p>Результат уже доступен HR-командам, которым вы разрешили видеть профиль.</p></div><UButton to="/candidate/profile">Открыть профиль <UIcon name="i-lucide-arrow-right" /></UButton></UCard>
    </template>
  </div>
</template>
