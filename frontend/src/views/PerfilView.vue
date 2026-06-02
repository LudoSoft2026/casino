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
const loadingDoc   = ref(false)
const mensajeDoc   = ref('')
const errorDoc     = ref('')
const archivo      = ref<File | null>(null)
const numeroDoc    = ref('')
const tipoDoc      = ref('INE')

const obtenerSaldo = async () => {
  loadingSaldo.value = true
  const res  = await apiFetch('/api/saldos')
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
  errorDoc.value   = ''
  mensajeDoc.value = ''

  if (!archivo.value) {
    errorDoc.value = 'Selecciona un archivo.'
    return
  }
  if (!numeroDoc.value.trim()) {
    errorDoc.value = 'Ingresa el número de tu INE.'
    return
  }

  loadingDoc.value = true

  const formData = new FormData()
  formData.append('documento', archivo.value)
  formData.append('numero_documento', numeroDoc.value.trim())
  formData.append('tipo_documento', 'INE')

  const res = await fetch(`${import.meta.env.VITE_API_URL || 'http://localhost:3000'}/api/documentos`, {
    method:  'POST',
    headers: { Authorization: `Bearer ${auth.token}` },
    body:    formData,
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
                <template #prepend><v-icon>mdi-at</v-icon></template>
                <v-list-item-title>{{ auth.usuario?.alias }}</v-list-item-title>
                <v-list-item-subtitle>Alias</v-list-item-subtitle>
              </v-list-item>
              <v-list-item>
                <template #prepend><v-icon>mdi-email</v-icon></template>
                <v-list-item-title>{{ auth.usuario?.correo }}</v-list-item-title>
                <v-list-item-subtitle>Correo</v-list-item-subtitle>
              </v-list-item>
              <v-list-item>
                <template #prepend><v-icon>mdi-shield-account</v-icon></template>
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
            Verificación de identidad — INE
          </v-card-title>
          <v-card-text>

            <!-- Instrucciones -->
              <v-alert
                v-if="!documento || documento.estado !== 'aprobado'"
                  type="info"
                  variant="tonal"
                class="mb-4"
              icon="mdi-information"
            >
            <div class="font-weight-bold mb-2">¿Cómo verificar tu identidad?</div>
              <ol class="ml-4">
                <li>Toma una foto clara de tu <strong>INE por ambos lados</strong> en un solo archivo.</li>
                <li>Asegúrate de que el número de folio sea <strong>legible</strong>.</li>
                <li>Ingresa el <strong>número de folio</strong> que aparece al frente de tu INE.</li>
                <li>Sube el archivo en formato <strong>JPG, PNG o PDF</strong>.</li>
                <li>El administrador revisará tu documento en un plazo de <strong>24 horas</strong>.</li>
              </ol>
            </v-alert>

            <!-- Ya tiene documento -->
            <div v-if="documento">
              <v-alert
                v-if="documento.estado !== 'aprobado'"
                :type="documento.estado === 'rechazado' ? 'error' : 'info'"
                variant="tonal"
                class="mb-4"
              >
                <div class="font-weight-bold">
                  {{ documento.estado === 'rechazado'
                    ? 'Documento rechazado. Puedes subir uno nuevo.'
                    : 'Documento en revisión. Te notificaremos cuando sea aprobado.' }}
                </div>
                <div v-if="documento.motivo_rechazo" class="mt-1">
                  Motivo: {{ documento.motivo_rechazo }}
                </div>
              </v-alert>

              <v-list density="compact" class="mb-4">
                <v-list-item>
                  <v-list-item-title>Tipo: <strong>{{ documento.tipo_documento }}</strong></v-list-item-title>
                </v-list-item>
                <v-list-item>
                  <v-list-item-title>Número de folio: <strong>{{ documento.numero_documento }}</strong></v-list-item-title>
                </v-list-item>
                <v-list-item>
                  <v-list-item-title>
                    Estado:
                    <v-chip
                      :color="documento.estado === 'aprobado' ? 'success' : documento.estado === 'rechazado' ? 'error' : 'warning'"
                      size="small"
                      class="ml-1"
                    >
                      {{ documento.estado }}
                    </v-chip>
                  </v-list-item-title>
                </v-list-item>
              </v-list>

              <!-- Re-subir si fue rechazado -->
              <div v-if="documento.estado === 'rechazado'">
                <v-divider class="mb-4" />
                <div class="text-subtitle-2 font-weight-bold mb-3">Subir nuevo documento:</div>
                <v-alert v-if="errorDoc"   type="error"   variant="tonal" class="mb-3">{{ errorDoc }}</v-alert>
                <v-alert v-if="mensajeDoc" type="success" variant="tonal" class="mb-3">{{ mensajeDoc }}</v-alert>
                <v-text-field
                  v-model="numeroDoc"
                  label="Número de folio de tu INE *"
                  variant="outlined"
                  prepend-inner-icon="mdi-card-account-details"
                  class="mb-3"
                  placeholder="Ej: 1234567890"
                />
                <v-file-input
                  label="Selecciona tu INE (JPG, PNG o PDF)"
                  accept=".jpg,.jpeg,.png,.pdf"
                  variant="outlined"
                  prepend-icon="mdi-paperclip"
                  class="mb-3"
                  @change="onFileChange"
                />
                <v-btn color="primary" :loading="loadingDoc" block @click="subirDocumento">
                  <v-icon start>mdi-upload</v-icon>
                  Subir INE
                </v-btn>
              </div>
            </div>

            <!-- No tiene documento -->
            <div v-else>
              <v-alert v-if="errorDoc"   type="error"   variant="tonal" class="mb-4">{{ errorDoc }}</v-alert>
              <v-alert v-if="mensajeDoc" type="success" variant="tonal" class="mb-4">{{ mensajeDoc }}</v-alert>

              <v-text-field
                v-model="numeroDoc"
                label="Número de folio de tu INE *"
                variant="outlined"
                prepend-inner-icon="mdi-card-account-details"
                class="mb-3"
                placeholder="Ej: 1234567890"
              />
              <v-file-input
                label="Selecciona tu INE (JPG, PNG o PDF)"
                accept=".jpg,.jpeg,.png,.pdf"
                variant="outlined"
                prepend-icon="mdi-paperclip"
                class="mb-3"
                @change="onFileChange"
              />
              <v-btn color="primary" :loading="loadingDoc" block @click="subirDocumento">
                <v-icon start>mdi-upload</v-icon>
                Subir INE para verificar mi cuenta
              </v-btn>
            </div>

          </v-card-text>
        </v-card>

      </v-col>
    </v-row>
  </v-container>
</template>