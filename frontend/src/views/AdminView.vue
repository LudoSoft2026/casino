<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { apiFetch } from '@/config/api'

interface Documento {
  documento_id: string
  nombre_completo: string
  correo: string
  tipo_documento: string
  numero_documento: string
  fecha_subida: string
  ruta_archivo: string
}

interface Opcion {
  id: string
  descripcion: string
}

interface ApuestaCerrada {
  id:              string
  titulo:          string
  estado:          string
  opciones:        Opcion[]
  evidencia:       string | null
  fecha_propuesta: string | null
}

interface ParticipacionAdmin {
  alias: string
  usuario_id: string
  id: string
  apuesta_titulo: string
  opcion_elegida: string
  monto: string
  ganancia_proyectada: string
  ganancia: string | null
  estado: string
  fecha_participacion: string
}

interface MesGrupo {
  mes: string
  participaciones: ParticipacionAdmin[]
}

interface UsuarioGrupo {
  alias: string
  expandido: boolean
  meses: MesGrupo[]
}

interface ApuestaActiva {
  id: string
  titulo: string
  estado: string
  creador_alias: string
  total_participantes: number
}

interface Usuario {
  id: string
  alias: string
  correo: string
  rol: string
  estado: string
  fecha_registro: string
}

const documentos      = ref<Documento[]>([])
const loadingDocs     = ref(false)
const mensajeDoc      = ref('')
const motivoRechazo   = ref('')
const dialogRechazo   = ref(false)
const docSeleccionado = ref('')

const apuestasCerradas    = ref<ApuestaCerrada[]>([])
const loadingCerradas     = ref(false)
const dialogConfirmar     = ref(false)
const apuestaConfirmar    = ref<ApuestaCerrada | null>(null)
const opcionGanadora      = ref('')
const mensajeConfirmar    = ref('')
const errorConfirmar      = ref('')
const loadingConfirmar    = ref(false)
const comentarioValidacion = ref('')

const usuariosParticipaciones = ref<UsuarioGrupo[]>([])
const loadingParticipaciones  = ref(false)

const apuestasActivas  = ref<ApuestaActiva[]>([])
const loadingActivas   = ref(false)
const mensajeEliminar  = ref('')

const usuarios            = ref<Usuario[]>([])
const loadingUsuarios     = ref(false)
const dialogEstado        = ref(false)
const usuarioSeleccionado = ref<Usuario | null>(null)
const accionEstado        = ref('suspender')
const motivoEstado        = ref('')
const mensajeEstado       = ref('')
const errorEstado         = ref('')
const loadingEstado       = ref(false)

const dialogSaldo  = ref(false)
const accionSaldo  = ref<'abonar' | 'deducir'>('abonar')
const usuarioSaldo = ref<Usuario | null>(null)
const montoSaldo   = ref(0)
const motivoSaldo  = ref('')
const mensajeSaldo = ref('')
const errorSaldo   = ref('')
const loadingSaldo = ref(false)

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

const cargarApuestasActivas = async () => {
  loadingActivas.value = true
  const res  = await apiFetch('/api/apuestas')
  const data = await res.json()
  apuestasActivas.value = data.apuestas ?? []
  loadingActivas.value = false
}

