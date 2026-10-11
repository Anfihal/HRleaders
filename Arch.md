# HR AI platform

## Архитектура MVP HRleaders (реализовано)

Веб-платформа обратного найма в ИТ с профилями, подтверждёнными данными ФСП. Обоснование — в [`docs/mvp-plan.md`](docs/mvp-plan.md): боли пользователей, гипотезы H1–H6 и отложенные идеи.

| Слой | Где | Что внутри |
|---|---|---|
| Front-end | `front-end/` | Vite + Vue 3 + Nuxt UI + Tailwind + Sass. Слои: API-клиент за интерфейсом `HttpClient` (DI через provide/inject), Pinia-сторы, чистые сервисы, страницы по ролям |
| Макеты | `front-end/sources/` | HTML/CSS/JS-фреймы всех экранов для импорта в Figma |
| Back-end | `back-end/app/` | FastAPI, bounded contexts `identity`, `talent`, `fsp`, `hiring`, `analytics`. В каждом: `domain` → `ports` (Protocol) → `use_cases` → `orm`/`repository`/`api` |
| Интеграция ФСП | `back-end/app/fsp`, `back-end/mock_fsp` | Порт `FspGateway`, HTTP-адаптер, переводчик словаря ФСП (anti-corruption layer) и мок API ФСП |
| Данные | `back-end/migrations` | Обратимые миграции Alembic: схема (`0001`) и справочники с правилами скоринга (`0002`). Seed демо-данных: `python -m app.seed` |
| Поставка | `docker-compose.yml`, `.github/workflows/ci.yml` | Postgres, mock-fsp, API, nginx с SPA. CI: lint, typecheck, unit/integration/e2e, сборка образов |

Принципы:

- Бизнес-правила (веса, пороги уровней, сопоставление дисциплин) хранятся в БД.
- Секреты и адреса задаются только через окружение.
- Ошибки типизированы, имеют единый формат и корректные HTTP-коды.
- Сессия хранится в HttpOnly-cookie.

## Исходная концепция (Telegram-бот, вне MVP)

Ниже — первоначальное описание идеи. Telegram-бот и ML-модули отложены: см. раздел «Гипотезы, сознательно отложенные» в `docs/mvp-plan.md`.

## Project Description

**HR AI platform** includes an intelligent AI-powered Telegram bot platform that revolutionizes recruitment processes and job searching. Built with modern AI capabilities, it serves as a comprehensive HR platform providing tailored experiences for both recruiters and job seekers through sophisticated role-based interactions.

 — отраслевой агрегатор ИТ-вакансий с подтверждаемым профилем

Веб-сервис для подбора ИТ-специалистов, в котором соискатели автоматически категоризируются по объективно подтверждённому профилю, а работодатель сам находит нужную категорию и выходит на конкретного кандидата с вакансией и заработной платой.
Актуальность

Существующие площадки поиска работы универсальны и уже не решают задачу эффективно ни для работодателя, ни для кандидата. Работодатель вручную фильтрует сотни нерелевантных откликов, а кандидат откликается вслепую и не получает обратной связи.

В ИТ-отрасли проблема усугубляется тем, что формальное резюме фиксирует стек и места работы, но не подтверждает практическую компетентность. Отраслевая специфика — стек, грейд, роль в команде, формат работы — на универсальных платформах не формализована.

Отдельный сервис, созданный под ИТ и говорящий с обеими сторонами на профессиональном языке, способен повысить точность подбора и сократить его сроки. Дополнительное преимущество — подтверждаемость квалификации на основе данных Федерации спортивного программирования (ФСП).
Решение

Мы разрабатываем цифровую платформу — отраслевой агрегатор вакансий для ИТ-специалистов с обратной механикой подбора:

    соискатели автоматически категоризируются по объективно подтверждаемому профилю;
    профиль обогащается достижениями из информационных систем ФСП;
    работодатель ищет кандидатов не по ключевым словам, а по подтверждённым категориям;
    работодатель сам выходит на конкретного кандидата с вакансией и заработной платой.

