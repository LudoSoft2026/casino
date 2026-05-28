<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { apiFetch } from '@/config/api'

const auth = useAuthStore()

const saldo = ref(0)
const documento = ref<null | {
  estado: string
  tipo_documento: string
  numero_documento: string
  motivo_rechazo: string | null
}>(null)
const loadingSaldo = ref(false)
const loadingDoc = ref(false)
const mensajeDoc = ref('')
const errorDoc = ref('')
const archivo = ref<File | null>(null)
const numeroDoc = ref('')
const tipoDoc = ref('INE')

const tiposDocumento = ['INE', 'pasaporte', 'cedula', 'otro']

const obtenerSaldo = async () => {
  loadingSaldo.value = true
  const res = await apiFetch('/api/saldos')
  const data = await res.json()
  saldo.value = data.saldo_disponible ?? 0
  loadingSaldo.value = false
}

const obtenerDocumento = async () => {
  const res = await apiFetch('/api/documentos/mi-documento')
  if (res.ok) {
    const data = await res.json()
    documento.value = data.documento
  }
}

const subirDocumento = async () => {
  errorDoc.value = ''
  mensajeDoc.value = ''

  if (!archivo.value) {
    errorDoc.value = 'Selecciona un archivo.'
    return
  }
  if (!numeroDoc.value) {
    errorDoc.value = 'Ingresa el número de documento.'
    return
  }

  loadingDoc.value = true

  const formData = new FormData()
  formData.append('documento', archivo.value)
  formData.append('numero_documento', numeroDoc.value)
  formData.append('tipo_documento', tipoDoc.value)

  const res = await fetch('http://localhost:3000/api/documentos', {
    method: 'POST',
    headers: { Authorization: `Bearer ${auth.token}` },
    body: formData,
  })

  const data = await res.json()

  if (res.ok) {
    mensajeDoc.value = data.mensaje
    await obtenerDocumento()
  } else {
    errorDoc.value = data.mensaje || 'Error al subir documento.'
  }

  loadingDoc.value = false
}

const onFileChange = (e: Event) => {
  const target = e.target as HTMLInputElement
  archivo.value = target.files?.[0] ?? null
}

onMounted(async () => {
  await obtenerSaldo()
  await obtenerDocumento()
})
</script>

<template>
  <v-container class="py-6">
    <v-row justify="center">
      <v-col cols="12" md="8">

        <!-- Saldo -->
        <v-card elevation="4" rounded="lg" class="mb-6">
          <v-card-title class="pa-4">
            <v-icon color="primary" class="mr-2">mdi-wallet</v-icon>
            Mi saldo
          </v-card-title>
          <v-card-text>
            <v-skeleton-loader v-if="loadingSaldo" type="text" />
            <div v-else class="text-h4 font-weight-bold text-primary">
              ${{ Number(saldo).toFixed(2) }}
            </div>
          </v-card-text>
        </v-card>

        <!-- Info usuario -->
        <v-card elevation="4" rounded="lg" class="mb-6">
          <v-card-title class="pa-4">
            <v-icon color="primary" class="mr-2">mdi-account</v-icon>
            Mi cuenta
          </v-card-title>
          <v-card-text>
            <v-list>
              <v-list-item>
                <template #prepend>
                  <v-icon>mdi-at</v-icon>
                </template>
                <v-list-item-title>{{ auth.usuario?.alias }}</v-list-item-title>
                <v-list-item-subtitle>Alias</v-list-item-subtitle>
              </v-list-item>
              <v-list-item>
                <template #prepend>
                  <v-icon>mdi-email</v-icon>
                </template>
                <v-list-item-title>{{ auth.usuario?.correo }}</v-list-item-title>
                <v-list-item-subtitle>Correo</v-list-item-subtitle>
              </v-list-item>
              <v-list-item>
                <template #prepend>
                  <v-icon>mdi-shield-account</v-icon>
                </template>
                <v-list-item-title>
                  <v-chip :color="auth.usuario?.estado === 'verificada' ? 'success' : 'warning'" size="small">
                    {{ auth.usuario?.estado }}
                  </v-chip>
                </v-list-item-title>
                <v-list-item-subtitle>Estado de cuenta</v-list-item-subtitle>
              </v-list-item>
            </v-list>
          </v-card-text>
        </v-card>

        <!-- Documento -->
        <v-card elevation="4" rounded="lg">
          <v-card-title class="pa-4">
            <v-icon color="primary" class="mr-2">mdi-card-account-details</v-icon>
            Verificación de identidad
          </v-card-title>
          <v-card-text>

            <!-- Ya tiene documento -->
            <div v-if="documento">

              <!-- Solo mostrar alert si NO está aprobado -->
              <v-alert v-if="documento.estado !== 'aprobado'"
                :type="documento.estado === 'rechazado' ? 'error' : 'info'" variant="tonal" class="mb-4">
                <div class="font-weight-bold">
                  {{ documento.estado === 'rechazado'
                    ? 'Se ha notificado al usuario sobre el rechazo del documento.'
                    : 'Documento en revisión' }}
                </div>
                <div v-if="documento.motivo_rechazo">
                  Motivo: {{ documento.motivo_rechazo }}
                </div>
              </v-alert>

              <v-list density="compact">
                <v-list-item>
                  <v-list-item-title>Tipo: {{ documento.tipo_documento }}</v-list-item-title>
                </v-list-item>
                <v-list-item>
                  <v-list-item-title>Número: {{ documento.numero_documento }}</v-list-item-title>
                </v-list-item>
              </v-list>

              <!-- Puede re-subir si fue rechazado -->
              <div v-if="documento.estado === 'rechazado'" class="mt-4">
                <div class="text-subtitle-2 mb-2">Subir nuevo documento:</div>
                <v-select v-model="tipoDoc" :items="tiposDocumento" label="Tipo de documento" variant="outlined"
                  class="mb-3" />
                <v-text-field v-model="numeroDoc" label="Número de documento" variant="outlined" class="mb-3" />
                <input type="file" accept=".jpg,.jpeg,.png,.pdf" @change="onFileChange" class="mb-3" />
                <v-btn color="primary" :loading="loadingDoc" @click="subirDocumento" block>
                  Subir documento
                </v-btn>
              </div>
            </div>

            <!-- No tiene documento -->
            <div v-else>
              <v-alert type="warning" variant="tonal" class="mb-4">
                Sube tu documento de identidad para verificar tu cuenta y poder crear apuestas.
              </v-alert>

              <v-alert v-if="errorDoc" type="error" variant="tonal" class="mb-4">
                {{ errorDoc }}
              </v-alert>

              <v-alert v-if="mensajeDoc" type="success" variant="tonal" class="mb-4">
                {{ mensajeDoc }}
              </v-alert>

              <v-select v-model="tipoDoc" :items="tiposDocumento" label="Tipo de documento" variant="outlined"
                class="mb-3" />
              <v-text-field v-model="numeroDoc" label="Número de documento" variant="outlined" class="mb-3" />
              <input type="file" accept=".jpg,.jpeg,.png,.pdf" @change="onFileChange" class="mb-3" />
              <v-btn color="primary" :loading="loadingDoc" @click="subirDocumento" block class="mt-2">
                Subir documento
              </v-btn>
            </div>

          </v-card-text>
        </v-card>

      </v-col>
    </v-row>
  </v-container>
</template>
