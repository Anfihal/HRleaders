<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { ApiError } from '../api'
import { api } from '../session'

const metrics = ref<Record<string, number>>({})
const loading = ref(true)
const error = ref('')
const cards = computed(() => [
  { label: 'Открытые вакансии', value: metrics.value.open_vacancies ?? 0, icon: 'i-lucide-briefcase-business', tone: '' },
  { label: 'Отправлено предложений', value: metrics.value.offers_sent ?? 0, icon: 'i-lucide-send', tone: 'violet' },
  { label: 'Принято предложений', value: metrics.value.offers_accepted ?? 0, icon: 'i-lucide-handshake', tone: 'green' },
  { label: 'Кандидаты в отслеживании', value: metrics.value.candidates_tracked ?? 0, icon: 'i-lucide-bookmark-check', tone: 'orange' }
])
const acceptanceRate = computed(() => metrics.value.offers_sent ? Math.round((metrics.value.offers_accepted ?? 0) * 100 / metrics.value.offers_sent) : 0)
onMounted(async () => {
  try { metrics.value = await api.analytics() }
  catch (cause) { error.value = cause instanceof ApiError ? cause.message : 'Не удалось загрузить аналитику.' }
  finally { loading.value = false }
})
</script>

<template>
  <div class="page-wrap">
    <header class="page-heading"><div><div class="eyebrow">HR / ПОКАЗАТЕЛИ КОМАНДЫ</div><h1>Аналитика найма</h1><p>Сводная картина вакансий, контактов и результатов предложений.</p></div><span class="header-illustration"><UIcon name="i-lucide-chart-no-axes-combined" /></span></header>
    <UAlert v-if="error" color="error" variant="subtle" :description="error" class="mb-5" />
    <div v-if="loading" class="loading-state"><UIcon name="i-lucide-loader-circle" class="spin" />Собираем показатели…</div>
    <template v-else>
      <div class="analytics-grid"><UCard v-for="item in cards" :key="item.label" class="metric-card"><div class="metric-top"><span class="metric-icon" :class="item.tone"><UIcon :name="item.icon" /></span><UBadge color="neutral" variant="subtle">сейчас</UBadge></div><strong>{{ item.value }}</strong><span>{{ item.label }}</span></UCard></div>
      <section class="section-block analytics-panels">
        <UCard class="plain-card">
          <span class="eyebrow">КОНВЕРСИЯ</span><h2>Отклик на предложения</h2><p>Доля предложений, которые кандидаты приняли.</p>
          <div class="conversion-number">{{ acceptanceRate }}<small>%</small></div><UProgress :model-value="acceptanceRate" color="success" /><div class="conversion-legend"><span><i class="legend-dot green-dot" />Принято · {{ metrics.offers_accepted ?? 0 }}</span><span><i class="legend-dot gray-dot" />Отправлено · {{ metrics.offers_sent ?? 0 }}</span></div>
        </UCard>
        <UCard class="plain-card funnel-card">
          <span class="eyebrow">ВОРОНКА</span><h2>Текущая активность</h2>
          <div class="funnel-step"><span class="funnel-index">01</span><div><strong>{{ metrics.open_vacancies ?? 0 }}</strong><span>открытых вакансий</span></div><span class="funnel-line" /></div>
          <div class="funnel-step"><span class="funnel-index">02</span><div><strong>{{ metrics.candidates_tracked ?? 0 }}</strong><span>сохранённых кандидатов</span></div><span class="funnel-line" /></div>
          <div class="funnel-step"><span class="funnel-index">03</span><div><strong>{{ metrics.offers_sent ?? 0 }}</strong><span>отправленных предложений</span></div></div>
        </UCard>
      </section>
      <UAlert color="neutral" variant="subtle" icon="i-lucide-info" description="Показатели отражают текущие данные выбранного режима. В demo-режиме используются локальные демонстрационные записи." />
    </template>
  </div>
</template>
