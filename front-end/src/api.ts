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

export class ApiError extends Error {
  readonly status?: number

  constructor(message: string, status?: number) {
    super(message)
    this.name = 'ApiError'
    this.status = status
  }
}

export interface HrApi {
  login(email: string, password: string): Promise<User>
  register(input: {
    email: string
    password: string
    name: string
    role: 'candidate' | 'hr'
    company?: string
  }): Promise<User>
  me(): Promise<User | null>
  logout(): Promise<void>
  myProfile(): Promise<Candidate>
  updateProfile(profile: Partial<Candidate>): Promise<Candidate>
  searchCandidates(filter?: {
    query?: string
    grade?: string
    skill?: string
    offset?: number
    limit?: number
  }): Promise<Page<Candidate>>
  candidate(id: string): Promise<Candidate>
  follow(id: string): Promise<TrackedCandidate>
  unfollow(id: string): Promise<void>
  trackedCandidates(): Promise<TrackedCandidate[]>
  assessmentCatalog(): Promise<AssessmentTest[]>
  assignments(): Promise<AssessmentAssignment[]>
  assignAssessment(input: {
    candidateId: string
    disciplineCode: string
    targetGrade: string
  }): Promise<AssessmentAssignment>
  startAssignment(id: string): Promise<AssessmentAttempt>
  attempts(): Promise<AssessmentAttempt[]>
  attempt(id: string): Promise<AssessmentAttempt>
  startAssessment(testId: string, assignmentId?: string): Promise<AssessmentAttempt>
  answerAssessment(id: string, questionId: string, answer: string): Promise<AssessmentAttempt>
  submitAssessment(id: string): Promise<AssessmentAttempt>
  vacancies(): Promise<Vacancy[]>
  createVacancy(vacancy: Omit<Vacancy, 'id' | 'createdAt' | 'isOpen'>): Promise<Vacancy>
  closeVacancy(id: string): Promise<void>
  offers(incoming: boolean): Promise<Offer[]>
  sendOffer(input: { candidateId: string; vacancyId: string; salary: number; message: string }): Promise<Offer>
  respondToOffer(id: string, action: 'accept' | 'decline', reason?: string): Promise<Offer>
  analytics(): Promise<Record<string, number>>
  assistant(prompt: string): Promise<string>
}

const apiBase = (import.meta.env.VITE_API_BASE_URL || '/api/v1/').replace(/\/?$/, '/')
let accessToken: string | null = null

export function setAccessToken(value: string | null) {
  accessToken = value
}

