<template>
  <div class="admin-page">
    <div class="page-header">
      <h1>Panel de Administración</h1>
      <p>Gestión, auditoría y validación de la plataforma</p>
    </div>

    <!-- Tabs -->
    <div class="tab-bar">
      <button
        v-for="tab in tabs"
        :key="tab.id"
        class="tab-btn"
        :class="{ 'tab-btn--active': activeTab === tab.id }"
        @click="activeTab = tab.id"
      >
        {{ tab.icon }} {{ tab.label }}
        <span v-if="tab.badge" class="tab-badge">{{ tab.badge }}</span>
      </button>
    </div>

    <!-- Tab: Usuarios -->
    <div v-if="activeTab === 'users'" class="tab-content">
      <div class="table-wrap">
        <table class="data-table">
          <thead>
            <tr>
              <th>Usuario</th>
              <th>Correo</th>
              <th>Saldo</th>
              <th>Rol</th>
              <th>Estado</th>
              <th>Acciones</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="u in auth.allUsers" :key="u.id">
              <td>
                <strong class="td-alias">@{{ u.alias }}</strong>
                <br /><small>{{ u.nombre }}</small>
              </td>
              <td>{{ u.email }}</td>
              <td class="td-balance">$ {{ u.balance.toLocaleString() }}</td>
              <td>
                <span class="role-chip" :class="u.role === 'admin' ? 'role-admin' : 'role-user'">
                  {{ u.role }}
                </span>
              </td>
              <td>
                <span class="status-chip" :class="u.isBlocked ? 'chip-blocked' : 'chip-ok'">
                  {{ u.isBlocked ? 'Bloqueado' : 'Activo' }}
                </span>
              </td>
              <td>
                <button
                  v-if="u.id !== auth.user?.id"
                  class="btn-action"
                  :class="u.isBlocked ? 'btn-unblock' : 'btn-block'"
                  @click="toggleBlock(u.id, u.isBlocked)"
                >
                  {{ u.isBlocked ? 'Desbloquear' : 'Bloquear' }}
                </button>
                <span v-else class="own-account">Tu cuenta</span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Tab: Resultados pendientes -->
    <div v-if="activeTab === 'results'" class="tab-content">
      <div v-if="pendingEvents.length === 0" class="empty-state">
        <span>✅</span>
        <p>No hay resultados pendientes de validar.</p>
      </div>
      <div v-else class="results-list">
        <div v-for="evt in pendingEvents" :key="evt.id" class="result-card">
          <div class="result-top">
            <span class="result-cat">{{ evt.category }}</span>
            <span class="result-creator">por @{{ evt.creatorAlias }}</span>
          </div>
          <h3 class="result-title">{{ evt.title }}</h3>

          <div class="result-options">
            <div
              v-for="opt in evt.options"
              :key="opt.id"
              class="result-option"
              :class="{ 'result-option--submitted': opt.id === evt.submittedResult }"
            >
              <span>{{ opt.label }}</span>
              <div class="result-opt-right">
                <span v-if="opt.id === evt.submittedResult" class="submitted-badge">
                  Propuesto
                </span>
                <span class="opt-pool">$ {{ opt.totalBets.toLocaleString() }}</span>
              </div>
            </div>
          </div>

          <div class="result-actions">
            <button class="btn-approve" @click="eventsStore.validateResult(evt.id, true)">
              ✓ Aprobar resultado
            </button>
            <button class="btn-reject" @click="eventsStore.validateResult(evt.id, false)">
              ✗ Rechazar — pedir nuevo resultado
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Tab: Auditoría -->
    <div v-if="activeTab === 'audit'" class="tab-content">
      <div class="table-wrap">
        <table class="data-table">
          <thead>
            <tr>
              <th>Usuario</th>
              <th>Evento</th>
              <th>Opción</th>
              <th>Monto</th>
              <th>Estado</th>
              <th>Fecha</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="bet in allBets" :key="bet.id">
              <td><strong>@{{ getUserAlias(bet.userId) }}</strong></td>
              <td class="td-event"><small>{{ bet.eventTitle }}</small></td>
              <td>{{ bet.optionLabel }}</td>
              <td class="td-balance">$ {{ bet.amount.toLocaleString() }}</td>
              <td>
                <span class="status-chip" :class="`chip-${bet.status}`">
                  {{ betStatusLabels[bet.status] }}
                </span>
              </td>
              <td><small>{{ formatDate(bet.placedAt) }}</small></td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watchEffect } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useEventsStore } from '@/stores/events'
