<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { apiFetch } from '@/config/api'

interface Transaccion {
  tipo:            string
  monto:           string
  saldo_anterior:  string
  saldo_posterior: string
  descripcion:     string
  fecha:           string
}

const saldo          = ref(0)
const transacciones  = ref<Transaccion[]>([])
const loading        = ref(false)

const montoRecarga   = ref(100)
const metodoRecarga  = ref('tarjeta_ficticia')
const loadingRecarga = ref(false)
const mensajeRecarga = ref('')
const errorRecarga   = ref('')

const montoRetiro    = ref(100)
const metodoRetiro   = ref('transferencia_bancaria')
const loadingRetiro  = ref(false)
const mensajeRetiro  = ref('')
const errorRetiro    = ref('')

const colorTipo = (tipo: string) => {
  if (tipo === 'ganancia' || tipo === 'bienvenida' || tipo === 'recarga') return 'success'
  if (tipo === 'retiro' || tipo === 'apuesta_deduccion') return 'error'
  if (tipo === 'devolucion') return 'info'
  return 'warning'
}

const iconoTipo = (tipo: string) => {
  if (tipo === 'ganancia')          return 'mdi-trophy'
  if (tipo === 'bienvenida')        return 'mdi-gift'
  if (tipo === 'recarga')           return 'mdi-plus-circle'
  if (tipo === 'retiro')            return 'mdi-minus-circle'
  if (tipo === 'apuesta_deduccion') return 'mdi-cards-playing'
  if (tipo === 'devolucion')        return 'mdi-refresh'
  return 'mdi-cash'
}

const cargar = async () => {
  loading.value = true
  const resSaldo = await apiFetch('/api/saldos')
  const dataSaldo = await resSaldo.json()
  saldo.value = dataSaldo.saldo_disponible ?? 0

  const resHistorial = await apiFetch('/api/saldos/historial')
  const dataHistorial = await resHistorial.json()
  transacciones.value = Array.isArray(dataHistorial) ? dataHistorial : (dataHistorial.movimientos ?? [])
  loading.value = false
}

const recargar = async () => {
  mensajeRecarga.value = ''
  errorRecarga.value   = ''
  loadingRecarga.value = true

  const res  = await apiFetch('/api/saldos/recargar', {
    method: 'POST',
    body:   JSON.stringify({ monto: montoRecarga.value, metodo: metodoRecarga.value }),
  })
  const data = await res.json()

  if (res.ok) {
    mensajeRecarga.value = data.mensaje
    await cargar()
  } else {
    errorRecarga.value = data.mensaje || 'Error al recargar.'
  }
  loadingRecarga.value = false
}

const retirar = async () => {
  mensajeRetiro.value = ''
  errorRetiro.value   = ''
  loadingRetiro.value = true

  const res  = await apiFetch('/api/retiros', {
    method: 'POST',
    body:   JSON.stringify({ monto_solicitado: montoRetiro.value, metodo_retiro: metodoRetiro.value }),
  })
  const data = await res.json()

  if (res.ok) {
    mensajeRetiro.value = data.mensaje
    await cargar()
  } else {
    errorRetiro.value = data.mensaje || 'Error al retirar.'
  }
  loadingRetiro.value = false
}

onMounted(async () => {
  await cargar()
})
</script>

