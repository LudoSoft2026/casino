<template>
  <div class="modal-overlay" @click.self="$emit('close')">
    <article class="bet-modal">
      <header class="modal-header">
        <h3>Realizar Apuesta</h3>
        <p v-if="event">{{ event.title }}</p>
      </header>

      <div v-if="event" class="modal-body">
        <p class="event-desc">{{ event.description }}</p>

        <section class="form-section">
          <label>Elige una opción</label>
          <div class="options-grid">
            <button
              v-for="opt in event.options"
              :key="opt.id"
              class="option-btn"
              :class="{ 'option-btn--selected': selectedOption === opt.id }"
              @click="selectedOption = opt.id"
            >
              <span class="opt-name">{{ opt.label }}</span>
              <span class="opt-pct">{{ getPercent(opt) }}%</span>
            </button>
          </div>
        </section>

        <section class="form-section">
          <label>Monto a apostar</label>
          <div class="amount-wrap">
            <span class="coin-icon">$</span>
            <input
              type="number"
              v-model.number="amount"
              min="1"
              :max="auth.balance"
              placeholder="0"
            />
          </div>
          <small class="balance-hint">Saldo disponible: $ {{ auth.balance.toLocaleString() }}</small>

          <div v-if="projectedReturn > 0 && selectedOption" class="projection">
            <span class="proj-label">Retorno estimado</span>
            <span class="proj-value">$ {{ projectedReturn.toLocaleString() }}</span>
          </div>
        </section>

        <p v-if="errorMessage" class="error-msg">{{ errorMessage }}</p>

        <button
          class="btn-submit"
          @click="handleBet"
          :disabled="!selectedOption || amount <= 0"
        >
          Confirmar Apuesta
        </button>
      </div>

      <footer>
        <button class="btn-close" @click="$emit('close')">Cerrar</button>
      </footer>
    </article>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useEventsStore, type EventOption } from '@/stores/events'
import { useBetsStore } from '@/stores/bets'

const props = defineProps<{ eventId: string; preSelectedOptionId?: string }>()
const emit = defineEmits<{ close: []; success: [] }>()

const auth = useAuthStore()
const eventsStore = useEventsStore()
const betsStore = useBetsStore()

const event = computed(() => eventsStore.getById(props.eventId))
const selectedOption = ref<string>(props.preSelectedOptionId ?? '')
const amount = ref<number>(0)
const errorMessage = ref('')

const projectedReturn = computed(() => {
  if (!event.value || !selectedOption.value || amount.value <= 0) return 0
  const opt = event.value.options.find(o => o.id === selectedOption.value)
  if (!opt) return 0
  const newPool = event.value.totalPool + amount.value
  const newOptBets = opt.totalBets + amount.value
  return Math.round((amount.value * newPool) / newOptBets)
})

function getPercent(opt: EventOption): number {
  if (!event.value?.totalPool) return 0
  return Math.round((opt.totalBets / event.value.totalPool) * 100)
}

function handleBet(): void {
  errorMessage.value = ''
  if (!auth.isLoggedIn) { errorMessage.value = 'Debes iniciar sesión para apostar.'; return }
  if (!selectedOption.value) { errorMessage.value = 'Selecciona una opción.'; return }
  if (amount.value <= 0) { errorMessage.value = 'El monto debe ser mayor a 0.'; return }
  if (!event.value) return

  const opt = event.value.options.find(o => o.id === selectedOption.value)
  if (!opt) return

  try {
    betsStore.placeBet(
      auth.user!.id, event.value.id, event.value.title,
      opt.id, opt.label, amount.value,
    )
    emit('success')
    emit('close')
  } catch (err: any) {
    errorMessage.value = err.message
  }
}
</script>

<style scoped>
.modal-overlay {
  position: fixed; inset: 0; background: rgba(0,0,0,0.85);
  display: flex; justify-content: center; align-items: center; z-index: 3000;
}
.bet-modal {
  background: #161b22; padding: 30px; border-radius: 12px;
  border: 1px solid #007bff; color: white; width: 100%; max-width: 440px;
  max-height: 90vh; overflow-y: auto; box-shadow: 0 10px 30px rgba(0,0,0,0.5);
  display: flex; flex-direction: column; gap: 15px;
}
.modal-header h3 { margin: 0; font-size: 1.3rem; color: #fff; }
.modal-header p  { margin: 4px 0 0; color: #8b949e; font-size: 0.85rem; }
.modal-body { display: flex; flex-direction: column; gap: 15px; }
.event-desc { color: #8b949e; font-size: 0.85rem; line-height: 1.5; margin: 0; }

.form-section { display: flex; flex-direction: column; gap: 8px; }
.form-section > label {
  color: #58a6ff; font-size: 0.72rem; font-weight: bold;
  text-transform: uppercase; letter-spacing: 0.5px;
}

.options-grid { display: flex; flex-direction: column; gap: 8px; }
.option-btn {
  display: flex; justify-content: space-between; align-items: center;
  padding: 12px 16px; border-radius: 8px;
  background: #0d1117; border: 1px solid #30363d;
  color: #e6edf3; cursor: pointer; transition: all 0.2s; font-size: 0.9rem;
}
.option-btn:hover { border-color: #58a6ff; }
.option-btn--selected { border-color: #007bff; background: rgba(0,123,255,0.1); color: #fff; }
.opt-pct { font-size: 0.78rem; color: #8b949e; }
.option-btn--selected .opt-pct { color: #58a6ff; }

.amount-wrap {
  display: flex; align-items: center; background: #0d1117;
  border: 1px solid #30363d; border-radius: 8px; padding: 0 14px;
  transition: border-color 0.2s;
}
.amount-wrap:focus-within { border-color: #58a6ff; }
.coin-icon { font-size: 1rem; margin-right: 8px; }
.amount-wrap input {
  flex: 1; padding: 12px 0; background: transparent;
  border: none; color: white; font-size: 1rem; outline: none;
}
.amount-wrap input::placeholder { color: #4b5563; }

.balance-hint { color: #8b949e; font-size: 0.78rem; }

.projection {
  display: flex; justify-content: space-between; align-items: center;
  background: rgba(35,134,54,0.08); border: 1px solid rgba(35,134,54,0.3);
  border-radius: 8px; padding: 10px 14px; margin-top: 4px;
}
.proj-label { color: #8b949e; font-size: 0.82rem; }
.proj-value { color: #2ea043; font-weight: bold; font-size: 0.95rem; }

.btn-submit {
  background: #007bff; color: white; border: none; padding: 14px;
  width: 100%; border-radius: 8px; font-weight: bold; font-size: 1rem;
  cursor: pointer; transition: background 0.2s, transform 0.1s;
}
.btn-submit:hover:not(:disabled) { background: #58a6ff; transform: scale(1.01); }
.btn-submit:disabled { opacity: 0.5; cursor: not-allowed; }

.btn-close {
  background: transparent; color: #8b949e; width: 100%;
  margin-top: 5px; cursor: pointer; border: none; font-size: 0.9rem;
}
.btn-close:hover { color: white; text-decoration: underline; }

.error-msg {
  color: #f85149; font-size: 0.85rem; text-align: center;
  font-weight: bold; margin: 0;
}
</style>
