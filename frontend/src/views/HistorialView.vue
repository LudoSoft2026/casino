<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { apiFetch } from '@/config/api'

interface Participacion {
  id:                  string
  apuesta_id:          string
  apuesta_titulo:      string
  opcion_elegida:      string
  cuota:               string
  monto:               string
  ganancia_proyectada: string
  estado:              string
  ganancia:            string | null
  fecha_participacion: string
}

const participaciones = ref<Participacion[]>([])
const loading         = ref(false)
const error           = ref('')
const fechaInicio     = ref('')
const fechaFin        = ref('')

const estadoLabel = (estado: string) => {
  if (estado === 'ganadora')  return 'Ganada'
  if (estado === 'perdedora') return 'Perdida'
  if (estado === 'devuelta')  return 'Cancelada'
  return 'Pendiente'
}

const colorEstado = (estado: string) => {
  if (estado === 'ganadora')  return 'success'
  if (estado === 'perdedora') return 'error'
  if (estado === 'devuelta')  return 'warning'
  return 'info'
}

const participacionesFiltradas = computed(() => {
  return participaciones.value.filter(p => {
    const fecha = new Date(p.fecha_participacion)
    if (fechaInicio.value && fecha < new Date(fechaInicio.value)) return false
    if (fechaFin.value && fecha > new Date(fechaFin.value + 'T23:59:59')) return false
    return true
  })
})

const cargar = async () => {
  loading.value = true
  error.value   = ''
  try {
    const res  = await apiFetch('/api/participaciones/historial')
    if (!res.ok) {
      error.value = 'No se pudo recuperar el historial, intenta más tarde.'
      return
    }
    const data = await res.json()
    participaciones.value = Array.isArray(data) ? data : (data.participaciones ?? [])
  } catch {
    error.value = 'No se pudo recuperar el historial, intenta más tarde.'
  } finally {
    loading.value = false
  }
}

const limpiarFiltros = () => {
  fechaInicio.value = ''
  fechaFin.value    = ''
}

onMounted(async () => {
  await cargar()
})
</script>

<template>
  <v-container class="py-6">
    <div class="text-h5 font-weight-bold mb-6">
      <v-icon color="primary" class="mr-2">mdi-history</v-icon>
      Mi historial de apuestas
    </div>

    <!-- Filtros por fecha -->
    <v-card elevation="2" rounded="lg" class="mb-6">
      <v-card-text>
        <v-row align="center">
          <v-col cols="12" md="4">
            <v-text-field
              v-model="fechaInicio"
              label="Desde"
              type="date"
              variant="outlined"
              density="compact"
              prepend-inner-icon="mdi-calendar"
              hide-details
            />
          </v-col>
          <v-col cols="12" md="4">
            <v-text-field
              v-model="fechaFin"
              label="Hasta"
              type="date"
              variant="outlined"
              density="compact"
              prepend-inner-icon="mdi-calendar"
              hide-details
            />
          </v-col>
          <v-col cols="12" md="4">
            <v-btn variant="tonal" @click="limpiarFiltros">
              <v-icon class="mr-1">mdi-filter-off</v-icon>
              Limpiar filtros
            </v-btn>
          </v-col>
        </v-row>
      </v-card-text>
    </v-card>

    <!-- Error -->
    <v-alert v-if="error" type="error" variant="tonal" class="mb-4">
      {{ error }}
    </v-alert>

    <!-- Loading -->
    <v-row v-if="loading" justify="center">
      <v-col cols="auto">
        <v-progress-circular indeterminate color="primary" size="64" />
      </v-col>
    </v-row>

    <!-- Sin participaciones -->
    <v-row v-else-if="participacionesFiltradas.length === 0" justify="center">
      <v-col cols="12" class="text-center">
        <v-icon size="64" color="grey">mdi-emoticon-sad-outline</v-icon>
        <div class="text-h6 mt-2 text-medium-emphasis">
          Aún no has participado en ninguna apuesta.
        </div>
      </v-col>
    </v-row>

    <!-- Lista -->
    <v-row v-else>
      <v-col
        v-for="p in participacionesFiltradas"
        :key="p.id"
        cols="12" md="6"
      >
        <v-card elevation="4" rounded="lg">
          <v-card-title class="pb-1">
            {{ p.apuesta_titulo }}
          </v-card-title>

          <v-card-text>
            <v-row density="comfortable">
              <v-col cols="6">
                <div class="text-caption text-medium-emphasis">Opción elegida</div>
                <div class="font-weight-bold">{{ p.opcion_elegida }}</div>
              </v-col>
              <v-col cols="6">
                <div class="text-caption text-medium-emphasis">Cuota</div>
                <div class="font-weight-bold">×{{ p.cuota }}</div>
              </v-col>
              <v-col cols="6">
                <div class="text-caption text-medium-emphasis">Monto apostado</div>
                <div class="font-weight-bold">${{ Number(p.monto).toFixed(2) }}</div>
              </v-col>
              <v-col cols="6">
                <div class="text-caption text-medium-emphasis">Ganancia proyectada</div>
                <div class="font-weight-bold text-primary">${{ Number(p.ganancia_proyectada).toFixed(2) }}</div>
              </v-col>
              <v-col cols="6">
                <div class="text-caption text-medium-emphasis">Estado</div>
                <v-chip :color="colorEstado(p.estado)" size="small">
                  {{ estadoLabel(p.estado) }}
                </v-chip>
              </v-col>
              <v-col cols="6" v-if="p.ganancia">
                <div class="text-caption text-medium-emphasis">Ganancia obtenida</div>
                <div class="font-weight-bold text-success">${{ Number(p.ganancia).toFixed(2) }}</div>
              </v-col>
            </v-row>

            <div class="text-caption text-medium-emphasis mt-2">
              {{ new Date(p.fecha_participacion).toLocaleString() }}
            </div>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>

  </v-container>
</template>
