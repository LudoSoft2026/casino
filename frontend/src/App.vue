<script setup lang="ts">
import Navbar from '@/components/Navbar.vue'
import { useAuthStore } from '@/stores/auth'
import { useRouter } from 'vue-router'
import { apiFetch } from '@/config/api'
import { onMounted, onUnmounted } from 'vue'

const auth   = useAuthStore()
const router = useRouter()

let intervalo: ReturnType<typeof setInterval>

const verificarSesion = async () => {
  if (!auth.isLoggedIn) return
  const res = await apiFetch('/api/saldos')
  if (res.status === 401 || res.status === 403) {
    auth.logout()
    router.push('/login?mensaje=' + encodeURIComponent('Su cuenta ha sido suspendida o bloqueada.'))
  }
}

onMounted(() => {
  if (auth.isLoggedIn) {
    intervalo = setInterval(verificarSesion, 10000)
  }
})

onUnmounted(() => {
  clearInterval(intervalo)
})
</script>

<template>
  <v-app>
    <Navbar v-if="auth.isLoggedIn" />
    <main>
      <v-main>
        <RouterView />
      </v-main>
    </main>
  </v-app>
</template>
