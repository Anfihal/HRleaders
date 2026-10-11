<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ApiError } from '../api'
import { api } from '../session'
import type { AssessmentTest, Candidate, Vacancy } from '../types'

const props = defineProps<{ recruiterView?: boolean }>()
const route = useRoute()
const router = useRouter()
const profile = ref<Candidate | null>(null)
const tests = ref<AssessmentTest[]>([])
const vacancies = ref<Vacancy[]>([])
const tracked = ref(false)
const loading = ref(true)
const saving = ref(false)
const error = ref('')
const success = ref('')
const offerModal = ref(false)
const offerSaving = ref(false)
const offerForm = reactive({ vacancyId: '', salary: '250000', message: 'Ваш опыт подходит нашей команде. Будем рады обсудить детали роли.' })
const draft = reactive({ name: '', headline: '', city: '', grade: '', teamRole: '', workFormat: '', salary: '', skills: '', about: '', openToOffers: true })
const editable = computed(() => !props.recruiterView)

async function load() {
  loading.value = true
  error.value = ''
  try {
    profile.value = props.recruiterView ? await api.candidate(String(route.params.id)) : await api.myProfile()
    Object.assign(draft, {
      name: profile.value.name, headline: profile.value.headline, city: profile.value.city ?? '',
      grade: profile.value.grade ?? '', teamRole: profile.value.teamRole ?? '',
      workFormat: profile.value.workFormat ?? '', salary: profile.value.salary?.toString() ?? '',
      skills: profile.value.skills.join(', '), about: profile.value.about ?? '',
      openToOffers: profile.value.openToOffers
    })
    if (props.recruiterView) {
      const [items, testsList, vacancyList] = await Promise.all([api.trackedCandidates(), api.assessmentCatalog(), api.vacancies()])
      tracked.value = items.some((item) => item.id === profile.value?.id)
      tests.value = testsList
      vacancies.value = vacancyList.filter((item) => item.isOpen)
    }

  } catch (cause) {
    error.value = cause instanceof ApiError ? cause.message : 'Не удалось загрузить профиль.'
  } finally { loading.value = false }
}

watch(() => route.params.id, load)
onMounted(load)

async function save() {
  if (!profile.value) return
  saving.value = true
  error.value = ''
  success.value = ''
  try {
    profile.value = await api.updateProfile({
      name: draft.name.trim(), headline: draft.headline.trim(), city: draft.city.trim(),
      grade: draft.grade || null, teamRole: draft.teamRole.trim(), workFormat: draft.workFormat || null,
      salary: draft.salary ? Number(draft.salary) : null, skills: draft.skills.split(',').map((x) => x.trim()).filter(Boolean),
      about: draft.about.trim(), openToOffers: draft.openToOffers
    })
    success.value = 'Профиль сохранён.'
  } catch (cause) { error.value = cause instanceof ApiError ? cause.message : 'Не удалось сохранить профиль.' }
  finally { saving.value = false }
}

async function toggleFollow() {
  if (!profile.value) return
  try {
    if (tracked.value) await api.unfollow(profile.value.id)
    else await api.follow(profile.value.id)
    tracked.value = !tracked.value
  } catch (cause) { error.value = cause instanceof ApiError ? cause.message : 'Не удалось обновить отслеживание.' }
}

async function assign(test: AssessmentTest) {
  if (!profile.value) return
  try {
    await api.assignAssessment({ candidateId: profile.value.id, disciplineCode: test.discipline, targetGrade: test.grade })
    success.value = `Тест «${test.title}» назначен кандидату.`
  } catch (cause) { error.value = cause instanceof ApiError ? cause.message : 'Не удалось назначить тест.' }
}

function onTestSelected(value: unknown) {
  if (typeof value !== 'string') return
  const test = tests.value.find((item) => item.id === value)
  if (test) assign(test)
}

async function createOffer() {
  if (!profile.value) return
  error.value = ''
  offerSaving.value = true
  try {
    await api.sendOffer({
      candidateId: profile.value.id,
      vacancyId: offerForm.vacancyId,
      salary: Number(offerForm.salary),
      message: offerForm.message.trim()
    })
    offerModal.value = false
    success.value = 'Предложение отправлено кандидату.'
  } catch (cause) {
    error.value = cause instanceof ApiError ? cause.message : 'Не удалось отправить предложение.'
  } finally {
    offerSaving.value = false
  }
}
</script>

