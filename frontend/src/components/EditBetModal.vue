<template>
  <div class="modal-overlay" @click.self="$emit('close')">
    <article class="bet-modal">
      <header class="modal-header">
        <h3>Gestionar Apuesta</h3>
        <p>{{ bet.eventTitle }}</p>
      </header>

      <div class="modal-body">
        <section class="form-section">
          <label>Opción seleccionada</label>
          <div class="selected-option">{{ bet.optionLabel }}</div>
        </section>

        <section class="form-section">
          <label>Nuevo monto</label>
          <div class="amount-wrap">
            <span class="coin-icon">$</span>
            <input
              type="number"
              v-model.number="newAmount"
              min="1"
              :max="auth.balance + bet.amount"
              placeholder="0"
            />
          </div>
          <small class="balance-hint">
            Actual: $ {{ bet.amount }} &nbsp;·&nbsp; Saldo disponible: $ {{ auth.balance.toLocaleString() }}
          </small>
        </section>

        <p v-if="errorMessage" class="error-msg">{{ errorMessage }}</p>

        <div class="action-row">
          <button class="btn-submit" @click="handleEdit">Guardar cambios</button>
          <button class="btn-danger" @click="handleCancel">Cancelar apuesta</button>
        </div>
      </div>

      <footer>
        <button class="btn-close" @click="$emit('close')">Cerrar</button>
      </footer>
    </article>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useBetsStore, type Bet } from '@/stores/bets'

const props = defineProps<{ bet: Bet }>()
const emit = defineEmits<{ close: [] }>()

const auth = useAuthStore()
const betsStore = useBetsStore()

const newAmount = ref(props.bet.amount)
const errorMessage = ref('')

function handleEdit(): void {
  errorMessage.value = ''
  if (newAmount.value <= 0) { errorMessage.value = 'El monto debe ser mayor a 0.'; return }
  try {
    betsStore.editBet(props.bet.id, newAmount.value)
    emit('close')
  } catch (err: any) {
    errorMessage.value = err.message
  }
}

function handleCancel(): void {
  betsStore.cancelBet(props.bet.id)
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
  border: 1px solid #007bff; color: white; width: 100%; max-width: 400px;
  box-shadow: 0 10px 30px rgba(0,0,0,0.5); display: flex; flex-direction: column; gap: 15px;
}
.modal-header h3 { margin: 0; font-size: 1.3rem; color: #fff; }
.modal-header p  { margin: 4px 0 0; color: #8b949e; font-size: 0.85rem; }
.modal-body { display: flex; flex-direction: column; gap: 15px; }

.form-section { display: flex; flex-direction: column; gap: 8px; }
.form-section > label {
  color: #58a6ff; font-size: 0.72rem; font-weight: bold;
  text-transform: uppercase; letter-spacing: 0.5px;
}
.selected-option {
  background: #0d1117; border: 1px solid #30363d;
  border-radius: 8px; padding: 12px 16px; color: #e6edf3; font-size: 0.9rem;
}

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
.balance-hint { color: #8b949e; font-size: 0.78rem; }

.action-row { display: flex; flex-direction: column; gap: 8px; }
.btn-submit {
  background: #007bff; color: white; border: none; padding: 12px; width: 100%;
  border-radius: 8px; font-weight: bold; font-size: 0.95rem; cursor: pointer; transition: background 0.2s;
}
.btn-submit:hover { background: #58a6ff; }

.btn-danger {
  background: rgba(248,81,73,0.08); color: #f85149;
  border: 1px solid rgba(248,81,73,0.3); padding: 12px; width: 100%;
  border-radius: 8px; font-weight: bold; font-size: 0.95rem; cursor: pointer; transition: background 0.2s;
}
.btn-danger:hover { background: rgba(248,81,73,0.18); }

.btn-close {
  background: transparent; color: #8b949e; width: 100%;
  margin-top: 5px; cursor: pointer; border: none;
}
.btn-close:hover { color: white; text-decoration: underline; }

.error-msg {
  color: #f85149; font-size: 0.85rem; text-align: center; font-weight: bold; margin: 0;
}
</style>