import { useBetsStore } from '@/stores/bets'

const router = useRouter()
const auth = useAuthStore()
const eventsStore = useEventsStore()
const betsStore = useBetsStore()

watchEffect(() => { if (!auth.isLoggedIn || !auth.isAdmin) router.push('/') })

const activeTab = ref('users')

const pendingEvents = computed(() =>
  eventsStore.events.filter(e => e.status === 'pending_validation'),
)
const allBets = computed(() =>
  [...betsStore.bets].sort((a, b) => b.placedAt.localeCompare(a.placedAt)),
)

const tabs = computed(() => [
  { id: 'users',   label: 'Usuarios',             icon: '👥', badge: null },
  { id: 'results', label: 'Resultados pendientes', icon: '⚖️', badge: pendingEvents.value.length || null },
  { id: 'audit',   label: 'Auditoría',             icon: '📋', badge: null },
])

const betStatusLabels: Record<string, string> = {
  active: 'Activa',
  won: 'Ganada',
  lost: 'Perdida',
  cancelled: 'Cancelada',
  pending_result: 'Pendiente',
}

function getUserAlias(userId: string): string {
  return auth.allUsers.find(u => u.id === userId)?.alias ?? userId
}

function toggleBlock(userId: string, isBlocked: boolean): void {
  if (isBlocked) auth.unblockUser(userId)
  else auth.blockUser(userId)
}

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString('es-MX', { day: 'numeric', month: 'short', year: 'numeric' })
}
</script>

