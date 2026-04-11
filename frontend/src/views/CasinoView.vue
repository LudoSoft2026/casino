<template>
  <div class="catalog-page">

    <!-- Header -->
    <div class="page-header">
      <div>
        <h1>Mercados</h1>
        <p>Apuesta en los eventos más emocionantes</p>
      </div>
      <div v-if="auth.isLoggedIn" class="header-balance">
        <span class="balance-chip">$ {{ auth.balance.toLocaleString() }}</span>
        <span class="active-bets" v-if="myActiveBets > 0">{{ myActiveBets }} apuesta{{ myActiveBets > 1 ? 's' : '' }} activa{{ myActiveBets > 1 ? 's' : '' }}</span>
      </div>
    </div>

    <!-- Category tabs — estilo Polymarket -->
    <div class="market-tabs">
      <button
        class="tab"
        :class="{ 'tab--active': eventsStore.categoryFilter === '' }"
        @click="eventsStore.categoryFilter = ''"
      >
        Todos
      </button>
      <button
        v-for="cat in categories"
        :key="cat"
        class="tab"
        :class="{ 'tab--active': eventsStore.categoryFilter === cat }"
        @click="eventsStore.categoryFilter = eventsStore.categoryFilter === cat ? '' : cat"
      >
        {{ catIcons[cat] }} {{ cat }}
      </button>
    </div>

    <!-- Events grid -->
    <div v-if="filteredEvents.length > 0" class="events-grid">
      <EventCard
        v-for="evt in filteredEvents"
        :key="evt.id"
        :event="evt"
        @bet="openBetModal"
        @submitResult="openResultModal"
      />
    </div>
    <div v-else class="empty-state">
      <span class="empty-icon">🔍</span>
      <p>No se encontraron eventos.</p>
      <button class="tab tab--active" @click="clearFilters">Ver todos</button>
    </div>

    <!-- Modals -->
    <BetModal
      v-if="betModalEventId"
      :eventId="betModalEventId"
      :preSelectedOptionId="betModalOptionId"
      @close="closeBetModal"
      @success="closeBetModal"
    />
    <SubmitResultModal
      v-if="resultModalEventId"
      :eventId="resultModalEventId"
      @close="resultModalEventId = ''"
      @success="resultModalEventId = ''"
    />

    <!-- Prompt si intenta apostar sin login -->
    <div v-if="showLoginPrompt" class="overlay-prompt" @click.self="showLoginPrompt = false">
      <div class="login-prompt">
        <p>Debes iniciar sesión para apostar.</p>
        <button class="btn-ok" @click="showLoginPrompt = false">Entendido</button>
      </div>
    </div>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onUnmounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useEventsStore } from '@/stores/events'
import { useBetsStore } from '@/stores/bets'
import EventCard from '@/components/EventCard.vue'
import BetModal from '@/components/BetModal.vue'
import SubmitResultModal from '@/components/SubmitResultModal.vue'

const auth = useAuthStore()
const eventsStore = useEventsStore()
const betsStore = useBetsStore()

const betModalEventId = ref('')
const betModalOptionId = ref('')
const resultModalEventId = ref('')
const showLoginPrompt = ref(false)

const categories = ['Deportes', 'Entretenimiento', 'Política', 'Cultura', 'Educacion']
const catIcons: Record<string, string> = {
  Deportes: '⚽', Entretenimiento: '🎬', Política: '🏛', Cultura: '🎭', Educacion: '📚',
}

const filteredEvents = computed(() =>
  eventsStore.events.filter(e => {
    if (eventsStore.categoryFilter && e.category !== eventsStore.categoryFilter) return false
    if (eventsStore.searchQuery && !e.title.toLowerCase().includes(eventsStore.searchQuery.toLowerCase())) return false
    return true
  }),
)

const myActiveBets = computed(() => {
  if (!auth.user) return 0
  return betsStore.getUserBets(auth.user.id).filter(b => b.status === 'active').length
})

function openBetModal(eventId: string, optionId: string): void {
  if (!auth.isLoggedIn) { showLoginPrompt.value = true; return }
  betModalEventId.value = eventId
  betModalOptionId.value = optionId
}

function closeBetModal(): void {
  betModalEventId.value = ''
  betModalOptionId.value = ''
}

function openResultModal(eventId: string): void {
  resultModalEventId.value = eventId
}

function clearFilters(): void {
  eventsStore.searchQuery = ''
  eventsStore.categoryFilter = ''
}

onUnmounted(() => {
  eventsStore.searchQuery = ''
  eventsStore.categoryFilter = ''
})
</script>

<style scoped>
.catalog-page { display: flex; flex-direction: column; gap: 24px; }

/* Header */
.page-header {
  display: flex; justify-content: space-between; align-items: flex-end;
  padding-bottom: 20px; border-bottom: 1px solid #21262d;
}
.page-header h1 { margin: 0; font-size: 1.8rem; color: #fff; font-weight: bold; }
.page-header p  { margin: 4px 0 0; color: #8b949e; font-size: 0.88rem; }

.header-balance { display: flex; flex-direction: column; align-items: flex-end; gap: 4px; }
.balance-chip {
  background: #21262d; border: 1px solid #30363d; border-radius: 20px;
  padding: 5px 14px; font-weight: bold; color: #f59e0b; font-size: 0.9rem;
}
.active-bets { font-size: 0.72rem; color: #8b949e; }

/* Market tabs — Polymarket style */
.market-tabs {
  display: flex; gap: 6px; overflow-x: auto; padding-bottom: 2px;
  scrollbar-width: none;
}
.market-tabs::-webkit-scrollbar { display: none; }

.tab {
  padding: 7px 18px; border-radius: 20px; font-size: 0.82rem; font-weight: bold;
  border: 1px solid #30363d; background: transparent; color: #8b949e;
  cursor: pointer; transition: all 0.15s; white-space: nowrap; flex-shrink: 0;
}
.tab:hover { border-color: #58a6ff; color: #e6edf3; }
.tab--active {
  border-color: #58a6ff; background: rgba(88, 166, 255, 0.12); color: #58a6ff;
}

/* Grid */
.events-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 14px;
}

/* Empty */
.empty-state {
  text-align: center; padding: 60px 20px; color: #8b949e;
  display: flex; flex-direction: column; align-items: center; gap: 16px;
}
.empty-icon { font-size: 2.5rem; }
.empty-state p { font-size: 1rem; }

/* Login prompt */
.overlay-prompt {
  position: fixed; inset: 0; background: rgba(0,0,0,0.7);
  display: flex; justify-content: center; align-items: center; z-index: 3000;
}
.login-prompt {
  background: #161b22; border: 1px solid #30363d; border-radius: 12px;
  padding: 24px 30px; color: white; text-align: center;
  display: flex; flex-direction: column; gap: 15px;
}
.login-prompt p { margin: 0; color: #e6edf3; }
.btn-ok {
  background: #007bff; color: white; border: none; padding: 10px 24px;
  border-radius: 8px; font-weight: bold; cursor: pointer; transition: background 0.2s;
}
.btn-ok:hover { background: #58a6ff; }
</style>
