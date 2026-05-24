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

interface Opcion {
  id:          string
  descripcion: string
}

interface ApuestaCerrada {
  id:       string
  titulo:   string
  estado:   string
  opciones: Opcion[]
}

interface ParticipacionAdmin {
  alias:               string
  usuario_id:          string
  id:                  string
  apuesta_titulo:      string
  opcion_elegida:      string
  monto:               string
  ganancia_proyectada: string
  ganancia:            string | null
  estado:              string
  fecha_participacion: string
}

interface MesGrupo {
  mes:             string
  participaciones: ParticipacionAdmin[]
}

interface UsuarioGrupo {
  alias:    string
  expandido: boolean
  meses:    MesGrupo[]
}

const documentos      = ref<Documento[]>([])
const loadingDocs     = ref(false)
const mensajeDoc      = ref('')
const motivoRechazo   = ref('')
const dialogRechazo   = ref(false)
const docSeleccionado = ref('')

const apuestasCerradas     = ref<ApuestaCerrada[]>([])
const loadingCerradas      = ref(false)
const dialogConfirmar      = ref(false)
const apuestaConfirmar     = ref<ApuestaCerrada | null>(null)
const opcionGanadora       = ref('')
const mensajeConfirmar     = ref('')
const errorConfirmar       = ref('')
const loadingConfirmar     = ref(false)
const comentarioValidacion = ref('')

const usuariosParticipaciones = ref<UsuarioGrupo[]>([])
const loadingParticipaciones  = ref(false)

const cargarDocumentos = async () => {
  loadingDocs.value = true
  const res  = await apiFetch('/api/documentos/pendientes')
  const data = await res.json()
  documentos.value = Array.isArray(data) ? data : (data.documentos ?? [])
  loadingDocs.value = false
}

const cargarApuestasCerradas = async () => {
  loadingCerradas.value = true
  const res  = await apiFetch('/api/apuestas/admin/cerradas')
  const data = await res.json()
  apuestasCerradas.value = data.apuestas ?? []
  loadingCerradas.value = false
}

