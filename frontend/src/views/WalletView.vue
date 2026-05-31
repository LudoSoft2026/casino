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

const saldo         = ref(0)
const transacciones = ref<Transaccion[]>([])
const loading       = ref(false)

const colorTipo = (tipo: string) => {
  if (tipo === 'ganancia' || tipo === 'bienvenida' || tipo === 'recarga' || tipo === 'devolucion') return 'success'
  if (tipo === 'retiro' || tipo === 'apuesta_deduccion') return 'error'
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
