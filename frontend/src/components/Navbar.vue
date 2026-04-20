<!-- eslint-disable vue/multi-word-component-names -->
<script setup lang="ts">
import { useAuthStore } from '@/stores/auth'
import { useRouter } from 'vue-router'
import { apiFetch } from '@/config/api'
import { ref } from 'vue'

const auth   = useAuthStore()
const router = useRouter()

const saldo   = ref(0)
const loading = ref(false)

const obtenerSaldo = async () => {
  loading.value = true
  const res  = await apiFetch('/api/saldos')
  const data = await res.json()
  saldo.value = data.saldo_disponible ?? 0
  loading.value = false
}

const cerrarSesion = () => {
  auth.logout()
  router.push('/login')
}

if (auth.isLoggedIn) {
  obtenerSaldo()
}
</script>

<template>
  <v-app-bar color="surface" elevation="2">
    <!-- Logo -->
    <v-app-bar-title>
      <v-btn variant="text" @click="$router.push('/apuestas')">
        <v-icon color="primary" class="mr-2">mdi-cards-playing</v-icon>
        <span class="font-weight-bold">GoldenAce</span>
      </v-btn>
    </v-app-bar-title>

    <template #append>
      <div v-if="auth.isLoggedIn" class="d-flex align-center ga-2 mr-4">

        <!-- Saldo -->
        <v-chip color="primary" variant="tonal" prepend-icon="mdi-wallet" size="large">
          ${{ Number(saldo).toFixed(2) }}
        </v-chip>

        <!-- Alias -->
        <v-chip variant="tonal" prepend-icon="mdi-account" size="large">
          {{ auth.usuario?.alias }}
        </v-chip>

        <!-- Menú -->
        <v-menu>
          <template #activator="{ props }">
            <v-btn icon size="large" v-bind="props">
              <v-icon size="28">mdi-dots-vertical</v-icon>
            </v-btn>
          </template>
          <v-list>
            <v-list-item
              prepend-icon="mdi-account"
              title="Mi perfil"
              @click="$router.push('/perfil')"
            />
            <v-list-item
              v-if="auth.isAdmin"
              prepend-icon="mdi-shield-crown"
              title="Panel Admin"
              @click="$router.push('/admin')"
            />
            <v-list-item
              prepend-icon="mdi-plus"
              title="Crear apuesta"
              @click="$router.push('/apuestas/crear')"
            />
            <v-divider />
            <v-list-item
              prepend-icon="mdi-logout"
              title="Cerrar sesión"
              @click="cerrarSesion"
            />
          </v-list>
        </v-menu>

      </div>
    </template>
  </v-app-bar>
</template>