<template>
  <article class="event-card" :class="catBorderClass">

    <div class="card-top">
      <span class="status-pill" :class="`s-${event.status}`">{{ statusLabel }}</span>
      <span class="card-creator">@{{ event.creatorAlias }}</span>
    </div>

    <h3 class="card-title">{{ event.title }}</h3>

    <!-- Opciones apostables (evento abierto y tiempo restante > 30s) -->
    <div v-if="event.status === 'open' && !isBlocked" class="options-pm">
      <button
        v-for="opt in event.options"
        :key="opt.id"
        class="opt-btn"
        @click="$emit('bet', event.id, opt.id)"
      >
        <div class="opt-top">
          <span class="opt-label">{{ opt.label }}</span>
          <span class="opt-pct">{{ getPercent(opt) }}%</span>
        </div>
        <div class="opt-track">
          <div class="opt-fill" :style="{ width: getPercent(opt) + '%' }"></div>
        </div>
      </button>
    </div>

    <!-- Opciones bloqueadas (≤ 30s antes del cierre) -->
    <div v-else-if="event.status === 'open' && isBlocked" class="options-pm">
      <div
        v-for="opt in event.options"
        :key="opt.id"
        class="opt-btn opt-btn--blocked"
      >
        <div class="opt-top">
          <span class="opt-label">{{ opt.label }}</span>
          <span class="opt-pct">{{ getPercent(opt) }}%</span>
        </div>
        <div class="opt-track">
          <div class="opt-fill" :style="{ width: getPercent(opt) + '%' }"></div>
        </div>
      </div>
      <p class="blocked-notice">🔒 Apuestas cerradas</p>
    </div>

    <!-- Opciones no apostables: solo informativas -->
    <div v-else class="options-static">
      <div
        v-for="opt in event.options"
        :key="opt.id"
        class="opt-static"
        :class="{ 'opt-winner': opt.id === (event.finalResult || event.submittedResult) }"
      >
        <div class="opt-top">
          <span class="opt-label">{{ opt.label }}</span>
          <span class="opt-pct">{{ getPercent(opt) }}%</span>
        </div>
        <div class="opt-track">
          <div class="opt-fill" :style="{ width: getPercent(opt) + '%' }"></div>
        </div>
      </div>
    </div>

    <!-- Footer con countdown en tiempo real -->
    <div class="card-footer">
      <span class="pool">$ {{ event.totalPool.toLocaleString() }} en juego</span>

      <span
        v-if="event.status === 'open' || event.status === 'in_progress'"
        class="countdown"
        :class="[`countdown--${cdColor}`, cdRemaining <= 60_000 ? 'countdown--pulse' : '']"
      >
        <span class="cd-dot">●</span>
        {{ cdDisplay }}
      </span>
      <span v-else class="end-date">
        {{ formatDate(event.endDate) }}
      </span>
    </div>

    <div v-if="isCreator && event.status === 'pending_result'" class="creator-action">
      <button class="btn-result" @click.stop="$emit('submitResult', event.id)">
        Reportar resultado
      </button>
    </div>

  </article>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useCountdown } from '@/composables/useCountdown'
import type { BetEvent, EventOption } from '@/stores/events'

const props = defineProps<{ event: BetEvent }>()
defineEmits<{ bet: [id: string, optionId: string]; submitResult: [id: string] }>()

const auth = useAuthStore()
const isCreator = computed(() => auth.user?.id === props.event.creatorId)

const { display: cdDisplay, color: cdColor, isBlocked, remaining: cdRemaining } = useCountdown(props.event.endDate)

const catBorderMap: Record<string, string> = {
  Deportes: 'border-blue',
  Entretenimiento: 'border-purple',
  Política: 'border-amber',
  Cultura: 'border-green',
  Educacion: 'border-cyan',
}
const statusLabels: Record<string, string> = {
  open: '● Abierto',
  in_progress: '● En curso',
  pending_result: '◐ Esperando resultado',
  pending_validation: '◑ En validación',
  finished: '○ Finalizado',
}

const catBorderClass = computed(() => catBorderMap[props.event.category] ?? 'border-gray')
const statusLabel    = computed(() => statusLabels[props.event.status] ?? props.event.status)

function getPercent(opt: EventOption): number {
  if (!props.event.totalPool) return 0
  return Math.round((opt.totalBets / props.event.totalPool) * 100)
}

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString('es-MX', { day: 'numeric', month: 'short' })
}
</script>

