<script setup lang="ts">
import { onMounted, onUnmounted, ref } from 'vue'
import { useApuestasStore, type Apuesta } from '@/stores/apuestas'
import { useAuthStore } from '@/stores/auth'
import { apiFetch } from '@/config/api'
import { io } from 'socket.io-client'

interface Categoria {
  id:     string
  nombre: string
  icono:  string
}

const categorias       = ref<Categoria[]>([])
const filtroCategoria  = ref<string | null>(null)
const filtroTendencia  = ref(false)

const cargarCategorias = async () => {
  const res  = await apiFetch('/api/categorias')
  const data = await res.json()
  categorias.value = data.categorias ?? []
}

const aplicarFiltros = async () => {
  const params = new URLSearchParams()
  if (filtroCategoria.value) params.append('categoria_id', filtroCategoria.value)
  if (filtroTendencia.value) params.append('tendencia', 'true')

  const res  = await apiFetch(`/api/apuestas?${params.toString()}`)
  const data = await res.json()
  apuestasStore.apuestas = data.apuestas ?? []
  apuestasStore.apuestas.forEach((a: Apuesta) => {
    contadores.value[a.id] = a.segundos_restantes
  })
}

const apuestasStore = useApuestasStore()
const auth          = useAuthStore()

const dialogApostar       = ref(false)
const apuestaSeleccionada = ref<Apuesta | null>(null)
const opcionSeleccionada  = ref('')
const montoApostar        = ref(0)
const loadingApostar      = ref(false)
const mensajeApostar      = ref('')
const errorApostar        = ref('')

const loadingCancelar = ref<Record<string, boolean>>({})
const snackCancelar   = ref(false)
const mensajeCancelar = ref('')

// Proponer resultado
const dialogProponer      = ref(false)
const apuestaProponer     = ref<{ id: string; titulo: string; opciones: { id: string; descripcion: string }[] } | null>(null)
const opcionGanadora      = ref('')
const evidencia           = ref('')
const mensajeProponer     = ref('')
const errorProponer       = ref('')
const loadingProponer     = ref(false)

const contadores = ref<Record<string, number>>({})
const socket = io(import.meta.env.VITE_SOCKET_URL || 'http://localhost:3000')
let intervalo: ReturnType<typeof setInterval>

