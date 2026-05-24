import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      redirect: '/apuestas',
    },
    {
      path: '/login',
      name: 'login',
      component: () => import('@/views/LoginView.vue'),
      meta: { requiresGuest: true },
    },
    {
      path: '/registro',
      name: 'registro',
      component: () => import('@/views/RegistroView.vue'),
      meta: { requiresGuest: true },
    },
    {
      path: '/apuestas',
      name: 'apuestas',
      component: () => import('@/views/ApuestasView.vue'),
      meta: { requiresAuth: true },
    },
    {
      path: '/historial',
      name: 'historial',
      component: () => import('@/views/HistorialView.vue'),
      meta: { requiresAuth: true },
    },
    {
      path: '/apuestas/crear',
      name: 'crear-apuesta',
      component: () => import('@/views/CrearApuestaView.vue'),
      meta: { requiresAuth: true },
    },
    {
    path: '/wallet',
    name: 'wallet',
    component: () => import('@/views/WalletView.vue'),
    meta: { requiresAuth: true },
    },
    {
      path: '/admin',
      name: 'admin',
      component: () => import('@/views/AdminView.vue'),
      meta: { requiresAuth: true, requiresAdmin: true },
    },
    {
      path: '/perfil',
      name: 'perfil',
      component: () => import('@/views/PerfilView.vue'),
      meta: { requiresAuth: true },
    },
  ],
})

// Guard de navegación
router.beforeEach((to, _from) => {
  const auth = useAuthStore()

  if (to.meta.requiresAuth && !auth.isLoggedIn) {
    return '/login'
  } else if (to.meta.requiresGuest && auth.isLoggedIn) {
    return '/apuestas'
  } else if (to.meta.requiresAdmin && !auth.isAdmin) {
    return '/apuestas'
  }
})

export default router
