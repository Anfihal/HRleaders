<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { ApiError } from '../api'
import { api } from '../session'
import type { Vacancy } from '../types'

const vacancies = ref<Vacancy[]>([])
const loading = ref(true)
const error = ref('')
const modalOpen = ref(false)
const saving = ref(false)
const form = reactive({ title: '', discipline: 'mobile', grade: 'middle', workFormat: 'remote', salaryFrom: '', salaryTo: '', skills: '', description: '' })

async function load() {
  loading.value = true
  try { vacancies.value = await api.vacancies() }
  catch (cause) { error.value = cause instanceof ApiError ? cause.message : 'Не удалось загрузить вакансии.' }
  finally { loading.value = false }
}
onMounted(load)
async function create() {
  error.value = ''
  if (!form.title.trim() || !form.description.trim()) { error.value = 'Укажите название роли и описание вакансии.'; return }
  if (!form.salaryFrom || !form.salaryTo || !Number.isFinite(Number(form.salaryFrom)) || !Number.isFinite(Number(form.salaryTo))) { error.value = 'Укажите корректный диапазон зарплаты.'; return }
  if (Number(form.salaryFrom) > Number(form.salaryTo)) { error.value = 'Минимальная зарплата не может быть больше максимальной.'; return }
  saving.value = true
  try {
    const vacancy = await api.createVacancy({
      title: form.title.trim(), discipline: form.discipline, grade: form.grade, workFormat: form.workFormat,
      salaryFrom: Number(form.salaryFrom), salaryTo: Number(form.salaryTo),
      skills: form.skills.split(',').map((x) => x.trim()).filter(Boolean), description: form.description.trim()
    })
    vacancies.value.unshift(vacancy)
    modalOpen.value = false
    Object.assign(form, { title: '', salaryFrom: '', salaryTo: '', skills: '', description: '' })
  } catch (cause) { error.value = cause instanceof ApiError ? cause.message : 'Не удалось создать вакансию.' }
  finally { saving.value = false }
}
async function close(vacancy: Vacancy) {
  try { await api.closeVacancy(vacancy.id); vacancy.isOpen = false }
  catch (cause) { error.value = cause instanceof ApiError ? cause.message : 'Не удалось закрыть вакансию.' }
}
</script>

<template>
  <div class="page-wrap">
    <header class="page-heading"><div><div class="eyebrow">HR / КОМАНДА</div><h1>Вакансии</h1><p>Создавайте роли с прозрачными задачами и диапазоном вознаграждения.</p></div><UButton icon="i-lucide-plus" @click="modalOpen = true">Создать вакансию</UButton></header>
    <UAlert v-if="error" color="error" variant="subtle" :description="error" class="mb-4" />
    <div v-if="loading" class="loading-state"><UIcon name="i-lucide-loader-circle" class="spin" />Загружаем вакансии…</div>
    <template v-else>
      <div class="metric-strip"><div><strong>{{ vacancies.filter(x => x.isOpen).length }}</strong><span>активных вакансий</span></div><div><strong>{{ vacancies.length }}</strong><span>всего опубликовано</span></div><div><strong>{{ new Set(vacancies.filter(x => x.isOpen).map(x => x.discipline)).size }}</strong><span>направления</span></div></div>
      <section class="section-block">
        <div class="section-heading"><div><span class="eyebrow">РОЛИ КОМАНДЫ</span><h2>Ваши вакансии</h2></div></div>
        <div v-if="!vacancies.length" class="empty-state"><span class="empty-icon"><UIcon name="i-lucide-briefcase-business" /></span><h3>Вакансий ещё нет</h3><p>Создайте первую роль и добавьте подходящие навыки.</p><UButton @click="modalOpen = true">Создать вакансию</UButton></div>
        <div v-else class="vacancy-grid">
          <UCard v-for="vacancy in vacancies" :key="vacancy.id" class="vacancy-card">
            <div class="vacancy-top"><span class="step-icon lavender"><UIcon name="i-lucide-briefcase-business" /></span><UBadge :color="vacancy.isOpen ? 'success' : 'neutral'" variant="subtle">{{ vacancy.isOpen ? 'Открыта' : 'Закрыта' }}</UBadge></div>
            <h3>{{ vacancy.title }}</h3><p>{{ vacancy.discipline }} · {{ vacancy.grade }} · {{ vacancy.workFormat }}</p>
            <strong class="salary-range">{{ vacancy.salaryFrom.toLocaleString('ru-RU') }} – {{ vacancy.salaryTo.toLocaleString('ru-RU') }} ₽</strong>
            <p class="vacancy-description">{{ vacancy.description }}</p>
            <div class="skill-list"><UBadge v-for="skill in vacancy.skills" :key="skill" color="neutral" variant="subtle">{{ skill }}</UBadge></div>
            <div class="vacancy-actions"><UButton to="/hr/candidates" variant="outline" color="neutral">Найти кандидатов</UButton><UButton v-if="vacancy.isOpen" color="error" variant="ghost" @click="close(vacancy)">Закрыть</UButton></div>
          </UCard>
        </div>
      </section>
    </template>

    <UModal v-model:open="modalOpen" title="Новая вакансия" description="Опишите роль, чтобы подходящие кандидаты могли узнать о ней.">
      <template #body>
        <form class="form-stack" @submit.prevent="create">
          <UFormField label="Название роли"><UInput v-model="form.title" placeholder="Flutter Engineer" required class="w-full" /></UFormField>
          <div class="form-grid"><UFormField label="Направление"><USelect v-model="form.discipline" :items="[{label:'Mobile',value:'mobile'},{label:'Backend',value:'backend'},{label:'Frontend',value:'frontend'},{label:'Data',value:'data'}]" class="w-full" /></UFormField><UFormField label="Грейд"><USelect v-model="form.grade" :items="[{label:'Junior',value:'junior'},{label:'Middle',value:'middle'},{label:'Senior',value:'senior'},{label:'Lead',value:'lead'}]" class="w-full" /></UFormField><UFormField label="Формат"><USelect v-model="form.workFormat" :items="[{label:'Удалённо',value:'remote'},{label:'Гибрид',value:'hybrid'},{label:'Офис',value:'office'}]" class="w-full" /></UFormField><UFormField label="Зарплата от"><UInput v-model="form.salaryFrom" type="number" min="0" required class="w-full" /></UFormField><UFormField label="Зарплата до"><UInput v-model="form.salaryTo" type="number" min="0" required class="w-full" /></UFormField></div>
          <UFormField label="Навыки · через запятую"><UInput v-model="form.skills" placeholder="Flutter, Dart, SQL" class="w-full" /></UFormField>
          <UFormField label="Описание"><UTextarea v-model="form.description" :rows="3" required class="w-full" /></UFormField>
        </form>
      </template>
      <template #footer><div class="modal-footer"><UButton color="neutral" variant="outline" @click="modalOpen = false">Отмена</UButton><UButton :loading="saving" @click="create">Создать вакансию</UButton></div></template>
    </UModal>
  </div>
</template>