export class HttpHrApi implements HrApi {
  private async request<T>(
    method: string,
    path: string,
    body?: unknown,
    query?: Record<string, string | number | boolean | undefined>
  ): Promise<T> {
    const url = new URL(path.replace(/^\//, ''), new URL(apiBase, window.location.origin))
    Object.entries(query ?? {}).forEach(([key, value]) => {
      if (value !== undefined && value !== '') url.searchParams.set(key, String(value))
    })
    let response: Response
    try {
      response = await fetch(url, {
        method,
        credentials: 'include',
        headers: {
          Accept: 'application/json',
          ...(body === undefined ? {} : { 'Content-Type': 'application/json' }),
          ...(accessToken ? { Authorization: `Bearer ${accessToken}` } : {})
        },
        ...(body === undefined ? {} : { body: JSON.stringify(body) })
      })
    } catch {
      throw new ApiError('Не удалось подключиться к серверу. Проверьте сеть и адрес API.')
    }
    if (response.status === 204) return undefined as T
    const payload = await response.json().catch(() => null)
    if (!response.ok) {
      const message =
        (payload as { detail?: string; message?: string } | null)?.detail ??
        (payload as { message?: string } | null)?.message ??
        `Ошибка запроса (${response.status})`
      throw new ApiError(message, response.status)
    }
    return payload as T
  }

  async login(email: string, password: string): Promise<User> {
    const result = await this.request<{
      user: { id: string; email: string; full_name: string; role: User['role']; company_name?: string }
      access_token?: string
    }>('POST', 'auth/login', { email, password })
    setAccessToken(result.access_token ?? null)
    return this.user(result.user)
  }

  async register(input: {
    email: string
    password: string
    name: string
    role: 'candidate' | 'hr'
    company?: string
  }): Promise<User> {
    const result = await this.request<{
      user: { id: string; email: string; full_name: string; role: User['role']; company_name?: string }
      access_token?: string
    }>('POST', 'auth/register', {
      email: input.email,
      password: input.password,
      full_name: input.name,
      role: input.role,
      company_name: input.company
    })
    setAccessToken(result.access_token ?? null)
    return this.user(result.user)
  }

  private user(raw: { id: string; email: string; full_name: string; role: User['role']; company_name?: string }): User {
    return { id: raw.id, email: raw.email, name: raw.full_name, role: raw.role, company: raw.company_name }
  }

  async me(): Promise<User | null> {
    try {
      return this.user(await this.request('GET', 'auth/me'))
    } catch (error) {
      if (error instanceof ApiError && [401, 403].includes(error.status ?? 0)) return null
      throw error
    }
  }

  async logout() {
    try {
      await this.request('POST', 'auth/logout')
    } finally {
      setAccessToken(null)
    }
  }

  myProfile() { return this.request<Candidate>('GET', 'candidates/me').then((p) => this.candidateModel(p)) }
  updateProfile(profile: Partial<Candidate>) {
    return this.request<Candidate>('PUT', 'candidates/me', {
      full_name: profile.name,
      headline: profile.headline,
      city: profile.city,
      grade: profile.grade,
      team_role: profile.teamRole,
      work_format: profile.workFormat,
      salary_expectation: profile.salary,
      skills: profile.skills,
      about: profile.about,
      open_to_offers: profile.openToOffers,
      fsp_participant_id: profile.fspId
    }).then((p) => this.candidateModel(p))
  }

  async searchCandidates(filter: { query?: string; grade?: string; skill?: string; offset?: number; limit?: number } = {}) {
    const result = await this.request<{ items: unknown[]; total: number; limit: number; offset: number }>(
      'GET', 'candidates', undefined, {
        grade: filter.grade,
        skill: filter.skill || filter.query,
        offset: filter.offset ?? 0,
        limit: filter.limit ?? 20
      }
    )
    return { ...result, items: result.items.map((item) => this.candidateModel(item)) }
  }
  candidate(id: string) { return this.request('GET', `candidates/${encodeURIComponent(id)}`).then((p) => this.candidateModel(p)) }
  async follow(id: string): Promise<TrackedCandidate> {
    return this.tracked(await this.request('PUT', `recruiting/tracked-candidates/${encodeURIComponent(id)}`))
  }
  async unfollow(id: string) { await this.request('DELETE', `recruiting/tracked-candidates/${encodeURIComponent(id)}`) }
  async trackedCandidates() {
    return (await this.request<unknown[]>('GET', 'recruiting/tracked-candidates')).map((item) => this.tracked(item))
  }
  async assessmentCatalog(): Promise<AssessmentTest[]> {
    const questions = await this.request<Array<Record<string, unknown>>>('GET', 'assessments/questions')
    const groups = new Map<string, AssessmentTest>()
    for (const question of questions) {
      if (question.question_type !== 'single_choice' || !Array.isArray(question.options) || !question.options.length) continue
      const discipline = String(question.discipline_code ?? '')
      const grade = String(question.target_grade ?? '')
      const id = `${discipline}::${grade}`
      const test = groups.get(id) ?? {
        id, title: `${discipline} · ${grade}`, description: 'Оценочный тест HRleaders',
        discipline, grade, durationMinutes: 20, questions: []
      }
      test.questions.push({
        id: String(question.id),
        prompt: String(question.body ?? ''),
        options: (question.options as string[]),
        skills: Array.isArray(question.skills) ? question.skills as string[] : []
      })
      groups.set(id, test)
    }
    return [...groups.values()]
  }
  async assignments() { return (await this.request<unknown[]>('GET', 'recruiting/assessment-assignments')).map((x) => this.assignment(x)) }
  async assignAssessment(input: { candidateId: string; disciplineCode: string; targetGrade: string }) {
    return this.assignment(await this.request('POST', 'recruiting/assessment-assignments', {
      candidate_id: input.candidateId,
      discipline_code: input.disciplineCode,
      target_grade: input.targetGrade
    }))
  }
  async startAssignment(id: string) {
    const assignment = (await this.assignments()).find((item) => item.id === id)
    if (!assignment) throw new ApiError('Назначение не найдено', 404)
    return this.startAssessment(`${assignment.disciplineCode}::${assignment.targetGrade}`, id)
  }
  async attempts() {
    const items = await this.request<Array<Record<string, unknown>>>('GET', 'assessments/attempts')
    return Promise.all(items.map((item) => this.attempt(String(item.id))))
  }
  async attempt(id: string): Promise<AssessmentAttempt> {
    const raw = await this.request<Record<string, unknown>>('GET', `assessments/attempts/${encodeURIComponent(id)}`)
    const answers = Array.isArray(raw.answers) ? raw.answers as Array<Record<string, unknown>> : []
    const tests = await this.assessmentCatalog()
    const test = tests.find((x) => x.discipline === raw.discipline_code && x.grade === raw.target_grade)
    const questionIds = Array.isArray(raw.question_ids) ? raw.question_ids as string[] : []
    return {
      id: String(raw.id),
      candidateId: '',
      assignmentId: undefined,
      testId: `${raw.discipline_code}::${raw.target_grade}`,
      startedAt: String(raw.started_at),
      status: raw.status as AssessmentAttempt['status'],
      answers: questionIds.map((questionId) => {
        const value = answers.find((answer) => answer.question_id === questionId)?.answer
        const index = test?.questions.find((q) => q.id === questionId)?.options.indexOf(String(value))
        return index === undefined || index < 0 ? null : index
      }),
      answerCorrectness: questionIds.map((questionId) => {
        const correctness = answers.find((answer) => answer.question_id === questionId)?.is_correct
        return typeof correctness === 'boolean' ? correctness : null
      }),
      percent: typeof raw.score_percent === 'number' ? raw.score_percent : null,
      completedAt: (raw.scored_at ?? raw.submitted_at) as string | null
    }
  }
  async startAssessment(testId: string, assignmentId?: string) {
    const [discipline_code, target_grade] = testId.split('::')
    const raw = await this.request<Record<string, unknown>>('POST', 'assessments/attempts/start', {
      discipline_code, target_grade, ...(assignmentId ? { assignment_id: assignmentId } : {})
    })
    return this.normalizeAttempt(raw, testId, assignmentId)
  }
  async answerAssessment(id: string, questionId: string, answer: string) {
    const raw = await this.request<Record<string, unknown>>('POST', `assessments/attempts/${encodeURIComponent(id)}/answers`, { question_id: questionId, answer })
    const attempt = await this.attempt(id)
    return { ...attempt, status: raw.status as AssessmentAttempt['status'] }
  }
  async submitAssessment(id: string) {
    await this.request<Record<string, unknown>>('POST', `assessments/attempts/${encodeURIComponent(id)}/submit`)
    return this.attempt(id)
  }
  private normalizeAttempt(raw: Record<string, unknown>, testId: string, assignmentId?: string): AssessmentAttempt {
    const answers = Array.isArray(raw.answers) ? raw.answers as Array<Record<string, unknown>> : []
    const test = testId
    return {
      id: String(raw.id), candidateId: '', assignmentId, testId: test,
      startedAt: String(raw.started_at), status: raw.status as AssessmentAttempt['status'],
      answers: answers.map(() => null),
      percent: typeof raw.score_percent === 'number' ? raw.score_percent : null,
      completedAt: (raw.scored_at ?? raw.submitted_at) as string | null
    }
  }
  async vacancies() {
    return (await this.request<unknown[]>('GET', 'vacancies')).map((x) => this.vacancy(x))
  }
  async createVacancy(input: Omit<Vacancy, 'id' | 'createdAt' | 'isOpen'>) {
    return this.vacancy(await this.request('POST', 'vacancies', {
      title: input.title, salary_from: input.salaryFrom, salary_to: input.salaryTo,
      discipline_code: input.discipline, grade: input.grade, work_format: input.workFormat,
      skills: input.skills, description: input.description
    }))
  }
  async closeVacancy(id: string) { await this.request('POST', `vacancies/${encodeURIComponent(id)}/close`) }
  async offers(incoming: boolean) {
    return (await this.request<unknown[]>('GET', incoming ? 'offers/incoming' : 'offers')).map((x) => this.offer(x))
  }
  async sendOffer(input: { candidateId: string; vacancyId: string; salary: number; message: string }) {
    return this.offer(await this.request('POST', 'offers', {
      candidate_id: input.candidateId, vacancy_id: input.vacancyId, salary: input.salary, message: input.message
    }))
  }
  async respondToOffer(id: string, action: 'accept' | 'decline', reason?: string) {
    return this.offer(await this.request('POST', `offers/${encodeURIComponent(id)}/${action}`, action === 'decline' ? { reason } : {}))
  }
  async analytics() { return this.request<Record<string, number>>('GET', 'analytics/overview') }
  async assistant(_prompt: string): Promise<string> { throw new ApiError('HR Assistant доступен только в demo-режиме: серверный API не подключён.') }

  private candidateModel(value: unknown): Candidate {
    const x = value as Record<string, unknown>
    return {
      id: String(x.id), name: String(x.full_name ?? x.candidate_name ?? ''),
      headline: String(x.headline ?? ''), city: x.city as string | null,
      grade: x.grade as string | null, teamRole: x.team_role as string | null,
      workFormat: x.work_format as string | null,
      salary: x.salary_expectation as number | null,
      skills: Array.isArray(x.skills) ? x.skills as string[] : [],
      about: x.about as string | null, verified: Boolean(x.is_fsp_verified),
      openToOffers: Boolean(x.open_to_offers), fspId: x.fsp_participant_id as string | null,
      achievements: []
    }
  }
  private tracked(value: unknown): TrackedCandidate {
    const x = value as Record<string, unknown>
    return {
      id: String(x.candidate_id), name: String(x.candidate_name),
      headline: String(x.headline), skills: [], verified: false, openToOffers: true,
      followedAt: String(x.followed_at), latestScorePercent: x.latest_score_percent as number | null,
      latestAssessmentAt: x.latest_assessment_at as string | null, achievements: []
    }
  }
  private assignment(value: unknown): AssessmentAssignment {
    const x = value as Record<string, unknown>
    return {
      id: String(x.id), recruiterId: String(x.recruiter_id), candidateId: String(x.candidate_id),
      candidateName: String(x.candidate_name), disciplineCode: String(x.discipline_code),
      targetGrade: String(x.target_grade), status: x.status as AssessmentAssignment['status'],
      assignedAt: String(x.assigned_at), dueAt: x.due_at as string | null,
      attemptId: x.attempt_id as string | null, scorePercent: x.score_percent as number | null
    }
  }
  private vacancy(value: unknown): Vacancy {
    const x = value as Record<string, unknown>
    return {
      id: String(x.id), title: String(x.title), salaryFrom: Number(x.salary_from),
      salaryTo: Number(x.salary_to), discipline: String(x.discipline_code ?? ''),
      grade: String(x.grade ?? ''), workFormat: String(x.work_format ?? ''),
      skills: Array.isArray(x.skills) ? x.skills as string[] : [],
      description: String(x.description), isOpen: Boolean(x.is_open), createdAt: String(x.created_at)
    }
  }
  private offer(value: unknown): Offer {
    const x = value as Record<string, unknown>
    return {
      id: String(x.id), candidateId: String(x.candidate_id),
      candidateName: String(x.candidate_name), candidateHeadline: String(x.candidate_headline),
      vacancy: this.vacancy(x.vacancy), company: String(x.company_name), salary: Number(x.salary),
      message: String(x.message), status: x.status as Offer['status'], createdAt: String(x.created_at),
      declineReason: x.decline_reason as string | null
    }
  }
}
