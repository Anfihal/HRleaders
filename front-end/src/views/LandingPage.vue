<script setup lang="ts">
import { useRouter } from 'vue-router'
const router = useRouter()
</script>

<template>
  <main class="landing">
    <header class="landing-header">
      <RouterLink to="/" class="brand"><span class="brand-mark">h</span><span>hrleaders</span></RouterLink>
      <UButton color="neutral" variant="ghost" to="/login">Войти</UButton>
    </header>
    <section class="landing-hero">
      <div class="eyebrow"><span class="pulse-dot" /> НАВЫКИ ПОДТВЕРЖДЕНЫ · ЛЮДИ НАЙДЕНЫ</div>
      <h1>Найм начинается<br>с <span>знакомства</span></h1>
      <p>Соединяем специалистов и HR-команды через навыки, подтверждённые делом.</p>
      <div class="landing-actions">
        <UButton size="xl" icon="i-lucide-user-round" @click="router.push('/register?role=candidate')">Я кандидат</UButton>
        <UButton size="xl" color="neutral" variant="outline" icon="i-lucide-briefcase-business" @click="router.push('/register?role=hr')">Я рекрутёр</UButton>
      </div>
      <div class="hero-art">
        <div class="hero-orbit orbit-left"><span class="avatar-figure">Д</span><small>Кандидат</small></div>
        <div class="handshake-art"><UIcon name="i-lucide-handshake" /></div>
        <div class="hero-orbit orbit-right"><span class="avatar-figure red">HR</span><small>HR-команда</small></div>
        <span class="spark spark-one">✳</span><span class="spark spark-two">✦</span>
      </div>
    </section>
    <section class="landing-features">
      <article><span>01 / НАВЫКИ</span><h2>Профиль с доказательствами</h2><p>Достижения FSP и реальные навыки, а не только строки резюме.</p></article>
      <article><span>02 / ВСТРЕЧА</span><h2>Человеческий найм</h2><p>Поиск, тестовые задания, предложения и прозрачная обратная связь.</p></article>
      <article><span>03 / ДОВЕРИЕ</span><h2>Путь понятен обеим сторонам</h2><p>Кандидат и рекрутёр видят статусы и следующие шаги процесса.</p></article>
    </section>
    <footer>HRleaders · платформа навыко-ориентированного найма</footer>
  </main>
</template>