onMounted(async () => {
  await apuestasStore.listar()
  await apuestasStore.cargarMisApuestas()
  await cargarCategorias()
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
const esMiApuesta  = (id: string) => apuestasStore.misApuestas.some(a => a.id === id)

const misApuestasCerradas = () => apuestasStore.misApuestas.filter(a => a.estado === 'cerrada')

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

const cancelarApuesta = async (apuestaId: string) => {
  loadingCancelar.value[apuestaId] = true
  const res  = await apiFetch(`/api/apuestas/cancelar/${apuestaId}`, { method: 'DELETE' })
  const data = await res.json()
  mensajeCancelar.value = data.mensaje
  snackCancelar.value   = true
  await apuestasStore.listar()
  await apuestasStore.cargarMisApuestas()
  loadingCancelar.value[apuestaId] = false
}

const abrirDialogoProponer = async (apuestaId: string, titulo: string) => {
  opcionGanadora.value  = ''
  evidencia.value       = ''
  mensajeProponer.value = ''
  errorProponer.value   = ''

  const res  = await apiFetch(`/api/apuestas/${apuestaId}/opciones`)
  const data = await res.json()
  apuestaProponer.value = { id: apuestaId, titulo, opciones: data.opciones ?? [] }
  dialogProponer.value  = true
}

const proponer = async () => {
  if (!opcionGanadora.value) {
    errorProponer.value = 'Selecciona la opción ganadora.'
    return
  }
  if (!evidencia.value.trim()) {
    errorProponer.value = 'Por favor, indica una fuente o descripción para validar el resultado.'
    return
  }
  loadingProponer.value = true
  errorProponer.value   = ''

  const res  = await apiFetch('/api/resultados/proponer', {
    method: 'POST',
    body:   JSON.stringify({
      apuesta_id:         apuestaProponer.value!.id,
      opcion_ganadora_id: opcionGanadora.value,
      evidencia:          evidencia.value,
    }),
  })
  const data = await res.json()

  if (data.resultadoId) {
    mensajeProponer.value = data.mensaje
    await apuestasStore.cargarMisApuestas()
  } else {
    errorProponer.value = data.mensaje || 'Error al proponer resultado.'
  }
  loadingProponer.value = false
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
        <v-btn v-if="!auth.isAdmin" color="primary" prepend-icon="mdi-plus" @click="$router.push('/apuestas/crear')">
          Crear apuesta
        </v-btn>
      </v-col>
    </v-row>

    <!-- Filtros -->
    <v-row class="mb-4" align="center">
      <v-col cols="12" md="5">
        <v-select
          v-model="filtroCategoria"
          :items="categorias"
          item-title="nombre"
          item-value="id"
          label="Filtrar por categoría"
          variant="outlined"
          density="compact"
          clearable
          hide-details
          prepend-inner-icon="mdi-tag"
          @update:model-value="aplicarFiltros"
        />
      </v-col>
      <v-col cols="12" md="4">
        <v-switch
          v-model="filtroTendencia"
          label="En tendencia 🔥"
          color="orange"
          hide-details
          @update:model-value="aplicarFiltros"
        />
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
        <div class="text-h6 mt-2 text-medium-emphasis">
          {{ filtroCategoria
            ? 'Por el momento no hay apuestas activas en esta categoría. ¡Anímate a crear una!'
            : 'No hay apuestas activas por el momento.' }}
        </div>
      </v-col>
    </v-row>

    <v-row v-else>
      <v-col v-for="apuesta in apuestasStore.apuestas" :key="apuesta.id" cols="12" md="6" lg="4">
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

            <v-chip :color="getBloqueada(apuesta.id) ? 'error' : 'success'" size="small" class="mt-2">
              <v-icon start>mdi-clock</v-icon>
              {{ formatearTiempo(getSegundos(apuesta.id)) }}
            </v-chip>

            <div class="mt-3">
              <div v-for="opcion in apuesta.opciones" :key="opcion.id"
                class="d-flex justify-space-between align-center mb-1">
                <span class="text-sm">{{ opcion.descripcion }}</span>
                <v-chip size="small" color="primary">×{{ opcion.cuota }}</v-chip>
              </div>
            </div>
          </v-card-text>

          <v-card-actions class="flex-column pa-3 ga-2">
            <v-btn
              v-if="!auth.isAdmin"
              block
              color="primary"
              :disabled="getBloqueada(apuesta.id)"
              @click="abrirDialogo(apuesta)"
            >
              {{ getBloqueada(apuesta.id) ? 'Bloqueada' : 'Apostar' }}
            </v-btn>
            <v-btn v-else block color="grey" disabled>
              El admin no puede apostar
            </v-btn>
            <v-btn
              v-if="esMiApuesta(apuesta.id) && !auth.isAdmin"
              block
              color="error"
              variant="tonal"
              :loading="loadingCancelar[apuesta.id]"
              @click="cancelarApuesta(apuesta.id)"
            >
              <v-icon start>mdi-close-circle</v-icon>
              Cancelar apuesta
            </v-btn>
          </v-card-actions>

        </v-card>
      </v-col>
    </v-row>

    <!-- Mis apuestas cerradas pendientes de resultado -->
    <div v-if="!auth.isAdmin && misApuestasCerradas().length > 0" class="mt-8">
      <div class="text-h6 font-weight-bold mb-4">
        <v-icon color="warning" class="mr-2">mdi-flag-checkered</v-icon>
        Mis apuestas cerradas — proponer resultado
      </div>
      <v-row>
        <v-col v-for="apuesta in misApuestasCerradas()" :key="apuesta.id" cols="12" md="6" lg="4">
          <v-card elevation="4" rounded="lg" color="surface">
            <v-card-title>{{ apuesta.titulo }}</v-card-title>
            <v-card-subtitle>
              <v-chip color="error" size="small">Cerrada</v-chip>
            </v-card-subtitle>
            <v-card-actions>
              <v-btn
                block
                color="warning"
                @click="abrirDialogoProponer(apuesta.id, apuesta.titulo)"
              >
                <v-icon start>mdi-flag-checkered</v-icon>
                Proponer resultado
              </v-btn>
            </v-card-actions>
          </v-card>
        </v-col>
      </v-row>
    </div>

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
            <v-radio v-for="opcion in apuestaSeleccionada.opciones" :key="opcion.id"
              :label="`${opcion.descripcion} (×${opcion.cuota})`" :value="opcion.id" />
          </v-radio-group>
          <v-text-field v-model.number="montoApostar" label="Monto a apostar" type="number" variant="outlined"
            prepend-inner-icon="mdi-cash" :min="apuestaSeleccionada.monto_minimo" class="mt-2" />
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

    <!-- Dialog proponer resultado -->
    <v-dialog v-model="dialogProponer" max-width="500">
      <v-card v-if="apuestaProponer" rounded="lg">
        <v-card-title>Proponer resultado</v-card-title>
        <v-card-subtitle>{{ apuestaProponer.titulo }}</v-card-subtitle>
        <v-card-text>
          <v-alert v-if="mensajeProponer" type="success" variant="tonal" class="mb-4">
            {{ mensajeProponer }}
          </v-alert>
          <v-alert v-if="errorProponer" type="error" variant="tonal" class="mb-4">
            {{ errorProponer }}
          </v-alert>
          <div class="text-subtitle-2 mb-2">Selecciona la opción ganadora:</div>
          <v-radio-group v-model="opcionGanadora">
            <v-radio
              v-for="opcion in apuestaProponer.opciones"
              :key="opcion.id"
              :label="opcion.descripcion"
              :value="opcion.id"
            />
          </v-radio-group>
          <v-textarea
            v-model="evidencia"
            label="Fuente o evidencia del resultado *"
            variant="outlined"
            rows="2"
            placeholder="Ej: https://... o descripción del resultado"
            class="mt-3"
          />
        </v-card-text>
        <v-card-actions>
          <v-btn variant="text" @click="dialogProponer = false">Cancelar</v-btn>
          <v-spacer />
          <v-btn
            color="warning"
            :loading="loadingProponer"
            :disabled="!!mensajeProponer"
            @click="proponer"
          >
            Proponer
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Snackbar cancelar -->
    <v-snackbar v-model="snackCancelar" :timeout="3000" color="success">
      {{ mensajeCancelar }}
    </v-snackbar>

  </v-container>
</template> 