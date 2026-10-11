<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ApiError } from '../api'
import { api } from '../session'
import type { AssessmentAttempt, AssessmentTest } from '../types'

const route = useRoute()
const router = useRouter()
const attempt = ref<AssessmentAttempt | null>(null)
const test = ref<AssessmentTest | null>(null)
const index = ref(0)
const error = ref('')
const saving = ref(false)
const question = computed(() => test.value?.questions[index.value])
const selected = computed(() => attempt.value?.answers[index.value] ?? null)
const progress = computed(() => test.value ? Math.round((index.value / test.value.questions.length) * 100) : 0)

onMounted(async () => {
  try {
    attempt.value = await api.attempt(String(route.params.id))
    test.value = (await api.assessmentCatalog()).find((item) => item.id === attempt.value?.testId) ?? null
    if (!test.value) throw new ApiError('Тест для этой попытки недоступен.')
    index.value = attempt.value.answers.findIndex((answer) => answer === null)
    if (index.value < 0) index.value = Math.max(0, test.value.questions.length - 1)
    if (attempt.value.status === 'scored') await router.replace(`/candidate/assessments/${encodeURIComponent(attempt.value.id)}/report`)
  } catch (cause) { error.value = cause instanceof ApiError ? cause.message : 'Не удалось загрузить попытку.' }
})

async function choose(optionIndex: number) {
  if (!attempt.value || !question.value || attempt.value.status !== 'in_progress') return
  saving.value = true
  error.value = ''
  try {
    attempt.value = await api.answerAssessment(attempt.value.id, question.value.id, question.value.options[optionIndex])
  } catch (cause) { error.value = cause instanceof ApiError ? cause.message : 'Не удалось сохранить ответ.' }
  finally { saving.value = false }
}

async function submit() {
  if (!attempt.value) return
  saving.value = true
  try {
    attempt.value = await api.submitAssessment(attempt.value.id)
    await router.replace(`/candidate/assessments/${encodeURIComponent(attempt.value.id)}/report`)
  } catch (cause) { error.value = cause instanceof ApiError ? cause.message : 'Не удалось завершить тест.' }
  finally { saving.value = false }
}
</script>

<template>
  <div class="page-wrap attempt-wrap">
    <header class="page-heading compact-heading"><div><div class="eyebrow">ОЦЕНКА НАВЫКОВ</div><h1>{{ test?.title || 'Загрузка теста…' }}</h1><p>Выберите один ответ. Ваш прогресс сохраняется автоматически.</p></div><UButton to="/candidate/assessments" color="neutral" variant="outline" icon="i-lucide-x">Выйти из теста</UButton></header>
    <UAlert v-if="error" color="error" variant="subtle" :description="error" class="mb-5" />
    <UCard v-if="test && attempt" class="question-card">
      <div class="question-top"><span>ВОПРОС {{ index + 1 }} <span class="muted">/ {{ test.questions.length }}</span></span><span><UIcon name="i-lucide-clock-3" /> {{ test.durationMinutes }} минут</span></div>
      <UProgress :model-value="progress" class="question-progress" />
      <h2>{{ question?.prompt }}</h2>
      <div class="answer-list">
        <button v-for="(option, optionIndex) in question?.options" :key="option" type="button" class="answer-option" :class="{ selected: selected === optionIndex }" :disabled="saving || attempt.status !== 'in_progress'" @click="choose(optionIndex)">
          <span class="answer-letter">{{ String.fromCharCode(65 + optionIndex) }}</span><span>{{ option }}</span><UIcon v-if="selected === optionIndex" name="i-lucide-circle-check" />
        </button>
      </div>
      <div class="question-footer">
        <UButton color="neutral" variant="outline" icon="i-lucide-arrow-left" :disabled="index === 0" @click="index--">Назад</UButton>
        <span>{{ attempt.answers.filter(answer => answer !== null).length }} из {{ test.questions.length }} отвечено</span>
        <UButton v-if="index < test.questions.length - 1" :disabled="selected === null" @click="index++">Далее <UIcon name="i-lucide-arrow-right" /></UButton>
        <UButton v-else :loading="saving" :disabled="attempt.answers.some(answer => answer === null)" color="success" @click="submit">Завершить тест <UIcon name="i-lucide-check" /></UButton>
      </div>
    </UCard>
  </div>
</template>