<template>
  <v-container class="py-6">
    <div class="text-h5 font-weight-bold mb-6">
      <v-icon color="primary" class="mr-2">mdi-wallet</v-icon>
      Mi Wallet
    </div>

    <!-- Saldo -->
    <v-card elevation="4" rounded="lg" class="mb-6" color="primary">
      <v-card-text class="pa-6">
        <div class="text-caption text-white">Saldo disponible</div>
        <div class="text-h3 font-weight-bold text-white">
          ${{ Number(saldo).toFixed(2) }}
        </div>
      </v-card-text>
    </v-card>

    <!-- Acciones -->
    <v-row class="mb-6">
      <!-- Recargar -->
      <v-col cols="12" md="6">
        <v-card elevation="4" rounded="lg">
          <v-card-title class="pa-4">
            <v-icon color="success" class="mr-2">mdi-plus-circle</v-icon>
            Recargar saldo
          </v-card-title>
          <v-card-text>
            <v-alert v-if="mensajeRecarga" type="success" variant="tonal" class="mb-3" density="compact">
              {{ mensajeRecarga }}
            </v-alert>
            <v-alert v-if="errorRecarga" type="error" variant="tonal" class="mb-3" density="compact">
              {{ errorRecarga }}
            </v-alert>
            <v-text-field
              v-model.number="montoRecarga"
              label="Monto a recargar"
              type="number"
              variant="outlined"
              prepend-inner-icon="mdi-cash"
              class="mb-3"
            />
            <v-select
              v-model="metodoRecarga"
              :items="['tarjeta_ficticia', 'transferencia', 'efectivo']"
              label="Método"
              variant="outlined"
              class="mb-3"
            />
            <v-btn block color="success" :loading="loadingRecarga" @click="recargar">
              Recargar
            </v-btn>
          </v-card-text>
        </v-card>
      </v-col>

      <!-- Retirar -->
      <v-col cols="12" md="6">
        <v-card elevation="4" rounded="lg">
          <v-card-title class="pa-4">
            <v-icon color="error" class="mr-2">mdi-minus-circle</v-icon>
            Retirar saldo
          </v-card-title>
          <v-card-text>
            <v-alert v-if="mensajeRetiro" type="success" variant="tonal" class="mb-3" density="compact">
              {{ mensajeRetiro }}
            </v-alert>
            <v-alert v-if="errorRetiro" type="error" variant="tonal" class="mb-3" density="compact">
              {{ errorRetiro }}
            </v-alert>
            <v-text-field
              v-model.number="montoRetiro"
              label="Monto a retirar"
              type="number"
              variant="outlined"
              prepend-inner-icon="mdi-cash"
              class="mb-3"
            />
            <v-select
              v-model="metodoRetiro"
              :items="['transferencia_bancaria', 'tarjeta', 'monedero']"
              label="Método"
              variant="outlined"
              class="mb-3"
            />
            <v-alert type="info" variant="tonal" density="compact" class="mb-3">
              Comisión 4%: -${{ (montoRetiro * 0.04).toFixed(2) }} |
              Recibirás: ${{ (montoRetiro * 0.96).toFixed(2) }}
            </v-alert>
            <v-btn block color="error" :loading="loadingRetiro" @click="retirar">
              Retirar
            </v-btn>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>

    <!-- Historial de transacciones -->
    <v-card elevation="4" rounded="lg">
      <v-card-title class="pa-4">
        <v-icon color="primary" class="mr-2">mdi-history</v-icon>
        Historial de transacciones
      </v-card-title>
      <v-card-text>
        <v-progress-circular v-if="loading" indeterminate color="primary" />

        <v-alert v-else-if="transacciones.length === 0" type="info" variant="tonal">
          No hay transacciones registradas.
        </v-alert>

        <v-list v-else lines="two">
          <v-list-item
            v-for="(tx, index) in transacciones"
            :key="index"
          >
            <template #prepend>
              <v-icon :color="colorTipo(tx.tipo)" class="mr-3">
                {{ iconoTipo(tx.tipo) }}
              </v-icon>
            </template>

            <template #title>
              <span class="text-capitalize">{{ tx.tipo.replace('_', ' ') }}</span>
            </template>

            <template #subtitle>
              <div>{{ tx.descripcion }}</div>
              <div class="text-caption">{{ new Date(tx.fecha).toLocaleString() }}</div>
            </template>

            <template #append>
              <div class="text-right">
                <div
                  :class="colorTipo(tx.tipo) === 'success' ? 'text-success' : 'text-error'"
                  class="font-weight-bold"
                >
                  {{ colorTipo(tx.tipo) === 'success' ? '+' : '-' }}${{ Number(tx.monto).toFixed(2) }}
                </div>
                <div class="text-caption text-medium-emphasis">
                  Saldo: ${{ Number(tx.saldo_posterior).toFixed(2) }}
                </div>
              </div>
            </template>
          </v-list-item>
        </v-list>
      </v-card-text>
    </v-card>
  </v-container>
</template>