<style scoped>
.event-card {
  background: #161b22;
  border: 1px solid #30363d;
  border-left-width: 3px;
  border-radius: 12px;
  padding: 16px;
  display: flex;
  flex-direction: column;
  gap: 12px;
  transition: transform 0.15s, box-shadow 0.15s;
}
.event-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(0, 0, 0, 0.35);
}

/* Left border por categoría */
.border-blue   { border-left-color: #007bff; }
.border-purple { border-left-color: #a855f7; }
.border-amber  { border-left-color: #f59e0b; }
.border-green  { border-left-color: #10b981; }
.border-cyan   { border-left-color: #06b6d4; }
.border-gray   { border-left-color: #30363d; }

/* Top row */
.card-top { display: flex; justify-content: space-between; align-items: center; }
.status-pill {
  font-size: 0.68rem; font-weight: bold; padding: 2px 8px;
  border-radius: 20px; text-transform: uppercase; letter-spacing: 0.4px;
}
.s-open              { color: #2ea043; }
.s-in_progress       { color: #38bdf8; }
.s-pending_result    { color: #f59e0b; }
.s-pending_validation { color: #a78bfa; }
.s-finished          { color: #6b7280; }
.card-creator { font-size: 0.72rem; color: #4b5563; }

/* Title */
.card-title {
  margin: 0; font-size: 0.95rem; font-weight: bold; color: #e6edf3;
  line-height: 1.4; display: -webkit-box; -webkit-line-clamp: 3;
  -webkit-box-orient: vertical; overflow: hidden;
}

/* Options — open (clickable) */
.options-pm { display: flex; flex-direction: column; gap: 8px; }

.opt-btn {
  width: 100%; background: #0d1117; border: 1px solid #30363d; border-radius: 8px;
  padding: 10px 12px; cursor: pointer; transition: border-color 0.15s, background 0.15s;
  display: flex; flex-direction: column; gap: 6px; text-align: left;
}
.opt-btn:hover { border-color: #58a6ff; background: rgba(88,166,255,0.06); }

.opt-btn--blocked {
  cursor: not-allowed; opacity: 0.55;
}
.opt-btn--blocked:hover { border-color: #30363d; background: #0d1117; }

.blocked-notice {
  margin: 0; font-size: 0.75rem; color: #f85149;
  text-align: center; font-weight: bold; letter-spacing: 0.3px;
}

/* Options — static */
.options-static { display: flex; flex-direction: column; gap: 8px; }
.opt-static {
  background: #0d1117; border: 1px solid #21262d; border-radius: 8px;
  padding: 10px 12px; display: flex; flex-direction: column; gap: 6px;
}
.opt-winner { border-color: #f59e0b; background: rgba(245,158,11,0.05); }

/* Option internals */
.opt-top   { display: flex; justify-content: space-between; align-items: center; }
.opt-label { font-size: 0.85rem; color: #e6edf3; font-weight: 500; }
.opt-pct   { font-size: 0.85rem; font-weight: bold; color: #58a6ff; }
.opt-track { height: 4px; background: #21262d; border-radius: 2px; overflow: hidden; }
.opt-fill  {
  height: 100%; background: linear-gradient(90deg, #007bff, #58a6ff);
  border-radius: 2px; transition: width 0.4s ease;
}
.opt-winner .opt-fill { background: linear-gradient(90deg, #d97706, #fbbf24); }

/* Footer */
.card-footer {
  display: flex; justify-content: space-between; align-items: center;
  padding-top: 4px; border-top: 1px solid #21262d;
}
.pool     { font-size: 0.75rem; color: #f59e0b; font-weight: bold; }
.end-date { font-size: 0.72rem; color: #4b5563; }

/* Countdown */
.countdown {
  display: flex; align-items: center; gap: 4px;
  font-size: 0.75rem; font-weight: bold; font-variant-numeric: tabular-nums;
}
.countdown--green { color: #2ea043; }
.countdown--amber { color: #f59e0b; }
.countdown--red   { color: #f85149; }

.cd-dot { font-size: 0.55rem; }

.countdown--red .cd-dot {
  animation: pulse-dot 1s ease-in-out infinite;
}
@keyframes pulse-dot {
  0%, 100% { opacity: 1; }
  50%       { opacity: 0.2; }
}

/* Creator action */
.creator-action { border-top: 1px solid #30363d; padding-top: 10px; }
.btn-result {
  width: 100%; background: rgba(245,158,11,0.08); border: 1px solid rgba(245,158,11,0.3);
  color: #fbbf24; border-radius: 6px; padding: 7px; font-size: 0.82rem;
  font-weight: bold; cursor: pointer; transition: background 0.2s;
}
.btn-result:hover { background: rgba(245,158,11,0.18); }
</style>
