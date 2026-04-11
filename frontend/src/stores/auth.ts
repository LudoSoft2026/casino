import { ref, computed } from 'vue'
import { defineStore } from 'pinia'

export interface User {
  id: string
  alias: string
  email: string
  nombre: string
  role: 'user' | 'admin'
  balance: number
  isBlocked: boolean
  createdAt: string
}

const seedUsers: User[] = [
  {
    id: '1',
    alias: 'admin',
    email: 'admin@gambling.com',
    nombre: 'Administrador',
    role: 'admin',
    balance: 9999,
    isBlocked: false,
    createdAt: '2026-01-01T00:00:00Z',
  },
  {
    id: '2',
    alias: 'juanito',
    email: 'juan@mail.com',
    nombre: 'Juan García',
    role: 'user',
    balance: 850,
    isBlocked: false,
    createdAt: '2026-02-15T00:00:00Z',
  },
  {
    id: '3',
    alias: 'maria_music',
    email: 'maria@mail.com',
    nombre: 'María López',
    role: 'user',
    balance: 1200,
    isBlocked: false,
    createdAt: '2026-03-01T00:00:00Z',
  },
]

export const useAuthStore = defineStore('auth', () => {
  const user = ref<User | null>(null)
  const allUsers = ref<User[]>([...seedUsers])

  const isLoggedIn = computed(() => user.value !== null)
  const isAdmin = computed(() => user.value?.role === 'admin')
  const balance = computed(() => user.value?.balance ?? 0)

  function login(alias: string, _contrasena: string): boolean {
    // TODO: POST /api/auth/login
    const found = allUsers.value.find(u => u.alias === alias || u.email === alias)
    if (!found) return false
    if (found.isBlocked) throw new Error('Tu cuenta está bloqueada. Contacta al administrador.')
    user.value = { ...found }
    return true
  }

  function register(form: {
    nombre: string
    apPaterno: string
    apMaterno: string
    alias: string
    email: string
    password: string
    telefono: string
    fechaNacimiento: string
  }): void {
    // TODO: POST /api/auth/register
    if (allUsers.value.some(u => u.alias === form.alias)) throw new Error('El alias ya está en uso.')
    if (allUsers.value.some(u => u.email === form.email)) throw new Error('El correo ya está registrado.')
    const newUser: User = {
      id: String(Date.now()),
      alias: form.alias,
      email: form.email,
      nombre: `${form.nombre} ${form.apPaterno}`,
      role: 'user',
      balance: 1000,
      isBlocked: false,
      createdAt: new Date().toISOString(),
    }
    allUsers.value.push(newUser)
    user.value = { ...newUser }
  }

  function logout(): void {
    user.value = null
  }

  function updateBalance(delta: number): void {
    if (!user.value) return
    user.value.balance += delta
    const idx = allUsers.value.findIndex(u => u.id === user.value!.id)
    if (idx !== -1) allUsers.value[idx].balance = user.value.balance
  }

  function blockUser(userId: string): void {
    // TODO: PATCH /api/admin/users/:id/block
    const idx = allUsers.value.findIndex(u => u.id === userId)
    if (idx !== -1) allUsers.value[idx].isBlocked = true
  }

  function unblockUser(userId: string): void {
    // TODO: PATCH /api/admin/users/:id/unblock
    const idx = allUsers.value.findIndex(u => u.id === userId)
    if (idx !== -1) allUsers.value[idx].isBlocked = false
  }

  return { user, allUsers, isLoggedIn, isAdmin, balance, login, register, logout, updateBalance, blockUser, unblockUser }
})
