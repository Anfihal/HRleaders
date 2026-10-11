<script setup lang="ts">
import { nextTick, ref } from 'vue'
import { ApiError } from '../api'
import { api, isDemo } from '../session'

interface Message { role: 'user' | 'assistant'; text: string }
const messages = ref<Message[]>([{ role: 'assistant', text: 'Здравствуйте! Я помогу подготовить вопросы для интервью или структуру вакансии. Расскажите, что сейчас нужно команде.' }])
const prompt = ref('')
const loading = ref(false)
const error = ref('')
const history = ref<HTMLElement | null>(null)

async function ask(value = prompt.value) {
  const text = value.trim()
  if (!text || loading.value) return
  messages.value.push({ role: 'user', text })
  prompt.value = ''
  loading.value = true
  error.value = ''
  try {
    const answer = await api.assistant(text)
    messages.value.push({ role: 'assistant', text: answer })
  } catch (cause) {
    error.value = cause instanceof ApiError ? cause.message : 'Не удалось получить ответ.'
  } finally {
    loading.value = false
    await nextTick()
    history.value?.scrollTo({ top: history.value.scrollHeight, behavior: 'smooth' })
  }
}
</script>

<template>
  <div class="page-wrap">
    <header class="page-heading"><div><div class="eyebrow">HR / ИНСТРУМЕНТЫ КОМАНДЫ</div><h1>HR Assistant<span class="heading-spark">✳</span></h1><p>Поддержка в подготовке интервью и описаний ролей.</p></div><UBadge :color="isDemo ? 'warning' : 'neutral'" variant="subtle">{{ isDemo ? 'DEMO-ОТВЕТЫ' : 'НЕДОСТУПЕН' }}</UBadge></header>
    <UAlert v-if="!isDemo" color="warning" variant="subtle" icon="i-lucide-info" description="На сервере пока нет API HR Assistant. Live-режим не подменяет ответы фиктивным AI." class="mb-5" />
    <UCard class="assistant-card">
      <div class="assistant-top"><span class="assistant-avatar"><UIcon name="i-lucide-sparkles" /></span><div><strong>HR Assistant</strong><span>{{ isDemo ? 'Локальный демонстрационный помощник' : 'Серверный API не подключён' }}</span></div><UBadge color="success" variant="subtle"><i class="status-dot" />готов</UBadge></div>
      <div ref="history" class="chat-history" aria-live="polite">
        <div v-for="(message, index) in messages" :key="index" class="chat-message" :class="message.role"><span v-if="message.role === 'assistant'" class="chat-avatar"><UIcon name="i-lucide-sparkles" /></span><p>{{ message.text }}</p></div>
        <div v-if="loading" class="chat-message assistant"><span class="chat-avatar"><UIcon name="i-lucide-sparkles" /></span><p class="typing"><i /><i /><i /></p></div>
      </div>
      <UAlert v-if="error" color="warning" variant="subtle" :description="error" class="assistant-alert" />
      <div class="suggested-prompts"><span>ПОПРОБУЙТЕ</span><button type="button" @click="ask('Подготовь вопросы для интервью Flutter-разработчика')">Вопросы для интервью</button><button type="button" @click="ask('Помоги составить описание вакансии')">Описание вакансии</button></div>
      <form class="chat-compose" @submit.prevent="ask()"><UTextarea v-model="prompt" :rows="2" autoresize :disabled="!isDemo || loading" placeholder="Спросите о найме или интервью…" class="w-full" /><UButton type="submit" icon="i-lucide-send" aria-label="Отправить" :disabled="!isDemo || !prompt.trim()" :loading="loading" /></form>
      <p class="assistant-disclaimer"><UIcon name="i-lucide-shield-alert" /> {{ isDemo ? 'Демонстрационные шаблоны, не AI-оценка. Не вводите персональные данные кандидатов.' : 'Не вводите чувствительные данные в незапущенный инструмент.' }}</p>
    </UCard>
  </div>
</template>
