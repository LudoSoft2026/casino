<template>
  <div class="modal-overlay" @click.self="$emit('close')">
    <article class="login-modal">

      <!-- ── Encabezado ── -->
      <header class="modal-header">
        <h3>Iniciar sesión</h3>
        <p>Bienvenido de vuelta.</p>
      </header>

      <!-- ── Formulario ── -->
      <form @submit.prevent="handleLogin">
        <section class="form-fields">
          <input v-model="form.usuario"    type="text"     placeholder="Usuario"    required />
          <input v-model="form.contrasena" type="password" placeholder="Contraseña" required />
        </section>

        <p v-if="errorMessage" class="error-msg">{{ errorMessage }}</p>

        <button type="submit" class="btn-submit">Entrar</button>
      </form>

      <footer>
        <button class="btn-close" @click="$emit('close')">Cerrar</button>
      </footer>

    </article>
  </div>
</template>

<script setup>
import { reactive, ref } from 'vue'
import { useAuthStore } from '@/stores/auth'

const emit = defineEmits(['close', 'success'])

const auth = useAuthStore()
const errorMessage = ref('')

const form = reactive({
  usuario:    '',
  contrasena: '',
})

const handleLogin = () => {
  errorMessage.value = ''
  if (!form.usuario || !form.contrasena) {
    errorMessage.value = 'Por favor, ingresa tu usuario y contraseña.'
    return
  }
  try {
    const ok = auth.login(form.usuario, form.contrasena)
    if (!ok) {
      errorMessage.value = 'Usuario o contraseña incorrectos.'
      return
    }
    emit('success')
    emit('close')
  } catch (err) {
    errorMessage.value = err.message
  }
}
</script>

<style scoped>

/* ═══════════════════════════════
   OVERLAY Y CONTENEDOR PRINCIPAL
═══════════════════════════════ */
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.8);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 3000;
}

.login-modal {
  background: #161b22;
  padding: 30px;
  border-radius: 12px;
  border: 1px solid #007bff;
  color: white;
  width: 300px;
  display: flex;
  flex-direction: column;
  gap: 15px;
}

/* ═══════════════════════════════
   ENCABEZADO
═══════════════════════════════ */
.modal-header h3 { margin: 0; font-size: 1.4rem; color: #ffffff; }
.modal-header p  { margin: 4px 0 0; color: #8b949e; font-size: 0.9rem; }

/* ═══════════════════════════════
   CAMPOS DEL FORMULARIO
═══════════════════════════════ */
.form-fields {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

input {
  width: 100%;
  padding: 14px;
  border-radius: 8px;
  border: 1px solid #30363d;
  background: #0d1117;
  color: #ffffff;
  font-size: 1rem;
  box-sizing: border-box;
  outline: none;
  transition: border-color 0.2s, box-shadow 0.2s;
}
input:focus {
  border-color: #58a6ff;
  box-shadow: 0 0 8px rgba(88, 166, 255, 0.3);
}

/* ═══════════════════════════════
   BOTONES Y MENSAJES
═══════════════════════════════ */
.btn-submit {
  background: #007bff;
  color: white;
  padding: 14px;
  width: 100%;
  border-radius: 8px;
  font-weight: bold;
  cursor: pointer;
  border: none;
  font-size: 1rem;
  margin-top: 5px;
  transition: background 0.2s, transform 0.1s;
}
.btn-submit:hover { background: #58a6ff; transform: scale(1.02); }

.btn-close {
  background: transparent;
  color: #8b949e;
  width: 100%;
  margin-top: 5px;
  cursor: pointer;
  border: none;
}
.btn-close:hover { color: white; text-decoration: underline; }

.error-msg {
  color: #f85149;
  font-size: 0.85rem;
  text-align: center;
  font-weight: bold;
  margin: 0;
}
</style>