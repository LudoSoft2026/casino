<template>
  <div class="modal-overlay" @click.self="$emit('close')">
    <article class="register-modal">

      <!-- ── Encabezado ── -->
      <header class="modal-header">
        <h3>Crear cuenta</h3>
        <p>Completa tus datos para comenzar.</p>
      </header>

      <!-- ── Formulario principal ── -->
      <form @submit.prevent="handleRegister">

        <!-- Sección 1: Datos personales -->
        <section class="form-section">
          <label>Información Personal</label>
          <input v-model="form.nombre"    placeholder="Nombre"          required />
          <input v-model="form.apPaterno" placeholder="Apellido paterno" required />
          <input v-model="form.apMaterno" placeholder="Apellido materno" required />

          <!-- Fecha de nacimiento dividida en 3 selects -->
          <div class="date-group">
            <select v-model="form.dia" required>
              <option value="" disabled selected>Día</option>
              <option v-for="d in 31" :key="d" :value="d">{{ d }}</option>
            </select>
            <select v-model="form.mes" required>
              <option value="" disabled selected>Mes</option>
              <option value="1">Enero</option>
              <option value="2">Febrero</option>
              <option value="3">Marzo</option>
              <option value="4">Abril</option>
              <option value="5">Mayo</option>
              <option value="6">Junio</option>
              <option value="7">Julio</option>
              <option value="8">Agosto</option>
              <option value="9">Septiembre</option>
              <option value="10">Octubre</option>
              <option value="11">Noviembre</option>
              <option value="12">Diciembre</option>
            </select>
            <select v-model="form.anio" required>
              <option value="" disabled selected>Año</option>
              <option v-for="y in years" :key="y" :value="y">{{ y }}</option>
            </select>
          </div>

          <input v-model="form.telefono" type="tel" placeholder="Teléfono *" required />
        </section>

        <!-- Sección 2: Datos de cuenta -->
        <section class="form-section">
          <label>Información de Cuenta</label>
          <input v-model="form.alias"           placeholder="Nombre de usuario"   required />
          <input v-model="form.email"           type="email"    placeholder="Correo electrónico" required />
          <input v-model="form.password"        type="password" placeholder="Contraseña"         required />
          <input v-model="form.confirmPassword" type="password" placeholder="Confirmar contraseña" required />
        </section>

        <!-- Sección 3: INE (opcional por el momento) -->
        <section class="form-section">
          <label>Identificación Oficial — INE </label>

          <input type="file" id="ine-upload" accept="image/*,.pdf" @change="handleIneUpload" hidden />

          <label for="ine-upload" class="ine-dropzone" :class="{ 'ine-uploaded': imagePreviewINE }">
            <!-- Estado vacío -->
            <template v-if="!imagePreviewINE">
              <span class="ine-icon">🪪</span>
              <p>Subir foto de INE frontal</p>
              <small>JPG, PNG o PDF (Máx. 5MB)</small>
            </template>

            <!-- Vista previa tras subir -->
            <template v-else>
              <figure class="ine-preview-wrap">
                <img :src="imagePreviewINE" alt="Vista previa INE" class="ine-preview" />
                <figcaption class="ine-change-hint">Cambiar identificación</figcaption>
              </figure>
            </template>
          </label>
        </section>

        <!-- Mensaje de error -->
        <p v-if="errorMessage" class="error-msg">{{ errorMessage }}</p>

        <button type="submit" class="btn-submit">Finalizar registro</button>
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

// ── Estado ──────────────────────────────────────────────
const errorMessage    = ref('');
const imagePreviewINE = ref(null);

// Años disponibles: desde el año actual -18 hasta 80 años atrás
const years = Array.from({ length: 80 }, (_, i) => new Date().getFullYear() - 18 - i);

const form = reactive({
  nombre:          '',
  apPaterno:       '',
  apMaterno:       '',
  dia:             '',
  mes:             '',
  anio:            '',
  telefono:        '',
  alias:           '',
  email:           '',
  password:        '',
  confirmPassword: '',
  fotoIne:         null, 
});

// ── Handlers ─────────────────────────────────────────────

/** Carga y previsualiza el archivo de INE */
const handleIneUpload = (event) => {
  const file = event.target.files[0];
  if (!file) return;

  if (file.size > 5 * 1024 * 1024) {
    errorMessage.value = "El archivo es muy pesado (Máx. 5MB).";
    return;
  }

  form.fotoIne = file;
  imagePreviewINE.value = file.type.startsWith('image/')
    ? URL.createObjectURL(file)
    : "https://cdn-icons-png.flaticon.com/512/337/337946.png"; // ícono genérico para PDF

  errorMessage.value = "";
};

