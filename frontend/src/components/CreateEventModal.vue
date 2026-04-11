<template>
  <div class="modal-overlay" @click.self="$emit('close')">
    <article class="create-modal">

      <header class="modal-header">
        <h3>Crear Apuesta</h3>
        <p>Define las opciones y el periodo de tu apuesta</p>
      </header>

      <form @submit.prevent="handleSubmit" class="modal-body">

        <!-- Información del evento -->
        <section class="form-section">
          <label>Información del Evento</label>
          <input v-model="form.title" placeholder="Título de la Apuesta" required />
          <textarea
            v-model="form.description"
            placeholder="Descripción"
            rows="2"
            required
          ></textarea>
          <select v-model="form.category" required>
            <option value="" disabled selected>Selecciona una categoría</option>
            <option v-for="cat in categories" :key="cat" :value="cat">
              {{ catIcons[cat] }} {{ cat }}
            </option>
          </select>
        </section>

        <!-- Fecha de inicio -->
        <section class="form-section">
          <label>Fecha de Inicio</label>
          <div class="date-group">
            <select v-model="form.startDia" required>
              <option value="" disabled selected>Día</option>
              <option v-for="d in 31" :key="d" :value="d">{{ d }}</option>
            </select>
            <select v-model="form.startMes" required>
              <option value="" disabled selected>Mes</option>
              <option v-for="(m, i) in meses" :key="i" :value="i + 1">{{ m }}</option>
            </select>
            <select v-model="form.startAnio" required>
              <option value="" disabled selected>Año</option>
              <option v-for="y in years" :key="y" :value="y">{{ y }}</option>
            </select>
            <select v-model="form.startHora" required>
              <option value="" disabled selected>Hora</option>
              <option v-for="h in 24" :key="h - 1" :value="h - 1">{{ String(h - 1).padStart(2, '0') }}</option>
            </select>
            <select v-model="form.startMin" required>
              <option value="" disabled selected>Min</option>
              <option v-for="m in minutes" :key="m" :value="m">{{ String(m).padStart(2, '0') }}</option>
            </select>
          </div>
        </section>

        <!-- Fecha de cierre -->
        <section class="form-section">
          <label>Fecha de Cierre</label>
          <div class="date-group">
            <select v-model="form.endDia" required>
              <option value="" disabled selected>Día</option>
              <option v-for="d in 31" :key="d" :value="d">{{ d }}</option>
            </select>
            <select v-model="form.endMes" required>
              <option value="" disabled selected>Mes</option>
              <option v-for="(m, i) in meses" :key="i" :value="i + 1">{{ m }}</option>
            </select>
            <select v-model="form.endAnio" required>
              <option value="" disabled selected>Año</option>
              <option v-for="y in years" :key="y" :value="y">{{ y }}</option>
            </select>
            <select v-model="form.endHora" required>
              <option value="" disabled selected>Hora</option>
              <option v-for="h in 24" :key="h - 1" :value="h - 1">{{ String(h - 1).padStart(2, '0') }}</option>
            </select>
            <select v-model="form.endMin" required>
              <option value="" disabled selected>Min</option>
              <option v-for="m in minutes" :key="m" :value="m">{{ String(m).padStart(2, '0') }}</option>
            </select>
          </div>
        </section>

        <!-- Opciones de apuesta -->
        <section class="form-section">
          <label>Opciones de Apuesta</label>
          <small class="hint">Mínimo 2 opciones, máximo 4.</small>
          <div v-for="(_, i) in form.options" :key="i" class="option-row">
            <input v-model="form.options[i]" :placeholder="`Opción ${i + 1}`" required />
            <button
              v-if="form.options.length > 2"
              type="button"
              class="btn-remove"
              @click="removeOption(i)"
            >×</button>
          </div>
          <button
            v-if="form.options.length < 4"
            type="button"
            class="btn-add"
            @click="addOption"
          >+ Añadir opción</button>
        </section>

        <p v-if="errorMessage" class="error-msg">{{ errorMessage }}</p>
        <p v-if="successMessage" class="success-msg">{{ successMessage }}</p>

        <button type="submit" class="btn-submit">Publicar Apuesta</button>
      </form>

      <footer>
        <button class="btn-close" @click="$emit('close')">Cerrar</button>
      </footer>
    </article>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useEventsStore } from '@/stores/events'

const emit = defineEmits<{ close: []; success: [] }>()

const auth = useAuthStore()
const eventsStore = useEventsStore()

const categories = ['Deportes', 'Entretenimiento', 'Política', 'Cultura', 'Educacion']
const catIcons: Record<string, string> = {
  Deportes: '⚽', Entretenimiento: '🎬', Política: '🏛', Cultura: '🎭', Educacion: '📚',
}
const meses = ['Enero','Febrero','Marzo','Abril','Mayo','Junio','Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre']
const currentYear = new Date().getFullYear()
const years = [currentYear, currentYear + 1, currentYear + 2]
const minutes = [0, 15, 30, 45]

const form = reactive({
  title: '',
  description: '',
  category: '',
  options: ['', ''] as string[],
  startDia: '' as number | '',
  startMes: '' as number | '',
  startAnio: '' as number | '',
  startHora: '' as number | '',
  startMin: '' as number | '',
  endDia: '' as number | '',
  endMes: '' as number | '',
  endAnio: '' as number | '',
  endHora: '' as number | '',
  endMin: '' as number | '',
})

const errorMessage = ref('')
const successMessage = ref('')

