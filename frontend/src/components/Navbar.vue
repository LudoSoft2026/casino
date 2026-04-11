<template>
  <nav class="navbar">
    <router-link to="/" class="brand">
      <img src="@/assets/logo.svg" alt="Logo Gambling" class="logo-img" />
      <span class="brand-name">Gambling</span>
    </router-link>

    <div class="search-container">
      <input
        type="text"
        v-model="eventsStore.searchQuery"
        placeholder="Buscar apuestas..."
        @focus="isSearchOpen = true"
        @blur="handleBlur"
        @input="navigateToHome"
      />
      <div v-if="isSearchOpen" class="search-dropdown">
        <p class="dropdown-title">CATEGORÍAS</p>
        <div class="tags-grid">
          <button class="tag" @click="filterByCategory('Deportes')">⚽ Deportes</button>
          <button class="tag" @click="filterByCategory('Entretenimiento')">🎬 Entretenimiento</button>
          <button class="tag" @click="filterByCategory('Política')">🏛 Política</button>
          <button class="tag" @click="filterByCategory('Cultura')">🎭 Cultura</button>
          <button class="tag" @click="filterByCategory('Educacion')">📚 Educacion</button>
          <button class="tag tag--clear" @click="clearFilters">✕ Ver todos</button>
        </div>
      </div>
    </div>

    <!-- Logged-in navigation links -->
    <div v-if="auth.isLoggedIn" class="nav-links">
      <router-link to="/" class="nav-link">Catálogo</router-link>
      <router-link to="/mis-apuestas" class="nav-link">Mis Apuestas</router-link>
      <button class="nav-link nav-btn" @click="isCreateEventOpen = true">Crear Evento</button>
      <router-link v-if="auth.isAdmin" to="/admin" class="nav-link nav-link--admin">Admin</router-link>
    </div>

    <!-- Not logged in: auth buttons -->
    <div v-else class="auth-group">
      <button class="btn-login" @click="isLoginOpen = true">Iniciar sesión</button>
      <button class="btn-register" @click="isRegisterOpen = true">Registrarse</button>
    </div>

    <!-- Logged-in user section -->
    <div v-if="auth.isLoggedIn" class="user-section">
      <span class="balance-chip">
        <span class="balance-val">$ {{ auth.balance.toLocaleString() }}</span>
      </span>
      <span class="username-label">@{{ auth.user?.alias }}</span>
      <button class="btn-logout" @click="auth.logout()">Salir</button>
    </div>

    <LoginModal v-if="isLoginOpen" @close="isLoginOpen = false" />
    <RegisterModal v-if="isRegisterOpen" @close="isRegisterOpen = false" />
    <CreateEventModal v-if="isCreateEventOpen" @close="isCreateEventOpen = false" />
  </nav>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useEventsStore } from '@/stores/events'
import LoginModal from './LoginModal.vue'
import RegisterModal from './RegisterModal.vue'
import CreateEventModal from './CreateEventModal.vue'

const router = useRouter()
const auth = useAuthStore()
const eventsStore = useEventsStore()

const isSearchOpen = ref(false)
const isLoginOpen = ref(false)
const isRegisterOpen = ref(false)
const isCreateEventOpen = ref(false)

const handleBlur = () => setTimeout(() => { isSearchOpen.value = false }, 200)

function navigateToHome() {
  if (router.currentRoute.value.path !== '/') router.push('/')
}

function filterByCategory(cat) {
  eventsStore.categoryFilter = cat
  eventsStore.searchQuery = ''
  isSearchOpen.value = false
  navigateToHome()
}

function clearFilters() {
  eventsStore.categoryFilter = ''
  eventsStore.searchQuery = ''
  isSearchOpen.value = false
  navigateToHome()
}
</script>

