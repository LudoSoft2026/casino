import { ref } from 'vue'
import { defineStore } from 'pinia'
import { useAuthStore } from './auth'

export interface Opcion {
  id:                  string
  descripcion:         string
  probabilidad_pct:    number
  cuota:               number
  orden:               number
  total_participantes: number
}

export interface Apuesta {
  id:                  string
  titulo:              string
  descripcion:         string
  monto_minimo:        number
  monto_maximo:        number | null
  total_participantes: number
  total_apostado:      number
  es_tendencia:        boolean
  fecha_finalizacion:  string
  segundos_restantes:  number
  creador_alias:       string
  en_periodo_bloqueo:  boolean
  opciones:            Opcion[]
}

export const useApuestasStore = defineStore('apuestas', () => {
  const apuestas = ref<Apuesta[]>([])
  const loading  = ref(false)
  const error    = ref('')

  const listar = async () => {
    loading.value = true
    error.value   = ''
    try {
      const res  = await fetch('http://localhost:3000/api/apuestas')
      const data = await res.json()
      apuestas.value = data.apuestas
    } catch {
      error.value = 'Error al cargar apuestas.'
    } finally {
      loading.value = false
    }
  }

  const crear = async (form: {
    titulo:             string
    descripcion:        string
    opciones:           string[]
    probabilidades:     number[]
    monto_minimo:       number
    monto_maximo:       number | null
    fecha_finalizacion: string
  }) => {
    const auth = useAuthStore()
    const res  = await fetch('http://localhost:3000/api/apuestas', {
      method:  'POST',
      headers: {
        'Content-Type':  'application/json',
        'Authorization': `Bearer ${auth.token}`,
      },
      body: JSON.stringify(form),
    })
    return await res.json()
  }

  const participar = async (apuestaId: string, opcionId: string, monto: number) => {
    const auth = useAuthStore()
    const res  = await fetch('http://localhost:3000/api/participaciones', {
      method:  'POST',
      headers: {
        'Content-Type':  'application/json',
        'Authorization': `Bearer ${auth.token}`,
      },
      body: JSON.stringify({
        apuesta_id: apuestaId,
        opcion_id:  opcionId,
        monto,
      }),
    })
    return await res.json()
  }

  return { apuestas, loading, error, listar, crear, participar }
})
