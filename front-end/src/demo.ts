import { ApiError, type HrApi } from './api'
import type {
  AssessmentAssignment,
  AssessmentAttempt,
  AssessmentTest,
  Candidate,
  Offer,
  Page,
  TrackedCandidate,
  User,
  Vacancy
} from './types'

const key = 'hrleaders-vite-demo-v1'
const now = () => new Date().toISOString()
const id = () => crypto.randomUUID()

interface DemoState {
  user: User | null
  candidates: Candidate[]
  tracked: Array<{ recruiterId: string; candidateId: string; followedAt: string }>
  assignments: AssessmentAssignment[]
  attempts: AssessmentAttempt[]
  vacancies: Vacancy[]
  offers: Offer[]
}

const demoTests: AssessmentTest[] = [
  {
    id: 'algorithmic::junior',
    title: 'Algorithmic reasoning · Junior',
    description: 'Короткий демонстрационный тест по основам алгоритмов.',
    discipline: 'algorithmic',
    grade: 'junior',
    durationMinutes: 5,
    questions: [
      { id: 'complexity', prompt: 'Какая структура даёт в среднем поиск ключа за O(1)?', options: ['Хеш-таблица', 'Отсортированный список', 'Связный список'], skills: ['Структуры данных'] },
      { id: 'iteration', prompt: 'Сколько итераций выполняется в цикле от 0 до 4, не включая 4?', options: ['4', '5', '3'], skills: ['Циклы'] },
      { id: 'search', prompt: 'Какие данные нужны бинарному поиску?', options: ['Отсортированные данные', 'Граф', 'Хеш-функция'], skills: ['Алгоритмы поиска'] }
    ]
  },
  {
    id: 'mobile::middle',
    title: 'Mobile engineering · Middle',
    description: 'Базовая оценка проектирования мобильных приложений.',
    discipline: 'mobile',
    grade: 'middle',
    durationMinutes: 7,
    questions: [
      { id: 'state', prompt: 'Что помогает изолировать UI от бизнес-логики?', options: ['Слой состояния', 'Глобальный build()', 'Случайный таймер'], skills: ['Архитектура'] },
      { id: 'offline', prompt: 'Что важно для offline-first приложения?', options: ['Локальное хранилище и синхронизация', 'Только анимации', 'Отключить кэш'], skills: ['Надёжность'] }
    ]
  }
]

function seed(): DemoState {
  const candidates = Array.from({ length: 18 }, (_, i): Candidate => ({
    id: `candidate-${i + 1}`,
    name: i === 0 ? 'Дарья Орлова' : ['Алексей Смирнов', 'Анна Волкова', 'Илья Петров', 'Мария Соколова'][i % 4],
    headline: i % 2 ? 'Python backend engineer' : 'Flutter / Dart engineer',
    city: ['Москва', 'Казань', 'Новосибирск'][i % 3],
    grade: ['junior', 'middle', 'senior', 'lead'][i % 4],
    teamRole: i % 2 ? 'backend' : 'mobile',
    workFormat: ['remote', 'hybrid'][i % 2],
    salary: 150000 + i * 12000,
    skills: i % 2 ? ['Python', 'SQL', 'FastAPI'] : ['Dart', 'Flutter', 'SQL'],
    about: 'Строю надёжные продукты и люблю решать практические инженерные задачи.',
    verified: i % 3 !== 2,
    openToOffers: true,
    fspId: i % 3 ? `DEMO-${i + 1}` : null,
    achievements: i % 3 ? [{ competition: 'Демонстрационный чемпионат программирования', date: '2026-09-20', discipline: 'algorithmic', result: 'Участник' }] : []
  }))
  const vacancies: Vacancy[] = [
    { id: 'vacancy-1', title: 'Flutter Engineer', salaryFrom: 180000, salaryTo: 350000, discipline: 'mobile', grade: 'middle', workFormat: 'remote', skills: ['Dart', 'Flutter'], description: 'Разработка мобильного продукта вместе с небольшой командой.', isOpen: true, createdAt: now() },
    { id: 'vacancy-2', title: 'Python Backend Engineer', salaryFrom: 200000, salaryTo: 400000, discipline: 'backend', grade: 'senior', workFormat: 'hybrid', skills: ['Python', 'SQL'], description: 'Проектирование API и сервисов для HR-платформы.', isOpen: true, createdAt: now() }
  ]
  const hr: User = { id: 'demo-hr', email: 'hr@demo.hrleaders.example', name: 'HR Partner', role: 'hr', company: 'Radius Software' }
  const offers: Offer[] = [{
    id: 'offer-1', candidateId: candidates[0].id, candidateName: candidates[0].name,
    candidateHeadline: candidates[0].headline, vacancy: vacancies[0], company: hr.company!,
    salary: 250000, message: 'Ваш опыт подходит команде. Будем рады обсудить детали.',
    status: 'sent', createdAt: now()
  }]
  return { user: null, candidates, tracked: [], assignments: [], attempts: [], vacancies, offers }
}