/** Valida y envía el formulario */
const handleRegister = () => {
  errorMessage.value = ''

  // Campos obligatorios
  if (!form.nombre || !form.apPaterno || !form.apMaterno ||
      !form.dia    || !form.mes       || !form.anio      ||
      !form.telefono || !form.alias   || !form.email     || !form.password) {
    errorMessage.value = 'Por favor, completa todos los campos obligatorios.'
    return
  }

  // Edad mínima 18 años
  if (new Date().getFullYear() - form.anio < 18) {
    errorMessage.value = 'Debes ser mayor de edad.'
    return
  }

  // Contraseñas coinciden
  if (form.password !== form.confirmPassword) {
    errorMessage.value = 'Las contraseñas no coinciden.'
    return
  }

  // Seguridad de contraseña: mínimo 8 caracteres, 1 mayúscula, 1 número
  if (!/^(?=.*[A-Z])(?=.*\d).{8,}$/.test(form.password)) {
    errorMessage.value = 'Contraseña: mínimo 8 caracteres, 1 mayúscula y 1 número.'
    return
  }

  const fechaNacimiento = `${form.anio}-${String(form.mes).padStart(2, '0')}-${String(form.dia).padStart(2, '0')}`

  try {
    auth.register({
      nombre: form.nombre,
      apPaterno: form.apPaterno,
      apMaterno: form.apMaterno,
      alias: form.alias,
      email: form.email,
      password: form.password,
      telefono: form.telefono,
      fechaNacimiento,
    })
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
  background: rgba(0, 0, 0, 0.85);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 9999;
}

.register-modal {
  background: #161b22;
  padding: 35px;
  border-radius: 16px;
  border: 1px solid #007bff;
  color: white;
  width: 100%;
  max-width: 480px;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.5);
}

/* ═══════════════════════════════
   ENCABEZADO
═══════════════════════════════ */
.modal-header {
  margin-bottom: 20px;
  padding-bottom: 15px;
  border-bottom: 1px solid #30363d;
}
.modal-header h3 { margin: 0; font-size: 1.5rem; color: #ffffff; }
.modal-header p  { color: #8b949e; font-size: 0.9rem; margin-top: 5px; }

/* ═══════════════════════════════
   SECCIONES DEL FORMULARIO
═══════════════════════════════ */
.form-section {
  display: flex;
  flex-direction: column;
  gap: 10px;
  margin-bottom: 25px;
}
.form-section > label {
  color: #58a6ff;
  font-size: 0.75rem;
  font-weight: bold;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

/* Tag "Opcional" junto al label */
.optional-tag {
  font-size: 0.65rem;
  background: #30363d;
  color: #8b949e;
  padding: 2px 6px;
  border-radius: 4px;
  margin-left: 6px;
  text-transform: none;
  font-weight: normal;
  letter-spacing: 0;
  vertical-align: middle;
}

/* ═══════════════════════════════
   INPUTS DE TEXTO
═══════════════════════════════ */
input {
  width: 100%;
  padding: 12px;
  border-radius: 8px;
  border: 1px solid #30363d;
  background: #0d1117;
  color: white;
  box-sizing: border-box;
  outline: none;
  transition: border-color 0.2s;
}
input:focus { border-color: #58a6ff; }

/* ═══════════════════════════════
   SELECTOR DE FECHA (Día/Mes/Año)
═══════════════════════════════ */
.date-group {
  display: grid;
  grid-template-columns: 1fr 2fr 1.5fr;
  gap: 8px;
}

select {
  width: 100%;
  padding: 12px;
  border-radius: 8px;
  border: 1px solid #30363d;
  background: #0d1117;
  color: #8b949e;
  box-sizing: border-box;
  outline: none;
  cursor: pointer;
  appearance: none;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 24 24' fill='%238b949e'%3E%3Cpath d='M7 10l5 5 5-5z'/%3E%3C/svg%3E");
  background-repeat: no-repeat;
  background-position: right 10px center;
  transition: border-color 0.2s;
}
select:focus   { border-color: #58a6ff; }
select option  { background: #0d1117; color: white; }

/* ═══════════════════════════════
   ZONA DE CARGA DE INE
═══════════════════════════════ */
.ine-dropzone {
  display: block;
  border: 2px dashed #30363d;
  border-radius: 12px;
  padding: 20px;
  text-align: center;
  cursor: pointer;
  background: #0d1117;
  transition: border-color 0.3s;
}
.ine-dropzone:hover  { border-color: #58a6ff; }
.ine-dropzone.ine-uploaded { border-color: #238636; border-style: solid; }

.ine-icon { font-size: 1.5rem; display: block; }

/* Contenedor de previsualización */
.ine-preview-wrap {
  position: relative;
  width: 100%;
  height: 140px;
  border-radius: 8px;
  overflow: hidden;
  margin: 0;
}
.ine-preview {
  width: 100%;
  height: 100%;
  object-fit: contain;
  background: #000;
}
.ine-change-hint {
  position: absolute;
  inset: 0;
  background: rgba(0, 0, 0, 0.7);
  display: flex;
  justify-content: center;
  align-items: center;
  opacity: 0;
  transition: opacity 0.2s;
  font-size: 0.8rem;
}
.ine-preview-wrap:hover .ine-change-hint { opacity: 1; }

/* ═══════════════════════════════
   BOTONES Y MENSAJES
═══════════════════════════════ */
.btn-submit {
  background: #238636;
  color: white;
  padding: 14px;
  width: 100%;
  border-radius: 8px;
  font-weight: bold;
  cursor: pointer;
  border: none;
  font-size: 1rem;
  margin-top: 10px;
  transition: background 0.2s, transform 0.1s;
}
.btn-submit:hover { background: #2ea043; transform: scale(1.01); }

.btn-close {
  background: transparent;
  color: #8b949e;
  width: 100%;
  margin-top: 15px;
  cursor: pointer;
  border: none;
}

.error-msg {
  color: #f85149;
  font-size: 0.85rem;
  margin-top: 10px;
  text-align: center;
  font-weight: bold;
}
</style>