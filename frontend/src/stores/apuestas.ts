import { ref } from 'vue'
import { defineStore } from 'pinia'
import { apiFetch } from '@/config/api'

export interface Opcion {
  id: string
  descripcion: string
  probabilidad_pct: number
  cuota: number
  orden: number
  total_participantes: number
}

export interface Apuesta {
  id: string
  titulo: string
  descripcion: string
  monto_minimo: number
  monto_maximo: number | null
  total_participantes: number
  total_apostado: number
  es_tendencia: boolean
  fecha_finalizacion: string
  segundos_restantes: number
  creador_alias: string
  en_periodo_bloqueo: boolean
  opciones: Opcion[]
}

export const useApuestasStore = defineStore('apuestas', () => {
  const apuestas = ref<Apuesta[]>([])
  const loading = ref(false)
  const error = ref('')

  const listar = async () => {
    loading.value = true
    error.value = ''
    try {
      const res = await apiFetch('/api/apuestas')
      const data = await res.json()
      apuestas.value = data.apuestas
    } catch {
      error.value = 'Error al cargar apuestas.'
    } finally {
      loading.value = false
    }
  }

  const misApuestas = ref<{ id: string; titulo: string; estado: string }[]>([])

  const cargarMisApuestas = async () => {
    const res = await apiFetch('/api/apuestas/mis-apuestas')
    const data = await res.json()
    misApuestas.value = data.apuestas ?? []
  }

  const crear = async (form: {
    titulo: string
    descripcion: string
    opciones: string[]
    probabilidades: number[]
    monto_minimo: number
    monto_maximo: number | null
    fecha_finalizacion: string
  }) => {
    const body = {
      titulo: form.titulo,
      descripcion: form.descripcion,
      opciones: form.opciones,
      probabilidades: form.probabilidades,
      monto_minimo: form.monto_minimo,
      fecha_finalizacion: form.fecha_finalizacion,
      ...(form.monto_maximo ? { monto_maximo: form.monto_maximo } : {}),
    }

    const res = await apiFetch('/api/apuestas', {
      method: 'POST',
      body: JSON.stringify(body),
    })
    return await res.json()
  }

  const participar = async (apuestaId: string, opcionId: string, monto: number) => {
    const res = await apiFetch('/api/participaciones', {
      method: 'POST',
      body: JSON.stringify({
        apuesta_id: apuestaId,
        opcion_id: opcionId,
        monto,
      }),
    })
    return await res.json()
  }

  return { apuestas, loading, error, listar, crear, participar, misApuestas, cargarMisApuestas }
})
