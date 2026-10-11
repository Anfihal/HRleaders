export type Role = 'candidate' | 'hr' | 'admin' | 'analyst' | 'superadmin'

export interface User {
  id: string
  email: string
  name: string
  role: Role
  company?: string | null
}

export interface Candidate {
  id: string
  name: string
  headline: string
  city?: string | null
  grade?: string | null
  teamRole?: string | null
  workFormat?: string | null
  salary?: number | null
  skills: string[]
  about?: string | null
  verified: boolean
  openToOffers: boolean
  fspId?: string | null
  achievements: Achievement[]
}

export interface Achievement {
  competition: string
  date: string
  discipline: string
  result: string
}

export interface AssessmentQuestion {
  id: string
  prompt: string
  options: string[]
  skills: string[]
}

export interface AssessmentTest {
  id: string
  title: string
  description: string
  discipline: string
  grade: string
  durationMinutes: number
  questions: AssessmentQuestion[]
}

export type AttemptStatus = 'in_progress' | 'submitted' | 'scored' | 'expired'

export interface AssessmentAttempt {
  id: string
  candidateId: string
  assignmentId?: string
  testId: string
  startedAt: string
  status: AttemptStatus
  answers: Array<number | null>
  answerCorrectness?: Array<boolean | null>
  percent?: number | null
  completedAt?: string | null
}

export type AssignmentStatus =
  | 'assigned'
  | 'in_progress'
  | 'submitted'
  | 'scored'
  | 'expired'

export interface AssessmentAssignment {
  id: string
  recruiterId: string
  candidateId: string
  candidateName: string
  disciplineCode: string
  targetGrade: string
  status: AssignmentStatus
  assignedAt: string
  dueAt?: string | null
  attemptId?: string | null
  scorePercent?: number | null
}

export interface TrackedCandidate extends Candidate {
  followedAt: string
  latestScorePercent?: number | null
  latestAssessmentAt?: string | null
}

export interface Vacancy {
  id: string
  title: string
  salaryFrom: number
  salaryTo: number
  discipline: string
  grade: string
  workFormat: string
  skills: string[]
  description: string
  isOpen: boolean
  createdAt: string
}

export type OfferStatus =
  | 'sent'
  | 'viewed'
  | 'accepted'
  | 'declined'
  | 'withdrawn'

export interface Offer {
  id: string
  candidateId: string
  candidateName: string
  candidateHeadline: string
  vacancy: Vacancy
  company: string
  salary: number
  message: string
  status: OfferStatus
  createdAt: string
  declineReason?: string | null
}

export interface Page<T> {
  items: T[]
  total: number
  limit: number
  offset: number
}

export interface AppError {
  message: string
  status?: number
}
