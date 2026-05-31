<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { apiFetch } from '@/config/api'

interface RankingEntry {
  posicion:             number
  alias:                string
  apuestas_ganadas:     number
  ganancias_acumuladas: string
  semana_inicio:        string
  ultima_actualizacion: string
}

const ranking  = ref<RankingEntry[]>([])
const loading  = ref(false)
const error    = ref('')

const medallaColor = (posicion: number) => {
  if (posicion === 1) return '#FFD700'
  if (posicion === 2) return '#C0C0C0'
  if (posicion === 3) return '#CD7F32'
  return ''
}

const medallaIcono = (posicion: number) => {
  if (posicion === 1) return 'mdi-trophy'
  if (posicion === 2) return 'mdi-medal'
  if (posicion === 3) return 'mdi-medal'
  return 'mdi-account'
}

const cargar = async () => {
  loading.value = true
  error.value   = ''
  try {
    const res  = await apiFetch('/api/ranking')
    if (!res.ok) {
      error.value = 'No se pudo cargar el ranking semanal. Intente nuevamente.'
      return
    }
    const data = await res.json()
    ranking.value = data.ranking ?? []
  } catch {
    error.value = 'No se pudo cargar el ranking semanal. Intente nuevamente.'
  } finally {
    loading.value = false
  }
}

const semanaActual = () => {
  const hoy    = new Date()
  const inicio = new Date(hoy)
  inicio.setDate(hoy.getDate() - hoy.getDay() + 1)
  const fin    = new Date(inicio)
  fin.setDate(inicio.getDate() + 6)
  return `${inicio.toLocaleDateString()} - ${fin.toLocaleDateString()}`
}

onMounted(async () => {
  await cargar()
})
</script>

<template>
  <v-container class="py-6">
    <div class="text-h5 font-weight-bold mb-2">
      <v-icon color="primary" class="mr-2">mdi-trophy</v-icon>
      Ranking Semanal
    </div>
    <div class="text-caption text-medium-emphasis mb-6">
      Semana: {{ semanaActual() }}
    </div>

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

    <!-- Sin usuarios -->
    <v-row v-else-if="ranking.length === 0" justify="center">
      <v-col cols="12" class="text-center">
        <v-icon size="64" color="grey">mdi-trophy-outline</v-icon>
        <div class="text-h6 mt-2 text-medium-emphasis">
          Aún no hay usuarios ganadores esta semana.
        </div>
      </v-col>
    </v-row>

    <!-- Ranking -->
    <div v-else>
      <!-- Top 3 -->
      <v-row justify="center" class="mb-6">
        <v-col
          v-for="entry in ranking.slice(0, 3)"
          :key="entry.posicion"
          cols="12" md="4"
          class="text-center"
        >
          <v-card elevation="4" rounded="lg" class="pa-4">
            <v-icon
              size="48"
              :style="{ color: medallaColor(entry.posicion) }"
            >
              {{ medallaIcono(entry.posicion) }}
            </v-icon>
            <div class="text-h6 font-weight-bold mt-2">{{ entry.alias }}</div>
            <div class="text-caption text-medium-emphasis">#{{ entry.posicion }}</div>
            <v-divider class="my-2" />
            <div class="text-body-2">
              <v-icon size="16" color="success">mdi-check-circle</v-icon>
              {{ entry.apuestas_ganadas }} apuestas ganadas
            </div>
            <div class="text-body-2 text-success font-weight-bold">
              +${{ Number(entry.ganancias_acumuladas).toFixed(2) }}
            </div>
          </v-card>
        </v-col>
      </v-row>

      <!-- Resto del ranking -->
      <v-card elevation="4" rounded="lg" v-if="ranking.length > 3">
        <v-card-title class="pa-4">
          <v-icon color="primary" class="mr-2">mdi-format-list-numbered</v-icon>
          Clasificación completa
        </v-card-title>
        <v-table>
          <thead>
            <tr>
              <th>#</th>
              <th>Usuario</th>
              <th>Apuestas ganadas</th>
              <th>Ganancias acumuladas</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="entry in ranking.slice(3)" :key="entry.posicion">
              <td>{{ entry.posicion }}</td>
              <td>{{ entry.alias }}</td>
              <td>{{ entry.apuestas_ganadas }}</td>
              <td class="text-success">${{ Number(entry.ganancias_acumuladas).toFixed(2) }}</td>
            </tr>
          </tbody>
        </v-table>
      </v-card>

      <!-- Última actualización -->
      <div class="text-caption text-medium-emphasis text-center mt-4">
        Última actualización: {{ new Date(ranking[0]?.ultima_actualizacion).toLocaleString() }}
      </div>
    </div>

  </v-container>
</template>