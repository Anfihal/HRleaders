# HRleaders Web (Vue + Vite + Nuxt UI)

Отдельное веб-приложение HRleaders. Интерфейс построен на Vue 3, Vue Router и Nuxt UI; эта папка не заменяет Flutter-клиент.

## Запуск

```powershell
cd C:\home\Flutter\hr-flutter-app\vite-app
npm install
npm run dev
```

По умолчанию включён демонстрационный режим: используется локальный adapter с вымышленными профилями и сохранением состояния в `localStorage`. Демо-вход:

| Роль | Email | Пароль |
|---|---|---|
| Кандидат | `candidate@demo.hrleaders.example` | `Demo12345` |
| HR-рекрутёр | `hr@demo.hrleaders.example` | `Demo12345` |

В демо реализованы поиск и отслеживание кандидатов, назначение и прохождение оценок, профили, вакансии, предложения, локальные шаблонные ответы HR Assistant и необязательная мини-игра в форме регистрации кандидата. Очистка browser storage сбрасывает локальные данные.

## Серверный API

Live-режим можно включить переменной `VITE_DEMO=false`. При отсутствии `VITE_API_BASE_URL` клиент использует `/api/v1/`; Vite проксирует `/api` на `http://localhost:8000`. Адрес прокси задаётся через `VITE_API_PROXY_TARGET`, а API base URL — через `VITE_API_BASE_URL`.

```powershell
$env:VITE_DEMO = "false"
$env:VITE_API_PROXY_TARGET = "http://localhost:8000"
npm run dev
```

Клиент ожидает endpoints из `public/api/openapi.json`; само наличие OpenAPI-файла не означает, что соответствующие endpoints реализованы или запущены на backend. Переписка и серверный HR Assistant не подключены. В live-режиме Assistant явно сообщает, что endpoint отсутствует, вместо показа фиктивного ответа.

## Сборка и тесты

```powershell
npm run build
npm test
```

Nuxt UI генерирует типовые декларации во время Vite build, поэтому production script сначала собирает приложение, затем выполняет `vue-tsc --noEmit`.
