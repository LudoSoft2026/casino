import { useAuthStore } from '@/stores/auth'
import router from '@/router'

export const apiFetch = async (url: string, options: RequestInit = {}) => {
  const auth = useAuthStore()

  const res = await fetch(`http://localhost:3000${url}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(auth.token ? { Authorization: `Bearer ${auth.token}` } : {}),
      ...options.headers,
    },
  })

  if (res.status === 401) {
    auth.logout()
    router.push('/login')
  }

  if (res.status === 403) {
    const data = await res.clone().json()
    auth.logout()
    router.push(`/login?mensaje=${encodeURIComponent(data.message || 'Tu cuenta ha sido suspendida o bloqueada.')}`)
  }

  return res
}
