<!-- eslint-disable vue/multi-word-component-names -->
<script setup lang="ts">
import { useAuthStore } from '@/stores/auth'
import { useRouter } from 'vue-router'
import { apiFetch } from '@/config/api'
import { ref, onMounted, onUnmounted } from 'vue'
import { io } from 'socket.io-client'

const auth   = useAuthStore()
const router = useRouter()

const saldo       = ref(0)
const loading     = ref(false)
const drawerAdmin = ref(false)

const socket = io(import.meta.env.VITE_SOCKET_URL || 'http://localhost:3000', {
  autoConnect: false
})

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

const irA = (ruta: string, tab?: string) => {
  if (tab) {
    router.push({ path: ruta, query: { tab } })
  } else {
    router.push(ruta)
  }
  drawerAdmin.value = false
}

onMounted(() => {
  if (auth.isLoggedIn) {
    obtenerSaldo()
    if (auth.usuario?.id) {
      socket.connect()
      socket.on('connect', () => {
        socket.emit('join:usuario', auth.usuario!.id)
      })
      socket.on('saldo:actualizado', (data: { saldo: number }) => {
        saldo.value = data.saldo
      })
    }
  }
})

onUnmounted(() => {
  socket.disconnect()
})
</script>

<template>
  <!-- Drawer lateral admin -->
  <v-navigation-drawer
    v-if="auth.isAdmin"
    v-model="drawerAdmin"
    temporary
    location="left"
    width="260"
  >
    <v-list-item
      prepend-icon="mdi-shield-crown"
      title="Panel Admin"
      subtitle="GoldenAce"
      class="py-4 bg-primary"
    />
    <v-divider />
    <v-list density="compact" nav class="mt-2">
      <v-list-item
        prepend-icon="mdi-card-account-details"
        title="Documentos"
        rounded="lg"
        @click="irA('/admin', 'documentos')"
      />
      <v-list-item
        prepend-icon="mdi-cards-playing"
        title="Apuestas"
        rounded="lg"
        @click="irA('/admin', 'apuestas')"
      />
      <v-list-item
        prepend-icon="mdi-account-cog"
        title="Usuarios"
        rounded="lg"
        @click="irA('/admin', 'usuarios')"
      />
      <v-list-item
        prepend-icon="mdi-history"
        title="Historial"
        rounded="lg"
        @click="irA('/admin', 'historial')"
      />
      <v-list-item
        prepend-icon="mdi-tag-multiple"
        title="Categorías"
        rounded="lg"
        @click="irA('/admin', 'categorias')"
      />
      <v-divider class="my-2" />
      <v-list-item
        prepend-icon="mdi-trophy"
        title="Ranking"
        rounded="lg"
        @click="irA('/ranking')"
      />
      <v-list-item
        prepend-icon="mdi-cards-playing"
        title="Ver apuestas"
        rounded="lg"
        @click="irA('/apuestas')"
      />
    </v-list>
    <template #append>
      <v-divider />
      <v-list density="compact" nav class="mb-2">
        <v-list-item
          prepend-icon="mdi-logout"
          title="Cerrar sesión"
          color="error"
          rounded="lg"
          @click="cerrarSesion"
        />
      </v-list>
    </template>
  </v-navigation-drawer>

  <v-app-bar color="surface" elevation="2">
    <template #prepend>
      <v-btn v-if="auth.isAdmin" icon @click="drawerAdmin = !drawerAdmin">
        <v-icon>mdi-menu</v-icon>
      </v-btn>
    </template>

    <v-app-bar-title>
      <v-btn variant="text" @click="$router.push('/apuestas')">
        <v-icon color="primary" class="mr-2">mdi-cards-playing</v-icon>
        <span class="font-weight-bold">GoldenAce</span>
      </v-btn>
    </v-app-bar-title>

    <template #append>
      <div v-if="auth.isLoggedIn" class="d-flex align-center ga-2 mr-4">

        <!-- Saldo solo si no es admin -->
        <v-chip v-if="!auth.isAdmin" color="primary" variant="tonal" prepend-icon="mdi-wallet" size="large">
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
            <v-list-item v-if="!auth.isAdmin" prepend-icon="mdi-account" title="Mi perfil"
              @click="$router.push('/perfil')" />
            <v-list-item v-if="auth.isAdmin" prepend-icon="mdi-shield-crown" title="Panel Admin"
              @click="$router.push('/admin')" />
            <v-list-item v-if="!auth.isAdmin" prepend-icon="mdi-plus" title="Crear apuesta"
              @click="$router.push('/apuestas/crear')" />
            <v-list-item v-if="!auth.isAdmin" prepend-icon="mdi-wallet" title="Mi wallet"
              @click="$router.push('/wallet')" />
            <v-list-item v-if="!auth.isAdmin" prepend-icon="mdi-history" title="Mi historial"
              @click="$router.push('/historial')" />
            <v-divider />
            <v-list-item prepend-icon="mdi-trophy" title="Ranking" @click="$router.push('/ranking')" />
            <v-list-item prepend-icon="mdi-logout" title="Cerrar sesión" @click="cerrarSesion" />
          </v-list>
        </v-menu>

      </div>
    </template>
  </v-app-bar>
</template>