const eliminarApuesta = async (apuestaId: string) => {
  const res  = await apiFetch(`/api/apuestas/${apuestaId}`, { method: 'DELETE' })
  const data = await res.json()
  mensajeEliminar.value = data.mensaje
  await cargarApuestasActivas()
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

const cargarUsuarios = async () => {
  loadingUsuarios.value = true
  const res  = await apiFetch('/api/usuarios')
  const data = await res.json()
  usuarios.value = data.usuarios ?? []
  loadingUsuarios.value = false
}

const abrirDialogoEstado = (usuario: Usuario) => {
  usuarioSeleccionado.value = usuario
  accionEstado.value        = 'suspender'
  motivoEstado.value        = ''
  mensajeEstado.value       = ''
  errorEstado.value         = ''
  dialogEstado.value        = true
}

const cambiarEstado = async () => {
  if (!motivoEstado.value) {
    errorEstado.value = 'El motivo es obligatorio.'
    return
  }
  loadingEstado.value = true
  errorEstado.value   = ''

  const res  = await apiFetch(`/api/usuarios/${usuarioSeleccionado.value!.id}/estado`, {
    method: 'PUT',
    body:   JSON.stringify({ accion: accionEstado.value, motivo: motivoEstado.value }),
  })
  const data = await res.json()

  if (res.ok) {
    mensajeEstado.value = data.mensaje
    await cargarUsuarios()
  } else {
    errorEstado.value = data.mensaje || 'Error al cambiar estado.'
  }
  loadingEstado.value = false
}

const abrirDialogoSaldo = (usuario: Usuario, accion: 'abonar' | 'deducir') => {
  usuarioSaldo.value  = usuario
  accionSaldo.value   = accion
  montoSaldo.value    = 0
  motivoSaldo.value   = ''
  mensajeSaldo.value  = ''
  errorSaldo.value    = ''
  dialogSaldo.value   = true
}

const gestionarSaldo = async () => {
  if (!montoSaldo.value || montoSaldo.value <= 0) {
    errorSaldo.value = 'El monto a ingresar debe ser mayor a cero.'
    return
  }
  if (!motivoSaldo.value.trim()) {
    errorSaldo.value = 'Debe especificar un motivo.'
    return
  }
  loadingSaldo.value = true
  errorSaldo.value   = ''

  const endpoint = accionSaldo.value === 'abonar' ? '/api/saldos/admin/abonar' : '/api/saldos/admin/deducir'
  const res  = await apiFetch(endpoint, {
    method: 'POST',
    body:   JSON.stringify({
      usuario_id: usuarioSaldo.value!.id,
      monto:      montoSaldo.value,
      motivo:     motivoSaldo.value,
    }),
  })
  const data = await res.json()

  if (res.ok) {
    mensajeSaldo.value = data.mensaje
    await cargarUsuarios()
  } else {
    errorSaldo.value = data.mensaje || 'Error al gestionar saldo.'
  }
  loadingSaldo.value = false
}

const colorEstado = (estado: string) => {
  if (estado === 'verificada') return 'success'
  if (estado === 'suspendida') return 'warning'
  if (estado === 'bloqueada')  return 'error'
  return 'info'
}

const urlArchivo = (ruta: string) => {
  const nombre = ruta.split('\\').pop() ?? ruta.split('/').pop()
  return `http://localhost:3000/uploads/${nombre}`
}

onMounted(async () => {
  await cargarDocumentos()
  await cargarApuestasCerradas()
  await cargarParticipaciones()
  await cargarApuestasActivas()
  await cargarUsuarios()
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
              <th>Estado</th>
              <th>Acciones</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="apuesta in apuestasCerradas" :key="apuesta.id">
              <td>{{ apuesta.titulo }}</td>
              <td>
                <v-chip :color="apuesta.estado === 'en_revision' ? 'warning' : 'error'" size="small">
                  <v-icon start>{{ apuesta.estado === 'en_revision' ? 'mdi-flag-checkered' : 'mdi-lock' }}</v-icon>
                  {{ apuesta.estado === 'en_revision' ? 'Resultado propuesto' : 'Sin resultado' }}
                </v-chip>
              </td>
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

    <!-- Apuestas activas -->
    <v-card elevation="4" rounded="lg" class="mb-6">
      <v-card-title class="pa-4">
        <v-icon color="success" class="mr-2">mdi-cards-playing</v-icon>
        Apuestas activas
        <v-chip class="ml-2" size="small" color="success">{{ apuestasActivas.length }}</v-chip>
      </v-card-title>
      <v-card-text>
        <v-alert v-if="mensajeEliminar" type="success" variant="tonal" class="mb-4" density="compact">
          {{ mensajeEliminar }}
        </v-alert>
        <v-alert v-if="apuestasActivas.length === 0" type="info" variant="tonal">
          No hay apuestas activas.
        </v-alert>
        <v-table v-else>
          <thead>
            <tr>
              <th>Apuesta</th>
              <th>Creador</th>
              <th>Participantes</th>
              <th>Acciones</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="apuesta in apuestasActivas" :key="apuesta.id">
              <td>{{ apuesta.titulo }}</td>
              <td>{{ apuesta.creador_alias }}</td>
              <td>{{ apuesta.total_participantes }}</td>
              <td>
                <v-btn color="error" size="small" @click="eliminarApuesta(apuesta.id)">
                  <v-icon start>mdi-delete</v-icon>
                  Eliminar
                </v-btn>
              </td>
            </tr>
          </tbody>
        </v-table>
      </v-card-text>
    </v-card>

    <!-- Gestión de usuarios -->
    <v-card elevation="4" rounded="lg" class="mb-6">
      <v-card-title class="pa-4">
        <v-icon color="purple" class="mr-2">mdi-account-cog</v-icon>
        Gestión de usuarios
        <v-chip class="ml-2" size="small" color="purple">{{ usuarios.length }}</v-chip>
      </v-card-title>
      <v-card-text>
        <v-progress-circular v-if="loadingUsuarios" indeterminate color="primary" />
        <v-alert v-else-if="usuarios.length === 0" type="info" variant="tonal">
          No hay usuarios registrados.
        </v-alert>
        <v-table v-else>
          <thead>
            <tr>
              <th>Alias</th>
              <th>Correo</th>
              <th>Estado</th>
              <th>Registro</th>
              <th>Acciones</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="usuario in usuarios" :key="usuario.id">
              <td>{{ usuario.alias }}</td>
              <td>{{ usuario.correo }}</td>
              <td>
                <v-chip :color="colorEstado(usuario.estado)" size="small">
                  {{ usuario.estado }}
                </v-chip>
              </td>
              <td>{{ new Date(usuario.fecha_registro).toLocaleDateString() }}</td>
              <td>
                <v-btn color="warning" size="small" class="mr-1" @click="abrirDialogoEstado(usuario)">
                  <v-icon start>mdi-account-edit</v-icon>
                  Gestionar
                </v-btn>
                <v-btn color="success" size="small" class="mr-1" @click="abrirDialogoSaldo(usuario, 'abonar')">
                  <v-icon start>mdi-plus-circle</v-icon>
                  Abonar
                </v-btn>
                <v-btn color="error" size="small" @click="abrirDialogoSaldo(usuario, 'deducir')">
                  <v-icon start>mdi-minus-circle</v-icon>
                  Deducir
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
          <v-expansion-panel v-for="usuario in usuariosParticipaciones" :key="usuario.alias">
            <v-expansion-panel-title>
              <v-icon class="mr-2">mdi-account</v-icon>
              {{ usuario.alias }}
              <v-chip class="ml-2" size="small" color="info">
                {{ usuario.meses.reduce((acc, m) => acc + m.participaciones.length, 0) }} apuestas
              </v-chip>
            </v-expansion-panel-title>
            <v-expansion-panel-text>
              <v-expansion-panels>
                <v-expansion-panel v-for="mes in usuario.meses" :key="mes.mes">
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
                            <v-chip size="small"
                              :color="p.estado === 'ganadora' ? 'success' : p.estado === 'perdedora' ? 'error' : 'info'">
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
          <v-alert v-if="apuestaConfirmar.evidencia" type="info" variant="tonal" class="mb-4">
            <div class="font-weight-bold">Evidencia del creador:</div>
            <div>{{ apuestaConfirmar.evidencia }}</div>
            <div class="text-caption mt-1">
              Propuesto: {{ new Date(apuestaConfirmar.fecha_propuesta!).toLocaleString() }}
            </div>
          </v-alert>
          <div class="text-subtitle-2 mb-2">Selecciona la opción ganadora:</div>
          <v-radio-group v-model="opcionGanadora">
            <v-radio v-for="opcion in apuestaConfirmar.opciones" :key="opcion.id"
              :label="opcion.descripcion" :value="opcion.id" />
          </v-radio-group>
          <v-textarea v-model="comentarioValidacion" label="Comentarios de validación (opcional)"
            variant="outlined" rows="2" class="mt-3" />
        </v-card-text>
        <v-card-actions>
          <v-btn variant="text" @click="dialogConfirmar = false">Cancelar</v-btn>
          <v-spacer />
          <v-btn color="warning" :loading="loadingConfirmar" :disabled="!!mensajeConfirmar"
            @click="confirmarApuestaCerrada">
            Confirmar ganador
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Dialog gestión usuario -->
    <v-dialog v-model="dialogEstado" max-width="500">
      <v-card v-if="usuarioSeleccionado" rounded="lg">
        <v-card-title>Gestionar usuario</v-card-title>
        <v-card-subtitle>{{ usuarioSeleccionado.alias }}</v-card-subtitle>
        <v-card-text>
          <v-alert v-if="mensajeEstado" type="success" variant="tonal" class="mb-4">
            {{ mensajeEstado }}
          </v-alert>
          <v-alert v-if="errorEstado" type="error" variant="tonal" class="mb-4">
            {{ errorEstado }}
          </v-alert>
          <div class="text-subtitle-2 mb-2">Selecciona la acción:</div>
          <v-radio-group v-model="accionEstado" class="mb-3">
            <v-radio label="Activar"   value="activar"   color="success" />
            <v-radio label="Suspender" value="suspender" color="warning" />
            <v-radio label="Bloquear"  value="bloquear"  color="error" />
          </v-radio-group>
          <v-textarea v-model="motivoEstado" label="Motivo *" variant="outlined" rows="2" />
        </v-card-text>
        <v-card-actions>
          <v-btn variant="text" @click="dialogEstado = false">Cancelar</v-btn>
          <v-spacer />
          <v-btn color="warning" :loading="loadingEstado" :disabled="!!mensajeEstado" @click="cambiarEstado">
            Confirmar
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Dialog gestión saldo -->
    <v-dialog v-model="dialogSaldo" max-width="500">
      <v-card v-if="usuarioSaldo" rounded="lg">
        <v-card-title>
          {{ accionSaldo === 'abonar' ? 'Abonar saldo' : 'Deducir saldo' }}
        </v-card-title>
        <v-card-subtitle>{{ usuarioSaldo.alias }}</v-card-subtitle>
        <v-card-text>
          <v-alert v-if="mensajeSaldo" type="success" variant="tonal" class="mb-4">
            {{ mensajeSaldo }}
          </v-alert>
          <v-alert v-if="errorSaldo" type="error" variant="tonal" class="mb-4">
            {{ errorSaldo }}
          </v-alert>
          <v-text-field
            v-model.number="montoSaldo"
            label="Monto *"
            type="number"
            variant="outlined"
            prepend-inner-icon="mdi-cash"
            class="mb-3"
          />
          <v-textarea
            v-model="motivoSaldo"
            label="Motivo *"
            variant="outlined"
            rows="2"
            :placeholder="accionSaldo === 'abonar' ? 'Ej. Bono de bienvenida, Premio de torneo' : 'Ej. Corrección de error, Penalización'"
          />
        </v-card-text>
        <v-card-actions>
          <v-btn variant="text" @click="dialogSaldo = false">Cancelar</v-btn>
          <v-spacer />
          <v-btn
            :color="accionSaldo === 'abonar' ? 'success' : 'error'"
            :loading="loadingSaldo"
            :disabled="!!mensajeSaldo"
            @click="gestionarSaldo"
          >
            {{ accionSaldo === 'abonar' ? 'Abonar' : 'Deducir' }}
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

  </v-container>
</template>