<style scoped>
.admin-page { display: flex; flex-direction: column; gap: 24px; }
.page-header h1 { margin: 0; font-size: 1.8rem; color: #fff; font-weight: bold; }
.page-header p  { margin: 6px 0 0; color: #8b949e; }

/* Tabs */
.tab-bar {
  display: flex; gap: 4px; border-bottom: 1px solid #30363d;
}
.tab-btn {
  padding: 10px 18px; background: transparent; border: none;
  border-bottom: 2px solid transparent; color: #8b949e;
  font-size: 0.88rem; font-weight: bold; cursor: pointer;
  transition: all 0.2s; margin-bottom: -1px;
  display: flex; align-items: center; gap: 6px;
}
.tab-btn:hover { color: #e6edf3; }
.tab-btn--active { color: #58a6ff; border-bottom-color: #58a6ff; }
.tab-badge {
  background: #f59e0b; color: #000; border-radius: 10px;
  padding: 1px 7px; font-size: 0.7rem; font-weight: bold;
}

/* Table */
.tab-content { overflow-x: auto; }
.table-wrap  { overflow-x: auto; }
.data-table  { width: 100%; border-collapse: collapse; min-width: 600px; }
.data-table th {
  text-align: left; padding: 10px 16px; color: #8b949e;
  font-size: 0.72rem; text-transform: uppercase; letter-spacing: 0.5px;
  border-bottom: 1px solid #30363d; white-space: nowrap;
}
.data-table td {
  padding: 12px 16px; border-bottom: 1px solid #21262d;
  color: #e6edf3; font-size: 0.88rem; vertical-align: middle;
}
.data-table tr:hover td { background: rgba(88,166,255,0.03); }
.data-table small { color: #8b949e; font-size: 0.78rem; }

.td-alias   { color: #58a6ff; }
.td-balance { color: #f59e0b; font-weight: bold; }
.td-event   { max-width: 200px; }

/* Chips */
.role-chip {
  font-size: 0.7rem; font-weight: bold; padding: 2px 8px;
  border-radius: 4px; text-transform: uppercase;
}
.role-admin { background: rgba(245,158,11,0.12); color: #fbbf24; border: 1px solid rgba(245,158,11,0.3); }
.role-user  { background: rgba(88,166,255,0.12); color: #58a6ff; border: 1px solid rgba(88,166,255,0.3); }

.status-chip {
  font-size: 0.7rem; font-weight: bold; padding: 2px 8px; border-radius: 4px;
}
.chip-ok      { background: rgba(35,134,54,0.12); color: #2ea043; border: 1px solid rgba(35,134,54,0.3); }
.chip-blocked { background: rgba(248,81,73,0.12); color: #f85149; border: 1px solid rgba(248,81,73,0.3); }

.chip-active         { background: rgba(35,134,54,0.12); color: #2ea043; }
.chip-won            { background: rgba(35,134,54,0.12); color: #2ea043; }
.chip-lost           { background: rgba(248,81,73,0.12); color: #f85149; }
.chip-cancelled      { background: rgba(75,85,99,0.18); color: #9ca3af; }
.chip-pending_result { background: rgba(245,158,11,0.12); color: #f59e0b; }

/* Action buttons */
.btn-action {
  padding: 5px 12px; border-radius: 6px; font-size: 0.78rem;
  font-weight: bold; cursor: pointer; transition: background 0.2s; border: 1px solid;
}
.btn-block   { background: rgba(248,81,73,0.08); color: #f85149; border-color: rgba(248,81,73,0.3); }
.btn-block:hover { background: rgba(248,81,73,0.18); }
.btn-unblock { background: rgba(35,134,54,0.08); color: #2ea043; border-color: rgba(35,134,54,0.3); }
.btn-unblock:hover { background: rgba(35,134,54,0.18); }
.own-account { font-size: 0.75rem; color: #8b949e; }

/* Results */
.results-list { display: flex; flex-direction: column; gap: 16px; }
.result-card {
  background: #161b22; border: 1px solid #30363d; border-radius: 10px;
  padding: 20px; display: flex; flex-direction: column; gap: 12px;
}
.result-top     { display: flex; justify-content: space-between; }
.result-cat     { font-size: 0.72rem; font-weight: bold; color: #58a6ff; text-transform: uppercase; }
.result-creator { font-size: 0.78rem; color: #8b949e; }
.result-title   { margin: 0; font-size: 1rem; color: #fff; font-weight: bold; }

.result-options { display: flex; flex-direction: column; gap: 8px; }
.result-option {
  display: flex; justify-content: space-between; align-items: center;
  padding: 10px 14px; border-radius: 8px; background: #0d1117;
  border: 1px solid #30363d; font-size: 0.88rem; color: #e6edf3;
}
.result-option--submitted { border-color: #f59e0b; background: rgba(245,158,11,0.05); }
.result-opt-right { display: flex; align-items: center; gap: 10px; }
.submitted-badge {
  font-size: 0.68rem; color: #f59e0b; font-weight: bold;
  background: rgba(245,158,11,0.12); padding: 2px 8px; border-radius: 4px;
}
.opt-pool { font-size: 0.78rem; color: #8b949e; }

.result-actions { display: flex; gap: 10px; flex-wrap: wrap; }
.btn-approve {
  background: rgba(35,134,54,0.08); color: #2ea043; border: 1px solid rgba(35,134,54,0.3);
  padding: 9px 16px; border-radius: 6px; font-weight: bold; font-size: 0.85rem;
  cursor: pointer; transition: background 0.2s;
}
.btn-approve:hover { background: rgba(35,134,54,0.18); }
.btn-reject {
  background: rgba(248,81,73,0.08); color: #f85149; border: 1px solid rgba(248,81,73,0.3);
  padding: 9px 16px; border-radius: 6px; font-weight: bold; font-size: 0.85rem;
  cursor: pointer; transition: background 0.2s;
}
.btn-reject:hover { background: rgba(248,81,73,0.18); }

/* Empty */
.empty-state {
  text-align: center; padding: 60px 20px; color: #8b949e;
  display: flex; flex-direction: column; align-items: center; gap: 16px; font-size: 1rem;
}
</style>
