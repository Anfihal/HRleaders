import type { RouteRecordRaw } from 'vue-router'
import LandingPage from './views/LandingPage.vue'
import LoginPage from './views/LoginPage.vue'
import RegisterPage from './views/RegisterPage.vue'
import DashboardPage from './views/DashboardPage.vue'
import ProfilePage from './views/ProfilePage.vue'
import AssessmentsPage from './views/AssessmentsPage.vue'
import AttemptPage from './views/AttemptPage.vue'
import ReportPage from './views/ReportPage.vue'
import OffersPage from './views/OffersPage.vue'
import CandidatesPage from './views/CandidatesPage.vue'
import TrackingPage from './views/TrackingPage.vue'
import VacanciesPage from './views/VacanciesPage.vue'
import AnalyticsPage from './views/AnalyticsPage.vue'
import AssistantPage from './views/AssistantPage.vue'
import MessagesPage from './views/MessagesPage.vue'
import { currentUser, restoreSession } from './session'

export const routes: RouteRecordRaw[] = [
  { path: '/', name: 'landing', component: LandingPage, meta: { public: true, title: 'HRleaders' } },
  { path: '/login', name: 'login', component: LoginPage, meta: { public: true, title: 'Вход' } },
  { path: '/register', name: 'register', component: RegisterPage, meta: { public: true, title: 'Регистрация' } },
  { path: '/candidate', name: 'candidate-home', component: DashboardPage, meta: { role: 'candidate', title: 'Главная' } },
  { path: '/candidate/profile', name: 'candidate-profile', component: ProfilePage, meta: { role: 'candidate', title: 'Профиль' } },
  { path: '/candidate/assessments', name: 'candidate-assessments', component: AssessmentsPage, meta: { role: 'candidate', title: 'Тесты' } },
  { path: '/candidate/assessments/:id', name: 'candidate-attempt', component: AttemptPage, meta: { role: 'candidate', title: 'Прохождение теста' } },
  { path: '/candidate/assessments/:id/report', name: 'candidate-report', component: ReportPage, meta: { role: 'candidate', title: 'Отчёт' } },
  { path: '/candidate/offers', name: 'candidate-offers', component: OffersPage, props: { incoming: true }, meta: { role: 'candidate', title: 'Предложения' } },
  { path: '/candidate/matches', name: 'candidate-matches', component: OffersPage, props: { matches: true }, meta: { role: 'candidate', title: 'Совпадения' } },
  { path: '/hr', name: 'hr-home', component: DashboardPage, meta: { role: 'hr', title: 'Обзор' } },
  { path: '/hr/candidates', name: 'hr-candidates', component: CandidatesPage, meta: { role: 'hr', title: 'Кандидаты' } },
  { path: '/hr/candidates/:id', name: 'hr-candidate', component: ProfilePage, props: { recruiterView: true }, meta: { role: 'hr', title: 'Кандидат' } },
  { path: '/hr/tracking', name: 'hr-tracking', component: TrackingPage, meta: { role: 'hr', title: 'Отслеживание' } },
  { path: '/hr/vacancies', name: 'hr-vacancies', component: VacanciesPage, meta: { role: 'hr', title: 'Вакансии' } },
  { path: '/hr/offers', name: 'hr-offers', component: OffersPage, props: { incoming: false }, meta: { role: 'hr', title: 'Предложения' } },
  { path: '/hr/analytics', name: 'hr-analytics', component: AnalyticsPage, meta: { role: 'hr', title: 'Аналитика' } },
  { path: '/hr/assistant', name: 'hr-assistant', component: AssistantPage, meta: { role: 'hr', title: 'HR Assistant' } },
  { path: '/messages', name: 'messages', component: MessagesPage, meta: { title: 'Сообщения' } },
  { path: '/:pathMatch(.*)*', redirect: '/' }
]

export async function guard(to: import('vue-router').RouteLocationNormalized) {
  await restoreSession()
  if (to.meta.public) return true
  const user = currentUser.value
  if (!user) return { name: 'login', query: { from: to.fullPath } }
  if (to.meta.role === 'candidate' && user.role !== 'candidate') return '/hr'
  if (to.meta.role === 'hr' && user.role === 'candidate') return '/candidate'
  return true
}
