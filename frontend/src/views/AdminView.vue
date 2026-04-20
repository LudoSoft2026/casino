<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { apiFetch } from '@/config/api'

interface Documento {
  documento_id:     string
  nombre_completo:  string
  correo:           string
  tipo_documento:   string
  numero_documento: string
  fecha_subida:     string
  ruta_archivo:     string
}

interface Resultado {
  id:              string
  apuesta_titulo:  string
  opcion_ganadora: string
  fecha_propuesta: string
}

const documentos      = ref<Documento[]>([])
const loadingDocs     = ref(false)
const mensajeDoc      = ref('')
const motivoRechazo   = ref('')
const dialogRechazo   = ref(false)
const docSeleccionado = ref('')

const resultados     = ref<Resultado[]>([])
const loadingResults = ref(false)
const mensajeResult  = ref('')

const cargarDocumentos = async () => {
  loadingDocs.value = true
  const res  = await apiFetch('/api/documentos/pendientes')
  const data = await res.json()
  documentos.value = Array.isArray(data) ? data : (data.documentos ?? [])
  loadingDocs.value = false
}

const cargarResultados = async () => {
  loadingResults.value = true
  const res  = await apiFetch('/api/resultados/pendientes')
  const data = await res.json()
  resultados.value = data.resultados ?? []
  loadingResults.value = false
}

const aprobarDocumento = async (documentoId: string) => {
  mensajeDoc.value = ''
  const res  = await apiFetch('/api/documentos/revisar', {
    method: 'POST',
    body:   JSON.stringify({ documento_id: documentoId, aprobar: true }),
  })
  const data = await res.json()
  mensajeDoc.value = data.mensaje
  await cargarDocumentos()
}

const abrirDialogoRechazo = (documentoId: string) => {
  docSeleccionado.value = documentoId
  motivoRechazo.value   = ''
  dialogRechazo.value   = true
}

const rechazarDocumento = async () => {
  const res  = await apiFetch('/api/documentos/revisar', {
    method: 'POST',
    body:   JSON.stringify({
      documento_id:   docSeleccionado.value,
      aprobar:        false,
      motivo_rechazo: motivoRechazo.value,
    }),
  })
  const data = await res.json()
  mensajeDoc.value    = data.mensaje
  dialogRechazo.value = false
  await cargarDocumentos()
}

const confirmarResultado = async (resultadoId: string, aprobar: boolean, motivo?: string) => {
  const res  = await apiFetch('/api/resultados/confirmar', {
    method: 'POST',
    body:   JSON.stringify({
      resultado_id:   resultadoId,
      aprobar,
      motivo_rechazo: motivo ?? null,
    }),
  })
  const data = await res.json()
  mensajeResult.value = data.mensaje
  await cargarResultados()
}

const urlArchivo = (ruta: string) => {
  const nombre = ruta.split('\\').pop() ?? ruta.split('/').pop()
  return `http://localhost:3000/uploads/${nombre}`
}

onMounted(async () => {
  await cargarDocumentos()
  await cargarResultados()
})
</script>

<template>
  <v-container class="py-6">
    <div class="text-h5 font-weight-bold mb-6">
      <v-icon color="primary" class="mr-2">mdi-shield-crown</v-icon>
      Panel de Administración
    </div>

    <!-- Documentos pendientes -->
    <v-card elevation="4" rounded="lg" class="mb-6">
      <v-card-title class="pa-4">
        <v-icon color="warning" class="mr-2">mdi-card-account-details</v-icon>
        Documentos pendientes
        <v-chip class="ml-2" size="small" color="warning">{{ documentos.length }}</v-chip>
      </v-card-title>

      <v-card-text>
        <v-alert v-if="mensajeDoc" type="success" variant="tonal" class="mb-4" density="compact">
          {{ mensajeDoc }}
        </v-alert>

        <v-alert v-if="documentos.length === 0" type="info" variant="tonal">
          No hay documentos pendientes.
        </v-alert>

        <v-table v-else>
          <thead>
            <tr>
              <th>Usuario</th>
              <th>Correo</th>
              <th>Tipo</th>
              <th>Número</th>
              <th>Fecha</th>
              <th>Acciones</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="doc in documentos" :key="doc.documento_id">
              <td>{{ doc.nombre_completo }}</td>
              <td>{{ doc.correo }}</td>
              <td>{{ doc.tipo_documento }}</td>
              <td>{{ doc.numero_documento }}</td>
              <td>{{ new Date(doc.fecha_subida).toLocaleDateString() }}</td>
              <td>
                <v-btn
                  color="info"
                  size="small"
                  class="mr-2"
                  :href="urlArchivo(doc.ruta_archivo)"
                  target="_blank"
                >
                  <v-icon>mdi-eye</v-icon>
                </v-btn>
                <v-btn
                  color="success"
                  size="small"
                  class="mr-2"
                  @click="aprobarDocumento(doc.documento_id)"
                >
                  Aprobar
                </v-btn>
                <v-btn
                  color="error"
                  size="small"
                  @click="abrirDialogoRechazo(doc.documento_id)"
                >
                  Rechazar
                </v-btn>
              </td>
            </tr>
          </tbody>
        </v-table>
      </v-card-text>
    </v-card>

    <!-- Resultados pendientes -->
    <v-card elevation="4" rounded="lg">
      <v-card-title class="pa-4">
        <v-icon color="primary" class="mr-2">mdi-check-circle</v-icon>
        Resultados pendientes
        <v-chip class="ml-2" size="small" color="primary">{{ resultados.length }}</v-chip>
      </v-card-title>

      <v-card-text>
        <v-alert v-if="mensajeResult" type="success" variant="tonal" class="mb-4" density="compact">
          {{ mensajeResult }}
        </v-alert>

        <v-alert v-if="resultados.length === 0" type="info" variant="tonal">
          No hay resultados pendientes.
        </v-alert>

        <v-table v-else>
          <thead>
            <tr>
              <th>Apuesta</th>
              <th>Opción ganadora</th>
              <th>Fecha propuesta</th>
              <th>Acciones</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="resultado in resultados" :key="resultado.id">
              <td>{{ resultado.apuesta_titulo }}</td>
              <td>{{ resultado.opcion_ganadora }}</td>
              <td>{{ new Date(resultado.fecha_propuesta).toLocaleDateString() }}</td>
              <td>
                <v-btn
                  color="success"
                  size="small"
                  class="mr-2"
                  @click="confirmarResultado(resultado.id, true)"
                >
                  Confirmar
                </v-btn>
                <v-btn
                  color="error"
                  size="small"
                  @click="confirmarResultado(resultado.id, false, 'Resultado incorrecto')"
                >
                  Rechazar
                </v-btn>
              </td>
            </tr>
          </tbody>
        </v-table>
      </v-card-text>
    </v-card>

    <!-- Dialog rechazo documento -->
    <v-dialog v-model="dialogRechazo" max-width="400">
      <v-card rounded="lg">
        <v-card-title>Rechazar documento</v-card-title>
        <v-card-text>
          <v-textarea
            v-model="motivoRechazo"
            label="Motivo de rechazo"
            variant="outlined"
            rows="3"
          />
        </v-card-text>
        <v-card-actions>
          <v-btn variant="text" @click="dialogRechazo = false">Cancelar</v-btn>
          <v-spacer />
          <v-btn color="error" @click="rechazarDocumento">Rechazar</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

  </v-container>
</template>