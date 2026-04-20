<script setup lang="ts">
import Navbar from '@/components/Navbar.vue'
import { useAuthStore } from '@/stores/auth'

const auth = useAuthStore()
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