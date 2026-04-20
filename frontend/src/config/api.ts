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

  return res
}