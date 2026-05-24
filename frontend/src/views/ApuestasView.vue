<script setup lang="ts">
import { onMounted, onUnmounted, ref } from 'vue'
import { useApuestasStore, type Apuesta } from '@/stores/apuestas'
import { useAuthStore } from '@/stores/auth'
import { io } from 'socket.io-client'

const apuestasStore = useApuestasStore()
const auth          = useAuthStore()

const dialogApostar       = ref(false)
const apuestaSeleccionada = ref<Apuesta | null>(null)
const opcionSeleccionada  = ref('')
const montoApostar        = ref(0)
const loadingApostar      = ref(false)
const mensajeApostar      = ref('')
const errorApostar        = ref('')

const contadores = ref<Record<string, number>>({})
const socket     = io('http://localhost:3000')
let intervalo: ReturnType<typeof setInterval>

onMounted(async () => {
  await apuestasStore.listar()

  apuestasStore.apuestas.forEach(a => {
    contadores.value[a.id] = a.segundos_restantes
  })

intervalo = setInterval(() => {
  Object.keys(contadores.value).forEach(id => {
    const seg = contadores.value[id]
    if (seg !== undefined && seg > 0) {
      contadores.value[id] = seg - 1
    }
  })
}, 1000)

  socket.on('apuesta:actualizada', async () => {
    await apuestasStore.listar()
    apuestasStore.apuestas.forEach(a => {
      contadores.value[a.id] = a.segundos_restantes
    })
  })
})

onUnmounted(() => {
  clearInterval(intervalo)
  socket.disconnect()
})

const getSegundos  = (id: string) => contadores.value[id] ?? 0
const getBloqueada = (id: string) => getSegundos(id) <= 30

const abrirDialogo = (apuesta: Apuesta) => {
  apuestaSeleccionada.value = apuesta
  opcionSeleccionada.value  = ''
  montoApostar.value        = apuesta.monto_minimo
  mensajeApostar.value      = ''
  errorApostar.value        = ''
  dialogApostar.value       = true
}

const apostar = async () => {
  if (!opcionSeleccionada.value) {
    errorApostar.value = 'Selecciona una opción.'
    return
  }
  loadingApostar.value = true
  errorApostar.value   = ''

  const result = await apuestasStore.participar(
    apuestaSeleccionada.value!.id,
    opcionSeleccionada.value,
    montoApostar.value
  )

  if (result.participacionId) {
    mensajeApostar.value = `¡Apuesta realizada! Ganancia si ganas: $${result.gananciaSiGana}`
    await apuestasStore.listar()
  } else {
    errorApostar.value = result.mensaje || 'Error al apostar.'
  }

  loadingApostar.value = false
}

const formatearTiempo = (segundos: number) => {
  if (segundos <= 0) return 'Cerrada'
  const h = Math.floor(segundos / 3600)
  const m = Math.floor((segundos % 3600) / 60)
  const s = segundos % 60
  if (h > 0) return `${h}h ${m}m`
  if (m > 0) return `${m}m ${s}s`
  return `${s}s`
}
</script>