const cargarParticipaciones = async () => {
  loadingParticipaciones.value = true
  const res  = await apiFetch('/api/participaciones/admin/todas')
  const data = await res.json()
  const participaciones: ParticipacionAdmin[] = data.participaciones ?? []

  const porUsuario: Record<string, ParticipacionAdmin[]> = {}
  participaciones.forEach(p => {
    const alias = p.alias ?? 'Sin alias'
    if (!porUsuario[alias]) porUsuario[alias] = []
    porUsuario[alias].push(p)
  })

  usuariosParticipaciones.value = Object.entries(porUsuario).map(([alias, parts]) => {
    const porMes: Record<string, ParticipacionAdmin[]> = {}
    parts.forEach(p => {
      const fecha = new Date(p.fecha_participacion)
      const mes   = fecha.toLocaleString('es-MX', { month: 'long', year: 'numeric' })
      if (!porMes[mes]) porMes[mes] = []
      porMes[mes].push(p)
    })
    return {
      alias,
      expandido: false,
      meses: Object.entries(porMes).map(([mes, participaciones]) => ({ mes, participaciones })),
    }
  })

  loadingParticipaciones.value = false
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

const abrirDialogoConfirmar = (apuesta: ApuestaCerrada) => {
  apuestaConfirmar.value     = apuesta
  opcionGanadora.value       = ''
  mensajeConfirmar.value     = ''
  errorConfirmar.value       = ''
  comentarioValidacion.value = ''
  dialogConfirmar.value      = true
}

const confirmarApuestaCerrada = async () => {
  if (!opcionGanadora.value) {
    errorConfirmar.value = 'Selecciona la opción ganadora.'
    return
  }
  loadingConfirmar.value = true
  errorConfirmar.value   = ''

  const res  = await apiFetch('/api/apuestas/admin/declarar-ganador', {
    method: 'POST',
    body:   JSON.stringify({
      apuesta_id:         apuestaConfirmar.value!.id,
      opcion_ganadora_id: opcionGanadora.value,
    }),
  })
  const data = await res.json()

  if (res.ok) {
    mensajeConfirmar.value = 'Resultados validados y premios distribuidos correctamente.'
    await cargarApuestasCerradas()
  } else {
    errorConfirmar.value = data.mensaje || 'Error al declarar ganador.'
  }

  loadingConfirmar.value = false
}

const urlArchivo = (ruta: string) => {
  const nombre = ruta.split('\\').pop() ?? ruta.split('/').pop()
  return `http://localhost:3000/uploads/${nombre}`
}

onMounted(async () => {
  await cargarDocumentos()
  await cargarApuestasCerradas()
  await cargarParticipaciones()
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
                <v-btn color="info" size="small" class="mr-2" :href="urlArchivo(doc.ruta_archivo)" target="_blank">
                  <v-icon>mdi-eye</v-icon>
                </v-btn>
                <v-btn color="success" size="small" class="mr-2" @click="aprobarDocumento(doc.documento_id)">
                  Aprobar
                </v-btn>
                <v-btn color="error" size="small" @click="abrirDialogoRechazo(doc.documento_id)">
                  Rechazar
                </v-btn>
              </td>
            </tr>
          </tbody>
        </v-table>
      </v-card-text>
    </v-card>

    <!-- Apuestas cerradas -->
    <v-card elevation="4" rounded="lg" class="mb-6">
      <v-card-title class="pa-4">
        <v-icon color="error" class="mr-2">mdi-lock</v-icon>
        Apuestas cerradas — declarar ganador
        <v-chip class="ml-2" size="small" color="error">{{ apuestasCerradas.length }}</v-chip>
      </v-card-title>
      <v-card-text>
        <v-alert v-if="apuestasCerradas.length === 0" type="info" variant="tonal">
          No hay apuestas cerradas pendientes de resultado.
        </v-alert>
        <v-table v-else>
          <thead>
            <tr>
              <th>Apuesta</th>
              <th>Acciones</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="apuesta in apuestasCerradas" :key="apuesta.id">
              <td>{{ apuesta.titulo }}</td>
              <td>
                <v-btn color="warning" size="small" @click="abrirDialogoConfirmar(apuesta)">
                  <v-icon start>mdi-flag-checkered</v-icon>
                  Declarar ganador
                </v-btn>
              </td>
            </tr>
          </tbody>
        </v-table>
      </v-card-text>
    </v-card>

    <!-- Historial de participaciones por usuario -->
    <v-card elevation="4" rounded="lg" class="mb-6">
      <v-card-title class="pa-4">
        <v-icon color="info" class="mr-2">mdi-account-group</v-icon>
        Historial de participaciones por usuario
      </v-card-title>
      <v-card-text>
        <v-progress-circular v-if="loadingParticipaciones" indeterminate color="primary" />

        <v-alert v-else-if="usuariosParticipaciones.length === 0" type="info" variant="tonal">
          No hay participaciones registradas.
        </v-alert>

        <v-expansion-panels v-else>
          <v-expansion-panel
            v-for="usuario in usuariosParticipaciones"
            :key="usuario.alias"
          >
            <v-expansion-panel-title>
              <v-icon class="mr-2">mdi-account</v-icon>
              {{ usuario.alias }}
              <v-chip class="ml-2" size="small" color="info">
                {{ usuario.meses.reduce((acc, m) => acc + m.participaciones.length, 0) }} apuestas
              </v-chip>
            </v-expansion-panel-title>

            <v-expansion-panel-text>
              <v-expansion-panels>
                <v-expansion-panel
                  v-for="mes in usuario.meses"
                  :key="mes.mes"
                >
                  <v-expansion-panel-title>
                    <v-icon class="mr-2">mdi-calendar</v-icon>
                    {{ mes.mes }}
                    <v-chip class="ml-2" size="small" color="secondary">
                      {{ mes.participaciones.length }} apuestas
                    </v-chip>
                  </v-expansion-panel-title>

                  <v-expansion-panel-text>
                    <v-table density="compact">
                      <thead>
                        <tr>
                          <th>Apuesta</th>
                          <th>Opción</th>
                          <th>Monto</th>
                          <th>Ganancia proy.</th>
                          <th>Ganancia</th>
                          <th>Estado</th>
                        </tr>
                      </thead>
                      <tbody>
                        <tr v-for="p in mes.participaciones" :key="p.id">
                          <td>{{ p.apuesta_titulo }}</td>
                          <td>{{ p.opcion_elegida }}</td>
                          <td>${{ Number(p.monto).toFixed(2) }}</td>
                          <td>${{ Number(p.ganancia_proyectada).toFixed(2) }}</td>
                          <td>{{ p.ganancia ? '$' + Number(p.ganancia).toFixed(2) : '-' }}</td>
                          <td>
                            <v-chip
                              size="small"
                              :color="p.estado === 'ganadora' ? 'success' : p.estado === 'perdedora' ? 'error' : 'info'"
                            >
                              {{ p.estado }}
                            </v-chip>
                          </td>
                        </tr>
                      </tbody>
                    </v-table>
                  </v-expansion-panel-text>
                </v-expansion-panel>
              </v-expansion-panels>
            </v-expansion-panel-text>
          </v-expansion-panel>
        </v-expansion-panels>
      </v-card-text>
    </v-card>

    <!-- Dialog rechazo documento -->
    <v-dialog v-model="dialogRechazo" max-width="400">
      <v-card rounded="lg">
        <v-card-title>Rechazar documento</v-card-title>
        <v-card-text>
          <v-textarea v-model="motivoRechazo" label="Motivo de rechazo" variant="outlined" rows="3" />
        </v-card-text>
        <v-card-actions>
          <v-btn variant="text" @click="dialogRechazo = false">Cancelar</v-btn>
          <v-spacer />
          <v-btn color="error" @click="rechazarDocumento">Rechazar</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Dialog declarar ganador -->
    <v-dialog v-model="dialogConfirmar" max-width="500">
      <v-card v-if="apuestaConfirmar" rounded="lg">
        <v-card-title>Declarar ganador</v-card-title>
        <v-card-subtitle>{{ apuestaConfirmar.titulo }}</v-card-subtitle>
        <v-card-text>
          <v-alert v-if="mensajeConfirmar" type="success" variant="tonal" class="mb-4">
            {{ mensajeConfirmar }}
          </v-alert>
          <v-alert v-if="errorConfirmar" type="error" variant="tonal" class="mb-4">
            {{ errorConfirmar }}
          </v-alert>
          <div class="text-subtitle-2 mb-2">Selecciona la opción ganadora:</div>
          <v-radio-group v-model="opcionGanadora">
            <v-radio
              v-for="opcion in apuestaConfirmar.opciones"
              :key="opcion.id"
              :label="opcion.descripcion"
              :value="opcion.id"
            />
          </v-radio-group>
          <v-textarea
            v-model="comentarioValidacion"
            label="Comentarios de validación (opcional)"
            variant="outlined"
            rows="2"
            class="mt-3"
          />
        </v-card-text>
        <v-card-actions>
          <v-btn variant="text" @click="dialogConfirmar = false">Cancelar</v-btn>
          <v-spacer />
          <v-btn
            color="warning"
            :loading="loadingConfirmar"
            :disabled="!!mensajeConfirmar"
            @click="confirmarApuestaCerrada"
          >
            Confirmar ganador
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

  </v-container>
</template>
