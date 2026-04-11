import { ref } from 'vue'
import { defineStore } from 'pinia'

export type EventStatus = 'open' | 'in_progress' | 'pending_result' | 'pending_validation' | 'finished'

export interface EventOption {
  id: string
  label: string
  totalBets: number
}

export interface BetEvent {
  id: string
  title: string
  description: string
  category: string
  creatorId: string
  creatorAlias: string
  options: EventOption[]
  status: EventStatus
  startDate: string
  endDate: string
  submittedResult?: string
  finalResult?: string
  totalPool: number
  createdAt: string
}

const seed: BetEvent[] = [
  {
    id: 'evt-1',
    title: '¿Quién ganará el Clásico Nacional?',
    description: 'El partido más esperado del torneo entre las dos grandes potencias del fútbol mexicano.',
    category: 'Deportes',
    creatorId: '2',
    creatorAlias: 'juanito',
    options: [
      { id: 'opt-1a', label: 'América', totalBets: 1760 },
      { id: 'opt-1b', label: 'Chivas', totalBets: 1440 },
    ],
    status: 'open',
    startDate: '2026-04-15T18:00:00Z',
    endDate: '2026-04-15T20:00:00Z',
    totalPool: 3200,
    createdAt: '2026-04-01T10:00:00Z',
  },
  {
    id: 'evt-2',
    title: '¿Quién lanzará su álbum primero en 2026?',
    description: 'Dos artistas anunciaron álbumes para este año. ¿Cuál llegará primero al mercado?',
    category: 'Entretenimiento',
    creatorId: '3',
    creatorAlias: 'maria_music',
    options: [
      { id: 'opt-2a', label: 'Bad Bunny', totalBets: 720 },
      { id: 'opt-2b', label: 'J Balvin', totalBets: 1080 },
    ],
    status: 'open',
    startDate: '2026-04-20T00:00:00Z',
    endDate: '2026-04-30T00:00:00Z',
    totalPool: 1800,
    createdAt: '2026-04-02T12:00:00Z',
  },
  {
    id: 'evt-3',
    title: '¿Aprobará el Congreso la Reforma Educativa?',
    description: 'La polémica reforma está en debate. ¿Logrará los votos necesarios para aprobarse?',
    category: 'Política',
    creatorId: '2',
    creatorAlias: 'juanito',
    options: [
      { id: 'opt-3a', label: 'Sí, se aprueba', totalBets: 3150 },
      { id: 'opt-3b', label: 'No, se rechaza', totalBets: 1350 },
    ],
    status: 'in_progress',
    startDate: '2026-04-08T00:00:00Z',
    endDate: '2026-04-12T23:59:00Z',
    totalPool: 4500,
    createdAt: '2026-04-03T09:00:00Z',
  },
  {
    id: 'evt-4',
    title: 'Final Regional de Esports — Torneo Primavera',
    description: 'Los dos mejores equipos del torneo regional se enfrentan en la gran final.',
    category: 'Deportes',
    creatorId: '3',
    creatorAlias: 'maria_music',
    options: [
      { id: 'opt-4a', label: 'Equipo Alpha', totalBets: 1050 },
      { id: 'opt-4b', label: 'Equipo Beta', totalBets: 1050 },
    ],
    status: 'pending_result',
    startDate: '2026-04-07T16:00:00Z',
    endDate: '2026-04-08T16:00:00Z',
    submittedResult: 'opt-4a',
    totalPool: 2100,
    createdAt: '2026-04-04T14:00:00Z',
  },
  {
    id: 'evt-5',
    title: 'Premio Nacional de Literatura 2026',
    description: '¿Cuál de estas obras recibirá el premio de la Academia Nacional de Letras?',
    category: 'Cultura',
    creatorId: '2',
    creatorAlias: 'juanito',
    options: [
      { id: 'opt-5a', label: 'El Río Oscuro', totalBets: 405 },
      { id: 'opt-5b', label: 'Silencio Perpetuo', totalBets: 495 },
    ],
    status: 'pending_validation',
    startDate: '2026-04-05T00:00:00Z',
    endDate: '2026-04-05T23:59:00Z',
    submittedResult: 'opt-5a',
    totalPool: 900,
    createdAt: '2026-04-05T08:00:00Z',
  },
  {
    id: 'evt-6',
    title: 'Campeonato Municipal de Básquetbol',
    description: '¿Ganará el equipo local el campeonato por tercer año consecutivo?',
    category: 'Deportes',
    creatorId: '3',
    creatorAlias: 'maria_music',
    options: [
      { id: 'opt-6a', label: 'Sí gana', totalBets: 3360 },
      { id: 'opt-6b', label: 'No gana', totalBets: 2240 },
    ],
    status: 'finished',
    startDate: '2026-04-01T00:00:00Z',
    endDate: '2026-04-01T22:00:00Z',
    finalResult: 'opt-6a',
    totalPool: 5600,
    createdAt: '2026-03-28T10:00:00Z',
  },
]

export const useEventsStore = defineStore('events', () => {
  const events = ref<BetEvent[]>([...seed])
  const searchQuery = ref('')
  const categoryFilter = ref('')

  function getById(id: string): BetEvent | undefined {
    return events.value.find(e => e.id === id)
  }

  function createEvent(data: Omit<BetEvent, 'id' | 'totalPool' | 'createdAt' | 'status'>): BetEvent {
    // TODO: POST /api/events
    const evt: BetEvent = {
      ...data,
      options: data.options.map(o => ({ ...o, totalBets: 0 })),
      id: `evt-${Date.now()}`,
      totalPool: 0,
      status: 'open',
      createdAt: new Date().toISOString(),
    }
    events.value.unshift(evt)
    return evt
  }

  function submitResult(eventId: string, optionId: string): void {
    // TODO: POST /api/events/:id/result
    const evt = events.value.find(e => e.id === eventId)
    if (!evt) return
    evt.submittedResult = optionId
    evt.status = 'pending_validation'
  }

  function validateResult(eventId: string, approve: boolean): void {
    // TODO: POST /api/admin/events/:id/validate
    const evt = events.value.find(e => e.id === eventId)
    if (!evt) return
    if (approve) {
      evt.finalResult = evt.submittedResult
      evt.status = 'finished'
    } else {
      evt.submittedResult = undefined
      evt.status = 'pending_result'
    }
  }

  function addToBet(eventId: string, optionId: string, amount: number): void {
    const evt = events.value.find(e => e.id === eventId)
    if (!evt) return
    const opt = evt.options.find(o => o.id === optionId)
    if (!opt) return
    opt.totalBets += amount
    evt.totalPool += amount
  }

  function removeFromBet(eventId: string, optionId: string, amount: number): void {
    const evt = events.value.find(e => e.id === eventId)
    if (!evt) return
    const opt = evt.options.find(o => o.id === optionId)
    if (!opt) return
    opt.totalBets = Math.max(0, opt.totalBets - amount)
    evt.totalPool = Math.max(0, evt.totalPool - amount)
  }

  return { events, searchQuery, categoryFilter, getById, createEvent, submitResult, validateResult, addToBet, removeFromBet }
})