<template>
  <v-container class="py-6">

    <v-row align="center" class="mb-4">
      <v-col>
        <div class="text-h5 font-weight-bold">
          <v-icon color="primary" class="mr-2">mdi-cards-playing</v-icon>
          Apuestas activas
        </div>
      </v-col>
      <v-col cols="auto">
        <v-btn color="primary" prepend-icon="mdi-plus" @click="$router.push('/apuestas/crear')">
          Crear apuesta
        </v-btn>
      </v-col>
    </v-row>

    <v-row v-if="apuestasStore.loading" justify="center">
      <v-col cols="auto">
        <v-progress-circular indeterminate color="primary" size="64" />
      </v-col>
    </v-row>

    <v-row v-else-if="apuestasStore.apuestas.length === 0" justify="center">
      <v-col cols="12" class="text-center">
        <v-icon size="64" color="grey">mdi-emoticon-sad-outline</v-icon>
        <div class="text-h6 mt-2 text-medium-emphasis">No hay apuestas activas por el momento.</div>
      </v-col>
    </v-row>

    <v-row v-else>
      <v-col
        v-for="apuesta in apuestasStore.apuestas"
        :key="apuesta.id"
        cols="12" md="6" lg="4"
      >
        <v-card elevation="4" rounded="lg" height="100%">

          <v-card-title class="pb-1">
            <v-chip v-if="apuesta.es_tendencia" color="orange" size="small" class="mr-2">
              <v-icon start>mdi-fire</v-icon> Tendencia
            </v-chip>
            {{ apuesta.titulo }}
          </v-card-title>

          <v-card-subtitle class="pb-2">
            {{ apuesta.descripcion }}
          </v-card-subtitle>

          <v-card-text>
            <v-row density="comfortable">
              <v-col cols="6">
                <v-icon size="16" class="mr-1">mdi-account-group</v-icon>
                <span class="text-sm">{{ apuesta.total_participantes }} participantes</span>
              </v-col>
              <v-col cols="6">
                <v-icon size="16" class="mr-1">mdi-cash</v-icon>
                <span class="text-sm">Mín. ${{ apuesta.monto_minimo }}</span>
              </v-col>
            </v-row>

            <v-chip
              :color="getBloqueada(apuesta.id) ? 'error' : 'success'"
              size="small"
              class="mt-2"
            >
              <v-icon start>mdi-clock</v-icon>
              {{ formatearTiempo(getSegundos(apuesta.id)) }}
            </v-chip>

            <div class="mt-3">
              <div
                v-for="opcion in apuesta.opciones"
                :key="opcion.id"
                class="d-flex justify-space-between align-center mb-1"
              >
                <span class="text-sm">{{ opcion.descripcion }}</span>
                <v-chip size="small" color="primary">×{{ opcion.cuota }}</v-chip>
              </div>
            </div>
          </v-card-text>

          <v-card-actions>
            <v-btn
              v-if="!auth.isAdmin"
              block
              color="primary"
              :disabled="getBloqueada(apuesta.id)"
              @click="abrirDialogo(apuesta)"
            >
              {{ getBloqueada(apuesta.id) ? 'Bloqueada' : 'Apostar' }}
            </v-btn>
            <v-btn
              v-else
              block
              color="grey"
              disabled
            >
              El admin no puede apostar
            </v-btn>
          </v-card-actions>

        </v-card>
      </v-col>
    </v-row>

    <!-- Dialog apostar -->
    <v-dialog v-model="dialogApostar" max-width="500">
      <v-card v-if="apuestaSeleccionada" rounded="lg">
        <v-card-title>{{ apuestaSeleccionada.titulo }}</v-card-title>
        <v-card-text>
          <v-alert v-if="mensajeApostar" type="success" variant="tonal" class="mb-4">
            {{ mensajeApostar }}
          </v-alert>
          <v-alert v-if="errorApostar" type="error" variant="tonal" class="mb-4">
            {{ errorApostar }}
          </v-alert>
          <div class="text-subtitle-2 mb-2">Selecciona una opción:</div>
          <v-radio-group v-model="opcionSeleccionada">
            <v-radio
              v-for="opcion in apuestaSeleccionada.opciones"
              :key="opcion.id"
              :label="`${opcion.descripcion} (×${opcion.cuota})`"
              :value="opcion.id"
            />
          </v-radio-group>
          <v-text-field
            v-model.number="montoApostar"
            label="Monto a apostar"
            type="number"
            variant="outlined"
            prepend-inner-icon="mdi-cash"
            :min="apuestaSeleccionada.monto_minimo"
            class="mt-2"
          />
          <v-alert type="info" variant="tonal" density="compact" class="mt-2">
            Ganancia si ganas: ${{ opcionSeleccionada
              ? (montoApostar * (apuestaSeleccionada.opciones.find(o => o.id === opcionSeleccionada)?.cuota ?? 1)).toFixed(2)
              : '0.00'
            }}
          </v-alert>
        </v-card-text>
        <v-card-actions>
          <v-btn variant="text" @click="dialogApostar = false">Cancelar</v-btn>
          <v-spacer />
          <v-btn color="primary" :loading="loadingApostar" :disabled="!!mensajeApostar" @click="apostar">
            Confirmar apuesta
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

  </v-container>
</template>
