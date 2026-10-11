<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { ApiError } from '../api'
import { api, currentUser } from '../session'
import type { AssessmentAssignment, Candidate, Offer, Vacancy } from '../types'

const loading = ref(true)
const error = ref('')
const profile = ref<Candidate | null>(null)
const assignments = ref<AssessmentAssignment[]>([])
const offers = ref<Offer[]>([])
const vacancies = ref<Vacancy[]>([])
const trackedCount = ref(0)
const isCandidate = computed(() => currentUser.value?.role === 'candidate')
const greeting = computed(() => currentUser.value?.name?.split(' ')[0] || 'знакомства')

onMounted(async () => {
  try {
    if (isCandidate.value) {
      ;[profile.value, assignments.value, offers.value] = await Promise.all([
        api.myProfile(), api.assignments(), api.offers(true)
      ])
    } else {
      const [analytics, assignmentsList, offerList, vacancyList] = await Promise.all([
        api.analytics(), api.assignments(), api.offers(false), api.vacancies()
      ])
      assignments.value = assignmentsList
      offers.value = offerList
      vacancies.value = vacancyList.filter((vacancy) => vacancy.isOpen)
      trackedCount.value = analytics.candidates_tracked ?? 0
    }
  } catch (cause) {
    error.value = cause instanceof ApiError ? cause.message : 'Не удалось загрузить обзор.'
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <div class="page-wrap">
    <header class="page-heading">
      <div>
        <div class="eyebrow">HRLEADERS / {{ isCandidate ? 'КАНДИДАТ' : 'РЕКРУТЁР' }}</div>
        <h1>{{ isCandidate ? `Добро пожаловать, ${greeting}` : `Доброе утро, ${greeting}` }}<span class="heading-spark">✳</span></h1>
        <p>{{ isCandidate ? 'Ваши навыки — начало нового знакомства.' : 'Здесь начинается знакомство с нужными специалистами.' }}</p>
      </div>
      <UButton v-if="isCandidate" to="/candidate/profile" icon="i-lucide-user-round" color="neutral" variant="outline">Мой профиль</UButton>
      <UButton v-else to="/hr/candidates" icon="i-lucide-search">Найти кандидата</UButton>
    </header>
    <UAlert v-if="error" color="error" variant="subtle" :description="error" class="mb-6" />
    <div v-if="loading" class="loading-state"><UIcon name="i-lucide-loader-circle" class="spin" />Загружаем данные…</div>

    <template v-else-if="isCandidate">
      <UCard class="welcome-card candidate-welcome">
        <div class="welcome-copy">
          <UBadge color="primary" variant="subtle">ВАШ ПРОФИЛЬ</UBadge>
          <h2>{{ profile?.headline || 'Расскажите, что вы умеете' }}</h2>
          <p>{{ profile?.about || 'Добавьте навыки и достижения, чтобы HR-команды лучше увидели ваш опыт.' }}</p>
          <div class="welcome-actions">
            <UButton to="/candidate/profile" icon="i-lucide-arrow-up-right">{{ profile?.headline ? 'Обновить профиль' : 'Заполнить профиль' }}</UButton>
            <UButton to="/candidate/assessments" color="neutral" variant="outline" icon="i-lucide-clipboard-check">Пройти оценку</UButton>
          </div>
        </div>
        <div class="profile-progress">
          <div class="progress-ring"><strong>{{ Math.min(100, 30 + (profile?.skills.length ?? 0) * 10) }}%</strong></div>
          <span>профиль заполнен</span>
          <small>Добавьте навыки и подтвердите их оценкой</small>
        </div>
      </UCard>
      <section class="section-block">
        <div class="section-heading"><div><span class="eyebrow">ВАШ ПУТЬ</span><h2>Следующие шаги</h2></div></div>
        <div class="step-grid">
          <UCard class="step-card">
            <span class="step-number">01</span><div class="step-icon"><UIcon name="i-lucide-user-round-pen" /></div>
            <h3>Расскажите о себе</h3><p>Добавьте навыки, специализацию и формат работы.</p>
            <UButton to="/candidate/profile" variant="link" trailing-icon="i-lucide-arrow-right">Открыть профиль</UButton>
          </UCard>
          <UCard class="step-card">
            <span class="step-number">02</span><div class="step-icon lavender"><UIcon name="i-lucide-brain" /></div>
            <h3>Подтвердите навыки</h3><p>Короткая оценка поможет показать ваши сильные стороны.</p>
            <UButton to="/candidate/assessments" variant="link" trailing-icon="i-lucide-arrow-right">К тестам</UButton>
          </UCard>
          <UCard class="step-card">
            <span class="step-number">03</span><div class="step-icon peach"><UIcon name="i-lucide-mail-open" /></div>
            <h3>Будьте на связи</h3><p>Просматривайте и принимайте предложения от HR-команд.</p>
            <UButton to="/candidate/offers" variant="link" trailing-icon="i-lucide-arrow-right">Предложения · {{ offers.length }}</UButton>
          </UCard>
        </div>
      </section>
      <UCard v-if="assignments.some(item => item.status === 'assigned')" class="action-banner">
        <div><UBadge color="warning" variant="subtle">ЕСТЬ НОВОЕ</UBadge><h3>Вам назначена оценка</h3><p>Откройте раздел тестов, чтобы посмотреть задание от рекрутёра.</p></div>
        <UButton to="/candidate/assessments">Посмотреть задания <UIcon name="i-lucide-arrow-right" /></UButton>
      </UCard>
      <UCard v-else-if="offers.length" class="action-banner">
        <div><UBadge color="success" variant="subtle">НОВОЕ ЗНАКОМСТВО</UBadge><h3>У вас есть предложение</h3><p>{{ offers[0].company }} · {{ offers[0].vacancy.title }}</p></div>
        <UButton to="/candidate/offers">Открыть предложение <UIcon name="i-lucide-arrow-right" /></UButton>
      </UCard>
    </template>

    <template v-else>
      <UCard class="welcome-card recruiter-welcome">
        <div class="welcome-copy">
          <UBadge color="error" variant="subtle">ПОМОГАЕМ НАЙТИ СВОИХ</UBadge>
          <h2>Не просто резюме.<br><span>Подтверждённые навыки.</span></h2>
          <p>Находите специалистов, отслеживайте прогресс и создавайте осмысленные предложения.</p>
          <div class="welcome-actions">
            <UButton to="/hr/candidates" icon="i-lucide-search">Начать поиск</UButton>
            <UButton to="/hr/vacancies" color="neutral" variant="outline" icon="i-lucide-plus">Создать вакансию</UButton>
          </div>
        </div>
        <div class="recruiter-illustration"><div class="illust-orbit"><UIcon name="i-lucide-user-round-search" /></div><div class="illust-mark">h</div><span>найм начинается с диалога</span></div>
      </UCard>
      <section class="metric-grid">
        <UCard class="metric-card"><div class="metric-top"><span class="metric-icon"><UIcon name="i-lucide-users-round" /></span><UBadge color="success" variant="subtle">активный поиск</UBadge></div><strong>{{ trackedCount }}</strong><span>кандидатов в отслеживании</span><RouterLink to="/hr/tracking">Открыть список <UIcon name="i-lucide-arrow-up-right" /></RouterLink></UCard>
        <UCard class="metric-card"><div class="metric-top"><span class="metric-icon violet"><UIcon name="i-lucide-briefcase-business" /></span><UBadge color="primary" variant="subtle">открыты</UBadge></div><strong>{{ vacancies.length }}</strong><span>активных вакансий</span><RouterLink to="/hr/vacancies">Управлять вакансиями <UIcon name="i-lucide-arrow-up-right" /></RouterLink></UCard>
        <UCard class="metric-card"><div class="metric-top"><span class="metric-icon orange"><UIcon name="i-lucide-send" /></span><UBadge color="warning" variant="subtle">всего</UBadge></div><strong>{{ offers.length }}</strong><span>отправленных предложений</span><RouterLink to="/hr/offers">Посмотреть предложения <UIcon name="i-lucide-arrow-up-right" /></RouterLink></UCard>
      </section>
      <section class="section-block">
        <div class="section-heading"><div><span class="eyebrow">НЕ ТЕРЯЙТЕ ТЕМП</span><h2>Ваш рабочий поток</h2></div><UButton to="/hr/analytics" variant="link" trailing-icon="i-lucide-arrow-right">Все показатели</UButton></div>
        <div class="step-grid">
          <UCard class="step-card"><div class="step-icon"><UIcon name="i-lucide-search-check" /></div><h3>Найдите кандидата</h3><p>Настройте поиск по специализации, грейду и навыкам.</p><UButton to="/hr/candidates" variant="link" trailing-icon="i-lucide-arrow-right">Открыть поиск</UButton></UCard>
          <UCard class="step-card"><div class="step-icon lavender"><UIcon name="i-lucide-list-checks" /></div><h3>Назначьте оценку</h3><p>Попросите подтвердить знания коротким тестом.</p><UButton to="/hr/tracking" variant="link" trailing-icon="i-lucide-arrow-right">К кандидатам</UButton></UCard>
          <UCard class="step-card"><div class="step-icon peach"><UIcon name="i-lucide-sparkles" /></div><h3>Составьте предложение</h3><p>Дайте кандидату понятный следующий шаг.</p><UButton to="/hr/offers" variant="link" trailing-icon="i-lucide-arrow-right">Предложения</UButton></UCard>
        </div>
      </section>
      <UCard v-if="assignments.length" class="plain-card">
        <div class="section-heading"><div><span class="eyebrow">ОЦЕНКИ</span><h2>Недавние назначения</h2></div><UButton to="/hr/tracking" variant="link">Все назначения</UButton></div>
        <div v-for="item in assignments.slice(0, 3)" :key="item.id" class="compact-row">
          <UAvatar :alt="item.candidateName" size="sm" /><div class="row-main"><strong>{{ item.candidateName }}</strong><span>{{ item.disciplineCode }} · {{ item.targetGrade }}</span></div><UBadge color="neutral" variant="subtle">{{ item.status }}</UBadge>
        </div>
      </UCard>
    </template>
  </div>
</template>