<style scoped>
/* NAVBAR */
.navbar {
  position: fixed; top: 0; left: 0; width: 100%; height: 60px;
  background-color: #0d1117; display: flex; align-items: center;
  padding: 0 30px; box-sizing: border-box; z-index: 1000;
  border-bottom: 1px solid #30363d; box-shadow: 0 4px 6px rgba(0,0,0,0.3); gap: 20px;
}

.brand {
  display: flex; align-items: center; gap: 10px;
  color: white; font-weight: bold; font-size: 1.2rem; flex-shrink: 0;
  text-decoration: none;
}
.logo-img { height: 36px; }

/* SEARCH */
.search-container { flex-grow: 1; max-width: 360px; position: relative; }
.search-container input {
  width: 100%; padding: 8px 14px; border-radius: 8px;
  border: 1px solid #30363d; background-color: #161b22; color: white;
  transition: border-color 0.3s; outline: none; font-size: 0.88rem;
}
.search-container input:focus { border-color: #58a6ff; }
.search-container input::placeholder { color: #4b5563; }
.search-dropdown {
  position: absolute; top: 110%; left: 0; width: 100%; background-color: #161b22;
  border: 1px solid #30363d; border-radius: 12px; padding: 16px;
  box-shadow: 0 10px 20px rgba(0,0,0,0.5); z-index: 2000;
}
.dropdown-title { color: #8b949e; font-size: 0.72rem; font-weight: bold; margin-bottom: 12px; margin-top: 0; }
.tags-grid { display: flex; flex-wrap: wrap; gap: 8px; }
.tag {
  background: #21262d; border: 1px solid #30363d; color: white;
  padding: 6px 12px; border-radius: 6px; cursor: pointer; font-size: 0.8rem;
  transition: all 0.2s;
}
.tag:hover { border-color: #58a6ff; transform: scale(1.03); }
.tag--clear { color: #8b949e; border-style: dashed; }

/* NAV LINKS (logged in) */
.nav-links { display: flex; align-items: center; gap: 2px; }
.nav-link {
  color: #8b949e; text-decoration: none; font-size: 0.85rem; font-weight: 600;
  padding: 6px 12px; border-radius: 6px; transition: all 0.2s; white-space: nowrap;
}
.nav-link:hover { color: #fff; background: rgba(255,255,255,0.05); }
.nav-link.router-link-exact-active { color: #fff; }
.nav-btn { background: transparent; border: none; cursor: pointer; font-family: inherit; }
.nav-link--admin { color: #f59e0b; }
.nav-link--admin:hover { color: #fbbf24; background: rgba(245,158,11,0.1); }
.nav-link--admin.router-link-exact-active { color: #fbbf24; }

/* AUTH GROUP (not logged in) */
.auth-group { display: flex; gap: 10px; margin-left: auto; }
.btn-login {
  background: transparent; color: #8b949e; padding: 8px 16px;
  border-radius: 6px; border: none; cursor: pointer; font-size: 0.88rem;
  font-weight: 600; transition: all 0.2s;
}
.btn-login:hover { color: #fff; background: rgba(255,255,255,0.05); }
.btn-register {
  background: #007bff; color: white; padding: 8px 16px;
  border-radius: 6px; border: none; cursor: pointer; font-size: 0.88rem;
  font-weight: 600; transition: background 0.2s;
}
.btn-register:hover { background: #58a6ff; }

/* USER SECTION (logged in) */
.user-section { display: flex; align-items: center; gap: 12px; margin-left: auto; flex-shrink: 0; }
.balance-chip {
  display: flex; align-items: center; gap: 6px; background: #21262d;
  border: 1px solid #30363d; border-radius: 20px; padding: 5px 14px;
  font-weight: bold; font-size: 0.85rem;
}
.balance-val   { color: #2ea043; }
.username-label { color: #8b949e; font-size: 0.85rem; white-space: nowrap; }
.btn-logout {
  background: transparent; color: #8b949e; border: none;
  cursor: pointer; font-size: 0.85rem; transition: color 0.2s; padding: 0;
}
.btn-logout:hover { color: #f85149; }
</style>