Ключевые возможности
Для соискателя

    Создание профиля ИТ-специалиста.
    Автоматическое обогащение профиля достижениями ФСП: дисциплины, соревнования, результаты, роли, разряды.
    Категоризация по стеку, грейду, роли в команде и формату работы.
    Возможность конвертировать опыт соревновательного программирования в карьерное преимущество.
    Прозрачная обратная связь от работодателей.

Для работодателя

    Поиск кандидатов по формализованным ИТ-категориям.
    Фильтрация по подтверждённым достижениям и практическим навыкам.
    Снижение количества нерелевантных откликов.
    Прямой выход на кандидата с вакансией и зарплатой.
    Экономия времени технических специалистов на первичный скрининг.

Интеграция с ФСП

    Получение данных о достижениях участников соревнований.
    Структура данных: дисциплины, соревнования, результаты, роли, разряды.
    API и/или тестовый мок-сервис ФСП.
    Автоматическое обогащение профиля кандидата.

Как это работает

    Кандидат регистрируется на платформе и заполняет ИТ-профиль.
    Сервис через API ФСП подтягивает подтверждённые достижения участника.
    Алгоритм матчинга и категоризации формирует объективный профиль кандидата.
    Работодатель ищет нужную категорию специалистов.
    Работодатель выбирает конкретного кандидата и отправляет ему вакансию с заработной платой.
    Кандидат получает релевантное предложение и обратную связь.


## 🚀 Key Features

### **For Recruiters & HR Professionals:**
- **Smart Vacancy Management** - Create, analyze, and optimize job postings
- **AI-Powered Candidate Search** - Intelligent matching and filtering
- **Automated Resume Analysis** - Instant screening and scoring
- **Bulk Invitation System** - Streamlined candidate outreach
- **Candidate Scoring & Ranking** - Data-driven decision support

### **For Job Seekers:**
- **AI Resume Builder** - Create professional, optimized resumes
- **Interview Preparation** - Practice questions and answer assistance
- **Skill Assessment** - Test mode with various challenges
- **Personalized Learning** - Course recommendations and career development
- **Application Tracking** - Manage your job search journey

## 🏗️ Architecture & AI Integration

## 📁 Project Structure

```
hr-ai-core/hr-ai-bot/
├── main.py                     # Main application entry point
├── bot/                        # Core bot functionality
│   ├── roles/                  # Role-based feature separation
│   │   ├── recruiter/          # Recruiter-specific modules
│   │   │   ├── vacancy.py      # Vacancy creation & management
│   │   │   ├── search.py       # Candidate search & filtering
│   │   │   ├── analyze.py      # Resume analysis & parsing
│   │   │   └── invite.py       # Invitation management
│   │   └── candidate/          # Job seeker modules
│   │       ├── resume_builder.py    # Resume creation & optimization
│   │       ├── answer_helper.py     # Interview preparation
│   │       ├── test_mode.py         # Skills assessment
│   │       └── courses.py           # Learning recommendations
│   ├── auth/                   # Authentication & authorization
│   │   ├── register.py         # User registration system
│   │   └── role_detector.py    # Role detection & assignment
│   ├── ai/                     # AI/ML core modules
│   │   ├── client.py           # AI service client & integration
│   │   ├── vacancy_analyzer.py # Vacancy parsing & analysis
│   │   ├── candidate_scorer.py # Candidate evaluation & scoring
│   │   └── screening_bot.py    # Automated screening system
│   ├── database/               # Data persistence layer
│   │   ├── user_storage.py     # User management & profiles
│   │   └── vacancy_storage.py  # Vacancy database operations
│   └── utils/                  # Utility functions
│       ├── file_parser.py      # Document parsing (PDF, DOCX)
│       ├── validator.py        # Data validation & sanitization
│       └── logger.py           # Logging configuration
├── config/                     # Configuration management
│   ├── settings.py             # Application settings
│   ├── prompts.py              # AI prompts & templates
│   └── role_flow.py            # Conversation flows & states
├── .env                        # Environment variables
├── requirements.txt            # Project dependencies
└── README.md                   # Project documentation
```
