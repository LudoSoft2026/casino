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
  const usuario = ref<Usuario | null>(null)

  const isLoggedIn = computed(() => token.value !== null)
  const isAdmin    = computed(() => usuario.value?.rol === 'administrador')

  function setToken(newToken: string) {
    token.value = newToken
    localStorage.setItem('token', newToken)
  }

  function setUsuario(u: Usuario) {
    usuario.value = u
  }

  function logout() {
    token.value   = null
    usuario.value = null
    localStorage.removeItem('token')
  }

  return { token, usuario, isLoggedIn, isAdmin, setToken, setUsuario, logout }
})