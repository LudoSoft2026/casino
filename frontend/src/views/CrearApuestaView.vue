<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useApuestasStore } from '@/stores/apuestas'

const router        = useRouter()
const apuestasStore = useApuestasStore()

const form = ref({
  titulo:             '',
  descripcion:        '',
  monto_minimo:       50,
  monto_maximo:       null as number | null,
  fecha_finalizacion: '',
})

const opciones = ref([
  { descripcion: '', probabilidad: 0 },
  { descripcion: '', probabilidad: 0 },
])

const loading = ref(false)
const error   = ref('')

const sumaProbabilidades = computed(() =>
  opciones.value.reduce((acc, o) => acc + Number(o.probabilidad), 0)
)

const agregarOpcion = () => {
  opciones.value.push({ descripcion: '', probabilidad: 0 })
}

const eliminarOpcion = (index: number) => {
  if (opciones.value.length > 2) {
    opciones.value.splice(index, 1)
  }
}

const crear = async () => {
  error.value = ''

  if (!form.value.titulo || !form.value.descripcion || !form.value.fecha_finalizacion) {
    error.value = 'Completa todos los campos requeridos.'
    return
  }

  if (form.value.monto_minimo <= 0) {
    error.value = 'El monto mínimo debe ser mayor a 0.'
    return
  }

  if (new Date(form.value.fecha_finalizacion) <= new Date()) {
    error.value = 'La fecha de finalización debe ser posterior a la actual.'
    return
  }

  if (opciones.value.some(o => !o.descripcion)) {
    error.value = 'Completa todos los campos requeridos.'
    return
  }

  if (Math.abs(sumaProbabilidades.value - 100) > 0.01) {
    error.value = 'Las probabilidades deben sumar exactamente 100%.'
    return
  }

  loading.value = true

  const result = await apuestasStore.crear({
    titulo:             form.value.titulo,
    descripcion:        form.value.descripcion,
    opciones:           opciones.value.map(o => o.descripcion),
    probabilidades:     opciones.value.map(o => Number(o.probabilidad)),
    monto_minimo:       form.value.monto_minimo,
    monto_maximo:       form.value.monto_maximo,
    fecha_finalizacion: new Date(form.value.fecha_finalizacion).toISOString(),
  })

  loading.value = false

  if (result.apuestaId) {
    router.push('/apuestas')
  } else {
    error.value = result.mensaje || 'Error al crear apuesta.'
  }
}
</script>

<template>
  <v-container class="py-6">
    <v-row justify="center">
      <v-col cols="12" md="8">

        <v-card elevation="8" rounded="lg">
          <v-card-title class="pa-6">
            <v-icon color="primary" class="mr-2">mdi-plus-circle</v-icon>
            Crear nueva apuesta
          </v-card-title>

          <v-card-text class="px-6">
            <v-alert v-if="error" type="error" variant="tonal" class="mb-4" density="compact">
              {{ error }}
            </v-alert>

            <!-- Información básica -->
            <div class="text-subtitle-1 font-weight-bold mb-3">Información básica</div>

            <v-text-field
              v-model="form.titulo"
              label="Título *"
              variant="outlined"
              prepend-inner-icon="mdi-format-title"
              class="mb-3"
            />

            <v-textarea
              v-model="form.descripcion"
              label="Descripción *"
              variant="outlined"
              prepend-inner-icon="mdi-text"
              rows="3"
              class="mb-3"
            />

            <v-row>
              <v-col cols="12" md="6">
                <v-text-field
                  v-model.number="form.monto_minimo"
                  label="Monto mínimo *"
                  type="number"
                  variant="outlined"
                  prepend-inner-icon="mdi-cash"
                />
              </v-col>
              <v-col cols="12" md="6">
                <v-text-field
                  v-model.number="form.monto_maximo"
                  label="Monto máximo (opcional)"
                  type="number"
                  variant="outlined"
                  prepend-inner-icon="mdi-cash-multiple"
                />
              </v-col>
            </v-row>

            <v-text-field
              v-model="form.fecha_finalizacion"
              label="Fecha y hora de finalización *"
              type="datetime-local"
              variant="outlined"
              prepend-inner-icon="mdi-calendar-clock"
              class="mb-3"
            />

            <v-divider class="my-4" />

            <!-- Opciones -->
            <div class="d-flex justify-space-between align-center mb-3">
              <div class="text-subtitle-1 font-weight-bold">Opciones de apuesta</div>
              <v-chip :color="Math.abs(sumaProbabilidades - 100) <= 0.01 ? 'success' : 'error'">
                Total: {{ sumaProbabilidades }}%
              </v-chip>
            </div>

            <v-row
              v-for="(opcion, index) in opciones"
              :key="index"
              align="center"
            >
              <v-col cols="12" md="6">
                <v-text-field
                  v-model="opcion.descripcion"
                  :label="`Opción ${index + 1} *`"
                  variant="outlined"
                  density="compact"
                />
              </v-col>
              <v-col cols="12" md="4">
                <v-text-field
                  v-model.number="opcion.probabilidad"
                  label="Probabilidad %"
                  type="number"
                  variant="outlined"
                  density="compact"
                  suffix="%"
                />
              </v-col>
              <v-col cols="12" md="2">
                <v-btn
                  icon
                  variant="text"
                  color="error"
                  :disabled="opciones.length <= 2"
                  @click="eliminarOpcion(index)"
                >
                  <v-icon>mdi-delete</v-icon>
                </v-btn>
              </v-col>
            </v-row>

            <v-btn
              variant="tonal"
              color="primary"
              prepend-icon="mdi-plus"
              class="mb-4"
              @click="agregarOpcion"
            >
              Agregar opción
            </v-btn>

          </v-card-text>

          <v-card-actions class="px-6 pb-6">
            <v-btn variant="text" @click="$router.push('/apuestas')">Cancelar</v-btn>
            <v-spacer />
            <v-btn
              color="primary"
              size="large"
              :loading="loading"
              @click="crear"
            >
              Crear apuesta
            </v-btn>
          </v-card-actions>
        </v-card>

      </v-col>
    </v-row>
  </v-container>
</template>