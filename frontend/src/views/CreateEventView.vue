<template>
  <div class="create-page">
    <div class="page-header">
      <h1>Crear Evento</h1>
      <p>Define las opciones y el periodo de tu apuesta</p>
    </div>

    <form @submit.prevent="handleSubmit" class="create-form">

      <section class="form-section">
        <label>Información del Evento</label>
        <input v-model="form.title" placeholder="Título del evento *" required />
        <textarea
          v-model="form.description"
          placeholder="Descripción — ¿sobre qué trata el evento? *"
          rows="3"
          required
        ></textarea>
        <select v-model="form.category" required>
          <option value="" disabled selected>Selecciona una categoría *</option>
          <option v-for="cat in categories" :key="cat" :value="cat">
            {{ catIcons[cat] }} {{ cat }}
          </option>
        </select>
      </section>

      <section class="form-section">
        <label>Periodo de Apuesta</label>
        <div class="date-grid">
          <div class="field-group">
            <span class="field-label">Inicio</span>
            <input type="datetime-local" v-model="form.startDate" required />
          </div>
          <div class="field-group">
            <span class="field-label">Cierre</span>
            <input type="datetime-local" v-model="form.endDate" required />
          </div>
        </div>
      </section>

      <section class="form-section">
        <label>Opciones de Apuesta</label>
        <small class="hint-text">Mínimo 2 opciones, máximo 4.</small>
        <div v-for="(_, i) in form.options" :key="i" class="option-input-row">
          <input v-model="form.options[i]" :placeholder="`Opción ${i + 1} *`" required />
          <button
            v-if="form.options.length > 2"
            type="button"
            class="btn-remove"
            @click="removeOption(i)"
          >
            ×
          </button>
        </div>
        <button
          v-if="form.options.length < 4"
          type="button"
          class="btn-add-option"
          @click="addOption"
        >
          + Añadir opción
        </button>
      </section>

      <p v-if="errorMessage" class="error-msg">{{ errorMessage }}</p>
      <p v-if="successMessage" class="success-msg">{{ successMessage }}</p>

      <button type="submit" class="btn-submit">Publicar Evento</button>
    </form>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, watchEffect } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useEventsStore } from '@/stores/events'

const router = useRouter()
const auth = useAuthStore()
const eventsStore = useEventsStore()

watchEffect(() => { if (!auth.isLoggedIn) router.push('/') })

const categories = ['Deportes', 'Entretenimiento', 'Política', 'Cultura']
const catIcons: Record<string, string> = {
  Deportes: '⚽', Entretenimiento: '🎬', Política: '🏛', Cultura: '🎭',
}

const form = reactive({
  title: '',
  description: '',
  category: '',
  startDate: '',
  endDate: '',
  options: ['', ''] as string[],
})

const errorMessage = ref('')
const successMessage = ref('')

function addOption(): void {
  if (form.options.length < 4) form.options.push('')
}

function removeOption(i: number): void {
  form.options.splice(i, 1)
}

function handleSubmit(): void {
  errorMessage.value = ''
  successMessage.value = ''

  if (!form.title || !form.description || !form.category || !form.startDate || !form.endDate) {
    errorMessage.value = 'Completa todos los campos obligatorios.'; return
  }
  if (form.options.some(o => !o.trim())) {
    errorMessage.value = 'Todas las opciones deben tener texto.'; return
  }
  if (new Date(form.endDate) <= new Date(form.startDate)) {
    errorMessage.value = 'La fecha de cierre debe ser posterior al inicio.'; return
  }

  eventsStore.createEvent({
    title: form.title,
    description: form.description,
    category: form.category,
    creatorId: auth.user!.id,
    creatorAlias: auth.user!.alias,
    options: form.options.map((label, i) => ({
      id: `opt-${Date.now()}-${i}`,
      label,
      totalBets: 0,
    })),
    startDate: new Date(form.startDate).toISOString(),
    endDate: new Date(form.endDate).toISOString(),
  })

  successMessage.value = '¡Evento publicado con éxito! Redirigiendo...'
  setTimeout(() => router.push('/'), 1500)
}
</script>

<style scoped>
.create-page { display: flex; flex-direction: column; gap: 24px; max-width: 600px; }
.page-header h1 { margin: 0; font-size: 1.8rem; color: #fff; font-weight: bold; }
.page-header p  { margin: 6px 0 0; color: #8b949e; }

.create-form { display: flex; flex-direction: column; gap: 24px; }

.form-section { display: flex; flex-direction: column; gap: 10px; }
.form-section > label {
  color: #58a6ff; font-size: 0.72rem; font-weight: bold;
  text-transform: uppercase; letter-spacing: 0.5px;
}
.hint-text { color: #8b949e; font-size: 0.8rem; margin-top: -4px; }

input, textarea, select {
  width: 100%; padding: 12px 14px; border-radius: 8px;
  border: 1px solid #30363d; background: #0d1117;
  color: white; box-sizing: border-box; font-size: 0.95rem;
  outline: none; transition: border-color 0.2s; font-family: inherit;
}
input:focus, textarea:focus, select:focus { border-color: #58a6ff; }
input::placeholder, textarea::placeholder { color: #4b5563; }
textarea { resize: vertical; min-height: 80px; }
select { cursor: pointer; }
select option { background: #0d1117; color: white; }

.date-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
.field-group { display: flex; flex-direction: column; gap: 4px; }
.field-label { font-size: 0.78rem; color: #8b949e; }

.option-input-row { display: flex; gap: 8px; align-items: center; }
.option-input-row input { flex: 1; }

.btn-remove {
  flex-shrink: 0; width: 36px; height: 36px; border-radius: 6px;
  background: rgba(248,81,73,0.08); border: 1px solid rgba(248,81,73,0.3);
  color: #f85149; font-size: 1.3rem; cursor: pointer; transition: background 0.2s;
  display: flex; align-items: center; justify-content: center; padding: 0;
}
.btn-remove:hover { background: rgba(248,81,73,0.18); }

.btn-add-option {
  background: rgba(88,166,255,0.04); border: 1px dashed #30363d;
  color: #58a6ff; border-radius: 8px; padding: 10px; font-size: 0.85rem;
  cursor: pointer; transition: all 0.2s;
}
.btn-add-option:hover { border-color: #58a6ff; background: rgba(88,166,255,0.1); }

.btn-submit {
  background: #238636; color: white; border: none; padding: 14px; width: 100%;
  border-radius: 8px; font-weight: bold; font-size: 1rem; cursor: pointer; transition: background 0.2s;
}
.btn-submit:hover { background: #2ea043; }

.error-msg   { color: #f85149; font-size: 0.85rem; text-align: center; font-weight: bold; margin: 0; }
.success-msg { color: #2ea043; font-size: 0.85rem; text-align: center; font-weight: bold; margin: 0; }
</style>
