import { ref, computed } from 'vue'
import { defineStore } from 'pinia'

export interface Usuario {
  id:     string
  alias:  string
  correo: string
  rol:    'usuario' | 'administrador'
  estado: string
}

export const useAuthStore = defineStore('auth', () => {
  const token   = ref<string | null>(localStorage.getItem('token'))
  const usuario = ref<Usuario | null>(
    localStorage.getItem('usuario')
      ? JSON.parse(localStorage.getItem('usuario')!)
      : null
  )

  const isLoggedIn = computed(() => token.value !== null)
  const isAdmin    = computed(() => usuario.value?.rol === 'administrador')

  function setToken(newToken: string) {
    token.value = newToken
    localStorage.setItem('token', newToken)
  }

  function setUsuario(u: Usuario) {
    usuario.value = u
    localStorage.setItem('usuario', JSON.stringify(u))
  }

  function logout() {
    token.value   = null
    usuario.value = null
    localStorage.removeItem('token')
    localStorage.removeItem('usuario')
  }

  return { token, usuario, isLoggedIn, isAdmin, setToken, setUsuario, logout }
})