import { ref } from 'vue'
import { defineStore } from 'pinia'
import { useAuthStore } from './auth'
import { useEventsStore } from './events'

export type BetStatus = 'active' | 'won' | 'lost' | 'cancelled' | 'pending_result'

export interface Bet {
  id: string
  userId: string
  eventId: string
  eventTitle: string
  optionId: string
  optionLabel: string
  amount: number
  status: BetStatus
  placedAt: string
  settledAt?: string
  payout?: number
}

const seed: Bet[] = [
  {
    id: 'bet-1',
    userId: '2',
    eventId: 'evt-1',
    eventTitle: '¿Quién ganará el Clásico Nacional?',
    optionId: 'opt-1a',
    optionLabel: 'América',
    amount: 200,
    status: 'active',
    placedAt: '2026-04-05T10:00:00Z',
  },
  {
    id: 'bet-2',
    userId: '2',
    eventId: 'evt-3',
    eventTitle: '¿Aprobará el Congreso la Reforma Educativa?',
    optionId: 'opt-3a',
    optionLabel: 'Sí, se aprueba',
    amount: 150,
    status: 'active',
    placedAt: '2026-04-04T11:00:00Z',
  },
  {
    id: 'bet-3',
    userId: '2',
    eventId: 'evt-4',
    eventTitle: 'Final Regional de Esports — Torneo Primavera',
    optionId: 'opt-4a',
    optionLabel: 'Equipo Alpha',
    amount: 300,
    status: 'pending_result',
    placedAt: '2026-04-06T14:00:00Z',
  },
  {
    id: 'bet-4',
    userId: '2',
    eventId: 'evt-6',
    eventTitle: 'Campeonato Municipal de Básquetbol',
    optionId: 'opt-6a',
    optionLabel: 'Sí gana',
    amount: 100,
    status: 'won',
    placedAt: '2026-03-29T09:00:00Z',
    settledAt: '2026-04-02T00:00:00Z',
    payout: 167,
  },
]

export const useBetsStore = defineStore('bets', () => {
  const bets = ref<Bet[]>([...seed])

  function getUserBets(userId: string): Bet[] {
    return bets.value.filter(b => b.userId === userId)
  }

  function placeBet(
    userId: string,
    eventId: string,
    eventTitle: string,
    optionId: string,
    optionLabel: string,
    amount: number,
  ): Bet {
    // TODO: POST /api/bets
    const auth = useAuthStore()
    const evts = useEventsStore()
    if (auth.balance < amount) throw new Error('Saldo insuficiente.')
    const bet: Bet = {
      id: `bet-${Date.now()}`,
      userId,
      eventId,
      eventTitle,
      optionId,
      optionLabel,
      amount,
      status: 'active',
      placedAt: new Date().toISOString(),
    }
    bets.value.unshift(bet)
    auth.updateBalance(-amount)
    evts.addToBet(eventId, optionId, amount)
    return bet
  }

  function cancelBet(betId: string): void {
    // TODO: DELETE /api/bets/:id
    const auth = useAuthStore()
    const evts = useEventsStore()
    const bet = bets.value.find(b => b.id === betId)
    if (!bet || bet.status !== 'active') return
    bet.status = 'cancelled'
    auth.updateBalance(bet.amount)
    evts.removeFromBet(bet.eventId, bet.optionId, bet.amount)
  }

  function editBet(betId: string, newAmount: number): void {
    // TODO: PATCH /api/bets/:id
    const auth = useAuthStore()
    const evts = useEventsStore()
    const bet = bets.value.find(b => b.id === betId)
    if (!bet || bet.status !== 'active') return
    const diff = newAmount - bet.amount
    if (diff > 0 && auth.balance < diff) throw new Error('Saldo insuficiente.')
    evts.removeFromBet(bet.eventId, bet.optionId, bet.amount)
    evts.addToBet(bet.eventId, bet.optionId, newAmount)
    auth.updateBalance(-diff)
    bet.amount = newAmount
  }

  return { bets, getUserBets, placeBet, cancelBet, editBet }
})
