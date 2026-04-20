<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const auth   = useAuthStore()

const correo   = ref('')
const password = ref('')
const loading  = ref(false)
const error    = ref('')
const showPass = ref(false)

const login = async () => {
  error.value   = ''
  loading.value = true

  try {
    const res = await fetch('http://localhost:3000/api/auth/login', {
      method:  'POST',
      headers: { 'Content-Type': 'application/json' },
      body:    JSON.stringify({ correo: correo.value, password: password.value }),
    })

    const data = await res.json()

    if (!res.ok) {
      error.value = data.mensaje || 'Credenciales inválidas.'
      return
    }

    auth.setToken(data.token)
    auth.setUsuario(data.usuario)
    router.push('/apuestas')
  } catch {
    error.value = 'Error de conexión. Intenta nuevamente.'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <v-container class="fill-height" fluid>
    <v-row align="center" justify="center">
      <v-col cols="12" sm="8" md="4">

        <v-card elevation="8" rounded="lg">
          <v-card-title class="text-center pa-6">
            <v-icon size="48" color="primary">mdi-cards-playing</v-icon>
            <div class="text-h5 font-weight-bold mt-2">Casino App</div>
            <div class="text-subtitle-2 text-medium-emphasis">Inicia sesión para continuar</div>
          </v-card-title>

          <v-card-text class="px-6">
            <v-alert
              v-if="error"
              type="error"
              variant="tonal"
              class="mb-4"
              density="compact"
            >
              {{ error }}
            </v-alert>

            <v-text-field
              v-model="correo"
              label="Correo electrónico"
              type="email"
              prepend-inner-icon="mdi-email"
              variant="outlined"
              class="mb-3"
              @keyup.enter="login"
            />

            <v-text-field
              v-model="password"
              label="Contraseña"
              :type="showPass ? 'text' : 'password'"
              prepend-inner-icon="mdi-lock"
              :append-inner-icon="showPass ? 'mdi-eye-off' : 'mdi-eye'"
              variant="outlined"
              class="mb-3"
              @click:append-inner="showPass = !showPass"
              @keyup.enter="login"
            />

            <v-btn
              block
              color="primary"
              size="large"
              :loading="loading"
              @click="login"
            >
              Iniciar sesión
            </v-btn>
          </v-card-text>

          <v-card-actions class="justify-center pb-6">
            <span class="text-medium-emphasis text-sm">¿No tienes cuenta?</span>
            <v-btn variant="text" color="primary" @click="$router.push('/registro')">
              Regístrate
            </v-btn>
          </v-card-actions>
        </v-card>

      </v-col>
    </v-row>
  </v-container>
</template>