function load(): DemoState {
  try {
    const raw = localStorage.getItem(key)
    if (raw) return { ...seed(), ...JSON.parse(raw) as Partial<DemoState> }
  } catch {
    localStorage.removeItem(key)
  }
  return seed()
}

export class DemoHrApi implements HrApi {
  readonly state = load()

  private save() {
    localStorage.setItem(key, JSON.stringify(this.state))
  }
  private requireUser(): User {
    if (!this.state.user) throw new ApiError('Войдите, чтобы продолжить.', 401)
    return this.state.user
  }
  private requireRole(role: 'candidate' | 'hr') {
    const user = this.requireUser()
    if (user.role !== role) throw new ApiError('Недостаточно прав для этого действия.', 403)
    return user
  }

  async login(email: string, password: string) {
    const match = /^(candidate|hr|admin|analyst|superadmin)@demo\.hrleaders\.example$/.exec(email)
    if (!match || password !== 'Demo12345') throw new ApiError('Проверьте email и пароль.', 401)
    const role = match[1] as User['role']
    this.state.user = { id: role === 'candidate' ? 'candidate-1' : `demo-${role}`, email, name: role === 'hr' ? 'HR Partner' : role === 'candidate' ? 'Дарья Орлова' : role, role, company: role === 'hr' ? 'Radius Software' : null }
    this.save()
    return this.state.user
  }
  async register(input: { email: string; password: string; name: string; role: 'candidate' | 'hr'; company?: string }) {
    if (this.state.user) throw new ApiError('Сначала выйдите из текущего аккаунта.')
    this.state.user = { id: id(), email: input.email, name: input.name, role: input.role, company: input.company ?? null }
    if (input.role === 'candidate') {
      this.state.candidates.push({ id: this.state.user.id, name: input.name, headline: 'IT specialist', skills: [], verified: false, openToOffers: true, achievements: [] })
    }
    this.save()
    return this.state.user
  }
  async me() { return this.state.user }
  async logout() { this.state.user = null; this.save() }
  async myProfile() {
    const user = this.requireRole('candidate')
    const profile = this.state.candidates.find((candidate) => candidate.id === user.id) ?? this.state.candidates[0]
    return profile
  }
  async updateProfile(input: Partial<Candidate>) {
    const profile = await this.myProfile()
    Object.assign(profile, input)
    this.save()
    return profile
  }
  async searchCandidates(filter: { query?: string; grade?: string; skill?: string; offset?: number; limit?: number } = {}): Promise<Page<Candidate>> {
    this.requireRole('hr')
    const query = filter.query?.trim().toLowerCase()
    const results = this.state.candidates.filter((candidate) =>
      candidate.openToOffers &&
      (!query || `${candidate.name} ${candidate.headline} ${candidate.city}`.toLowerCase().includes(query)) &&
      (!filter.grade || candidate.grade === filter.grade) &&
      (!filter.skill || candidate.skills.some((skill) => skill.toLowerCase().includes(filter.skill!.toLowerCase())))
    )
    const offset = filter.offset ?? 0
    const limit = filter.limit ?? 20
    return { items: results.slice(offset, offset + limit), total: results.length, offset, limit }
  }
  async candidate(id: string) {
    this.requireRole('hr')
    const found = this.state.candidates.find((candidate) => candidate.id === id)
    if (!found) throw new ApiError('Кандидат не найден.', 404)
    return found
  }
  async follow(candidateId: string): Promise<TrackedCandidate> {
    const recruiter = this.requireRole('hr')
    await this.candidate(candidateId)
    if (!this.state.tracked.some((item) => item.recruiterId === recruiter.id && item.candidateId === candidateId)) {
      this.state.tracked.push({ recruiterId: recruiter.id, candidateId, followedAt: now() })
      this.save()
    }
    return this.trackedCandidates().then((items) => items.find((item) => item.id === candidateId)!)
  }
  async unfollow(candidateId: string) {
    const recruiter = this.requireRole('hr')
    this.state.tracked = this.state.tracked.filter((item) => item.recruiterId !== recruiter.id || item.candidateId !== candidateId)
    this.save()
  }
  async trackedCandidates() {
    const recruiter = this.requireRole('hr')
    return this.state.tracked.filter((item) => item.recruiterId === recruiter.id).flatMap((item) => {
      const candidate = this.state.candidates.find((x) => x.id === item.candidateId)
      if (!candidate) return []
      const result = this.state.attempts.filter((attempt) => attempt.candidateId === candidate.id && attempt.status === 'scored').sort((a, b) => (b.completedAt ?? '').localeCompare(a.completedAt ?? ''))[0]
      return [{ ...candidate, followedAt: item.followedAt, latestScorePercent: result?.percent, latestAssessmentAt: result?.completedAt }]
    })
  }
  async assessmentCatalog() { return demoTests }
  async assignments() {
    const user = this.requireUser()
    return this.state.assignments.filter((item) => user.role === 'hr' ? item.recruiterId === user.id : item.candidateId === user.id)
  }
  async assignAssessment(input: { candidateId: string; disciplineCode: string; targetGrade: string }) {
    const recruiter = this.requireRole('hr')
    const candidate = await this.candidate(input.candidateId)
    const test = demoTests.find((item) => item.discipline === input.disciplineCode && item.grade === input.targetGrade)
    if (!test) throw new ApiError('Тест недоступен.', 404)
    const assignment: AssessmentAssignment = {
      id: id(), recruiterId: recruiter.id, candidateId: candidate.id, candidateName: candidate.name,
      disciplineCode: test.discipline, targetGrade: test.grade, status: 'assigned', assignedAt: now()
    }
    this.state.assignments.unshift(assignment)
    this.save()
    return assignment
  }
  async startAssignment(assignmentId: string) {
    const candidate = this.requireRole('candidate')
    const assignment = this.state.assignments.find((item) => item.id === assignmentId && item.candidateId === candidate.id)
    if (!assignment || assignment.status !== 'assigned') throw new ApiError('Назначение не найдено или уже начато.', 404)
    const attempt = await this.startAssessment(`${assignment.disciplineCode}::${assignment.targetGrade}`, assignment.id)
    assignment.status = 'in_progress'
    assignment.attemptId = attempt.id
    this.save()
    return attempt
  }
  async attempts() {
    const user = this.requireRole('candidate')
    return this.state.attempts.filter((attempt) => attempt.candidateId === user.id)
  }
  async attempt(id: string) {
    const user = this.requireRole('candidate')
    const attempt = this.state.attempts.find((item) => item.id === id && item.candidateId === user.id)
    if (!attempt) throw new ApiError('Попытка не найдена.', 404)
    return attempt
  }
  async startAssessment(testId: string, assignmentId?: string) {
    const candidate = this.requireRole('candidate')
    const test = demoTests.find((item) => item.id === testId)
    if (!test) throw new ApiError('Тест не найден.', 404)
    const attempt: AssessmentAttempt = { id: id(), candidateId: candidate.id, assignmentId, testId, startedAt: now(), status: 'in_progress', answers: Array(test.questions.length).fill(null) }
    this.state.attempts.unshift(attempt)
    this.save()
    return attempt
  }
  async answerAssessment(attemptId: string, questionId: string, answer: string) {
    const attempt = await this.attempt(attemptId)
    if (attempt.status !== 'in_progress') throw new ApiError('Тест уже завершён.')
    const test = demoTests.find((item) => item.id === attempt.testId)!
    const questionIndex = test.questions.findIndex((question) => question.id === questionId)
    const optionIndex = test.questions[questionIndex]?.options.indexOf(answer) ?? -1
    if (questionIndex < 0 || optionIndex < 0) throw new ApiError('Ответ не подходит к вопросу.')
    attempt.answers[questionIndex] = optionIndex
    this.save()
    return attempt
  }
  async submitAssessment(attemptId: string) {
    const attempt = await this.attempt(attemptId)
    const test = demoTests.find((item) => item.id === attempt.testId)!
    if (attempt.answers.some((answer) => answer == null)) throw new ApiError('Ответьте на все вопросы перед завершением.')
    const correct = attempt.answers.filter((answer, index) => answer === test.questions[index].options.indexOf(test.questions[index].options[0])).length
    attempt.answerCorrectness = attempt.answers.map((answer, index) => answer === test.questions[index].options.indexOf(test.questions[index].options[0]))
    attempt.percent = Math.round(correct * 100 / test.questions.length)
    attempt.status = 'scored'
    attempt.completedAt = now()
    if (attempt.assignmentId) {
      const assignment = this.state.assignments.find((item) => item.id === attempt.assignmentId)
      if (assignment) {
        assignment.status = 'scored'
        assignment.scorePercent = attempt.percent
      }
    }
    this.save()
    return attempt
  }
  async vacancies() { this.requireUser(); return this.state.vacancies }
  async createVacancy(input: Omit<Vacancy, 'id' | 'createdAt' | 'isOpen'>) {
    this.requireRole('hr')
    const vacancy = { ...input, id: id(), createdAt: now(), isOpen: true }
    this.state.vacancies.unshift(vacancy)
    this.save()
    return vacancy
  }
  async closeVacancy(id: string) {
    this.requireRole('hr')
    const vacancy = this.state.vacancies.find((item) => item.id === id)
    if (!vacancy) throw new ApiError('Вакансия не найдена.', 404)
    vacancy.isOpen = false
    this.save()
  }
  async offers(incoming: boolean) {
    const user = this.requireUser()
    return this.state.offers.filter((offer) => incoming ? user.role === 'candidate' && offer.candidateId === user.id : user.role === 'hr')
  }
  async sendOffer(input: { candidateId: string; vacancyId: string; salary: number; message: string }) {
    const hr = this.requireRole('hr')
    const candidate = this.state.candidates.find((item) => item.id === input.candidateId)
    const vacancy = this.state.vacancies.find((item) => item.id === input.vacancyId && item.isOpen)
    if (!candidate || !vacancy) throw new ApiError('Выбранный кандидат или вакансия недоступны.')
    if (input.salary < vacancy.salaryFrom || input.salary > vacancy.salaryTo) throw new ApiError('Предложение должно входить в диапазон зарплаты вакансии.')
    const offer: Offer = { id: id(), candidateId: candidate.id, candidateName: candidate.name, candidateHeadline: candidate.headline, vacancy, company: hr.company ?? hr.name, salary: input.salary, message: input.message, status: 'sent', createdAt: now() }
    this.state.offers.unshift(offer)
    this.save()
    return offer
  }
  async respondToOffer(id: string, action: 'accept' | 'decline', reason?: string) {
    const user = this.requireRole('candidate')
    const offer = this.state.offers.find((item) => item.id === id && item.candidateId === user.id)
    if (!offer || !['sent', 'viewed'].includes(offer.status)) throw new ApiError('На это предложение нельзя ответить.')
    if (action === 'decline' && !reason?.trim()) throw new ApiError('Укажите причину отказа.')
    offer.status = action === 'accept' ? 'accepted' : 'declined'
    offer.declineReason = reason
    this.save()
    return offer
  }
  async analytics() {
    const offers = await this.offers(false)
    return {
      open_vacancies: this.state.vacancies.filter((item) => item.isOpen).length,
      offers_sent: offers.length,
      offers_accepted: offers.filter((item) => item.status === 'accepted').length,
      candidates_tracked: (await this.trackedCandidates()).length
    }
  }
  async assistant(prompt: string) {
    this.requireRole('hr')
    const text = prompt.toLowerCase()
    if (/interview|вопрос|собесед/.test(text)) return 'Демонстрационный ответ. Уточните контекст кандидата, попросите привести конкретный пример задачи и отдельно обсудите личный вклад, компромиссы и результат. Не передавайте персональные данные.'
    if (/vacan|вакан|описан/.test(text)) return 'Демонстрационный шаблон: цель роли, ежедневные задачи, ожидаемые результаты первых 90 дней, обязательные навыки, формат работы, команда и диапазон вознаграждения. Проверьте текст на отсутствие дискриминационных требований.'
    return 'Демонстрационный HR-шаблон: задайте критерии роли, разделите обязательные и желательные навыки, подготовьте одинаковые вопросы для всех кандидатов и фиксируйте оценку по доказательствам.'
  }
}
