<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { ApiError } from '../api'
import { api } from '../session'
import type { Offer } from '../types'

const props = defineProps<{ incoming?: boolean; matches?: boolean }>()
const offers = ref<Offer[]>([])
const loading = ref(true)
const error = ref('')
const declining = ref('')
const declineReason = ref('')
const selected = ref<Offer | null>(null)
const showOnly = computed(() => props.matches ? 'accepted' : undefined)
const visibleOffers = computed(() => offers.value.filter((offer) => !showOnly.value || offer.status === showOnly.value))

async function load() {
  loading.value = true
  try { offers.value = await api.offers(Boolean(props.incoming)) }
  catch (cause) { error.value = cause instanceof ApiError ? cause.message : 'Не удалось загрузить предложения.' }
  finally { loading.value = false }
}
onMounted(load)

async function respond(offer: Offer, action: 'accept' | 'decline') {
  error.value = ''
  if (action === 'decline' && !declineReason.value.trim()) { error.value = 'Укажите причину отказа.'; return }
  try {
    await api.respondToOffer(offer.id, action, declineReason.value)
    offer.status = action === 'accept' ? 'accepted' : 'declined'
    offer.declineReason = declineReason.value
    selected.value = null
    declineReason.value = ''
    declining.value = ''
  } catch (cause) { error.value = cause instanceof ApiError ? cause.message : 'Не удалось отправить ответ.' }
}

function badgeColor(status: Offer['status']) {
  return status === 'accepted' ? 'success' : status === 'declined' || status === 'withdrawn' ? 'error' : status === 'viewed' ? 'primary' : 'warning'
}
</script>

<template>
  <div class="page-wrap">
    <header class="page-heading"><div><div class="eyebrow">{{ incoming ? 'КАНДИДАТ' : 'HR' }} / {{ matches ? 'СОВПАДЕНИЯ' : 'ПРЕДЛОЖЕНИЯ' }}</div><h1>{{ matches ? 'Ваши совпадения' : incoming ? 'Предложения от команд' : 'Предложения кандидатам' }}</h1><p>{{ matches ? 'Компании, с которыми вы уже совпали.' : incoming ? 'Посмотрите детали роли и выберите, что подходит именно вам.' : 'История предложений, отправленных кандидатам.' }}</p></div><UButton v-if="!incoming" to="/hr/candidates" icon="i-lucide-user-round-search">Найти кандидата</UButton><UButton v-else-if="!matches" to="/candidate/profile" color="neutral" variant="outline" icon="i-lucide-user-round">Мой профиль</UButton></header>
    <UAlert v-if="error" color="error" variant="subtle" :description="error" class="mb-4" />
    <div v-if="loading" class="loading-state"><UIcon name="i-lucide-loader-circle" class="spin" />Загружаем предложения…</div>
    <template v-else>
      <div class="metric-strip"><div><strong>{{ visibleOffers.length }}</strong><span>{{ matches ? 'совпадений' : 'всего предложений' }}</span></div><div><strong>{{ visibleOffers.filter(x => x.status === 'sent' || x.status === 'viewed').length }}</strong><span>ожидают ответа</span></div><div><strong>{{ visibleOffers.filter(x => x.status === 'accepted').length }}</strong><span>принято</span></div></div>
      <section class="section-block">
        <div class="section-heading"><div><span class="eyebrow">ВАШИ ВОЗМОЖНОСТИ</span><h2>{{ matches ? 'Подтверждённые совпадения' : incoming ? 'Входящие' : 'Исходящие' }}</h2></div></div>
        <div v-if="!visibleOffers.length" class="empty-state"><span class="empty-icon"><UIcon :name="matches ? 'i-lucide-heart-handshake' : 'i-lucide-mail-search'" /></span><h3>{{ matches ? 'Совпадений пока нет' : 'Предложений пока нет' }}</h3><p>{{ incoming ? 'Открытый профиль помогает рекрутёрам найти вас. Загляните в раздел тестов, чтобы дополнить свой профиль результатом.' : 'Сохранённые кандидаты доступны в поиске — откройте профиль, чтобы продолжить знакомство.' }}</p><UButton v-if="incoming" to="/candidate/profile">Обновить профиль</UButton><UButton v-else to="/hr/candidates">Перейти к кандидатам</UButton></div>
        <div v-else class="offer-grid">
          <UCard v-for="offer in visibleOffers" :key="offer.id" class="offer-card">
            <div class="offer-top"><span class="step-icon peach"><UIcon name="i-lucide-handshake" /></span><UBadge :color="badgeColor(offer.status)" variant="subtle">{{ offer.status }}</UBadge></div>
            <span class="eyebrow">{{ offer.company }}</span><h3>{{ offer.vacancy.title }}</h3>
            <p v-if="incoming" class="candidate-headline">{{ offer.message }}</p><p v-else class="candidate-headline">{{ offer.candidateName }} · {{ offer.candidateHeadline }}</p>
            <div class="offer-salary"><strong>{{ offer.salary.toLocaleString('ru-RU') }} ₽</strong><span>в месяц, до вычета налогов</span></div>
            <div class="offer-details"><span><UIcon name="i-lucide-map-pin" /> {{ offer.vacancy.workFormat }}</span><span><UIcon name="i-lucide-signal" /> {{ offer.vacancy.grade }}</span></div>
            <div class="skill-list"><UBadge v-for="skill in offer.vacancy.skills" :key="skill" color="neutral" variant="subtle">{{ skill }}</UBadge></div>
            <div class="offer-bottom"><span>Получено {{ new Date(offer.createdAt).toLocaleDateString('ru-RU') }}</span><UButton size="sm" color="neutral" variant="outline" @click="selected = offer">Подробнее</UButton></div>
            <div v-if="incoming && ['sent','viewed'].includes(offer.status)" class="offer-actions"><UButton class="grow" color="success" @click="respond(offer, 'accept')"><UIcon name="i-lucide-check" /> Принять</UButton><UButton color="neutral" variant="outline" @click="declining = declining === offer.id ? '' : offer.id">Отказать</UButton></div>
            <div v-if="incoming && declining === offer.id" class="decline-box"><UInput v-model="declineReason" placeholder="Коротко укажите причину отказа" class="w-full" /><UButton size="sm" color="error" @click="respond(offer, 'decline')">Подтвердить отказ</UButton></div>
            <p v-if="offer.declineReason" class="offer-decline-note">Причина: {{ offer.declineReason }}</p>
          </UCard>
        </div>
      </section>
    </template>
    <UModal v-model:open="selected" title="Детали предложения">
      <template #body><div v-if="selected" class="offer-modal-content"><UBadge :color="badgeColor(selected.status)" variant="subtle">{{ selected.status }}</UBadge><h2>{{ selected.vacancy.title }}</h2><p>{{ selected.company }} · {{ selected.salary.toLocaleString('ru-RU') }} ₽ / месяц</p><p>{{ selected.message }}</p><h3>Описание роли</h3><p>{{ selected.vacancy.description }}</p><h3>Навыки</h3><div class="skill-list"><UBadge v-for="skill in selected.vacancy.skills" :key="skill" color="neutral" variant="subtle">{{ skill }}</UBadge></div></div></template>
      <template #footer><div class="modal-footer"><UButton color="neutral" variant="outline" @click="selected = null">Закрыть</UButton><UButton v-if="incoming && selected && ['sent','viewed'].includes(selected.status)" color="success" @click="respond(selected, 'accept')">Принять предложение</UButton></div></template>
    </UModal>
  </div>
</template>