<template>
  <div class="page-wrap">
    <header class="page-heading compact-heading">
      <div><div class="eyebrow">{{ recruiterView ? 'КАНДИДАТ / ПРОФИЛЬ' : 'МОЙ ПРОФИЛЬ' }}</div><h1>{{ recruiterView ? 'Профиль специалиста' : 'Мой профиль' }}</h1><p>{{ recruiterView ? 'Навыки, специализация и подтверждённый опыт.' : 'Помогите HR-командам увидеть ваш опыт и сильные стороны.' }}</p></div>
      <UButton v-if="recruiterView" color="neutral" variant="outline" icon="i-lucide-arrow-left" @click="router.push('/hr/candidates')">К поиску</UButton>
    </header>
    <UAlert v-if="error" color="error" variant="subtle" :description="error" class="mb-4" />
    <UAlert v-if="success" color="success" variant="subtle" :description="success" class="mb-4" />
    <div v-if="loading" class="loading-state"><UIcon name="i-lucide-loader-circle" class="spin" />Загружаем профиль…</div>
    <template v-else-if="profile">
      <UCard class="profile-banner">
        <UAvatar :alt="profile.name" size="3xl" />
        <div class="profile-identity"><div class="identity-name"><h2>{{ profile.name }}</h2><UBadge v-if="profile.verified" color="success" variant="subtle"><UIcon name="i-lucide-badge-check" /> Навыки подтверждены</UBadge></div><p>{{ profile.headline || 'Специалист' }}</p><span>{{ profile.city || 'Локация не указана' }} · {{ profile.grade || 'уровень не указан' }}</span></div>
        <div v-if="recruiterView" class="profile-actions">
          <UButton :color="tracked ? 'neutral' : 'primary'" :variant="tracked ? 'outline' : 'solid'" :icon="tracked ? 'i-lucide-bookmark-check' : 'i-lucide-bookmark-plus'" @click="toggleFollow">{{ tracked ? 'Отслеживается' : 'Отслеживать' }}</UButton>
          <UButton icon="i-lucide-send" :disabled="!vacancies.length" @click="offerModal = true">Предложить вакансию</UButton>
          <UButton icon="i-lucide-message-square" color="neutral" variant="outline" to="/messages">Связаться</UButton>
        </div>
      </UCard>
      <div class="profile-columns">
        <div class="profile-main">
          <UCard class="plain-card">
            <div class="section-heading"><div><span class="eyebrow">ОПЫТ</span><h2>О специалисте</h2></div></div>
            <template v-if="editable">
              <div class="form-grid">
                <UFormField label="Имя"><UInput v-model="draft.name" required class="w-full" /></UFormField>
                <UFormField label="Специализация"><UInput v-model="draft.headline" placeholder="Например, Flutter-разработчик" class="w-full" /></UFormField>
                <UFormField label="Город"><UInput v-model="draft.city" placeholder="Москва" class="w-full" /></UFormField>
                <UFormField label="Уровень"><USelect v-model="draft.grade" :items="[{label:'Junior',value:'junior'},{label:'Middle',value:'middle'},{label:'Senior',value:'senior'},{label:'Lead',value:'lead'}]" placeholder="Выбрать" class="w-full" /></UFormField>
                <UFormField label="Специализация / роль"><UInput v-model="draft.teamRole" placeholder="mobile, backend…" class="w-full" /></UFormField>
                <UFormField label="Формат работы"><USelect v-model="draft.workFormat" :items="[{label:'Удалённо',value:'remote'},{label:'Гибрид',value:'hybrid'},{label:'Офис',value:'office'}]" placeholder="Выбрать" class="w-full" /></UFormField>
                <UFormField label="Зарплатные ожидания"><UInput v-model="draft.salary" type="number" min="0" placeholder="250000" class="w-full" /></UFormField>
                <UFormField label="Навыки · через запятую" class="form-grid-wide"><UInput v-model="draft.skills" placeholder="Flutter, Dart, SQL" class="w-full" /></UFormField>
                <UFormField label="О себе" class="form-grid-wide"><UTextarea v-model="draft.about" :rows="4" placeholder="Опишите опыт и задачи, которые вам интересны" class="w-full" /></UFormField>
              </div>
              <div class="inline-toggle"><USwitch v-model="draft.openToOffers" /><span>Открыт(а) к предложениям</span></div>
              <div class="form-actions"><UButton :loading="saving" icon="i-lucide-save" @click="save">Сохранить профиль</UButton></div>
            </template>
            <template v-else>
              <p class="profile-about">{{ profile.about || 'Кандидат пока не добавил информацию о себе.' }}</p>
              <div class="detail-facts"><div><span>Роль</span><strong>{{ profile.teamRole || '—' }}</strong></div><div><span>Формат</span><strong>{{ profile.workFormat || '—' }}</strong></div><div><span>Ожидания</span><strong>{{ profile.salary ? `${profile.salary.toLocaleString('ru-RU')} ₽` : 'Обсуждается' }}</strong></div></div>
            </template>
          </UCard>
          <UCard class="plain-card">
            <div class="section-heading"><div><span class="eyebrow">КОМПЕТЕНЦИИ</span><h2>Навыки</h2></div><UBadge color="primary" variant="subtle">{{ profile.skills.length }}</UBadge></div>
            <div v-if="profile.skills.length" class="skill-list"><UBadge v-for="skill in profile.skills" :key="skill" color="neutral" variant="subtle">{{ skill }}</UBadge></div>
            <p v-else class="empty-inline">Навыки пока не добавлены.</p>
          </UCard>
          <UCard class="plain-card">
            <div class="section-heading"><div><span class="eyebrow">ДОСТИЖЕНИЯ</span><h2>Подтверждённый опыт</h2></div></div>
            <div v-if="profile.achievements.length" v-for="item in profile.achievements" :key="`${item.competition}-${item.date}`" class="achievement-row"><span class="achievement-icon"><UIcon name="i-lucide-trophy" /></span><div><strong>{{ item.competition }}</strong><span>{{ item.discipline }} · {{ item.result }} · {{ item.date }}</span></div></div>
            <p v-else class="empty-inline">Подтверждённых достижений пока нет.</p>
          </UCard>
        </div>
        <aside class="profile-aside">
          <UCard class="aside-card">
            <span class="eyebrow">ГОТОВНОСТЬ</span><div class="profile-score">{{ Math.min(100, 30 + profile.skills.length * 10) }}<small>%</small></div><p>Чем полнее профиль, тем проще найти подходящую возможность.</p><UProgress :model-value="Math.min(100, 30 + profile.skills.length * 10)" />
          </UCard>
          <UCard v-if="recruiterView" class="aside-card">
            <span class="eyebrow">СЛЕДУЮЩИЙ ШАГ</span><h3>Оценка навыков</h3><p>Предложите пройти короткий тест по специализации кандидата.</p>
            <div v-if="tests.length" class="form-stack"><USelect :items="tests.map(t => ({ label: t.title, value: t.id }))" placeholder="Выберите тест" @update:model-value="onTestSelected" /><span class="microcopy">Выбор сразу отправит назначение.</span></div>
            <UButton v-else to="/hr/candidates" variant="outline" block>Вернуться к поиску</UButton>
          </UCard>
          <UCard v-else class="aside-card soft-aside"><span class="eyebrow">ВАЖНО</span><h3>Ваш профиль — ваша история</h3><p>Проверяйте, что контакты и зарплатные ожидания актуальны. Вы сами решаете, кому отвечать.</p><RouterLink to="/candidate/offers">Мои предложения <UIcon name="i-lucide-arrow-right" /></RouterLink></UCard>
        </aside>
      </div>
    </template>
    <UModal v-model:open="offerModal" title="Предложение кандидату" description="Отправьте кандидату детали открытой вакансии.">
      <template #body>
        <div class="form-stack">
          <UFormField label="Открытая вакансия"><USelect v-model="offerForm.vacancyId" :items="vacancies.map(v => ({ label: `${v.title} · ${v.salaryFrom.toLocaleString('ru-RU')}–${v.salaryTo.toLocaleString('ru-RU')} ₽`, value: v.id }))" placeholder="Выберите вакансию" required class="w-full" /></UFormField>
          <UFormField label="Предлагаемая зарплата, ₽"><UInput v-model="offerForm.salary" type="number" min="0" required class="w-full" /></UFormField>
          <UFormField label="Сообщение кандидату"><UTextarea v-model="offerForm.message" :rows="4" required class="w-full" /></UFormField>
        </div>
      </template>
      <template #footer><div class="modal-footer"><UButton color="neutral" variant="outline" @click="offerModal = false">Отмена</UButton><UButton :loading="offerSaving" :disabled="!offerForm.vacancyId" icon="i-lucide-send" @click="createOffer">Отправить предложение</UButton></div></template>
    </UModal>
  </div>
</template>
