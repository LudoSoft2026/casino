<template>
  <div class="modal-overlay" @click.self="$emit('close')">
    <article class="bet-modal">
      <header class="modal-header">
        <h3>Reportar Resultado</h3>
        <p v-if="event">{{ event.title }}</p>
      </header>

      <div v-if="event" class="modal-body">
        <p class="info-text">
          Selecciona la opción ganadora. El resultado será revisado por el administrador antes de procesar los pagos.
        </p>

        <section class="form-section">
          <label>Resultado final</label>
          <div class="options-grid">
            <button
              v-for="opt in event.options"
              :key="opt.id"
              class="option-btn"
              :class="{ 'option-btn--selected': selectedOption === opt.id }"
              @click="selectedOption = opt.id"
            >
              <span>{{ opt.label }}</span>
              <span class="opt-bets">$ {{ opt.totalBets.toLocaleString() }}</span>
            </button>
          </div>
        </section>

        <p v-if="errorMessage" class="error-msg">{{ errorMessage }}</p>

        <button class="btn-submit" @click="handleSubmit" :disabled="!selectedOption">
          Enviar resultado
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
import { useEventsStore } from '@/stores/events'

const props = defineProps<{ eventId: string }>()
const emit = defineEmits<{ close: []; success: [] }>()

const eventsStore = useEventsStore()
const event = computed(() => eventsStore.getById(props.eventId))
const selectedOption = ref<string>('')
const errorMessage = ref('')

function handleSubmit(): void {
  if (!selectedOption.value) { errorMessage.value = 'Selecciona la opción ganadora.'; return }
  eventsStore.submitResult(props.eventId, selectedOption.value)
  emit('success')
  emit('close')
}
</script>

<style scoped>
.modal-overlay {
  position: fixed; inset: 0; background: rgba(0,0,0,0.85);
  display: flex; justify-content: center; align-items: center; z-index: 3000;
}
.bet-modal {
  background: #161b22; padding: 30px; border-radius: 12px;
  border: 1px solid #f59e0b; color: white; width: 100%; max-width: 420px;
  box-shadow: 0 10px 30px rgba(0,0,0,0.5); display: flex; flex-direction: column; gap: 15px;
}
.modal-header h3 { margin: 0; font-size: 1.3rem; color: #fff; }
.modal-header p  { margin: 4px 0 0; color: #8b949e; font-size: 0.85rem; }
.modal-body { display: flex; flex-direction: column; gap: 15px; }

.info-text {
  color: #8b949e; font-size: 0.85rem; line-height: 1.5; margin: 0;
  background: rgba(245,158,11,0.05); border: 1px solid rgba(245,158,11,0.2);
  padding: 10px 14px; border-radius: 8px;
}

.form-section { display: flex; flex-direction: column; gap: 8px; }
.form-section > label {
  color: #58a6ff; font-size: 0.72rem; font-weight: bold;
  text-transform: uppercase; letter-spacing: 0.5px;
}

.options-grid { display: flex; flex-direction: column; gap: 8px; }
.option-btn {
  display: flex; justify-content: space-between; align-items: center;
  padding: 12px 16px; border-radius: 8px; background: #0d1117; border: 1px solid #30363d;
  color: #e6edf3; cursor: pointer; transition: all 0.2s; font-size: 0.9rem;
}
.option-btn:hover { border-color: #f59e0b; }
.option-btn--selected { border-color: #f59e0b; background: rgba(245,158,11,0.08); color: #fff; }
.opt-bets { font-size: 0.78rem; color: #8b949e; }

.btn-submit {
  background: #f59e0b; color: #000; border: none; padding: 14px; width: 100%;
  border-radius: 8px; font-weight: bold; font-size: 1rem; cursor: pointer; transition: background 0.2s;
}
.btn-submit:hover:not(:disabled) { background: #fbbf24; }
.btn-submit:disabled { opacity: 0.5; cursor: not-allowed; }

.btn-close {
  background: transparent; color: #8b949e; width: 100%;
  margin-top: 5px; cursor: pointer; border: none;
}
.btn-close:hover { color: white; text-decoration: underline; }

.error-msg {
  color: #f85149; font-size: 0.85rem; text-align: center; font-weight: bold; margin: 0;
}
</style>
