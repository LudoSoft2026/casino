<template>
  <div class="history-page">
    <div class="page-header">
      <h1>Mis Apuestas</h1>
      <p>Historial de todas tus jugadas</p>
    </div>

    <!-- Stats -->
    <div class="stats-row">
      <div class="stat-card">
        <span class="stat-val">{{ totalBets }}</span>
        <span class="stat-lbl">Total jugadas</span>
      </div>
      <div class="stat-card">
        <span class="stat-val">{{ activeBets }}</span>
        <span class="stat-lbl">Activas</span>
      </div>
      <div class="stat-card stat-card--won">
        <span class="stat-val">$ {{ totalWon.toLocaleString() }}</span>
        <span class="stat-lbl">Total ganado</span>
      </div>
      <div class="stat-card">
        <span class="stat-val">$ {{ totalWagered.toLocaleString() }}</span>
        <span class="stat-lbl">Total apostado</span>
      </div>
    </div>

    <!-- Filter chips -->
    <div class="chip-row">
      <button
        v-for="f in filters"
        :key="f.value"
        class="chip"
        :class="{ 'chip--active': activeFilter === f.value }"
        @click="activeFilter = f.value"
      >
        {{ f.label }}
      </button>
    </div>

    <!-- Bets list -->
    <div v-if="filteredBets.length > 0" class="bets-list">
      <div v-for="bet in filteredBets" :key="bet.id" class="bet-card">
        <div class="bet-top">
          <span class="bet-status-chip" :class="`chip-${bet.status}`">
            {{ statusLabels[bet.status] }}
          </span>
          <span class="bet-amount">$ {{ bet.amount.toLocaleString() }}</span>
        </div>

        <h3 class="bet-title">{{ bet.eventTitle }}</h3>
        <p class="bet-option">Tu opción: <strong>{{ bet.optionLabel }}</strong></p>

        <div class="bet-bottom">
          <span class="bet-date">{{ formatDate(bet.placedAt) }}</span>
          <div class="bet-actions">
            <span v-if="bet.status === 'won' && bet.payout" class="payout-chip">
              +$ {{ bet.payout.toLocaleString() }} ganados
            </span>
            <button
              v-if="bet.status === 'active' && isEventOpen(bet.eventId)"
              class="btn-manage"
              @click="selectedBet = bet"
            >
              Gestionar
            </button>
          </div>
        </div>
      </div>
    </div>

    <div v-else class="empty-state">
      <span class="empty-icon">🎯</span>
      <p>No tienes apuestas en esta categoría.</p>
    </div>

    <EditBetModal v-if="selectedBet" :bet="selectedBet" @close="selectedBet = null" />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watchEffect } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useEventsStore } from '@/stores/events'
import { useBetsStore, type Bet } from '@/stores/bets'
import EditBetModal from '@/components/EditBetModal.vue'

const router = useRouter()
const auth = useAuthStore()
const eventsStore = useEventsStore()
const betsStore = useBetsStore()

watchEffect(() => { if (!auth.isLoggedIn) router.push('/') })

const activeFilter = ref('all')
const selectedBet = ref<Bet | null>(null)

const filters = [
  { value: 'all', label: 'Todas' },
  { value: 'active', label: 'Activas' },
  { value: 'pending_result', label: 'Pendientes' },
  { value: 'won', label: 'Ganadas' },
  { value: 'lost', label: 'Perdidas' },
  { value: 'cancelled', label: 'Canceladas' },
]

const statusLabels: Record<string, string> = {
  active: 'Activa',
  won: 'Ganada',
  lost: 'Perdida',
  cancelled: 'Cancelada',
  pending_result: 'Esperando resultado',
}

const myBets = computed(() => (auth.user ? betsStore.getUserBets(auth.user.id) : []))

const filteredBets = computed(() => {
  if (activeFilter.value === 'all') return myBets.value
  return myBets.value.filter(b => b.status === activeFilter.value)
})

const totalBets    = computed(() => myBets.value.length)
const activeBets   = computed(() => myBets.value.filter(b => b.status === 'active').length)
const totalWon     = computed(() => myBets.value.filter(b => b.status === 'won').reduce((s, b) => s + (b.payout ?? 0), 0))
const totalWagered = computed(() => myBets.value.reduce((s, b) => s + b.amount, 0))

