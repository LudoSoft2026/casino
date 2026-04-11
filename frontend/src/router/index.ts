import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'home',
      component: () => import('../views/CasinoView.vue'),
    },
    {
      path: '/casino',
      name: 'casino',
      component: () => import('../views/CasinoView.vue'),
    },
    {
      path: '/mis-apuestas',
      name: 'bet-history',
      component: () => import('../views/BetHistoryView.vue'),
    },
    {
      path: '/crear-evento',
      name: 'create-event',
      component: () => import('../views/CreateEventView.vue'),
    },
    {
      path: '/admin',
      name: 'admin',
      component: () => import('../views/AdminView.vue'),
    },
  ],
})

export default router
