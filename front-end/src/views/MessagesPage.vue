<template>
  <div class="page-wrap">
    <header class="page-heading"><div><div class="eyebrow">HRLEADERS / КОММУНИКАЦИЯ</div><h1>Сообщения</h1><p>Прямые сообщения помогают продолжить знакомство.</p></div></header>
    <UCard class="empty-state message-unavailable">
      <span class="empty-icon"><UIcon name="i-lucide-message-circle-more" /></span>
      <h3>Сообщения ещё не подключены</h3>
      <p>В API-контракте проекта пока нет сервиса переписки. Чтобы не показывать фальшивые диалоги, продолжайте общение через карточки предложений и профили.</p>
      <div class="welcome-actions"><UButton to="/hr/offers">Предложения HR</UButton><UButton to="/candidate/offers" color="neutral" variant="outline">Предложения кандидата</UButton></div>
    </UCard>
  </div>
</template>
