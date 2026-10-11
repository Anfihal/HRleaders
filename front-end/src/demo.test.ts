import { afterEach, describe, expect, it, vi } from 'vitest'
import { DemoHrApi } from './demo'

const storage = new Map<string, string>()

describe('DemoHrApi', () => {
  afterEach(() => {
    storage.clear()
    vi.stubGlobal('localStorage', {
      getItem: (key: string) => storage.get(key) ?? null,
      setItem: (key: string, value: string) => storage.set(key, value),
      removeItem: (key: string) => storage.delete(key)
    })
  })

  it('supports recruiter search, tracking, assignment, and candidate assessment completion', async () => {
    vi.stubGlobal('localStorage', {
      getItem: (key: string) => storage.get(key) ?? null,
      setItem: (key: string, value: string) => storage.set(key, value),
      removeItem: (key: string) => storage.delete(key)
    })
    const recruiter = new DemoHrApi()
    await recruiter.login('hr@demo.hrleaders.example', 'Demo12345')
    const candidates = await recruiter.searchCandidates({ skill: 'Flutter' })
    expect(candidates.total).toBeGreaterThan(0)
    const candidate = candidates.items[0]
    await recruiter.follow(candidate.id)
    expect((await recruiter.trackedCandidates()).map((item) => item.id)).toContain(candidate.id)
    const assignment = await recruiter.assignAssessment({
      candidateId: candidate.id,
      disciplineCode: 'algorithmic',
      targetGrade: 'junior'
    })

    const person = new DemoHrApi()
    await person.login('candidate@demo.hrleaders.example', 'Demo12345')
    const attempt = await person.startAssignment(assignment.id)
    const test = (await person.assessmentCatalog()).find((item) => item.id === attempt.testId)!
    for (const question of test.questions) {
      await person.answerAssessment(attempt.id, question.id, question.options[0])
    }
    const result = await person.submitAssessment(attempt.id)
    expect(result.status).toBe('scored')
    expect(result.percent).toBe(100)
    expect((await person.assignments()).find((item) => item.id === assignment.id)?.status).toBe('scored')
  })

  it('rejects demo login with an invalid password', async () => {
    vi.stubGlobal('localStorage', {
      getItem: (key: string) => storage.get(key) ?? null,
      setItem: (key: string, value: string) => storage.set(key, value),
      removeItem: (key: string) => storage.delete(key)
    })
    const demo = new DemoHrApi()
    await expect(demo.login('hr@demo.hrleaders.example', 'bad')).rejects.toThrow('Проверьте email и пароль.')
  })
})
