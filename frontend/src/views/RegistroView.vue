<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()

const form = ref({
  nombre:           '',
  apellido_paterno: '',
  apellido_materno: '',
  fecha_nacimiento: '',
  telefono:         '',
  alias:            '',
  correo:           '',
  password:         '',
  confirmar:        '',
})

const loading  = ref(false)
const error    = ref('')
const showPass = ref(false)
const showConfirm = ref(false)

const mayorDeEdad = computed(() => {
  if (!form.value.fecha_nacimiento) return true
  const hoy  = new Date()
  const nac  = new Date(form.value.fecha_nacimiento)
  const edad = hoy.getFullYear() - nac.getFullYear()
  return edad >= 18
})

const registro = async () => {
  error.value = ''

  if (!form.value.nombre || !form.value.apellido_paterno || !form.value.fecha_nacimiento ||
      !form.value.telefono || !form.value.alias || !form.value.correo || !form.value.password) {
    error.value = 'Completa todos los campos obligatorios.'
    return
  }

  if (!mayorDeEdad.value) {
    error.value = 'Debes ser mayor de edad para registrarte.'
    return
  }

  if (form.value.password !== form.value.confirmar) {
    error.value = 'Las contraseñas no coinciden.'
    return
  }

  if (form.value.password.length < 8) {
    error.value = 'La contraseña debe tener al menos 8 caracteres.'
    return
  }

  if (!/[A-Z]/.test(form.value.password)) {
    error.value = 'La contraseña debe tener al menos una mayúscula.'
    return
  }

  if (!/[0-9]/.test(form.value.password)) {
    error.value = 'La contraseña debe tener al menos un número.'
    return
  }

  loading.value = true

  try {
    const res = await fetch('http://localhost:3000/api/auth/registro', {
      method:  'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        nombre:           form.value.nombre,
        apellido_paterno: form.value.apellido_paterno,
        apellido_materno: form.value.apellido_materno,
        fecha_nacimiento: form.value.fecha_nacimiento,
        telefono:         form.value.telefono,
        alias:            form.value.alias,
        correo:           form.value.correo,
        password:         form.value.password,
      }),
    })

    const data = await res.json()

    if (!res.ok) {
      error.value = data.mensaje || 'Error al registrarse.'
      return
    }

    router.push('/login')
  } catch {
    error.value = 'Error de conexión. Intenta nuevamente.'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <v-container class="py-8">
    <v-row justify="center">
      <v-col cols="12" sm="10" md="6">

        <v-card elevation="8" rounded="lg">
          <v-card-title class="text-center pa-6">
            <v-icon size="48" color="primary">mdi-account-plus</v-icon>
            <div class="text-h5 font-weight-bold mt-2">Crear cuenta</div>
            <div class="text-subtitle-2 text-medium-emphasis">Completa el formulario para registrarte</div>
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

            <!-- Información personal -->
            <div class="text-subtitle-1 font-weight-bold mb-3">Información personal</div>

            <v-row>
              <v-col cols="12" md="4">
                <v-text-field
                  v-model="form.nombre"
                  label="Nombre *"
                  variant="outlined"
                  prepend-inner-icon="mdi-account"
                />
              </v-col>
              <v-col cols="12" md="4">
                <v-text-field
                  v-model="form.apellido_paterno"
                  label="Apellido paterno *"
                  variant="outlined"
                />
              </v-col>
              <v-col cols="12" md="4">
                <v-text-field
                  v-model="form.apellido_materno"
                  label="Apellido materno"
                  variant="outlined"
                />
              </v-col>
            </v-row>

            <v-row>
              <v-col cols="12" md="6">
                <v-text-field
                  v-model="form.fecha_nacimiento"
                  label="Fecha de nacimiento *"
                  type="date"
                  variant="outlined"
                  prepend-inner-icon="mdi-calendar"
                  :error-messages="!mayorDeEdad ? 'Debes ser mayor de edad' : ''"
                />
              </v-col>
              <v-col cols="12" md="6">
                <v-text-field
                  v-model="form.telefono"
                  label="Teléfono *"
                  variant="outlined"
                  prepend-inner-icon="mdi-phone"
                />
              </v-col>
            </v-row>

            <v-divider class="my-4" />

            <!-- Información de cuenta -->
            <div class="text-subtitle-1 font-weight-bold mb-3">Información de cuenta</div>

            <v-text-field
              v-model="form.alias"
              label="Nombre de usuario *"
              variant="outlined"
              prepend-inner-icon="mdi-at"
              class="mb-3"
            />

            <v-text-field
              v-model="form.correo"
              label="Correo electrónico *"
              type="email"
              variant="outlined"
              prepend-inner-icon="mdi-email"
              class="mb-3"
            />

            <v-text-field
              v-model="form.password"
              label="Contraseña *"
              :type="showPass ? 'text' : 'password'"
              variant="outlined"
              prepend-inner-icon="mdi-lock"
              :append-inner-icon="showPass ? 'mdi-eye-off' : 'mdi-eye'"
              class="mb-3"
              @click:append-inner="showPass = !showPass"
            />

            <v-text-field
              v-model="form.confirmar"
              label="Confirmar contraseña *"
              :type="showConfirm ? 'text' : 'password'"
              variant="outlined"
              prepend-inner-icon="mdi-lock-check"
              :append-inner-icon="showConfirm ? 'mdi-eye-off' : 'mdi-eye'"
              class="mb-3"
              @click:append-inner="showConfirm = !showConfirm"
            />

            <v-btn
              block
              color="primary"
              size="large"
              :loading="loading"
              @click="registro"
            >
              Crear cuenta
            </v-btn>
          </v-card-text>

          <v-card-actions class="justify-center pb-6">
            <span class="text-medium-emphasis text-sm">¿Ya tienes cuenta?</span>
            <v-btn variant="text" color="primary" @click="$router.push('/login')">
              Inicia sesión
            </v-btn>
          </v-card-actions>
        </v-card>
        <!-- Banner promocional -->
        <v-img
          src="/PromoCasino.png"
          rounded="lg"
          class="mt-4"
          cover
        />
      </v-col>
    </v-row>
  </v-container>
</template>
