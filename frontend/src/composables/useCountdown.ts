import { ref, computed, onMounted, onUnmounted } from 'vue'

export type CountdownColor = 'green' | 'amber' | 'red'

export function useCountdown(endDateISO: string) {
  const now = ref(Date.now())
  let timer: ReturnType<typeof setInterval>

  onMounted(() => {
    timer = setInterval(() => { now.value = Date.now() }, 1000)
  })
  onUnmounted(() => clearInterval(timer))

  const remaining = computed(() => {
    const end = new Date(endDateISO).getTime()
    return Math.max(0, end - now.value)
  })

  // Apuestas bloqueadas 30 segundos antes del cierre
  const isBlocked = computed(() => remaining.value <= 30_000)
  const isPast    = computed(() => remaining.value === 0)

  const display = computed((): string => {
    if (isPast.value) return 'Cerrado'
    const ms = remaining.value
    const totalSeconds = Math.floor(ms / 1000)
    const s = totalSeconds % 60
    const totalMinutes = Math.floor(totalSeconds / 60)
    const m = totalMinutes % 60
    const totalHours = Math.floor(totalMinutes / 60)
    const h = totalHours % 24
    const d = Math.floor(totalHours / 24)

    if (d > 0)  return `${d}d ${h}h`
    if (h > 0)  return `${h}h ${m}m`
    if (m > 0)  return `${m}m ${s}s`
    return `${s}s`
  })

  // Verde > 5 min · Ámbar 1–5 min · Rojo < 1 min o bloqueado
  const color = computed((): CountdownColor => {
    if (isPast.value || remaining.value <= 60_000)  return 'red'
    if (remaining.value <= 300_000)                 return 'amber'
    return 'green'
  })

  return { display, color, isBlocked, isPast, remaining }
}