function isEventOpen(eventId: string): boolean {
  return eventsStore.getById(eventId)?.status === 'open'
}

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString('es-MX', { day: 'numeric', month: 'short', year: 'numeric' })
}
</script>

<style scoped>
.history-page { display: flex; flex-direction: column; gap: 24px; }
.page-header h1 { margin: 0; font-size: 1.8rem; color: #fff; font-weight: bold; }
.page-header p  { margin: 6px 0 0; color: #8b949e; }

/* Stats */
.stats-row { display: flex; gap: 12px; flex-wrap: wrap; }
.stat-card {
  flex: 1; min-width: 120px; background: #161b22; border: 1px solid #30363d;
  border-radius: 10px; padding: 14px 18px; display: flex; flex-direction: column; gap: 4px;
}
.stat-card--won { border-color: rgba(35,134,54,0.35); background: rgba(35,134,54,0.04); }
.stat-val { font-size: 1.3rem; font-weight: bold; color: #fff; }
.stat-lbl { font-size: 0.72rem; color: #8b949e; text-transform: uppercase; letter-spacing: 0.4px; }

/* Chips */
.chip-row { display: flex; flex-wrap: wrap; gap: 8px; }
.chip {
  padding: 6px 14px; border-radius: 20px; font-size: 0.8rem; font-weight: bold;
  border: 1px solid #30363d; background: #161b22; color: #8b949e; cursor: pointer; transition: all 0.2s;
}
.chip:hover { border-color: #58a6ff; color: #e6edf3; }
.chip--active { border-color: #58a6ff; background: rgba(88,166,255,0.1); color: #58a6ff; }

/* Bets list */
.bets-list { display: flex; flex-direction: column; gap: 10px; }
.bet-card {
  background: #161b22; border: 1px solid #30363d; border-radius: 10px;
  padding: 16px 20px; display: flex; flex-direction: column; gap: 8px;
  transition: border-color 0.2s;
}
.bet-card:hover { border-color: #30363d; }

.bet-top { display: flex; justify-content: space-between; align-items: center; }
.bet-status-chip {
  font-size: 0.7rem; font-weight: bold; padding: 3px 10px;
  border-radius: 20px; text-transform: uppercase; letter-spacing: 0.4px;
}
.chip-active         { background: rgba(35,134,54,0.12); color: #2ea043; border: 1px solid rgba(35,134,54,0.3); }
.chip-won            { background: rgba(35,134,54,0.12); color: #2ea043; border: 1px solid rgba(35,134,54,0.3); }
.chip-lost           { background: rgba(248,81,73,0.12); color: #f85149; border: 1px solid rgba(248,81,73,0.3); }
.chip-cancelled      { background: rgba(75,85,99,0.18); color: #9ca3af; border: 1px solid rgba(75,85,99,0.3); }
.chip-pending_result { background: rgba(245,158,11,0.12); color: #f59e0b; border: 1px solid rgba(245,158,11,0.3); }

.bet-amount { font-weight: bold; color: #f59e0b; font-size: 0.95rem; }
.bet-title  { margin: 0; font-size: 0.95rem; color: #e6edf3; font-weight: bold; }
.bet-option { margin: 0; font-size: 0.85rem; color: #8b949e; }
.bet-option strong { color: #e6edf3; }

.bet-bottom { display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 8px; }
.bet-date   { font-size: 0.78rem; color: #8b949e; }
.bet-actions { display: flex; gap: 8px; align-items: center; }

.payout-chip {
  font-size: 0.8rem; color: #2ea043; font-weight: bold;
  background: rgba(35,134,54,0.1); padding: 4px 10px; border-radius: 6px;
}
.btn-manage {
  padding: 6px 14px; border-radius: 6px; font-size: 0.8rem; font-weight: bold;
  background: rgba(0,123,255,0.08); border: 1px solid rgba(0,123,255,0.3);
  color: #58a6ff; cursor: pointer; transition: background 0.2s;
}
.btn-manage:hover { background: rgba(0,123,255,0.18); }

/* Empty */
.empty-state {
  text-align: center; padding: 60px 20px; color: #8b949e;
  display: flex; flex-direction: column; align-items: center; gap: 16px;
}
.empty-icon { font-size: 2.5rem; }
</style>
