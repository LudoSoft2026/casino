<script setup lang="ts">
import { ref, onMounted } from 'vue'
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

const cargar = async () => {
  loading.value = true
  const res  = await apiFetch('/api/participaciones/historial')
  const data = await res.json()
  participaciones.value = Array.isArray(data) ? data : (data.participaciones ?? [])
  loading.value = false
}

const colorEstado = (estado: string) => {
  if (estado === 'ganadora')  return 'success'
  if (estado === 'perdedora') return 'error'
  if (estado === 'cancelada') return 'warning'
  return 'info'
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

    <!-- Loading -->
    <v-row v-if="loading" justify="center">
      <v-col cols="auto">
        <v-progress-circular indeterminate color="primary" size="64" />
      </v-col>
    </v-row>

    <!-- Sin participaciones -->
    <v-row v-else-if="participaciones.length === 0" justify="center">
      <v-col cols="12" class="text-center">
        <v-icon size="64" color="grey">mdi-emoticon-sad-outline</v-icon>
        <div class="text-h6 mt-2 text-medium-emphasis">No has participado en ninguna apuesta.</div>
      </v-col>
    </v-row>

    <!-- Lista -->
    <v-row v-else>
      <v-col
        v-for="p in participaciones"
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
                <div class="font-weight-bold">${{ p.monto }}</div>
              </v-col>
              <v-col cols="6">
                <div class="text-caption text-medium-emphasis">Ganancia proyectada</div>
                <div class="font-weight-bold text-primary">${{ p.ganancia_proyectada }}</div>
              </v-col>
              <v-col cols="6">
                <div class="text-caption text-medium-emphasis">Estado</div>
                <v-chip :color="colorEstado(p.estado)" size="small">
                  {{ p.estado }}
                </v-chip>
              </v-col>
              <v-col cols="6" v-if="p.ganancia">
                <div class="text-caption text-medium-emphasis">Ganancia obtenida</div>
                <div class="font-weight-bold text-success">${{ p.ganancia }}</div>
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