function addOption(): void {
  if (form.options.length < 4) form.options.push('')
}
function removeOption(i: number): void {
  form.options.splice(i, 1)
}

function buildDate(dia: number | '', mes: number | '', anio: number | '', hora: number | '', min: number | ''): Date | null {
  if (dia === '' || mes === '' || anio === '' || hora === '' || min === '') return null
  return new Date(anio, (mes as number) - 1, dia as number, hora as number, min as number)
}

function handleSubmit(): void {
  errorMessage.value = ''
  successMessage.value = ''

  if (!form.title || !form.description || !form.category) {
    errorMessage.value = 'Completa el título, descripción y categoría.'; return
  }
  if (form.options.some(o => !o.trim())) {
    errorMessage.value = 'Todas las opciones deben tener texto.'; return
  }

  const startDate = buildDate(form.startDia, form.startMes, form.startAnio, form.startHora, form.startMin)
  const endDate   = buildDate(form.endDia, form.endMes, form.endAnio, form.endHora, form.endMin)

  if (!startDate || !endDate) {
    errorMessage.value = 'Completa todas las fechas.'; return
  }
  if (endDate <= startDate) {
    errorMessage.value = 'La fecha de cierre debe ser posterior al inicio.'; return
  }

  eventsStore.createEvent({
    title: form.title,
    description: form.description,
    category: form.category,
    creatorId: auth.user!.id,
    creatorAlias: auth.user!.alias,
    options: form.options.map((label, i) => ({ id: `opt-${Date.now()}-${i}`, label, totalBets: 0 })),
    startDate: startDate.toISOString(),
    endDate: endDate.toISOString(),
  })

  successMessage.value = 'Apuesta publicada con éxito!'
  setTimeout(() => { emit('success'); emit('close') }, 1200)
}
</script>

<style scoped>
.modal-overlay {
  position: fixed; inset: 0; background: rgba(0,0,0,0.85);
  display: flex; justify-content: center; align-items: center; z-index: 3000;
}
.create-modal {
  background: #161b22; padding: 30px; border-radius: 16px;
  border: 1px solid #007bff; color: white;
  width: 100%; max-width: 520px; max-height: 90vh; overflow-y: auto;
  box-shadow: 0 10px 30px rgba(0,0,0,0.5);
  display: flex; flex-direction: column; gap: 0;
}
.modal-header { margin-bottom: 20px; padding-bottom: 15px; border-bottom: 1px solid #30363d; }
.modal-header h3 { margin: 0; font-size: 1.4rem; color: #fff; }
.modal-header p  { margin: 5px 0 0; color: #8b949e; font-size: 0.88rem; }

.modal-body { display: flex; flex-direction: column; gap: 20px; }

/* Sections */
.form-section { display: flex; flex-direction: column; gap: 8px; }
.form-section > label {
  color: #58a6ff; font-size: 0.72rem; font-weight: bold;
  text-transform: uppercase; letter-spacing: 0.5px;
}
.hint { color: #8b949e; font-size: 0.78rem; margin-top: -4px; }

/* Inputs */
input, textarea, select {
  width: 100%; padding: 11px 14px; border-radius: 8px;
  border: 1px solid #30363d; background: #0d1117; color: white;
  box-sizing: border-box; font-size: 0.9rem; outline: none;
  transition: border-color 0.2s; font-family: inherit;
}
input:focus, textarea:focus, select:focus { border-color: #58a6ff; }
input::placeholder, textarea::placeholder { color: #4b5563; }
textarea { resize: vertical; min-height: 60px; }
select { cursor: pointer; }
select option { background: #0d1117; color: white; }

/* Date group — igual que RegisterModal */
.date-group {
  display: grid;
  grid-template-columns: 1fr 1.6fr 1.2fr 1fr 1fr;
  gap: 6px;
}

/* Options */
.option-row { display: flex; gap: 8px; align-items: center; }
.option-row input { flex: 1; }
.btn-remove {
  flex-shrink: 0; width: 34px; height: 34px; border-radius: 6px;
  background: rgba(248,81,73,0.08); border: 1px solid rgba(248,81,73,0.3);
  color: #f85149; font-size: 1.3rem; cursor: pointer;
  display: flex; align-items: center; justify-content: center; padding: 0;
  transition: background 0.2s;
}
.btn-remove:hover { background: rgba(248,81,73,0.18); }
.btn-add {
  background: rgba(88,166,255,0.04); border: 1px dashed #30363d;
  color: #58a6ff; border-radius: 8px; padding: 9px; font-size: 0.85rem;
  cursor: pointer; transition: all 0.2s;
}
.btn-add:hover { border-color: #58a6ff; background: rgba(88,166,255,0.1); }

/* Submit */
.btn-submit {
  background: #238636; color: white; border: none; padding: 13px;
  width: 100%; border-radius: 8px; font-weight: bold; font-size: 1rem;
  cursor: pointer; transition: background 0.2s; margin-top: 4px;
}
.btn-submit:hover { background: #2ea043; }

.btn-close {
  background: transparent; color: #8b949e; width: 100%;
  margin-top: 14px; cursor: pointer; border: none; font-size: 0.9rem;
}
.btn-close:hover { color: white; text-decoration: underline; }

.error-msg   { color: #f85149; font-size: 0.85rem; text-align: center; font-weight: bold; margin: 0; }
.success-msg { color: #2ea043; font-size: 0.85rem; text-align: center; font-weight: bold; margin: 0; }
</style>
