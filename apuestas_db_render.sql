--
-- PostgreSQL database dump
--

\restrict CvbJx3gUXDa0qRxqqBI32GNBPcWJ2kDmFs5fmEEn5apmsfLdeBvtCELi3Hzs0jN

-- Dumped from database version 16.13
-- Dumped by pg_dump version 16.13

-- Started on 2026-06-01 12:53:08

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 2 (class 3079 OID 17351)
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- TOC entry 5264 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- TOC entry 3 (class 3079 OID 17388)
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- TOC entry 5265 (class 0 OID 0)
-- Dependencies: 3
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- TOC entry 945 (class 1247 OID 17436)
-- Name: estado_apuesta; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.estado_apuesta AS ENUM (
    'activa',
    'cerrada',
    'en_revision',
    'finalizada',
    'cancelada'
);


--
-- TOC entry 939 (class 1247 OID 17418)
-- Name: estado_documento; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.estado_documento AS ENUM (
    'pendiente',
    'aprobado',
    'rechazado'
);


--
-- TOC entry 948 (class 1247 OID 17448)
-- Name: estado_participacion; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.estado_participacion AS ENUM (
    'activa',
    'ganadora',
    'perdedora',
    'cancelada',
    'devuelta'
);


--
-- TOC entry 951 (class 1247 OID 17458)
-- Name: estado_resultado; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.estado_resultado AS ENUM (
    'propuesto',
    'confirmado',
    'rechazado'
);


--
-- TOC entry 957 (class 1247 OID 17484)
-- Name: estado_retiro; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.estado_retiro AS ENUM (
    'pendiente',
    'procesado',
    'rechazado'
);


--
-- TOC entry 933 (class 1247 OID 17400)
-- Name: estado_usuario; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.estado_usuario AS ENUM (
    'no_verificado',
    'pendiente',
    'verificada',
    'suspendida',
    'bloqueada'
);


--
-- TOC entry 936 (class 1247 OID 17412)
-- Name: rol_usuario; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.rol_usuario AS ENUM (
    'usuario',
    'administrador'
);


--
-- TOC entry 942 (class 1247 OID 17426)
-- Name: tipo_documento; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.tipo_documento AS ENUM (
    'INE',
    'pasaporte',
    'cedula',
    'otro'
);


--
-- TOC entry 960 (class 1247 OID 17492)
-- Name: tipo_fraude; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.tipo_fraude AS ENUM (
    'documento_duplicado',
    'multiples_intentos_login',
    'multicuenta_sospechosa',
    'patron_irregular'
);


--
-- TOC entry 954 (class 1247 OID 17466)
-- Name: tipo_transaccion; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.tipo_transaccion AS ENUM (
    'bienvenida',
    'recarga',
    'apuesta_deduccion',
    'ganancia',
    'retiro',
    'comision',
    'devolucion',
    'ajuste_admin'
);


--
-- TOC entry 284 (class 1255 OID 17792)
-- Name: cfg_num(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cfg_num(p_clave character varying) RETURNS numeric
    LANGUAGE sql STABLE
    AS $$
    SELECT valor::NUMERIC FROM configuracion_sistema WHERE clave = p_clave;
$$;


--
-- TOC entry 285 (class 1255 OID 17793)
-- Name: cfg_txt(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cfg_txt(p_clave character varying) RETURNS text
    LANGUAGE sql STABLE
    AS $$
    SELECT valor FROM configuracion_sistema WHERE clave = p_clave;
$$;


--
-- TOC entry 287 (class 1255 OID 17795)
-- Name: fn_calcular_cuota(numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_calcular_cuota(p_probabilidad_pct numeric) RETURNS numeric
    LANGUAGE plpgsql STABLE
    AS $$
DECLARE
    v_margen DECIMAL;
BEGIN
    IF p_probabilidad_pct <= 0 OR p_probabilidad_pct >= 100 THEN
        RAISE EXCEPTION 'Probabilidad debe estar entre 0 y 100 (exclusivo)';
    END IF;
    v_margen := cfg_num('margen_casa');
    RETURN ROUND((1.0 / (p_probabilidad_pct / 100.0)) * v_margen, 4);
END;
$$;


--
-- TOC entry 5266 (class 0 OID 0)
-- Dependencies: 287
-- Name: FUNCTION fn_calcular_cuota(p_probabilidad_pct numeric); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.fn_calcular_cuota(p_probabilidad_pct numeric) IS 'cuota = (1 / prob%) × margen_casa. Ej: 20% → 4.5000 | 80% → 1.1250';


--
-- TOC entry 289 (class 1255 OID 17797)
-- Name: fn_crear_saldo_bienvenida(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_crear_saldo_bienvenida() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_bienvenida DECIMAL(15,2);
BEGIN
    v_bienvenida := cfg_num('saldo_bienvenida');

    INSERT INTO saldos (usuario_id, saldo_disponible)
    VALUES (NEW.id, v_bienvenida);

    INSERT INTO transacciones (
        usuario_id, tipo, monto, saldo_anterior, saldo_posterior, descripcion
    ) VALUES (
        NEW.id, 'bienvenida', v_bienvenida, 0.00, v_bienvenida,
        'Saldo de bienvenida asignado al registrarse'
    );

    RETURN NEW;
END;
$$;


--
-- TOC entry 291 (class 1255 OID 17802)
-- Name: fn_finalizar_apuesta_al_confirmar(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_finalizar_apuesta_al_confirmar() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.estado = 'confirmado' AND OLD.estado = 'propuesto' THEN
        UPDATE apuestas
        SET estado = 'finalizada'
        WHERE id = NEW.apuesta_id;
        NEW.fecha_confirmacion = NOW();
    END IF;
    RETURN NEW;
END;
$$;


--
-- TOC entry 288 (class 1255 OID 17796)
-- Name: fn_preview_apuesta(numeric, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_preview_apuesta(p_monto numeric, p_opcion_id uuid) RETURNS TABLE(opcion_descripcion character varying, probabilidad_pct numeric, cuota numeric, monto_apostado numeric, ganancia_si_gana numeric, ganancia_neta numeric)
    LANGUAGE plpgsql STABLE
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        o.descripcion,
        o.probabilidad_pct,
        o.cuota,
        p_monto,
        ROUND(p_monto * o.cuota, 2),
        ROUND(p_monto * o.cuota - p_monto, 2)
    FROM opciones_apuesta o
    WHERE o.id = p_opcion_id;
END;
$$;


--
-- TOC entry 5267 (class 0 OID 0)
-- Dependencies: 288
-- Name: FUNCTION fn_preview_apuesta(p_monto numeric, p_opcion_id uuid); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.fn_preview_apuesta(p_monto numeric, p_opcion_id uuid) IS 'Usar en GET /apuestas/:id/preview antes de que el usuario confirme.';


--
-- TOC entry 292 (class 1255 OID 17804)
-- Name: fn_recalcular_tendencia(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_recalcular_tendencia() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_top_n INTEGER;
BEGIN
    v_top_n := cfg_num('tendencia_top_n')::INTEGER;

    UPDATE apuestas SET es_tendencia = FALSE
    WHERE estado = 'activa';

    UPDATE apuestas SET es_tendencia = TRUE
    WHERE id IN (
        SELECT id FROM apuestas
        WHERE estado = 'activa'
        ORDER BY total_participantes DESC, total_apostado DESC
        LIMIT v_top_n
    );

    RETURN NULL;
END;
$$;


--
-- TOC entry 290 (class 1255 OID 17799)
-- Name: fn_set_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.fecha_actualizacion = NOW();
    RETURN NEW;
END;
$$;


--
-- TOC entry 286 (class 1255 OID 17794)
-- Name: normalizar_texto(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.normalizar_texto(p_texto text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
    SELECT UPPER(TRIM(REGEXP_REPLACE(p_texto, '\s+', '', 'g')));
$$;


--
-- TOC entry 317 (class 1255 OID 25569)
-- Name: sp_abonar_saldo_admin(uuid, uuid, numeric, text); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_abonar_saldo_admin(IN p_admin_id uuid, IN p_usuario_id uuid, IN p_monto numeric, IN p_motivo text, OUT p_mensaje text)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_rol_admin  rol_usuario;
    v_estado     estado_usuario;
    v_saldo_ant  DECIMAL(15,2);
    v_saldo_new  DECIMAL(15,2);
    v_alias      VARCHAR;
BEGIN
    SELECT rol INTO v_rol_admin FROM usuarios WHERE id = p_admin_id;
    IF v_rol_admin != 'administrador' THEN
        p_mensaje := 'No tiene los permisos suficientes para realizar esta acción.';
        RETURN;
    END IF;

    SELECT estado, alias INTO v_estado, v_alias FROM usuarios WHERE id = p_usuario_id;
    IF NOT FOUND THEN
        p_mensaje := 'No se puede abonar saldo. El usuario no existe o se encuentra bloqueado.';
        RETURN;
    END IF;

    IF v_estado IN ('bloqueada', 'suspendida') THEN
        p_mensaje := 'No se puede abonar saldo. El usuario no existe o se encuentra bloqueado.';
        RETURN;
    END IF;

    IF p_monto <= 0 THEN
        p_mensaje := 'El monto a ingresar debe ser mayor a cero.';
        RETURN;
    END IF;

    SELECT saldo_disponible INTO v_saldo_ant
    FROM saldos WHERE usuario_id = p_usuario_id FOR UPDATE;

    UPDATE saldos
    SET saldo_disponible    = saldo_disponible + p_monto,
        fecha_actualizacion = NOW()
    WHERE usuario_id = p_usuario_id;

    v_saldo_new := v_saldo_ant + p_monto;

    INSERT INTO transacciones (
        usuario_id, tipo, monto, saldo_anterior, saldo_posterior, descripcion
    ) VALUES (
        p_usuario_id, 'recarga', p_monto, v_saldo_ant, v_saldo_new, p_motivo
    );

    INSERT INTO logs_admin (admin_id, usuario_id, accion, motivo)
    VALUES (p_admin_id, p_usuario_id, 'abonar_saldo', p_motivo);

    p_mensaje := 'Saldo abonado correctamente. El nuevo balance del usuario es de ' || v_saldo_new || ' monedas.';
END;
$$;


--
-- TOC entry 312 (class 1255 OID 17816)
-- Name: sp_ajuste_saldo_admin(uuid, uuid, numeric, text); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_ajuste_saldo_admin(IN p_admin_id uuid, IN p_usuario_id uuid, IN p_monto numeric, OUT p_mensaje text, IN p_descripcion text DEFAULT NULL::text)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_rol       rol_usuario;
    v_saldo_ant DECIMAL(15,2);
BEGIN
    SELECT rol INTO v_rol FROM usuarios WHERE id = p_admin_id;
    IF v_rol != 'administrador' THEN
        p_mensaje := 'Sin permisos para realizar ajustes de saldo.';
        RETURN;
    END IF;

    SELECT saldo_disponible INTO v_saldo_ant
    FROM saldos WHERE usuario_id = p_usuario_id FOR UPDATE;

    IF NOT FOUND THEN
        p_mensaje := 'Usuario no encontrado.';
        RETURN;
    END IF;

    IF v_saldo_ant + p_monto < 0 THEN
        p_mensaje := 'El ajuste dejaría el saldo en negativo.';
        RETURN;
    END IF;

    UPDATE saldos
    SET saldo_disponible    = saldo_disponible + p_monto,
        fecha_actualizacion = NOW()
    WHERE usuario_id = p_usuario_id;

    INSERT INTO transacciones (
        usuario_id, tipo, monto, saldo_anterior, saldo_posterior, descripcion
    ) VALUES (
        p_usuario_id, 'ajuste_admin', p_monto,
        v_saldo_ant, v_saldo_ant + p_monto,
        COALESCE(p_descripcion, 'Ajuste manual por administrador')
    );

    p_mensaje := 'Ajuste de saldo realizado correctamente.';
END;
$$;


--
-- TOC entry 314 (class 1255 OID 25562)
-- Name: sp_cambiar_estado_usuario(uuid, uuid, character varying, text); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_cambiar_estado_usuario(IN p_admin_id uuid, IN p_usuario_id uuid, IN p_accion character varying, IN p_motivo text, OUT p_mensaje text)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_rol_admin    rol_usuario;
    v_rol_usuario  rol_usuario;
    v_nuevo_estado estado_usuario;
    v_doc_estado   VARCHAR;
    v_alias        VARCHAR;
BEGIN
    SELECT rol INTO v_rol_admin FROM usuarios WHERE id = p_admin_id;
    IF v_rol_admin != 'administrador' THEN
        p_mensaje := 'No tiene los permisos suficientes para realizar cambios en el estado de las cuentas.';
        RETURN;
    END IF;

    IF p_admin_id = p_usuario_id THEN
        p_mensaje := 'No puedes modificar el estado de tu propia cuenta.';
        RETURN;
    END IF;

    SELECT rol, alias INTO v_rol_usuario, v_alias FROM usuarios WHERE id = p_usuario_id;
    IF v_rol_usuario = 'administrador' THEN
        p_mensaje := 'No puedes modificar el estado de otro administrador.';
        RETURN;
    END IF;

    IF p_accion = 'activar' THEN
        SELECT estado INTO v_doc_estado 
        FROM documentos_identidad 
        WHERE usuario_id = p_usuario_id AND estado = 'aprobado'
        LIMIT 1;

        IF v_doc_estado = 'aprobado' THEN
            v_nuevo_estado := 'verificada';
        ELSE
            v_nuevo_estado := 'no_verificado';
        END IF;

        UPDATE usuarios 
        SET estado = v_nuevo_estado, token_invalidado_en = NULL 
        WHERE id = p_usuario_id;

        p_mensaje := 'El usuario ' || v_alias || ' ha sido activado correctamente.';

    ELSIF p_accion = 'suspender' THEN
        v_nuevo_estado := 'suspendida';

        UPDATE usuarios 
        SET estado = v_nuevo_estado, token_invalidado_en = NOW()
        WHERE id = p_usuario_id;

        p_mensaje := 'El usuario ' || v_alias || ' ha sido suspendido correctamente.';

    ELSIF p_accion = 'bloquear' THEN
        v_nuevo_estado := 'bloqueada';

        UPDATE usuarios 
        SET estado = v_nuevo_estado, token_invalidado_en = NOW()
        WHERE id = p_usuario_id;

        p_mensaje := 'El usuario ' || v_alias || ' ha sido bloqueado correctamente.';

    ELSE
        p_mensaje := 'Acción no válida.';
        RETURN;
    END IF;

    INSERT INTO logs_admin (admin_id, usuario_id, accion, motivo)
    VALUES (p_admin_id, p_usuario_id, p_accion, p_motivo);

END;
$$;


--
-- TOC entry 315 (class 1255 OID 25563)
-- Name: sp_cancelar_apuesta(uuid, uuid); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_cancelar_apuesta(IN p_usuario_id uuid, IN p_apuesta_id uuid, OUT p_mensaje text)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_apuesta    apuestas%ROWTYPE;
    v_participacion RECORD;
    v_saldo_ant  DECIMAL(15,2);
BEGIN
    SELECT * INTO v_apuesta FROM apuestas WHERE id = p_apuesta_id;

    IF NOT FOUND THEN
        p_mensaje := 'Apuesta no encontrada.';
        RETURN;
    END IF;

    -- Verificar que sea el creador
    IF v_apuesta.creador_id != p_usuario_id THEN
        p_mensaje := 'Solo el creador puede cancelar esta apuesta.';
        RETURN;
    END IF;

    -- Verificar que esté activa
    IF v_apuesta.estado != 'activa' THEN
        p_mensaje := 'No se puede modificar la apuesta porque el evento ya ha comenzado o cerrado.';
        RETURN;
    END IF;

    -- Reembolsar a cada participante
    FOR v_participacion IN
        SELECT p.*, u.id AS uid
        FROM participaciones p
        JOIN usuarios u ON u.id = p.usuario_id
        WHERE p.apuesta_id = p_apuesta_id
          AND p.estado = 'activa'
    LOOP
        SELECT saldo_disponible INTO v_saldo_ant
        FROM saldos WHERE usuario_id = v_participacion.uid FOR UPDATE;

        UPDATE saldos
        SET saldo_disponible    = saldo_disponible + v_participacion.monto,
            fecha_actualizacion = NOW()
        WHERE usuario_id = v_participacion.uid;

        INSERT INTO transacciones (
            usuario_id, tipo, monto, saldo_anterior, saldo_posterior,
            referencia_id, descripcion
        ) VALUES (
            v_participacion.uid, 'devolucion',
            v_participacion.monto,
            v_saldo_ant,
            v_saldo_ant + v_participacion.monto,
            v_participacion.id,
            'Reembolso por cancelación de apuesta: "' || v_apuesta.titulo || '"'
        );

        UPDATE participaciones SET estado = 'devuelta' WHERE id = v_participacion.id;
    END LOOP;

    -- Cancelar apuesta
    UPDATE apuestas SET estado = 'cancelada' WHERE id = p_apuesta_id;

    p_mensaje := 'Apuesta cancelada. Se ha reembolsado el saldo a los participantes.';
END;
$$;


--
-- TOC entry 311 (class 1255 OID 17815)
-- Name: sp_cerrar_apuestas_expiradas(); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_cerrar_apuestas_expiradas(OUT p_total_cerradas integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE apuestas
    SET estado = 'cerrada'
    WHERE estado = 'activa'
      AND fecha_finalizacion <= NOW();

    GET DIAGNOSTICS p_total_cerradas = ROW_COUNT;
END;
$$;


--
-- TOC entry 309 (class 1255 OID 17811)
-- Name: sp_confirmar_resultado(uuid, uuid, boolean, text); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_confirmar_resultado(IN p_admin_id uuid, IN p_resultado_id uuid, IN p_aprobar boolean, OUT p_mensaje text, IN p_motivo_rechazo text DEFAULT NULL::text)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_resultado     resultados_apuesta%ROWTYPE;
    v_apuesta       apuestas%ROWTYPE;
    v_rol           rol_usuario;
    v_participacion RECORD;
    v_saldo_ant     DECIMAL(15,2);
BEGIN
    SELECT rol INTO v_rol FROM usuarios WHERE id = p_admin_id;
    IF v_rol != 'administrador' THEN
        p_mensaje := 'Solo administradores pueden confirmar resultados.';
        RETURN;
    END IF;

    SELECT * INTO v_resultado FROM resultados_apuesta WHERE id = p_resultado_id;
    IF NOT FOUND OR v_resultado.estado != 'propuesto' THEN
        p_mensaje := 'Resultado no encontrado o ya procesado.';
        RETURN;
    END IF;

    SELECT * INTO v_apuesta FROM apuestas WHERE id = v_resultado.apuesta_id;

    -- RECHAZAR → vuelve a "cerrada" para que el creador re-proponga
    IF NOT p_aprobar THEN
        UPDATE resultados_apuesta
        SET estado             = 'rechazado',
            confirmado_por     = p_admin_id,
            motivo_rechazo     = p_motivo_rechazo,
            fecha_confirmacion = NOW()
        WHERE id = p_resultado_id;

        UPDATE apuestas SET estado = 'cerrada' WHERE id = v_apuesta.id;
        p_mensaje := 'Resultado rechazado. El creador puede proponer uno nuevo.';
        RETURN;
    END IF;

    -- CONFIRMAR → trigger trg_finalizar_en_confirmacion cambia apuesta a "finalizada"
    UPDATE resultados_apuesta
    SET estado             = 'confirmado',
        confirmado_por     = p_admin_id,
        fecha_confirmacion = NOW()
    WHERE id = p_resultado_id;

    -- Acreditar ganancia_proyectada a cada ganador (lo que se prometió al apostar)
    FOR v_participacion IN
        SELECT p.*, o.cuota
        FROM participaciones p
        JOIN opciones_apuesta o ON o.id = p.opcion_id
        WHERE p.apuesta_id = v_apuesta.id
          AND p.opcion_id  = v_resultado.opcion_ganadora_id
          AND p.estado     = 'activa'
    LOOP
        UPDATE participaciones
        SET estado   = 'ganadora',
            ganancia = ganancia_proyectada
        WHERE id = v_participacion.id;

        SELECT saldo_disponible INTO v_saldo_ant
        FROM saldos WHERE usuario_id = v_participacion.usuario_id FOR UPDATE;

        UPDATE saldos
        SET saldo_disponible    = saldo_disponible + v_participacion.ganancia_proyectada,
            fecha_actualizacion = NOW()
        WHERE usuario_id = v_participacion.usuario_id;

        INSERT INTO transacciones (
            usuario_id, tipo, monto, saldo_anterior, saldo_posterior,
            referencia_id, descripcion
        ) VALUES (
            v_participacion.usuario_id, 'ganancia',
            v_participacion.ganancia_proyectada,
            v_saldo_ant,
            v_saldo_ant + v_participacion.ganancia_proyectada,
            v_participacion.id,
            'Ganancia en: "' || v_apuesta.titulo ||
            '" · cuota ×' || v_participacion.cuota
        );
    END LOOP;

    -- Marcar perdedores
    UPDATE participaciones
    SET estado = 'perdedora'
    WHERE apuesta_id = v_apuesta.id
      AND opcion_id != v_resultado.opcion_ganadora_id
      AND estado     = 'activa';

    p_mensaje := 'Resultado confirmado y ganancias acreditadas correctamente.';
EXCEPTION
    WHEN OTHERS THEN
        p_mensaje := 'Error al confirmar resultado: ' || SQLERRM;
        RAISE;
END;
$$;


--
-- TOC entry 306 (class 1255 OID 17808)
-- Name: sp_crear_apuesta(uuid, character varying, text, text[], numeric[], numeric, timestamp without time zone, numeric); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_crear_apuesta(IN p_creador_id uuid, IN p_titulo character varying, IN p_descripcion text, IN p_opciones text[], IN p_probabilidades numeric[], IN p_monto_minimo numeric, IN p_fecha_finalizacion timestamp without time zone, OUT p_apuesta_id uuid, OUT p_mensaje text, IN p_monto_maximo numeric DEFAULT NULL::numeric)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_estado     estado_usuario;
    v_suma_probs DECIMAL;
    v_i          INTEGER;
    v_cuota      DECIMAL(8,4);
BEGIN
    SELECT estado INTO v_estado FROM usuarios WHERE id = p_creador_id;
    IF v_estado != 'verificada' THEN
        p_mensaje := 'Tu cuenta debe estar verificada para crear apuestas.';
        RETURN;
    END IF;

    IF array_length(p_opciones, 1) < 2 THEN
        p_mensaje := 'Completa todos los campos requeridos.';
        RETURN;
    END IF;

    IF array_length(p_opciones, 1) != array_length(p_probabilidades, 1) THEN
        p_mensaje := 'Cada opción debe tener una probabilidad asignada.';
        RETURN;
    END IF;

    -- Validar que las probabilidades sumen 100
    v_suma_probs := 0;
    FOR v_i IN 1..array_length(p_probabilidades, 1) LOOP
        IF p_probabilidades[v_i] <= 0 OR p_probabilidades[v_i] >= 100 THEN
            p_mensaje := 'Cada probabilidad debe ser mayor a 0 y menor a 100.';
            RETURN;
        END IF;
        v_suma_probs := v_suma_probs + p_probabilidades[v_i];
    END LOOP;

    IF ABS(v_suma_probs - 100.0) > 0.01 THEN
        p_mensaje := 'Las probabilidades de todas las opciones deben sumar exactamente 100%.';
        RETURN;
    END IF;

    IF p_monto_minimo <= 0 THEN
        p_mensaje := 'El monto mínimo debe ser mayor a 0.';
        RETURN;
    END IF;

    IF p_fecha_finalizacion <= NOW() THEN
        p_mensaje := 'La fecha de finalización debe ser posterior a la actual.';
        RETURN;
    END IF;

    INSERT INTO apuestas (
        creador_id, titulo, descripcion,
        monto_minimo, monto_maximo, fecha_finalizacion
    ) VALUES (
        p_creador_id, TRIM(p_titulo), TRIM(p_descripcion),
        p_monto_minimo, p_monto_maximo, p_fecha_finalizacion
    )
    RETURNING id INTO p_apuesta_id;

    FOR v_i IN 1..array_length(p_opciones, 1) LOOP
        v_cuota := fn_calcular_cuota(p_probabilidades[v_i]);

        INSERT INTO opciones_apuesta (
            apuesta_id, descripcion, probabilidad_pct, cuota, orden
        ) VALUES (
            p_apuesta_id, TRIM(p_opciones[v_i]),
            p_probabilidades[v_i], v_cuota, v_i
        );
    END LOOP;

    p_mensaje := 'Apuesta creada con éxito.';
EXCEPTION
    WHEN OTHERS THEN
        p_mensaje := 'Error al crear apuesta: ' || SQLERRM;
        RAISE;
END;
$$;


--
-- TOC entry 319 (class 1255 OID 25589)
-- Name: sp_crear_categoria(uuid, text, text, text); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_crear_categoria(IN p_admin_id uuid, IN p_nombre text, IN p_descripcion text, IN p_icono text, OUT p_mensaje text, OUT p_categoria_id uuid)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_rol rol_usuario;
BEGIN
    SELECT rol INTO v_rol FROM usuarios WHERE id = p_admin_id;
    IF v_rol != 'administrador' THEN
        p_mensaje := 'No tiene los permisos suficientes para realizar esta acción.';
        RETURN;
    END IF;

    IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
        p_mensaje := 'El nombre de la categoría es obligatorio.';
        RETURN;
    END IF;

    IF EXISTS (SELECT 1 FROM categorias WHERE LOWER(nombre) = LOWER(TRIM(p_nombre))) THEN
        p_mensaje := 'Esta categoría ya se encuentra registrada.';
        RETURN;
    END IF;

    INSERT INTO categorias (nombre, descripcion, icono)
    VALUES (TRIM(p_nombre), p_descripcion, COALESCE(p_icono, 'mdi-tag'))
    RETURNING id INTO p_categoria_id;

    p_mensaje := 'Categoría creada correctamente.';
END;
$$;


--
-- TOC entry 318 (class 1255 OID 25570)
-- Name: sp_deducir_saldo_admin(uuid, uuid, numeric, text); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_deducir_saldo_admin(IN p_admin_id uuid, IN p_usuario_id uuid, IN p_monto numeric, IN p_motivo text, OUT p_mensaje text)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_rol_admin  rol_usuario;
    v_estado     estado_usuario;
    v_saldo_ant  DECIMAL(15,2);
    v_saldo_new  DECIMAL(15,2);
BEGIN
    SELECT rol INTO v_rol_admin FROM usuarios WHERE id = p_admin_id;
    IF v_rol_admin != 'administrador' THEN
        p_mensaje := 'No tiene los permisos suficientes para realizar esta acción.';
        RETURN;
    END IF;

    IF p_motivo IS NULL OR TRIM(p_motivo) = '' THEN
        p_mensaje := 'Debe especificar obligatoriamente un motivo para retirar fondos de una cuenta.';
        RETURN;
    END IF;

    SELECT estado INTO v_estado FROM usuarios WHERE id = p_usuario_id;
    IF NOT FOUND THEN
        p_mensaje := 'No se puede deducir saldo. El usuario no existe o se encuentra bloqueado.';
        RETURN;
    END IF;

    IF p_monto <= 0 THEN
        p_mensaje := 'El monto a ingresar debe ser mayor a cero.';
        RETURN;
    END IF;

    SELECT saldo_disponible INTO v_saldo_ant
    FROM saldos WHERE usuario_id = p_usuario_id FOR UPDATE;

    IF v_saldo_ant < p_monto THEN
        p_mensaje := 'El usuario no cuenta con las monedas suficientes para realizar este descuento.';
        RETURN;
    END IF;

    UPDATE saldos
    SET saldo_disponible    = saldo_disponible - p_monto,
        fecha_actualizacion = NOW()
    WHERE usuario_id = p_usuario_id;

    v_saldo_new := v_saldo_ant - p_monto;

    INSERT INTO transacciones (
        usuario_id, tipo, monto, saldo_anterior, saldo_posterior, descripcion
    ) VALUES (
        p_usuario_id, 'retiro', p_monto, v_saldo_ant, v_saldo_new, p_motivo
    );

    INSERT INTO logs_admin (admin_id, usuario_id, accion, motivo)
    VALUES (p_admin_id, p_usuario_id, 'deducir_saldo', p_motivo);

    p_mensaje := 'Saldo deducido correctamente. Se ha registrado el movimiento en la bitácora.';
END;
$$;


--
-- TOC entry 305 (class 1255 OID 17807)
-- Name: sp_gestionar_login(uuid, boolean, inet, text); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_gestionar_login(IN p_usuario_id uuid, IN p_exitoso boolean, IN p_ip_address inet, IN p_user_agent text, OUT p_bloqueado boolean, OUT p_mensaje text)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_intentos    SMALLINT;
    v_max         INTEGER;
    v_min_bloqueo INTEGER;
BEGIN
    v_max         := cfg_num('max_intentos_login')::INTEGER;
    v_min_bloqueo := cfg_num('minutos_bloqueo')::INTEGER;
    p_bloqueado   := FALSE;

    INSERT INTO intentos_login (usuario_id, ip_address, user_agent, exitoso)
    VALUES (p_usuario_id, p_ip_address, p_user_agent, p_exitoso);

    IF p_exitoso THEN
        UPDATE usuarios
        SET intentos_fallidos = 0,
            bloqueado_hasta   = NULL,
            estado            = CASE WHEN estado = 'bloqueada' THEN 'no_verificado'::estado_usuario
                                     ELSE estado END
        WHERE id = p_usuario_id;
        p_mensaje := 'Inicio de sesión exitoso.';
    ELSE
        SELECT intentos_fallidos INTO v_intentos FROM usuarios WHERE id = p_usuario_id;
        v_intentos := v_intentos + 1;

        IF v_intentos >= v_max THEN
            UPDATE usuarios
            SET intentos_fallidos = v_intentos,
                bloqueado_hasta   = NOW() + (v_min_bloqueo || ' minutes')::INTERVAL,
                estado            = 'bloqueada'
            WHERE id = p_usuario_id;

            INSERT INTO intentos_fraude (usuario_id, tipo, descripcion, ip_address)
            VALUES (
                p_usuario_id, 'multiples_intentos_login',
                'Cuenta bloqueada tras ' || v_max || ' intentos fallidos consecutivos.',
                p_ip_address
            );

            p_bloqueado := TRUE;
            p_mensaje   := 'Cuenta bloqueada por ' || v_min_bloqueo || ' minutos.';
        ELSE
            UPDATE usuarios SET intentos_fallidos = v_intentos WHERE id = p_usuario_id;
            p_mensaje := 'Credenciales incorrectas.';
        END IF;
    END IF;
END;
$$;


--
-- TOC entry 308 (class 1255 OID 17809)
-- Name: sp_participar_apuesta(uuid, uuid, uuid, numeric); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_participar_apuesta(IN p_usuario_id uuid, IN p_apuesta_id uuid, IN p_opcion_id uuid, IN p_monto numeric, OUT p_part_id uuid, OUT p_ganancia_si_gana numeric, OUT p_cuota_aplicada numeric, OUT p_mensaje text)
    LANGUAGE plpgsql
    AS $_$
DECLARE
    v_apuesta       apuestas%ROWTYPE;
    v_opcion        opciones_apuesta%ROWTYPE;
    v_estado        estado_usuario;
    v_saldo         DECIMAL(15,2);
    v_saldo_ant     DECIMAL(15,2);
    v_seg_cierre    INTEGER;
    v_seg_restantes DOUBLE PRECISION;
    v_ganancia_proy DECIMAL(10,2);
BEGIN
    v_seg_cierre := cfg_num('segundos_cierre_apuesta')::INTEGER;

    SELECT estado INTO v_estado FROM usuarios WHERE id = p_usuario_id;
    IF v_estado != 'verificada' THEN
        p_mensaje := 'Solo usuarios verificados pueden apostar.';
        RETURN;
    END IF;

    SELECT * INTO v_apuesta FROM apuestas WHERE id = p_apuesta_id FOR UPDATE;
    IF NOT FOUND OR v_apuesta.estado != 'activa' THEN
        p_mensaje := 'La apuesta no está disponible.';
        RETURN;
    END IF;

    -- Bloqueo de 30 segundos (validado en servidor, no solo frontend)
    v_seg_restantes := EXTRACT(EPOCH FROM (v_apuesta.fecha_finalizacion - NOW()));
    IF v_seg_restantes <= v_seg_cierre THEN
        p_mensaje := 'La apuesta está por cerrar. No se permiten nuevas participaciones.';
        RETURN;
    END IF;

    SELECT * INTO v_opcion
    FROM opciones_apuesta
    WHERE id = p_opcion_id AND apuesta_id = p_apuesta_id;

    IF NOT FOUND THEN
        p_mensaje := 'La opción seleccionada no es válida para esta apuesta.';
        RETURN;
    END IF;

    IF p_monto <= 0 THEN
        p_mensaje := 'El monto debe ser mayor a 0.';
        RETURN;
    END IF;
    IF p_monto < v_apuesta.monto_minimo THEN
        p_mensaje := 'El monto ingresado es menor al mínimo permitido ($' || v_apuesta.monto_minimo || ').';
        RETURN;
    END IF;
    IF v_apuesta.monto_maximo IS NOT NULL AND p_monto > v_apuesta.monto_maximo THEN
        p_mensaje := 'El monto supera el máximo permitido ($' || v_apuesta.monto_maximo || ').';
        RETURN;
    END IF;

    SELECT saldo_disponible INTO v_saldo
    FROM saldos WHERE usuario_id = p_usuario_id FOR UPDATE;

    IF v_saldo < p_monto THEN
        p_mensaje := 'Saldo insuficiente.';
        RETURN;
    END IF;

    -- Calcular y exponer ganancia proyectada
    v_ganancia_proy    := ROUND(p_monto * v_opcion.cuota, 2);
    p_ganancia_si_gana := v_ganancia_proy;
    p_cuota_aplicada   := v_opcion.cuota;

    INSERT INTO participaciones (
        usuario_id, apuesta_id, opcion_id, monto, ganancia_proyectada
    ) VALUES (
        p_usuario_id, p_apuesta_id, p_opcion_id, p_monto, v_ganancia_proy
    )
    RETURNING id INTO p_part_id;

    v_saldo_ant := v_saldo;
    UPDATE saldos
    SET saldo_disponible    = saldo_disponible - p_monto,
        fecha_actualizacion = NOW()
    WHERE usuario_id = p_usuario_id;

    INSERT INTO transacciones (
        usuario_id, tipo, monto, saldo_anterior, saldo_posterior,
        referencia_id, descripcion
    ) VALUES (
        p_usuario_id, 'apuesta_deduccion', p_monto,
        v_saldo_ant, v_saldo_ant - p_monto,
        p_part_id,
        'Apuesta en: "' || v_apuesta.titulo ||
        '" · opción: "' || v_opcion.descripcion ||
        '" · cuota ×' || v_opcion.cuota ||
        ' · ganancia proyectada: $' || v_ganancia_proy
    );

    UPDATE apuestas
    SET total_participantes = total_participantes + 1,
        total_apostado      = total_apostado + p_monto
    WHERE id = p_apuesta_id;

    UPDATE opciones_apuesta
    SET total_apostado      = total_apostado + p_monto,
        total_participantes = total_participantes + 1
    WHERE id = p_opcion_id;

    p_mensaje := 'Apuesta realizada con éxito.';
EXCEPTION
    WHEN unique_violation THEN
        p_mensaje := 'Ya tienes una apuesta registrada en esta opción.';
    WHEN OTHERS THEN
        p_mensaje := 'Error al procesar la apuesta: ' || SQLERRM;
        RAISE;
END;
$_$;


--
-- TOC entry 316 (class 1255 OID 25568)
-- Name: sp_proponer_resultado(uuid, uuid, uuid); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_proponer_resultado(IN p_creador_id uuid, IN p_apuesta_id uuid, IN p_opcion_ganadora_id uuid, OUT p_resultado_id uuid, OUT p_mensaje text)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_apuesta apuestas%ROWTYPE;
BEGIN
    SELECT * INTO v_apuesta FROM apuestas WHERE id = p_apuesta_id;

    IF NOT FOUND THEN
        p_mensaje := 'Apuesta no encontrada.';
        RETURN;
    END IF;

    -- Solo el creador puede proponer
    IF v_apuesta.creador_id != p_creador_id THEN
        p_mensaje := 'Solo el creador de la apuesta puede proponer el resultado.';
        RETURN;
    END IF;

    -- La apuesta debe estar cerrada o activa con tiempo vencido
    IF v_apuesta.estado NOT IN ('cerrada', 'activa') THEN
        p_mensaje := 'La apuesta no está en estado válido para declarar resultado.';
        RETURN;
    END IF;

    -- Verificar que no haya un resultado ya propuesto o confirmado activo
    IF EXISTS (
        SELECT 1 FROM resultados_apuesta
        WHERE apuesta_id = p_apuesta_id AND estado IN ('propuesto', 'confirmado')
    ) THEN
        p_mensaje := 'Ya existe un resultado propuesto para esta apuesta.';
        RETURN;
    END IF;

    -- Validar que la opción pertenece a esta apuesta
    IF NOT EXISTS (
        SELECT 1 FROM opciones_apuesta WHERE id = p_opcion_ganadora_id AND apuesta_id = p_apuesta_id
    ) THEN
        p_mensaje := 'La opción ganadora no pertenece a esta apuesta.';
        RETURN;
    END IF;

    -- Cambiar estado a "en revisión"
    UPDATE apuestas SET estado = 'en_revision' WHERE id = p_apuesta_id;

    INSERT INTO resultados_apuesta (apuesta_id, opcion_ganadora_id, propuesto_por)
    VALUES (p_apuesta_id, p_opcion_ganadora_id, p_creador_id)
    RETURNING id INTO p_resultado_id;

    p_mensaje := 'Resultado propuesto. Pendiente de confirmación por el administrador.';
END;
$$;


--
-- TOC entry 310 (class 1255 OID 17812)
-- Name: sp_recargar_saldo(uuid, numeric, character varying, character); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_recargar_saldo(IN p_usuario_id uuid, IN p_monto numeric, IN p_metodo character varying, OUT p_mensaje text, IN p_ultimos_4 character DEFAULT NULL::bpchar)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_saldo_ant DECIMAL(15,2);
    v_recarga_id UUID;
BEGIN
    IF p_monto <= 0 THEN
        p_mensaje := 'El monto debe ser mayor a 0.';
        RETURN;
    END IF;

    SELECT saldo_disponible INTO v_saldo_ant
    FROM saldos WHERE usuario_id = p_usuario_id FOR UPDATE;

    IF NOT FOUND THEN
        p_mensaje := 'Usuario no encontrado.';
        RETURN;
    END IF;

    INSERT INTO recargas (usuario_id, monto, metodo, ultimos_4_digitos)
    VALUES (p_usuario_id, p_monto, p_metodo, p_ultimos_4)
    RETURNING id INTO v_recarga_id;

    UPDATE saldos
    SET saldo_disponible    = saldo_disponible + p_monto,
        fecha_actualizacion = NOW()
    WHERE usuario_id = p_usuario_id;

    INSERT INTO transacciones (
        usuario_id, tipo, monto, saldo_anterior, saldo_posterior,
        referencia_id, descripcion
    ) VALUES (
        p_usuario_id, 'recarga', p_monto,
        v_saldo_ant, v_saldo_ant + p_monto,
        v_recarga_id,
        'Recarga ficticia · método: ' || p_metodo
    );

    p_mensaje := 'Recarga realizada con éxito.';
END;
$$;


--
-- TOC entry 304 (class 1255 OID 17806)
-- Name: sp_registrar_usuario(character varying, character varying, character varying, date, character varying, character varying, character varying, character varying); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_registrar_usuario(IN p_nombre character varying, IN p_apellido_paterno character varying, IN p_apellido_materno character varying, IN p_fecha_nacimiento date, IN p_telefono character varying, IN p_alias character varying, IN p_correo character varying, IN p_password_hash character varying, OUT p_usuario_id uuid, OUT p_mensaje text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF DATE_PART('year', AGE(p_fecha_nacimiento)) < 18 THEN
        p_mensaje := 'Debes ser mayor de edad para registrarte.';
        RETURN;
    END IF;

    IF EXISTS (SELECT 1 FROM usuarios WHERE correo = LOWER(TRIM(p_correo))) THEN
        p_mensaje := 'El correo electrónico ya está registrado.';
        RETURN;
    END IF;

    IF EXISTS (SELECT 1 FROM usuarios WHERE alias = TRIM(p_alias)) THEN
        p_mensaje := 'Este nombre de usuario ya existe.';
        RETURN;
    END IF;

    INSERT INTO usuarios (
        nombre, apellido_paterno, apellido_materno,
        fecha_nacimiento, telefono, alias, correo,
        password_hash, acepto_terminos
    ) VALUES (
        TRIM(p_nombre), TRIM(p_apellido_paterno), TRIM(p_apellido_materno),
        p_fecha_nacimiento, TRIM(p_telefono),
        TRIM(p_alias), LOWER(TRIM(p_correo)),
        p_password_hash, TRUE
    )
    RETURNING id INTO p_usuario_id;

    p_mensaje := 'Registro exitoso.';
EXCEPTION
    WHEN OTHERS THEN
        p_mensaje := 'Error al registrar: ' || SQLERRM;
END;
$$;


--
-- TOC entry 313 (class 1255 OID 17814)
-- Name: sp_revisar_documento(uuid, uuid, boolean, text); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_revisar_documento(IN p_admin_id uuid, IN p_documento_id uuid, IN p_aprobar boolean, OUT p_mensaje text, IN p_motivo_rechazo text DEFAULT NULL::text)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_doc      documentos_identidad%ROWTYPE;
    v_rol      rol_usuario;
    v_num_norm VARCHAR(50);
BEGIN
    SELECT rol INTO v_rol FROM usuarios WHERE id = p_admin_id;
    IF v_rol != 'administrador' THEN
        p_mensaje := 'Sin permisos para revisar documentos.';
        RETURN;
    END IF;
    SELECT * INTO v_doc FROM documentos_identidad WHERE id = p_documento_id;
    IF NOT FOUND OR v_doc.estado != 'pendiente' THEN
        p_mensaje := 'Documento no encontrado o ya revisado.';
        RETURN;
    END IF;
    IF p_aprobar THEN
        v_num_norm := normalizar_texto(v_doc.numero_documento);
        IF EXISTS (
            SELECT 1 FROM documentos_identidad
            WHERE normalizar_texto(numero_documento) = v_num_norm
              AND id     != v_doc.id
              AND estado  = 'aprobado'
        ) THEN
            INSERT INTO intentos_fraude (
                usuario_id, tipo, descripcion, dato_sospechoso
            ) VALUES (
                v_doc.usuario_id, 'documento_duplicado',
                'Intento de verificar con documento ya registrado en otra cuenta.',
                v_doc.numero_documento
            );
            p_mensaje := 'La identidad proporcionada ya se encuentra registrada en otra cuenta.';
            RETURN;
        END IF;
        UPDATE documentos_identidad
        SET estado         = 'aprobado',
            revisado_por   = p_admin_id,
            fecha_revision = NOW()
        WHERE id = p_documento_id;
        UPDATE usuarios SET estado = 'verificada' WHERE id = v_doc.usuario_id;
        p_mensaje := 'Usuario verificado. Ahora puede participar en la plataforma.';
    ELSE
        UPDATE documentos_identidad
        SET estado         = 'rechazado',
            revisado_por   = p_admin_id,
            fecha_revision = NOW(),
            motivo_rechazo = p_motivo_rechazo
        WHERE id = p_documento_id;
        UPDATE usuarios SET estado = 'no_verificado' WHERE id = v_doc.usuario_id;
        p_mensaje := 'Se ha notificado al usuario sobre el rechazo del documento.';
    END IF;
END;
$$;


--
-- TOC entry 307 (class 1255 OID 17813)
-- Name: sp_solicitar_retiro(uuid, numeric, character varying); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.sp_solicitar_retiro(IN p_usuario_id uuid, IN p_monto_solicitado numeric, IN p_metodo_retiro character varying, OUT p_retiro_id uuid, OUT p_mensaje text)
    LANGUAGE plpgsql
    AS $_$
DECLARE
    v_saldo        DECIMAL(15,2);
    v_saldo_ant    DECIMAL(15,2);
    v_comision_pct DECIMAL(5,2);
    v_comision     DECIMAL(10,2);
    v_monto_neto   DECIMAL(10,2);
    v_retiro_min   DECIMAL(10,2);
BEGIN
    v_comision_pct := cfg_num('comision_retiro');
    v_retiro_min   := cfg_num('retiro_minimo');

    IF p_monto_solicitado <= 0 THEN
        p_mensaje := 'El monto debe ser mayor a 0.';
        RETURN;
    END IF;

    IF p_monto_solicitado < v_retiro_min THEN
        p_mensaje := 'El retiro mínimo permitido es $' || v_retiro_min;
        RETURN;
    END IF;

    SELECT saldo_disponible INTO v_saldo
    FROM saldos WHERE usuario_id = p_usuario_id FOR UPDATE;

    IF v_saldo < p_monto_solicitado THEN
        p_mensaje := 'El monto a retirar no puede exceder el saldo disponible.';
        RETURN;
    END IF;

    v_comision   := ROUND(p_monto_solicitado * (v_comision_pct / 100.0), 2);
    v_monto_neto := p_monto_solicitado - v_comision;

    INSERT INTO retiros (
        usuario_id, monto_solicitado, comision, monto_neto, metodo_retiro
    ) VALUES (
        p_usuario_id, p_monto_solicitado, v_comision, v_monto_neto, p_metodo_retiro
    )
    RETURNING id INTO p_retiro_id;

    v_saldo_ant := v_saldo;
    UPDATE saldos
    SET saldo_disponible    = saldo_disponible - p_monto_solicitado,
        fecha_actualizacion = NOW()
    WHERE usuario_id = p_usuario_id;

    INSERT INTO transacciones (
        usuario_id, tipo, monto, saldo_anterior, saldo_posterior,
        referencia_id, descripcion
    ) VALUES (
        p_usuario_id, 'retiro', p_monto_solicitado,
        v_saldo_ant, v_saldo_ant - p_monto_solicitado,
        p_retiro_id,
        'Retiro solicitado · comisión 4%: $' || v_comision ||
        ' · monto neto: $' || v_monto_neto
    );

    p_mensaje := 'Retiro solicitado con éxito. Se aplicó una comisión del 4%.';
END;
$_$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 221 (class 1259 OID 17582)
-- Name: apuestas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.apuestas (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    creador_id uuid NOT NULL,
    titulo character varying(200) NOT NULL,
    descripcion text NOT NULL,
    monto_minimo numeric(10,2) NOT NULL,
    monto_maximo numeric(10,2),
    fecha_finalizacion timestamp without time zone NOT NULL,
    estado public.estado_apuesta DEFAULT 'activa'::public.estado_apuesta NOT NULL,
    es_tendencia boolean DEFAULT false NOT NULL,
    total_participantes integer DEFAULT 0 NOT NULL,
    total_apostado numeric(15,2) DEFAULT 0.00 NOT NULL,
    fecha_creacion timestamp without time zone DEFAULT now() NOT NULL,
    fecha_actualizacion timestamp without time zone DEFAULT now() NOT NULL,
    categoria_id uuid,
    CONSTRAINT chk_fecha_posterior CHECK ((fecha_finalizacion > fecha_creacion)),
    CONSTRAINT chk_monto_maximo CHECK (((monto_maximo IS NULL) OR (monto_maximo >= monto_minimo))),
    CONSTRAINT chk_monto_minimo CHECK ((monto_minimo > (0)::numeric)),
    CONSTRAINT chk_participantes CHECK ((total_participantes >= 0)),
    CONSTRAINT chk_total_apostado CHECK ((total_apostado >= (0)::numeric))
);


--
-- TOC entry 236 (class 1259 OID 25571)
-- Name: categorias; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.categorias (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    nombre character varying(100) NOT NULL,
    descripcion text,
    icono character varying(50) DEFAULT 'mdi-tag'::character varying,
    activa boolean DEFAULT true,
    fecha_creacion timestamp without time zone DEFAULT now()
);


--
-- TOC entry 217 (class 1259 OID 17501)
-- Name: configuracion_sistema; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.configuracion_sistema (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    clave character varying(100) NOT NULL,
    valor text NOT NULL,
    descripcion text,
    modificado_por uuid,
    fecha_modificacion timestamp without time zone DEFAULT now()
);


--
-- TOC entry 5268 (class 0 OID 0)
-- Dependencies: 217
-- Name: TABLE configuracion_sistema; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.configuracion_sistema IS 'Parámetros globales configurables por el administrador sin tocar código.';


--
-- TOC entry 219 (class 1259 OID 17537)
-- Name: documentos_identidad; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.documentos_identidad (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    numero_documento character varying(50) NOT NULL,
    tipo_documento public.tipo_documento DEFAULT 'INE'::public.tipo_documento NOT NULL,
    ruta_archivo character varying(500) NOT NULL,
    tipo_mime character varying(50),
    tamano_bytes integer,
    estado public.estado_documento DEFAULT 'pendiente'::public.estado_documento NOT NULL,
    motivo_rechazo text,
    revisado_por uuid,
    fecha_subida timestamp without time zone DEFAULT now() NOT NULL,
    fecha_revision timestamp without time zone
);


--
-- TOC entry 5269 (class 0 OID 0)
-- Dependencies: 219
-- Name: TABLE documentos_identidad; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.documentos_identidad IS 'Un documento único por persona. Prevención de multicuentas.';


--
-- TOC entry 5270 (class 0 OID 0)
-- Dependencies: 219
-- Name: COLUMN documentos_identidad.numero_documento; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.documentos_identidad.numero_documento IS 'Normalizado (sin espacios, mayúsculas). Restricción UNIQUE en BD.';


--
-- TOC entry 229 (class 1259 OID 17769)
-- Name: intentos_fraude; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.intentos_fraude (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid,
    tipo public.tipo_fraude NOT NULL,
    descripcion text NOT NULL,
    ip_address inet,
    dato_sospechoso character varying(255),
    revisado boolean DEFAULT false NOT NULL,
    revisado_por uuid,
    fecha timestamp without time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 228 (class 1259 OID 17751)
-- Name: intentos_login; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.intentos_login (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid,
    correo_intento character varying(255),
    ip_address inet,
    user_agent text,
    exitoso boolean DEFAULT false NOT NULL,
    fecha timestamp without time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 235 (class 1259 OID 25542)
-- Name: logs_admin; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.logs_admin (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    admin_id uuid NOT NULL,
    usuario_id uuid NOT NULL,
    accion character varying(50) NOT NULL,
    motivo text,
    fecha timestamp without time zone DEFAULT now()
);


--
-- TOC entry 222 (class 1259 OID 17611)
-- Name: opciones_apuesta; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.opciones_apuesta (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    apuesta_id uuid NOT NULL,
    descripcion character varying(200) NOT NULL,
    probabilidad_pct numeric(5,2) NOT NULL,
    cuota numeric(8,4) NOT NULL,
    orden smallint DEFAULT 1 NOT NULL,
    total_apostado numeric(15,2) DEFAULT 0.00 NOT NULL,
    total_participantes integer DEFAULT 0 NOT NULL,
    CONSTRAINT chk_cuota_positiva CHECK ((cuota > (0)::numeric)),
    CONSTRAINT chk_probabilidad_rango CHECK (((probabilidad_pct > (0)::numeric) AND (probabilidad_pct < (100)::numeric)))
);


--
-- TOC entry 5271 (class 0 OID 0)
-- Dependencies: 222
-- Name: COLUMN opciones_apuesta.probabilidad_pct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.opciones_apuesta.probabilidad_pct IS 'Porcentaje definido por el creador. Todas las opciones de una apuesta deben sumar 100.';


--
-- TOC entry 5272 (class 0 OID 0)
-- Dependencies: 222
-- Name: COLUMN opciones_apuesta.cuota; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.opciones_apuesta.cuota IS 'Calculado al crear: (1 / probabilidad%) × margen_casa. Ej: 20% → ×4.50';


--
-- TOC entry 223 (class 1259 OID 17628)
-- Name: participaciones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.participaciones (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    apuesta_id uuid NOT NULL,
    opcion_id uuid NOT NULL,
    monto numeric(10,2) NOT NULL,
    ganancia_proyectada numeric(10,2) NOT NULL,
    estado public.estado_participacion DEFAULT 'activa'::public.estado_participacion NOT NULL,
    ganancia numeric(10,2),
    fecha_participacion timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_ganancia_proyectada CHECK ((ganancia_proyectada > (0)::numeric)),
    CONSTRAINT chk_monto_participacion CHECK ((monto > (0)::numeric))
);


--
-- TOC entry 5273 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN participaciones.ganancia_proyectada; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.participaciones.ganancia_proyectada IS 'monto × cuota. Calculado y mostrado al usuario ANTES de confirmar. Se acredita si gana.';


--
-- TOC entry 5274 (class 0 OID 0)
-- Dependencies: 223
-- Name: COLUMN participaciones.ganancia; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.participaciones.ganancia IS 'NULL hasta que el resultado sea confirmado. Igual a ganancia_proyectada si gana.';


--
-- TOC entry 226 (class 1259 OID 17711)
-- Name: recargas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recargas (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    monto numeric(10,2) NOT NULL,
    metodo character varying(50) DEFAULT 'tarjeta_ficticia'::character varying NOT NULL,
    ultimos_4_digitos character(4),
    descripcion character varying(200),
    fecha timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_monto_recarga CHECK ((monto > (0)::numeric))
);


--
-- TOC entry 5275 (class 0 OID 0)
-- Dependencies: 226
-- Name: TABLE recargas; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.recargas IS 'Recargas ficticias. Los datos de tarjeta son simulados, nunca reales.';


--
-- TOC entry 224 (class 1259 OID 17659)
-- Name: resultados_apuesta; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.resultados_apuesta (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    apuesta_id uuid NOT NULL,
    opcion_ganadora_id uuid NOT NULL,
    propuesto_por uuid NOT NULL,
    confirmado_por uuid,
    estado public.estado_resultado DEFAULT 'propuesto'::public.estado_resultado NOT NULL,
    motivo_rechazo text,
    fecha_propuesta timestamp without time zone DEFAULT now() NOT NULL,
    fecha_confirmacion timestamp without time zone,
    evidencia text
);


--
-- TOC entry 5276 (class 0 OID 0)
-- Dependencies: 224
-- Name: TABLE resultados_apuesta; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.resultados_apuesta IS 'Doble filtro: creador propone, admin confirma. Si se rechaza, el creador puede re-proponer.';


--
-- TOC entry 227 (class 1259 OID 17726)
-- Name: retiros; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.retiros (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    monto_solicitado numeric(10,2) NOT NULL,
    comision numeric(10,2) NOT NULL,
    monto_neto numeric(10,2) NOT NULL,
    metodo_retiro character varying(50) NOT NULL,
    estado public.estado_retiro DEFAULT 'pendiente'::public.estado_retiro NOT NULL,
    motivo_rechazo text,
    procesado_por uuid,
    fecha_solicitud timestamp without time zone DEFAULT now() NOT NULL,
    fecha_procesado timestamp without time zone,
    CONSTRAINT chk_comision_ret CHECK ((comision >= (0)::numeric)),
    CONSTRAINT chk_monto_neto CHECK ((monto_neto = (monto_solicitado - comision))),
    CONSTRAINT chk_monto_retiro CHECK ((monto_solicitado > (0)::numeric))
);


--
-- TOC entry 220 (class 1259 OID 17565)
-- Name: saldos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.saldos (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    saldo_disponible numeric(15,2) DEFAULT 0.00 NOT NULL,
    fecha_actualizacion timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_saldo_no_negativo CHECK ((saldo_disponible >= (0)::numeric))
);


--
-- TOC entry 5277 (class 0 OID 0)
-- Dependencies: 220
-- Name: TABLE saldos; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.saldos IS 'Saldo ficticio actual. Una fila por usuario. Nunca negativo.';


--
-- TOC entry 225 (class 1259 OID 17693)
-- Name: transacciones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transacciones (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    tipo public.tipo_transaccion NOT NULL,
    monto numeric(10,2) NOT NULL,
    saldo_anterior numeric(15,2) NOT NULL,
    saldo_posterior numeric(15,2) NOT NULL,
    referencia_id uuid,
    descripcion text,
    fecha timestamp without time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 5278 (class 0 OID 0)
-- Dependencies: 225
-- Name: TABLE transacciones; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.transacciones IS 'Historial inmutable. Solo INSERT, nunca UPDATE ni DELETE.';


--
-- TOC entry 218 (class 1259 OID 17512)
-- Name: usuarios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.usuarios (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    nombre character varying(100) NOT NULL,
    apellido_paterno character varying(100) NOT NULL,
    apellido_materno character varying(100),
    fecha_nacimiento date NOT NULL,
    telefono character varying(20) NOT NULL,
    alias character varying(50) NOT NULL,
    correo character varying(255) NOT NULL,
    password_hash character varying(255) NOT NULL,
    estado public.estado_usuario DEFAULT 'no_verificado'::public.estado_usuario NOT NULL,
    rol public.rol_usuario DEFAULT 'usuario'::public.rol_usuario NOT NULL,
    intentos_fallidos smallint DEFAULT 0 NOT NULL,
    bloqueado_hasta timestamp without time zone,
    acepto_terminos boolean DEFAULT false NOT NULL,
    fecha_registro timestamp without time zone DEFAULT now() NOT NULL,
    fecha_actualizacion timestamp without time zone DEFAULT now() NOT NULL,
    token_invalidado_en timestamp without time zone,
    CONSTRAINT chk_acepto_terminos CHECK ((acepto_terminos = true)),
    CONSTRAINT chk_correo_formato CHECK (((correo)::text ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'::text)),
    CONSTRAINT chk_intentos CHECK ((intentos_fallidos >= 0)),
    CONSTRAINT chk_mayor_edad CHECK ((date_part('year'::text, age((fecha_nacimiento)::timestamp with time zone)) >= (18)::double precision))
);


--
-- TOC entry 5279 (class 0 OID 0)
-- Dependencies: 218
-- Name: TABLE usuarios; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.usuarios IS 'Usuarios registrados. Flujo de estado: no_verificado → pendiente → verificada.';


--
-- TOC entry 5280 (class 0 OID 0)
-- Dependencies: 218
-- Name: COLUMN usuarios.intentos_fallidos; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.usuarios.intentos_fallidos IS 'Se reinicia a 0 al iniciar sesión exitosamente.';


--
-- TOC entry 230 (class 1259 OID 17817)
-- Name: v_apuestas_activas; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_apuestas_activas AS
 SELECT a.id,
    a.titulo,
    a.descripcion,
    a.monto_minimo,
    a.monto_maximo,
    a.total_participantes,
    a.total_apostado,
    a.es_tendencia,
    a.fecha_finalizacion,
    (EXTRACT(epoch FROM ((a.fecha_finalizacion)::timestamp with time zone - now())))::integer AS segundos_restantes,
    a.fecha_creacion,
    u.alias AS creador_alias,
        CASE
            WHEN (EXTRACT(epoch FROM ((a.fecha_finalizacion)::timestamp with time zone - now())) <= (( SELECT (configuracion_sistema.valor)::integer AS valor
               FROM public.configuracion_sistema
              WHERE ((configuracion_sistema.clave)::text = 'segundos_cierre_apuesta'::text)))::numeric) THEN true
            ELSE false
        END AS en_periodo_bloqueo,
    ( SELECT json_agg(json_build_object('id', o.id, 'descripcion', o.descripcion, 'probabilidad_pct', o.probabilidad_pct, 'cuota', o.cuota, 'orden', o.orden, 'total_participantes', o.total_participantes) ORDER BY o.orden) AS json_agg
           FROM public.opciones_apuesta o
          WHERE (o.apuesta_id = a.id)) AS opciones
   FROM (public.apuestas a
     JOIN public.usuarios u ON ((u.id = a.creador_id)))
  WHERE ((a.estado = 'activa'::public.estado_apuesta) AND (a.fecha_finalizacion > now()));


--
-- TOC entry 5281 (class 0 OID 0)
-- Dependencies: 230
-- Name: VIEW v_apuestas_activas; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.v_apuestas_activas IS 'Lista para consumir desde la API. Incluye opciones con cuotas y segundos restantes.';


--
-- TOC entry 233 (class 1259 OID 17831)
-- Name: v_documentos_pendientes; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_documentos_pendientes AS
 SELECT d.id AS documento_id,
    u.id AS usuario_id,
    u.alias,
    (((u.nombre)::text || ' '::text) || (u.apellido_paterno)::text) AS nombre_completo,
    u.correo,
    d.tipo_documento,
    d.numero_documento,
    d.ruta_archivo,
    d.fecha_subida
   FROM (public.documentos_identidad d
     JOIN public.usuarios u ON ((u.id = d.usuario_id)))
  WHERE (d.estado = 'pendiente'::public.estado_documento)
  ORDER BY d.fecha_subida;


--
-- TOC entry 234 (class 1259 OID 17836)
-- Name: v_fraudes_pendientes; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_fraudes_pendientes AS
 SELECT f.id,
    f.tipo,
    f.descripcion,
    f.dato_sospechoso,
    f.ip_address,
    f.fecha,
    u.alias AS usuario_alias,
    u.correo AS usuario_correo
   FROM (public.intentos_fraude f
     LEFT JOIN public.usuarios u ON ((u.id = f.usuario_id)))
  WHERE (f.revisado = false)
  ORDER BY f.fecha DESC;


--
-- TOC entry 232 (class 1259 OID 17826)
-- Name: v_historial_participaciones; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_historial_participaciones AS
 SELECT p.id,
    p.usuario_id,
    p.apuesta_id,
    a.titulo AS apuesta_titulo,
    o.descripcion AS opcion_elegida,
    o.cuota,
    p.monto,
    p.ganancia_proyectada,
    p.estado,
    p.ganancia,
    p.fecha_participacion
   FROM ((public.participaciones p
     JOIN public.apuestas a ON ((a.id = p.apuesta_id)))
     JOIN public.opciones_apuesta o ON ((o.id = p.opcion_id)));


--
-- TOC entry 237 (class 1259 OID 25590)
-- Name: v_ranking_semanal; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_ranking_semanal AS
 SELECT u.id AS usuario_id,
    u.alias,
    count(p.id) AS apuestas_ganadas,
    sum(p.ganancia) AS ganancias_acumuladas,
    date_trunc('week'::text, now()) AS semana_inicio,
    now() AS ultima_actualizacion
   FROM (public.participaciones p
     JOIN public.usuarios u ON ((u.id = p.usuario_id)))
  WHERE ((p.estado = 'ganadora'::public.estado_participacion) AND (p.fecha_participacion >= date_trunc('week'::text, now())) AND (p.fecha_participacion < (date_trunc('week'::text, now()) + '7 days'::interval)))
  GROUP BY u.id, u.alias
  ORDER BY (count(p.id)) DESC, (sum(p.ganancia)) DESC;


--
-- TOC entry 231 (class 1259 OID 17822)
-- Name: v_saldo_usuario; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_saldo_usuario AS
 SELECT u.id AS usuario_id,
    u.alias,
    s.saldo_disponible,
    s.fecha_actualizacion AS ultimo_movimiento
   FROM (public.usuarios u
     JOIN public.saldos s ON ((s.usuario_id = u.id)));


--
-- TOC entry 5248 (class 0 OID 17582)
-- Dependencies: 221
-- Data for Name: apuestas; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.apuestas (id, creador_id, titulo, descripcion, monto_minimo, monto_maximo, fecha_finalizacion, estado, es_tendencia, total_participantes, total_apostado, fecha_creacion, fecha_actualizacion, categoria_id) FROM stdin;
fc125819-5758-4e2b-9368-e0428f52237e	9d11f875-d0bf-4afa-9940-e10513a83efa	Prueba bnggrgr	dsdsdgfgfgfgfgfgfgf	50.00	\N	2026-04-20 06:07:00	cerrada	f	0	0.00	2026-04-20 06:05:54.543188	2026-05-06 15:36:39.228571	\N
4c0ced9a-f094-458d-bf61-43bed3c6f38b	37d4b325-2151-4683-8003-c2990c23b6fd	Verificador de cuenta regresiva	Verificador de cuenta regresiva	50.00	\N	2026-05-25 05:34:00	finalizada	t	1	50.00	2026-05-25 05:32:45.515624	2026-05-25 06:32:39.187261	\N
6162ccae-65d8-437c-8231-6fe1dbd992a6	9d11f875-d0bf-4afa-9940-e10513a83efa	ccccccccccccccccccc	cccccccccccccccc	50.00	\N	2026-04-20 17:06:00	finalizada	f	0	0.00	2026-04-20 04:02:48.994995	2026-05-24 05:37:39.131266	\N
2cc79f68-6738-4b80-b9bf-929c9089673a	37d4b325-2151-4683-8003-c2990c23b6fd	DSDSDSDSDSDSD	SDSDSDSDSDSDSDS	50.00	\N	2026-05-25 04:42:00	en_revision	f	0	0.00	2026-05-25 04:41:24.966518	2026-05-30 10:05:56.307935	\N
9b889aea-3704-49d5-b577-d4dd6a3641c7	9d11f875-d0bf-4afa-9940-e10513a83efa	Apuesta prueba 24-05-26	Prueba para poder asignar un ganador a la apuesta siendo admin	49.00	100.00	2026-05-24 05:45:00	cerrada	f	0	0.00	2026-05-24 05:39:38.511796	2026-05-24 05:45:02.151362	\N
474b6abb-5366-4658-b872-6624bc8e7b38	37d4b325-2151-4683-8003-c2990c23b6fd	Prueba de verificacion de usuario	Prueba para verificar que el usuario que puede apostar es alguien verificado	50.00	\N	2026-05-25 04:43:00	en_revision	f	0	0.00	2026-05-25 04:38:43.930218	2026-05-30 10:39:43.923523	\N
a6873154-fc4d-460e-90c6-001a9f3fed6e	9d11f875-d0bf-4afa-9940-e10513a83efa	EbeSaurio 30 segundos	vvvvvvvvvvvv	50.00	\N	2026-04-20 03:45:00	finalizada	f	0	0.00	2026-04-20 03:44:52.811022	2026-05-24 15:41:01.205114	\N
92f6c050-8143-4e7a-86d0-427374ecd910	9d11f875-d0bf-4afa-9940-e10513a83efa	¿Quién ganará el partido?	Partido entre equipo A y equipo B	50.00	\N	2026-12-31 23:59:59	finalizada	t	1	100.00	2026-04-10 08:14:04.664517	2026-04-11 16:52:08.037061	\N
9be0d25d-f848-437e-9ae0-70de3a4b4145	37d4b325-2151-4683-8003-c2990c23b6fd	SJJSJSJSJSJSJ	SJJSJSJSJSJSJJS	50.00	\N	2026-05-25 06:27:00	finalizada	t	1	50.00	2026-05-25 06:25:32.410885	2026-05-25 06:28:30.212744	\N
0dfa4026-c7cf-4b46-ade4-6b3f67fa716d	2bed359b-90d4-4251-806b-6076b7c0a1bd	dddddddddd	ddddddddddddddddddddddd	50.00	\N	2026-05-25 05:57:00	finalizada	f	2	100.00	2026-05-25 05:55:18.150676	2026-05-25 06:32:14.973539	\N
58cb2d3d-f32f-452e-9df2-75bd5dcf6b83	99856cdf-3124-4a8b-930c-86b9e6087866	Prueba de los segundos	Segundos probar	50.00	100.00	2026-05-24 17:21:00	finalizada	t	2	104.00	2026-05-24 17:18:34.080545	2026-05-24 17:31:43.423348	\N
93688c1a-f27d-4fa6-8b1b-de8f0938126f	37d4b325-2151-4683-8003-c2990c23b6fd	Prueba para cancelar	Prueba para cancelar	50.00	\N	2026-09-25 01:34:00	cancelada	f	0	0.00	2026-05-28 01:31:27.676105	2026-05-28 01:32:43.086378	\N
20ee42a4-dd65-4176-b233-56e7d6e90e0e	9d11f875-d0bf-4afa-9940-e10513a83efa	dsdsdssssss	dsdsdsdsdsdsds	50.00	\N	2026-04-20 06:13:00	cerrada	f	0	0.00	2026-04-20 06:11:25.929933	2026-05-06 15:36:39.228571	\N
463dbb7e-8ebf-4f89-89a5-00a2a4f1f42c	9d11f875-d0bf-4afa-9940-e10513a83efa	ddddddddddd	dddddddddssssssssssss	50.00	\N	2026-04-20 06:15:00	cerrada	f	0	0.00	2026-04-20 06:12:23.184959	2026-05-06 15:36:39.228571	\N
834b5a3d-24b6-46b0-85ac-42934419adc3	9d11f875-d0bf-4afa-9940-e10513a83efa	Prueba tiempo	Es para ver cuantos segundos	50.00	100.00	2026-04-20 06:29:00	cerrada	f	0	0.00	2026-04-20 06:24:54.86911	2026-05-06 15:36:39.228571	\N
f1ce0e2a-6842-4891-89f6-06e3d44b42a4	9d11f875-d0bf-4afa-9940-e10513a83efa	ffffffffffffff	ffffffffffffffffff	50.00	\N	2026-04-20 10:33:00	cerrada	f	0	0.00	2026-04-20 03:31:15.746992	2026-05-06 15:36:39.228571	\N
2e15b71d-42fa-4b35-9f78-c12add655c4d	99856cdf-3124-4a8b-930c-86b9e6087866	Prueba de participantes	Prueba de participantes para poder visualizarlo mas rapido	50.00	100.00	2026-05-24 17:13:00	finalizada	t	1	51.00	2026-05-24 17:11:03.831266	2026-05-24 17:32:25.719837	\N
cba66a72-98f9-4fd5-a1e4-a9411efe5819	9d11f875-d0bf-4afa-9940-e10513a83efa	Prueba segundos tiempo	djjdjdjdjdjdjd	50.00	\N	2026-04-20 06:05:00	cerrada	f	0	0.00	2026-04-20 06:02:01.06588	2026-05-06 15:36:39.228571	\N
3adb74f4-fe7d-4e82-9689-149a4a502123	9d11f875-d0bf-4afa-9940-e10513a83efa	Prueba numero 1 de historial	hahahahahahaha	50.00	\N	2026-04-20 14:26:00	cerrada	f	0	0.00	2026-04-20 14:25:15.319938	2026-05-06 15:36:39.228571	\N
71872968-582d-4196-969d-6d1d8960c49a	37d4b325-2151-4683-8003-c2990c23b6fd	Apuestas universales	aPUESTA PARA PROBAR COSAS DE APUESTAS	50.00	\N	2026-05-27 06:09:00	finalizada	t	1	200.00	2026-05-27 06:06:11.317178	2026-05-27 06:37:36.447923	\N
8d2842a0-83ad-4d2a-8118-406275c72efc	9d11f875-d0bf-4afa-9940-e10513a83efa	Puedo intentar una remontada epica del semestre?	Apesar de la implementacion de la documentacion totalmente erronea puedo carrear esto haciendo el mejor desarrollo de software	100.00	1000.00	2026-05-06 15:22:00	en_revision	t	2	206.00	2026-05-06 15:20:25.793627	2026-05-06 15:48:20.100033	\N
1f96b894-b149-4e62-b944-47b1c2842c55	99856cdf-3124-4a8b-930c-86b9e6087866	Prueba de montos	Prueba de apostar numero minimo	50.00	\N	2026-05-24 17:40:00	cerrada	t	1	50.00	2026-05-24 17:38:30.938852	2026-05-24 17:40:28.460174	\N
ad1e6c2e-eea9-4557-8514-a31b714dcb0d	756529dc-d9a3-418d-b2fd-eeb49737123e	Prueba de ganadores	Sisisisisfefefe	50.00	\N	2026-05-31 00:07:00	finalizada	t	3	400.00	2026-05-31 00:03:03.589647	2026-05-31 00:09:55.982937	\N
6fc076eb-8c6d-497b-bca0-2793c9ef42a6	756529dc-d9a3-418d-b2fd-eeb49737123e	Apuesta Probar Funcionalidad	Funcionalidad de apuesta	50.00	\N	2026-05-30 15:15:00	finalizada	f	2	100.00	2026-05-30 15:12:41.246131	2026-05-30 15:32:24.255457	\N
470403e1-131b-4391-b3b2-34f4e895876f	37d4b325-2151-4683-8003-c2990c23b6fd	Prueba correcta	Prueba para la apuesta	50.00	\N	2026-05-30 22:07:00	cerrada	f	1	50.00	2026-05-27 22:08:14.439952	2026-05-30 22:07:09.659234	\N
e6d7fcab-c5f1-433f-a1b5-43cde0863664	2bed359b-90d4-4251-806b-6076b7c0a1bd	Prueba de resultados	Es una prueba	50.00	100.00	2026-05-06 16:05:00	finalizada	t	3	163.00	2026-05-06 16:02:32.86643	2026-05-06 16:10:02.53694	\N
c791b884-5b5f-45c7-b8f5-b050dff7f019	9d11f875-d0bf-4afa-9940-e10513a83efa	Prueba de 30 segundos	hahahahahahahaha	50.00	\N	2026-04-20 17:44:00	finalizada	f	0	0.00	2026-04-20 03:42:36.080819	2026-05-13 15:20:53.884886	\N
ea9d5938-0ba0-44ed-90c3-96c323ac529e	37d4b325-2151-4683-8003-c2990c23b6fd	Prueba de apuesta ganancias	Prueba de ganancias	50.00	\N	2026-05-25 04:50:00	en_revision	t	1	50.00	2026-05-25 04:44:40.96456	2026-05-30 10:08:54.447372	\N
a20eb344-61d8-46f8-b060-c29a95504ff3	37d4b325-2151-4683-8003-c2990c23b6fd	DSDSDSDS	SDSDSDDSDSDSDSDSDS	50.00	\N	2026-05-25 04:42:00	en_revision	f	0	0.00	2026-05-25 04:40:24.689191	2026-05-30 10:18:56.241688	\N
f23b2994-79ac-46a9-a782-0b46e53a504c	9d11f875-d0bf-4afa-9940-e10513a83efa	gkjghjkg	hththtrthghghg	50.00	\N	2026-04-20 07:32:00	cerrada	f	0	0.00	2026-04-20 07:29:26.433785	2026-05-06 15:36:39.228571	\N
d2893ddb-df50-4d29-b02d-13cc75219f09	9d11f875-d0bf-4afa-9940-e10513a83efa	ffffffffffffffff	fdddddddddddddddddd	50.00	\N	2026-04-20 17:41:00	finalizada	f	0	0.00	2026-04-20 03:40:48.373241	2026-05-13 15:21:00.197088	\N
07c27706-c498-4458-bd2e-b0288cc3bb27	9d11f875-d0bf-4afa-9940-e10513a83efa	¿Quien es la mejor Zoe?	Mejor jugador con el personaje de Zoe de league of legends	60.00	100.00	2026-04-21 04:21:00	finalizada	f	1	80.00	2026-04-20 03:21:22.656751	2026-05-06 15:59:49.212305	\N
512a936c-cd30-4070-a5d4-9e3094266fec	37d4b325-2151-4683-8003-c2990c23b6fd	DDDDDDDDDDDDDD	GHHHHHHHHHHHHHHHH	50.00	\N	2026-05-25 06:28:00	finalizada	f	1	50.00	2026-05-25 06:26:29.580426	2026-05-25 06:28:20.270376	\N
7ccb4865-8353-47ea-973e-b0b4d89ae5b3	9d11f875-d0bf-4afa-9940-e10513a83efa	hghhhhhhhhhhhhhhhhh	hhhhhhhhhhhhhhhh	50.00	\N	2026-04-20 17:07:00	finalizada	f	0	0.00	2026-04-20 04:03:20.166138	2026-05-13 15:32:03.355007	\N
74b70bb3-9ae4-44f8-ad20-3b0df84595d1	99856cdf-3124-4a8b-930c-86b9e6087866	Prueba de dinero	diero dinero	50.00	100.00	2026-05-24 17:37:00	cerrada	f	0	0.00	2026-05-24 17:34:31.543785	2026-05-24 17:37:13.547622	\N
8cff988e-b86c-492d-bc86-cdc408d27c95	2bed359b-90d4-4251-806b-6076b7c0a1bd	Prueba de actualizacion de saldos automaticamente	Prueba de actualizacion de saldos automaticamente	50.00	\N	2026-05-25 06:25:00	finalizada	t	1	50.00	2026-05-25 06:22:13.891076	2026-05-25 06:28:53.371183	\N
d4e7aba6-445c-4b55-8811-de1249dfb9a8	37d4b325-2151-4683-8003-c2990c23b6fd	Prueba Concreta	Sivcvcvcvcvcv	50.00	\N	2026-06-06 22:08:00	activa	t	2	100.00	2026-05-27 22:09:04.009126	2026-05-31 00:09:55.982937	\N
9a7a7d09-be98-4aaa-8063-ae2d31f68cbb	9d11f875-d0bf-4afa-9940-e10513a83efa	¿Quién ganará el partido?	Partido entre equipo A y equipo B	50.00	\N	2026-12-31 23:59:59	activa	t	4	395.00	2026-04-10 08:07:42.195115	2026-05-31 00:09:55.982937	\N
a56972be-883d-4bf1-8b90-07eca9c49986	37d4b325-2151-4683-8003-c2990c23b6fd	Apuesta Prueba reembolso	Reembolso de saldos	50.00	\N	2026-05-30 23:59:00	cancelada	t	2	100.00	2026-05-30 23:54:20.690727	2026-05-30 23:56:11.512837	\N
9bccf277-1e16-44b1-98c1-420f1105e73f	2bed359b-90d4-4251-806b-6076b7c0a1bd	¿Quién ganara la batalla 1 a 1 entre Ricardo y Clemente?	Duelo por doctorado El tigre vs Clementiza	50.00	\N	2026-12-31 23:59:59	activa	t	4	252.00	2026-04-13 16:57:19.174247	2026-05-31 00:09:55.982937	\N
9b42c01d-6056-4214-be85-2d27a5a132b7	99856cdf-3124-4a8b-930c-86b9e6087866	Apuesta prueba Bloqueo	Prueba del bloqueo	50.00	\N	2026-05-24 20:12:00	cerrada	t	1	50.00	2026-05-24 20:08:53.895464	2026-05-24 20:12:00.531461	\N
e0c6154c-eccd-4b47-a7a5-72bd46487fdc	9d11f875-d0bf-4afa-9940-e10513a83efa	Prueba 2 de historial	jdjdjdjdjdjdjd	50.00	\N	2026-04-20 14:28:00	finalizada	f	1	100.00	2026-04-20 14:26:20.06038	2026-05-27 06:46:30.290775	\N
0eee0a0a-4716-4342-af7e-62d5dc4de1a2	2bed359b-90d4-4251-806b-6076b7c0a1bd	Prueba general	Una prueba hecha para la implementacion de diferentes funciones	50.00	\N	2026-05-24 15:35:00	finalizada	t	2	107.00	2026-05-24 15:30:53.464611	2026-05-24 15:51:51.607064	\N
0841b73a-b7e3-4fe2-b00d-9bcc56c0f64d	2bed359b-90d4-4251-806b-6076b7c0a1bd	Visualizacion apuesta	Visualizacion apuesta	50.00	\N	2026-05-25 05:56:00	finalizada	t	2	100.00	2026-05-25 05:54:20.737417	2026-05-25 06:32:30.623015	\N
b975c2c6-d92b-488c-9d9d-d09c4ff5c693	9c4aaf43-8b29-46d4-a410-b7bc8d9dfe81	Joel pasara la materia de TESEBADA?	Joel esta en la cuerda floja para pasar la materia	100.00	\N	2026-04-20 14:02:00	finalizada	t	2	230.00	2026-04-20 13:58:52.229862	2026-05-27 06:49:58.2651	\N
a6db3985-33e0-40ab-a324-19c174c9135a	37d4b325-2151-4683-8003-c2990c23b6fd	Apuesta total pruebas	Prueba de las apuestas en tiempo real	50.00	\N	2026-06-06 06:18:00	cancelada	t	3	150.00	2026-05-27 06:19:11.96453	2026-05-28 01:40:27.037336	\N
\.


--
-- TOC entry 5258 (class 0 OID 25571)
-- Dependencies: 236
-- Data for Name: categorias; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.categorias (id, nombre, descripcion, icono, activa, fecha_creacion) FROM stdin;
6eef4ef1-fcfc-4513-aef1-8afdbd56af77	Deportes	Apuestas deportivas	mdi-soccer	t	2026-05-31 10:57:07.926983
813d1d9a-c9c6-476f-853b-3234c551693c	Académico	Apuestas académicas	mdi-school	t	2026-05-31 10:57:07.926983
4bf6dc58-d986-4403-9c9d-fa1c255247de	Videojuegos	Apuestas de videojuegos	mdi-controller	t	2026-05-31 10:57:07.926983
0a5fbd0f-d41d-4104-affd-cca49a3f5ce1	Entretenimiento	Apuestas de entretenimiento	mdi-movie	t	2026-05-31 10:57:07.926983
f72e8402-bf17-4ec8-8894-1705fa005185	General	Apuestas generales	mdi-tag	t	2026-05-31 10:57:07.926983
\.


--
-- TOC entry 5244 (class 0 OID 17501)
-- Dependencies: 217
-- Data for Name: configuracion_sistema; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.configuracion_sistema (id, clave, valor, descripcion, modificado_por, fecha_modificacion) FROM stdin;
1ed412e8-2ac7-43ce-887a-4e158dfc4282	saldo_bienvenida	500.00	Saldo ficticio asignado al registrarse	\N	2026-03-31 15:21:05.399227
473b96ad-2065-4fec-9019-04523e003bba	comision_retiro	4.00	Porcentaje de comisión por retiro (%)	\N	2026-03-31 15:21:05.399227
0ec3a418-d23d-4eba-be82-7bb572685a23	retiro_minimo	100.00	Monto mínimo para solicitar retiro	\N	2026-03-31 15:21:05.399227
d6d2def1-a73d-4f8f-9539-b3b0ddc91582	max_intentos_login	5	Intentos fallidos antes de bloquear cuenta	\N	2026-03-31 15:21:05.399227
b83f6172-9ba7-440a-9011-1dba50625b11	minutos_bloqueo	30	Minutos de bloqueo por exceso de intentos fallidos	\N	2026-03-31 15:21:05.399227
ddd5a9f7-e81f-4670-8288-d485510de386	segundos_cierre_apuesta	30	Segundos antes del cierre donde se bloquea apostar	\N	2026-03-31 15:21:05.399227
cb7ade65-f497-4bbd-b617-0af4264afa93	max_tam_documento_mb	5	Tamaño máximo del documento de identidad en MB	\N	2026-03-31 15:21:05.399227
44ca5d29-a5df-47cd-b68e-eca43bcd7798	sesion_inactividad_min	30	Minutos de inactividad para cerrar sesión	\N	2026-03-31 15:21:05.399227
e7678869-4083-4329-a9e9-450d5ec70de5	tendencia_top_n	3	Cuántas apuestas se marcan como tendencia	\N	2026-03-31 15:21:05.399227
ea8c9ffe-2c04-4f57-a762-69a79857decf	margen_casa	0.90	Factor de margen de casa para cuotas (0.90 = 10% margen)	\N	2026-03-31 15:21:05.399227
d98b78d4-d080-45d2-b7a5-a67b90ecf9c9	tendencia_min_participantes	3	Mínimo de participantes para ser marcada como tendencia	\N	2026-05-25 05:44:57.55313
\.


--
-- TOC entry 5246 (class 0 OID 17537)
-- Dependencies: 219
-- Data for Name: documentos_identidad; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.documentos_identidad (id, usuario_id, numero_documento, tipo_documento, ruta_archivo, tipo_mime, tamano_bytes, estado, motivo_rechazo, revisado_por, fecha_subida, fecha_revision) FROM stdin;
e9a0fec7-29b6-4a61-84d8-bdde0e9d7010	2bed359b-90d4-4251-806b-6076b7c0a1bd	trtrt44tref	INE	src\\config\\uploads\\1776694407576-776859041.png	image/png	2634826	aprobado	\N	9d11f875-d0bf-4afa-9940-e10513a83efa	2026-04-20 07:13:28.207906	2026-04-20 07:15:13.914555
483cfbd6-da46-4f89-871a-952e2089f620	9d11f875-d0bf-4afa-9940-e10513a83efa	hjghjfghj,fghjkyghjkuy	INE	src\\config\\uploads\\1776695319445-563369960.png	image/png	2634826	aprobado	\N	9d11f875-d0bf-4afa-9940-e10513a83efa	2026-04-20 07:28:39.953204	2026-04-20 07:28:53.306164
013af870-90d2-424f-97b3-70e2252bfca7	9c4aaf43-8b29-46d4-a410-b7bc8d9dfe81	oiopióújl	INE	src\\config\\uploads\\1776718642765-679886276.png	image/png	2634826	aprobado	\N	9d11f875-d0bf-4afa-9940-e10513a83efa	2026-04-20 13:57:22.970347	2026-04-20 13:57:44.160872
607511ce-c1ff-4535-a679-64d278ba3a96	99856cdf-3124-4a8b-930c-86b9e6087866	jdoaoid	INE	src\\config\\uploads\\1776722693321-524717124.png	image/png	2634826	aprobado	\N	9d11f875-d0bf-4afa-9940-e10513a83efa	2026-04-20 15:04:53.412154	2026-04-20 15:06:32.340671
ba834240-1b98-4565-bd7b-b03d2b75754d	37d4b325-2151-4683-8003-c2990c23b6fd	TEST123456	INE	src\\config\\uploads\\1779708035358-736775601.png	image/png	2113832	aprobado	\N	9d11f875-d0bf-4afa-9940-e10513a83efa	2026-05-25 04:20:35.745488	2026-05-25 04:23:46.641257
0b108710-211d-4dab-bc6a-1ec226608953	756529dc-d9a3-418d-b2fd-eeb49737123e	TEST1234567	INE	src\\config\\uploads\\1779946070267-167935669.png	image/png	2186960	aprobado	\N	9d11f875-d0bf-4afa-9940-e10513a83efa	2026-05-27 22:27:50.677304	2026-05-27 22:28:28.465825
d0dfa7e0-65da-4c4f-9889-48e1bdabe23c	212415cd-d7c7-4dab-97bd-d94bfd7d7ff0	987654321	INE	src\\config\\uploads\\1779954951242-691819855.png	image/png	2186960	aprobado	\N	9d11f875-d0bf-4afa-9940-e10513a83efa	2026-05-28 00:55:51.393667	2026-05-28 00:58:22.556188
572b5e4c-1454-4f75-a4ef-cf400154d14f	c83ee6d7-d883-421d-a68b-6f8ac5838c6c	fdsfsdfsdfs	INE	src\\config\\uploads\\1779955168423-519607005.png	image/png	2186960	rechazado	No le sabes	9d11f875-d0bf-4afa-9940-e10513a83efa	2026-05-28 00:59:28.553179	2026-05-28 01:00:23.982997
77365481-292f-4086-aa5d-632ed2d93e5b	d546048a-a343-4865-9123-ce49208cd45a	gffgfgdhdfhdgd	INE	src\\config\\uploads\\1780187137608-770286230.png	image/png	2113832	rechazado	La cuenta no ha sido aceptada por motivos legales, verifique con su banco	9d11f875-d0bf-4afa-9940-e10513a83efa	2026-05-30 17:25:37.830762	2026-05-30 17:28:25.59772
\.


--
-- TOC entry 5256 (class 0 OID 17769)
-- Dependencies: 229
-- Data for Name: intentos_fraude; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.intentos_fraude (id, usuario_id, tipo, descripcion, ip_address, dato_sospechoso, revisado, revisado_por, fecha) FROM stdin;
903a2300-4689-47c8-abf2-764eb1796f36	9c4aaf43-8b29-46d4-a410-b7bc8d9dfe81	multiples_intentos_login	Cuenta bloqueada tras 5 intentos fallidos consecutivos.	::1	\N	f	\N	2026-04-20 14:49:25.619501
93184fce-776d-4dcb-b2f9-89783239d0c3	9d11f875-d0bf-4afa-9940-e10513a83efa	multiples_intentos_login	Cuenta bloqueada tras 5 intentos fallidos consecutivos.	::1	\N	f	\N	2026-05-24 20:53:42.275438
43345ab9-63d4-48eb-90b4-55f4b6dbe172	c83ee6d7-d883-421d-a68b-6f8ac5838c6c	documento_duplicado	Intento de registrar documento de identidad ya existente	\N	\N	f	\N	2026-05-27 22:50:38.129601
2add4ba7-0952-4763-b2cc-e59458c12d3f	c83ee6d7-d883-421d-a68b-6f8ac5838c6c	documento_duplicado	Intento de registrar documento de identidad ya existente	\N	\N	f	\N	2026-05-27 22:55:03.416627
7efde887-5850-4832-aaca-0afe0bf8a82c	c83ee6d7-d883-421d-a68b-6f8ac5838c6c	documento_duplicado	Intento de registrar documento de identidad ya existente	\N	\N	f	\N	2026-05-27 22:57:14.5038
2dccf446-71b7-4f6b-8448-0298b6cb3025	2bed359b-90d4-4251-806b-6076b7c0a1bd	multiples_intentos_login	Cuenta bloqueada tras 5 intentos fallidos consecutivos.	::1	\N	f	\N	2026-05-31 00:42:33.67694
\.


--
-- TOC entry 5255 (class 0 OID 17751)
-- Dependencies: 228
-- Data for Name: intentos_login; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.intentos_login (id, usuario_id, correo_intento, ip_address, user_agent, exitoso, fecha) FROM stdin;
8f7c023e-78b6-48d0-a01c-c368d482692c	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::ffff:127.0.0.1	Thunder Client (https://www.thunderclient.com)	t	2026-04-10 01:52:12.759864
800368ab-7d7d-40c2-bc3a-f9cf3e28fc98	3f507fb0-512f-4b63-b5b7-7950c5d1d2d2	\N	::ffff:127.0.0.1	Thunder Client (https://www.thunderclient.com)	t	2026-04-10 02:42:08.539157
e93989fc-ef53-46fc-80ba-524c9e91a628	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::ffff:127.0.0.1	Thunder Client (https://www.thunderclient.com)	t	2026-04-10 07:47:40.486414
ad08663f-e89f-46f8-946c-351b33d2b281	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::ffff:127.0.0.1	Thunder Client (https://www.thunderclient.com)	t	2026-04-10 07:50:44.390152
7ef86387-fd31-49bf-86d8-34b8c611914b	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::ffff:127.0.0.1	Thunder Client (https://www.thunderclient.com)	t	2026-04-10 07:52:45.452396
8d1f1d55-c27d-4f47-890d-5cbbd82cdf9b	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::ffff:127.0.0.1	axios/1.14.0	t	2026-04-11 15:38:24.306828
3d7c62b1-a21a-4620-8447-79a45651d277	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::ffff:127.0.0.1	axios/1.14.0	t	2026-04-11 15:43:47.093792
69c5c059-07b7-43b4-8d96-8602f0a41342	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::ffff:127.0.0.1	axios/1.14.0	t	2026-04-11 16:49:32.637879
68781ec2-844b-4387-96cd-ded7c95a0627	2bed359b-90d4-4251-806b-6076b7c0a1bd	\N	::ffff:127.0.0.1	axios/1.14.0	t	2026-04-13 16:36:13.157019
c009b499-e373-4aab-bf28-979f26f386a8	2bed359b-90d4-4251-806b-6076b7c0a1bd	\N	::ffff:127.0.0.1	axios/1.14.0	f	2026-04-13 16:39:11.40938
4225a3f8-f06b-40ce-ba07-30672ad12276	2bed359b-90d4-4251-806b-6076b7c0a1bd	\N	::ffff:127.0.0.1	axios/1.14.0	t	2026-04-13 16:39:18.82795
dfcdf53a-38f2-4cdf-aecf-ddf9a8be1656	2bed359b-90d4-4251-806b-6076b7c0a1bd	\N	::ffff:127.0.0.1	axios/1.14.0	t	2026-04-13 16:50:04.532219
5a8b9c81-4778-4405-92f5-fb58a6896866	2bed359b-90d4-4251-806b-6076b7c0a1bd	\N	::ffff:127.0.0.1	axios/1.14.0	f	2026-04-13 17:04:04.791039
41e408ad-c256-4c6a-b540-b192b1b4a3c5	2bed359b-90d4-4251-806b-6076b7c0a1bd	\N	::ffff:127.0.0.1	axios/1.14.0	t	2026-04-13 17:05:00.910874
37825d30-bf86-48d6-81d5-92655b568704	3f507fb0-512f-4b63-b5b7-7950c5d1d2d2	\N	::ffff:127.0.0.1	axios/1.15.0	t	2026-04-19 15:25:27.87993
d74012be-cde1-4753-9e00-7ddc24e60cbe	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-20 01:12:48.603123
21334b42-6db9-4fd1-9e73-d8d3d6f3b0c5	fec57d62-02cc-413d-a720-ac4be0506a7d	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	f	2026-04-20 01:26:54.248232
903a0041-5626-4646-abbf-ef208e481956	fec57d62-02cc-413d-a720-ac4be0506a7d	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-20 01:27:08.606851
45eca786-1e85-40c8-9d96-4695a5b8f410	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-20 01:47:32.259949
859fc959-fba2-4eb7-8939-38a0dde34cb7	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-20 02:54:18.230966
cd34fdae-625c-4ad3-b603-145c721defbe	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-20 02:59:17.529222
9e363b1c-b43f-4d58-8ebc-8c8372e28225	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-20 03:53:26.707374
75b43b2f-2aed-40b2-ab39-d4276b151726	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-20 04:33:57.221925
1deae8ac-864c-4d53-b949-e032539f51dc	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-20 04:40:21.120269
4f25f302-cd14-441c-87b0-09f82e62102e	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-20 04:46:33.266532
42e1d899-82fe-4458-b893-d729ecc9dc7c	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-20 04:50:26.90781
b6c0d9fd-ba49-441c-98b4-51aaccf75460	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-20 04:53:23.857002
10d8b267-a087-404f-9eca-1d8fd75cb1ca	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-20 05:52:52.095937
730099b9-d7ad-484a-b376-f63931e1480d	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-20 06:24:12.380793
7cf47f25-e13e-49eb-8f8b-5e86ebf9f500	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-20 06:51:45.439586
2268838e-c0b9-46ce-b36f-cf90f750a7ab	2bed359b-90d4-4251-806b-6076b7c0a1bd	\N	::ffff:127.0.0.1	axios/1.15.0	t	2026-04-20 06:55:09.323235
d7a3e9c9-919f-4388-bf89-6e1b3b2bfaf6	2bed359b-90d4-4251-806b-6076b7c0a1bd	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-20 06:55:33.472545
930d45fd-657d-4c45-b097-2af212db6f3f	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-20 06:58:44.796104
ba05ac15-8df9-4a8a-b4f7-f576a03457df	2bed359b-90d4-4251-806b-6076b7c0a1bd	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	f	2026-04-20 07:05:49.288776
7961a068-1a0a-4a14-90e1-253c5e1831d3	2bed359b-90d4-4251-806b-6076b7c0a1bd	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-20 07:06:03.71601
b57cf803-0695-401c-a7cc-c164539abf94	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-20 07:14:08.172871
9391c9ce-b400-4556-a619-0bfa599f92d2	2bed359b-90d4-4251-806b-6076b7c0a1bd	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	f	2026-04-20 07:15:55.631142
42a5103e-a00e-4740-84a6-29f705a3048d	2bed359b-90d4-4251-806b-6076b7c0a1bd	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-20 07:16:23.804825
ddf6f0aa-c888-4e95-8a7d-5430f4742e3d	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-20 07:28:14.732552
e067ab89-0a10-4642-bc49-c209de57135d	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-20 13:47:34.726171
4ae21161-3bbc-4547-87bc-a181dc6c55de	9c4aaf43-8b29-46d4-a410-b7bc8d9dfe81	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-20 13:50:32.710667
c0b59d82-9ce2-4dfd-844a-14b8c9a9761d	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-20 13:53:28.851343
e33a742d-8497-4c58-a4e5-4c336ae6da50	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-20 13:54:14.263376
41d34c5d-f677-4379-b5d4-8a6052e21924	9c4aaf43-8b29-46d4-a410-b7bc8d9dfe81	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-20 13:55:18.085154
e79f7410-685b-408c-8e3e-99ee9eedf90b	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-20 13:57:33.703659
b6a0cabb-277b-4d8d-95dc-5bb3c4a20891	9c4aaf43-8b29-46d4-a410-b7bc8d9dfe81	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-20 13:57:55.44323
a917627f-8bf8-4479-bf40-f2f4bb5f7078	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-20 14:00:09.827028
254bb7f6-2a88-474d-bfdd-9be5b6a62b1d	2bed359b-90d4-4251-806b-6076b7c0a1bd	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	f	2026-04-20 14:00:49.24705
f540c77e-34d0-4794-898b-30770560601a	2bed359b-90d4-4251-806b-6076b7c0a1bd	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	f	2026-04-20 14:00:56.886783
60908e6a-6a6b-496e-a9e4-277fd8114847	2bed359b-90d4-4251-806b-6076b7c0a1bd	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-20 14:01:00.34911
6a7f55a9-c6ad-4ad3-8205-b6dd9dd71777	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-20 14:24:18.095715
f591089f-7b1f-46e8-aad7-89070aa635aa	9c4aaf43-8b29-46d4-a410-b7bc8d9dfe81	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-20 14:25:29.876539
7cd66fa5-2a00-4820-8125-65b59537ac6c	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-20 14:25:42.458955
f55dcfb4-9927-49e7-9367-e228a70bdc1d	9c4aaf43-8b29-46d4-a410-b7bc8d9dfe81	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-20 14:26:33.567655
c8518f9a-dfb3-482c-99e0-888026fc1546	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-20 14:27:04.453671
c627b857-1caa-4485-a72c-e60f35e52ea9	9c4aaf43-8b29-46d4-a410-b7bc8d9dfe81	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-20 14:29:10.511354
0815f2bd-8eea-4181-b782-1e641b23b3b4	9c4aaf43-8b29-46d4-a410-b7bc8d9dfe81	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	f	2026-04-20 14:49:22.707329
85329456-0875-4dbc-a7a6-b3ce53bc21f2	9c4aaf43-8b29-46d4-a410-b7bc8d9dfe81	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	f	2026-04-20 14:49:23.928832
15b7f76b-6f24-4c16-8976-2db9a4d3dab2	9c4aaf43-8b29-46d4-a410-b7bc8d9dfe81	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	f	2026-04-20 14:49:24.686804
e40ba728-1ee7-4b35-9848-14badaa3ce45	9c4aaf43-8b29-46d4-a410-b7bc8d9dfe81	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	f	2026-04-20 14:49:25.189579
2481cd37-d899-440a-9388-4cc501ec8f6b	9c4aaf43-8b29-46d4-a410-b7bc8d9dfe81	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	f	2026-04-20 14:49:25.619501
cbe86e40-f93f-493a-8bbb-dd4c6c58b5d0	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-20 14:56:51.718622
90aaae43-d62e-44fb-9151-4e18c0fbc115	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-20 14:59:07.881351
e73ac291-e020-4126-9908-6e406adf5e61	99856cdf-3124-4a8b-930c-86b9e6087866	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-20 15:03:28.77502
5ecc7f3e-45a8-4e29-88c2-7ebc8daddd38	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-20 15:05:54.815202
73687c06-934f-4fab-b230-0d9f28ff0a52	99856cdf-3124-4a8b-930c-86b9e6087866	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-20 15:07:12.858248
900b3895-4764-4e10-802a-820e0c3583c9	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-23 10:30:43.337013
72911437-26ac-4739-8556-1cf2664fae42	9c4aaf43-8b29-46d4-a410-b7bc8d9dfe81	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-23 10:40:04.024288
f4345f20-83c4-4503-b278-896bf6b8e51d	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-23 10:40:30.178347
ec9e7de2-4a2d-4f11-9678-7654f5e86030	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-05-06 13:07:04.448333
979d2c73-be10-4417-aee7-881f6b2725ae	9c4aaf43-8b29-46d4-a410-b7bc8d9dfe81	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-05-06 13:09:45.184642
8c33b79b-743c-4810-afc3-250f60e71ce6	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-05-06 14:06:24.449364
39fc4427-12d2-4acb-a266-249f662735ab	9c4aaf43-8b29-46d4-a410-b7bc8d9dfe81	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-05-06 14:21:43.596383
4765b1cd-6572-417a-9a8e-fef521026fb3	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-05-06 14:39:18.929301
29741838-1507-488e-99ef-aa9b6e04932d	9c4aaf43-8b29-46d4-a410-b7bc8d9dfe81	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-05-06 15:17:45.796462
7ff47c71-816f-4121-9b59-3131b35fed24	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-05-06 15:18:03.728463
2a13fe04-510a-4e4b-848a-81efcec5e4f9	9c4aaf43-8b29-46d4-a410-b7bc8d9dfe81	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-05-06 15:20:54.30795
8db55868-1056-484a-ad5a-5414da936e2c	2bed359b-90d4-4251-806b-6076b7c0a1bd	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-05-06 15:21:15.60017
8aab4aa0-cdf5-4b19-8d97-f580fa16ae54	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-05-06 15:27:17.550373
8fccac93-e4cf-48c2-9019-0f538cf6befc	9c4aaf43-8b29-46d4-a410-b7bc8d9dfe81	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-05-06 16:00:34.470072
fc34c029-c2ba-459b-aeba-289166781090	2bed359b-90d4-4251-806b-6076b7c0a1bd	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-05-06 16:02:05.070125
faa75479-559c-441b-bcce-7cda31346124	99856cdf-3124-4a8b-930c-86b9e6087866	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-05-06 16:02:52.903618
b5f93703-0d88-44d2-9f49-06672868ddaa	9c4aaf43-8b29-46d4-a410-b7bc8d9dfe81	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-05-06 16:03:18.381458
69841f79-b395-406f-90af-5eea2d72b354	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-05-06 16:03:56.245242
bbd4503c-64b3-4ef3-8fd5-cc7834fbe6c5	2bed359b-90d4-4251-806b-6076b7c0a1bd	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-05-06 16:04:23.886336
714976a1-90fe-4c52-af00-b210a7d2b545	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-05-06 16:05:15.603294
19851367-b957-44ce-80f5-fbbdf210292d	2bed359b-90d4-4251-806b-6076b7c0a1bd	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-05-06 16:11:20.647603
8946e205-063f-49da-86d9-d00462072fcd	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-05-06 16:11:59.611361
4d6f2bc5-df29-4732-819e-7363a8ae27b4	2bed359b-90d4-4251-806b-6076b7c0a1bd	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-05-06 16:13:16.676807
7f691095-9a62-4a6a-ba09-f960f2e63877	99856cdf-3124-4a8b-930c-86b9e6087866	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-05-06 16:13:46.860722
9ef4561b-6be5-4532-9726-c21b0dd6cfd9	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-13 15:18:36.860764
723a7049-3612-4836-8da0-fe7c12e7d7fd	9c4aaf43-8b29-46d4-a410-b7bc8d9dfe81	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-13 15:23:50.717437
4470c917-4293-492c-baa0-0fc94d57b31d	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-13 15:31:02.313634
79d3a58b-c2f0-415b-813d-94728ba5a22b	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-23 20:18:00.544238
5cd25d53-6618-493c-b33a-9d0a9fe0dd59	9c4aaf43-8b29-46d4-a410-b7bc8d9dfe81	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-24 06:55:31.450611
650830bf-62f1-4895-8403-48c45b97e23f	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-24 07:46:11.889147
1597ebe2-3d2d-4afa-b65c-ca5d3a804587	9c4aaf43-8b29-46d4-a410-b7bc8d9dfe81	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-24 07:55:04.447238
866b01d0-6789-45d0-aea1-2f67b525a807	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-24 11:17:44.628636
a3b178a7-97fd-4980-95d3-5c8737f4792b	9c4aaf43-8b29-46d4-a410-b7bc8d9dfe81	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-24 15:21:28.003663
773567e9-d6ff-44ff-90e1-23ee5e873491	99856cdf-3124-4a8b-930c-86b9e6087866	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-24 15:28:06.117543
a795ab6b-eac8-466f-a087-6b77796a8697	2bed359b-90d4-4251-806b-6076b7c0a1bd	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-24 15:29:18.320484
2b3bb073-85da-4f7a-b81c-b20148277162	99856cdf-3124-4a8b-930c-86b9e6087866	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-24 15:32:22.387493
32c0af60-b29c-4b76-bcc8-7fe850c16f7d	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-24 15:38:51.442872
dea294c1-8c90-4164-915c-de8d89618f9e	9c4aaf43-8b29-46d4-a410-b7bc8d9dfe81	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-24 15:57:49.987874
3c362d7a-618e-4d77-a463-66d4ad76a425	99856cdf-3124-4a8b-930c-86b9e6087866	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-24 15:57:56.660438
6f983b81-3b23-4547-9cb4-380526825e5a	2bed359b-90d4-4251-806b-6076b7c0a1bd	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-24 16:03:07.363846
122923af-3077-4180-983a-a89009f2a3ed	216dafa9-5f81-4bac-8880-9186725d4657	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-24 16:36:54.998451
1701a12b-cfb3-472a-8233-1e3d5323c669	2bed359b-90d4-4251-806b-6076b7c0a1bd	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-24 16:42:36.595067
136536f6-078e-4c87-8f63-8495bb698a6f	99856cdf-3124-4a8b-930c-86b9e6087866	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-24 16:43:09.864178
bf3468f1-4bd6-4db2-a479-14b30bd31610	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-24 17:21:45.057968
5d176b52-c399-4387-bee3-7edd860e21be	99856cdf-3124-4a8b-930c-86b9e6087866	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-24 17:32:14.064808
f92ddafa-48f2-4658-bada-f96e0248a7e0	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	PostmanRuntime/7.54.0	f	2026-05-24 20:53:34.620655
04a03866-7a9b-46be-a584-3848aaaab33c	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	PostmanRuntime/7.54.0	f	2026-05-24 20:53:38.625995
783bb16b-d1b3-42e4-bfcc-60a91a6f58d3	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	PostmanRuntime/7.54.0	f	2026-05-24 20:53:39.880906
f4de526e-4ea9-4e13-b103-274a67bff5e4	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	PostmanRuntime/7.54.0	f	2026-05-24 20:53:41.001055
47ee4fb5-774f-4594-a145-842846969c8c	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	PostmanRuntime/7.54.0	f	2026-05-24 20:53:42.275438
714d5c64-77b3-4d72-9744-e87915fd34ca	2bed359b-90d4-4251-806b-6076b7c0a1bd	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-24 20:58:58.75269
84799ae4-0502-49ca-a952-ed779c472796	d546048a-a343-4865-9123-ce49208cd45a	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-24 21:06:02.401288
77d642a7-6916-43e8-9fbe-f9fabd5f9348	2bed359b-90d4-4251-806b-6076b7c0a1bd	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-24 21:07:41.728233
148b607a-9afa-4c10-9650-85e2c689f21c	37d4b325-2151-4683-8003-c2990c23b6fd	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-25 04:15:13.536817
3b9d2fe1-2e10-4b33-91b8-a2e2985a6f9d	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-25 04:21:48.499281
0407d4f5-2b32-4cb9-9c87-09212df07af5	37d4b325-2151-4683-8003-c2990c23b6fd	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-25 04:26:02.574446
6fd3b4fe-c691-43ef-8c56-d347588dd98e	d546048a-a343-4865-9123-ce49208cd45a	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-25 04:46:52.790212
50be987f-e3ab-4c7a-ad5e-4e296e52099e	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-25 04:49:06.334235
d0e25743-98b1-4f45-96e3-ddf3ef8458f5	d546048a-a343-4865-9123-ce49208cd45a	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-25 04:51:54.536428
6d3d40c2-5b0a-4078-85e3-0cf47148d5c6	2bed359b-90d4-4251-806b-6076b7c0a1bd	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-25 04:58:34.600706
fe9c4373-a8d1-440d-ab74-36a64b2c69cd	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-25 04:59:09.958672
44219d32-1c34-471b-8b19-14fbf2325712	37d4b325-2151-4683-8003-c2990c23b6fd	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-25 05:31:35.845877
d6d5e20d-a6b9-4ee7-86cc-98384cdd2f5b	d546048a-a343-4865-9123-ce49208cd45a	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-25 06:06:50.534
5bcbec9d-8121-4e9c-9e6b-a4a61558062b	37d4b325-2151-4683-8003-c2990c23b6fd	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-25 06:09:13.882581
d332cc82-746a-4848-8b65-9dd0170b6b11	2bed359b-90d4-4251-806b-6076b7c0a1bd	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-25 06:20:13.593471
707081ee-d71b-487e-bc33-1af5a9f7f456	37d4b325-2151-4683-8003-c2990c23b6fd	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-25 06:22:38.487438
d039d338-e1fa-40d1-9c61-b1d88b54a53f	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-25 06:28:04.614071
d2382067-0f49-4277-ba38-de4f69ffdf9c	37d4b325-2151-4683-8003-c2990c23b6fd	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-25 06:29:20.5579
a1106dc1-9250-40ed-9757-0980046c4a27	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-25 06:31:53.577178
f761e452-9e69-4885-b878-09e58fb2a4d3	37d4b325-2151-4683-8003-c2990c23b6fd	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-25 06:32:55.604693
331a8c87-a98b-4de4-9d7f-82d5ced27d83	2bed359b-90d4-4251-806b-6076b7c0a1bd	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-27 06:34:30.933687
0d504e7c-6d6a-4ae1-a0f2-5361bb2876c0	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-27 06:37:19.72228
2c76b471-1cc0-48b7-bf54-77c27e1fd1d5	9c4aaf43-8b29-46d4-a410-b7bc8d9dfe81	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-27 06:46:11.105014
f987db2f-d294-4803-bcd8-d0aa5e68cf66	37d4b325-2151-4683-8003-c2990c23b6fd	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-27 21:29:38.736935
07d28a4e-a84b-4257-b5e8-339c7075b1e5	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-27 21:29:45.39387
1db49f68-7750-415b-9242-c400526c6b93	d546048a-a343-4865-9123-ce49208cd45a	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-27 21:55:27.890966
4e7dae83-caee-4f05-ba19-9dd7152b65fa	37d4b325-2151-4683-8003-c2990c23b6fd	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-27 22:05:48.977029
741c2260-ec28-4a59-a7fd-f806286c9d15	756529dc-d9a3-418d-b2fd-eeb49737123e	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-27 22:16:22.270642
01b31517-f1a4-410d-b246-f4a86bea8254	756529dc-d9a3-418d-b2fd-eeb49737123e	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-27 22:32:07.558344
c98b1cd7-cad8-42ea-90ed-f815c8edd494	c83ee6d7-d883-421d-a68b-6f8ac5838c6c	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-27 22:36:39.876361
638417b5-c17d-4f17-afb6-da78209e1134	37d4b325-2151-4683-8003-c2990c23b6fd	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-27 23:01:34.343351
0c8bef74-bc54-478e-b01a-ee456af62ef0	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-27 23:49:22.218423
f066f9b2-b9b5-4611-9474-d0d73f2d1fbe	c83ee6d7-d883-421d-a68b-6f8ac5838c6c	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-27 23:51:48.146146
b0482d0d-7ae2-4706-9058-05abdbb33456	c83ee6d7-d883-421d-a68b-6f8ac5838c6c	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-27 23:54:16.057943
70c55d41-55ef-402a-b8cc-276120e721a2	756529dc-d9a3-418d-b2fd-eeb49737123e	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-28 00:14:25.549472
4af26d55-b4f4-4c99-a054-874649f3f023	756529dc-d9a3-418d-b2fd-eeb49737123e	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-28 00:32:39.183765
693adf7e-7129-4454-b8e2-3460b604d06d	756529dc-d9a3-418d-b2fd-eeb49737123e	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-28 00:36:31.986281
b0eadcac-1bd3-4325-a8d0-078a0216d89a	756529dc-d9a3-418d-b2fd-eeb49737123e	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-28 00:38:12.203575
102eeba2-168c-4872-af8b-d027e004b481	756529dc-d9a3-418d-b2fd-eeb49737123e	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-28 00:49:08.906992
4d1f1d98-eee8-48a5-b226-7fc4c1d76233	212415cd-d7c7-4dab-97bd-d94bfd7d7ff0	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-28 00:55:16.938589
005d9d4c-fd45-42d3-bbb5-00c09df16ff9	c83ee6d7-d883-421d-a68b-6f8ac5838c6c	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-28 00:59:12.327969
43aed04c-5954-4640-a4d5-19d5dfa48ed0	756529dc-d9a3-418d-b2fd-eeb49737123e	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-28 01:05:29.617325
5ddfd1d6-41d6-436a-8833-3cd135c43294	212415cd-d7c7-4dab-97bd-d94bfd7d7ff0	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-28 01:06:14.38626
3085e4d7-027e-4522-b9b0-b974ec2e39d1	37d4b325-2151-4683-8003-c2990c23b6fd	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-28 01:11:09.445688
b41f5243-9d55-4ce4-be8e-41673666bc5f	756529dc-d9a3-418d-b2fd-eeb49737123e	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-28 01:13:44.508608
66bbf6d4-da26-4f82-96d0-8789a06bfc4a	212415cd-d7c7-4dab-97bd-d94bfd7d7ff0	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-28 01:13:52.580223
97597267-69d1-4996-a760-4d172be0b3fb	c83ee6d7-d883-421d-a68b-6f8ac5838c6c	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-28 01:14:04.986255
22b95c6a-d40e-477b-8702-b7abef8b72ad	37d4b325-2151-4683-8003-c2990c23b6fd	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-28 01:30:00.586343
741e8211-8cea-4454-bbb4-0e88a57d392a	756529dc-d9a3-418d-b2fd-eeb49737123e	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-28 01:33:54.225804
a6cb707b-8d71-4cdb-826a-e5263c4ab546	37d4b325-2151-4683-8003-c2990c23b6fd	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-28 01:39:12.246161
7c689b16-fdad-410d-813f-569c7ef9518e	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-29 08:55:43.90936
59009068-da73-4128-829a-8910f79c8acb	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-30 08:11:59.365448
1d4334c9-645b-4221-8da5-4a9ea0506315	756529dc-d9a3-418d-b2fd-eeb49737123e	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-30 15:11:31.09116
7aae8358-3631-42dc-b931-de0837790886	37d4b325-2151-4683-8003-c2990c23b6fd	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-30 15:13:35.02917
eab58a33-8df9-4332-b4fd-d2731d130c65	756529dc-d9a3-418d-b2fd-eeb49737123e	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-30 15:15:36.553031
b4168629-f64c-4bb0-baa5-91f1f2831299	d546048a-a343-4865-9123-ce49208cd45a	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-30 17:24:15.04748
5f9963da-3e42-4867-879a-804264da537b	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-30 17:26:01.874087
fdaff498-8d74-4751-a06a-c95069ce5d2c	d546048a-a343-4865-9123-ce49208cd45a	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-30 17:28:41.862815
9a55eba6-347d-4fd1-a57e-6e373532c246	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-30 17:29:12.588799
38691002-0131-4689-ad85-cb19f3706f02	37d4b325-2151-4683-8003-c2990c23b6fd	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-30 23:53:12.878626
42ecab61-6bed-4948-af59-bb9d021264b5	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-31 00:01:28.571067
9a88e565-b263-490b-b0f5-31df36620128	37d4b325-2151-4683-8003-c2990c23b6fd	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-31 00:03:31.536099
2e047bfe-f6f1-4807-8f81-4f63d3ab6a6b	212415cd-d7c7-4dab-97bd-d94bfd7d7ff0	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-31 00:04:40.356899
6abd7a35-7f0d-4545-ab52-3c542971d4e4	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-31 00:05:34.208361
86c46867-189b-4e69-914e-32aefb9147c0	212415cd-d7c7-4dab-97bd-d94bfd7d7ff0	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-31 00:11:08.790134
386b114f-3d0e-4895-a921-edee07921b51	37d4b325-2151-4683-8003-c2990c23b6fd	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-31 00:12:04.72432
348b7d3f-9930-4890-9534-8e7a5a02b921	212415cd-d7c7-4dab-97bd-d94bfd7d7ff0	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-31 00:17:46.792843
574f30a9-0102-4af6-9d81-25869bbc49a4	2bed359b-90d4-4251-806b-6076b7c0a1bd	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-31 00:41:25.239925
aebbb441-f2e7-439a-84c9-b03e2431d477	2bed359b-90d4-4251-806b-6076b7c0a1bd	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	f	2026-05-31 00:41:38.99181
ccb6f250-09d1-4a22-9139-4a242b080685	2bed359b-90d4-4251-806b-6076b7c0a1bd	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	f	2026-05-31 00:41:59.045952
9b6d80bb-4057-4dc8-a749-f7f0c9105e43	2bed359b-90d4-4251-806b-6076b7c0a1bd	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	f	2026-05-31 00:42:13.236266
60586d73-eb68-4fbe-9de3-af1d1f2ff2da	2bed359b-90d4-4251-806b-6076b7c0a1bd	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	f	2026-05-31 00:42:24.417903
184b3043-69a6-4b7d-a302-84123cdc9492	2bed359b-90d4-4251-806b-6076b7c0a1bd	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	f	2026-05-31 00:42:33.67694
a8cc485b-6498-4ff0-b7df-5a71e4540acf	756529dc-d9a3-418d-b2fd-eeb49737123e	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-31 00:52:55.259917
2caec207-4e67-44fb-b6ea-e8a0120d0627	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-31 07:38:44.409672
fc26b742-f09d-4e1b-b463-7327a651551f	756529dc-d9a3-418d-b2fd-eeb49737123e	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-31 07:39:40.665055
00e8d667-af2c-4f1e-84f8-c3ea39152e76	756529dc-d9a3-418d-b2fd-eeb49737123e	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-31 07:40:05.53615
29f37833-6f1d-480b-a0b9-c3f69e0d8d64	756529dc-d9a3-418d-b2fd-eeb49737123e	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-31 08:34:11.68829
f0cc5bed-710f-4266-95e5-2c7e88b4d8d1	756529dc-d9a3-418d-b2fd-eeb49737123e	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-31 10:45:37.944986
94f90780-d219-4453-b15b-656037160e21	37d4b325-2151-4683-8003-c2990c23b6fd	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-31 10:45:46.414517
c20d3a14-a875-418b-b9e8-bc227d7cd8c2	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-31 10:46:36.09615
ece44c6a-4c68-40d2-99bf-49cf616e4a2e	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-31 10:50:33.804496
9c6841d0-77ad-4ca2-bf82-a666fc9c8d3b	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-31 10:50:44.162255
52b72648-9b90-47ba-bc62-f17477119620	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-31 10:51:19.472207
c7244de7-f97e-4bd2-8a27-0d8192d524ad	212415cd-d7c7-4dab-97bd-d94bfd7d7ff0	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-31 10:51:35.797596
0bfe43d1-d3df-47a8-ad13-c4dbf0bbc428	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-31 10:52:23.145916
0b2d767b-e0a9-4847-af2c-6611a2e70433	212415cd-d7c7-4dab-97bd-d94bfd7d7ff0	\N	::ffff:127.0.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	t	2026-05-31 10:52:29.647022
\.


--
-- TOC entry 5257 (class 0 OID 25542)
-- Dependencies: 235
-- Data for Name: logs_admin; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.logs_admin (id, admin_id, usuario_id, accion, motivo, fecha) FROM stdin;
64a3e912-b625-4331-8bac-4b937951ffcc	9d11f875-d0bf-4afa-9940-e10513a83efa	c83ee6d7-d883-421d-a68b-6f8ac5838c6c	suspender	Subio documentos ya registrados en la app	2026-05-27 23:50:16.123912
0e618408-58c2-4b24-86a6-0660667471cd	9d11f875-d0bf-4afa-9940-e10513a83efa	c83ee6d7-d883-421d-a68b-6f8ac5838c6c	activar	Has cumplido tu status	2026-05-27 23:53:46.119421
23abaf7e-c380-4fa6-8215-dc24f9070ebc	9d11f875-d0bf-4afa-9940-e10513a83efa	c83ee6d7-d883-421d-a68b-6f8ac5838c6c	activar	cvcvc	2026-05-28 00:06:54.083267
df5efe72-7e89-472c-ba18-0cb0ebf05c6d	9d11f875-d0bf-4afa-9940-e10513a83efa	756529dc-d9a3-418d-b2fd-eeb49737123e	suspender	Falta de compromiso	2026-05-28 00:17:51.398217
7ba14678-2991-4332-8b85-32f22d22d1f0	9d11f875-d0bf-4afa-9940-e10513a83efa	756529dc-d9a3-418d-b2fd-eeb49737123e	activar	Aprobado\n	2026-05-28 00:32:32.570314
eaa2ce8b-b8aa-4f01-944b-9a2133222d90	9d11f875-d0bf-4afa-9940-e10513a83efa	756529dc-d9a3-418d-b2fd-eeb49737123e	suspender	Atras prro	2026-05-28 00:32:59.933498
70cb48c8-c43b-4344-9177-ccee1659d489	9d11f875-d0bf-4afa-9940-e10513a83efa	756529dc-d9a3-418d-b2fd-eeb49737123e	activar	vfvfvf	2026-05-28 00:36:28.698841
abbee5d7-a95d-4cf3-bd0f-3b48c5dd6d69	9d11f875-d0bf-4afa-9940-e10513a83efa	756529dc-d9a3-418d-b2fd-eeb49737123e	suspender	vfvff	2026-05-28 00:36:38.364042
29dcc024-6269-4488-bfbd-874e1d076f25	9d11f875-d0bf-4afa-9940-e10513a83efa	756529dc-d9a3-418d-b2fd-eeb49737123e	activar	vvdvd	2026-05-28 00:38:06.698499
eaee8b6f-0046-4c54-bbba-043537aee26d	9d11f875-d0bf-4afa-9940-e10513a83efa	756529dc-d9a3-418d-b2fd-eeb49737123e	bloquear	fdfdfd	2026-05-28 00:38:21.276827
7f11721d-da25-4666-995a-de0ea4f9a2ea	9d11f875-d0bf-4afa-9940-e10513a83efa	756529dc-d9a3-418d-b2fd-eeb49737123e	activar	grgrgr	2026-05-28 00:49:06.31516
6927e906-684e-44ea-8eb1-4cbdda18ba6a	9d11f875-d0bf-4afa-9940-e10513a83efa	756529dc-d9a3-418d-b2fd-eeb49737123e	abonar_saldo	sdddd	2026-05-30 23:28:58.890354
54c840b8-8a39-40f6-b709-1e1110d4ec8a	9d11f875-d0bf-4afa-9940-e10513a83efa	756529dc-d9a3-418d-b2fd-eeb49737123e	abonar_saldo	Bono de bienvenida-Abonado	2026-05-30 23:35:10.701229
41ffb418-d0f2-4dd6-9977-38d82ca11369	9d11f875-d0bf-4afa-9940-e10513a83efa	756529dc-d9a3-418d-b2fd-eeb49737123e	deducir_saldo	Penalización por mal uso	2026-05-30 23:38:55.142141
\.


--
-- TOC entry 5249 (class 0 OID 17611)
-- Dependencies: 222
-- Data for Name: opciones_apuesta; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.opciones_apuesta (id, apuesta_id, descripcion, probabilidad_pct, cuota, orden, total_apostado, total_participantes) FROM stdin;
6c316435-73c9-42a1-9c90-2932a8fb64de	92f6c050-8143-4e7a-86d0-427374ecd910	Equipo B	30.00	3.0000	2	0.00	0
82dd59c6-93d4-49ee-b04e-81db4a8383b3	92f6c050-8143-4e7a-86d0-427374ecd910	Empate	20.00	4.5000	3	0.00	0
31ff8fbe-e468-4c82-b960-58b672aa6208	92f6c050-8143-4e7a-86d0-427374ecd910	Equipo A	50.00	1.8000	1	100.00	1
59732379-35cd-4e51-ada1-2e326e5d1ab6	9bccf277-1e16-44b1-98c1-420f1105e73f	Empate	20.00	4.5000	3	0.00	0
0e46cca4-9363-454b-a221-7b2d1eb4839d	9a7a7d09-be98-4aaa-8063-ae2d31f68cbb	Empate	20.00	4.5000	3	60.00	1
a70ec81e-2615-4411-8b49-9e2244608c40	07c27706-c498-4458-bd2e-b0288cc3bb27	eBE	19.00	4.7368	2	0.00	0
969d6ff1-71b7-473a-8bed-6d273c259267	07c27706-c498-4458-bd2e-b0288cc3bb27	Yo	1.00	90.0000	3	0.00	0
33c78a50-7688-48d1-999e-a356600fa825	07c27706-c498-4458-bd2e-b0288cc3bb27	Zacatar	80.00	1.1250	1	80.00	1
562df5ed-8b14-41b2-a328-3083a0a797b1	6162ccae-65d8-437c-8231-6fe1dbd992a6	cvvvvvvvvvvvvv	50.00	1.8000	1	0.00	0
b2ef2dbb-b9d1-4742-a256-91d496daa23b	6162ccae-65d8-437c-8231-6fe1dbd992a6	bbbbbbbbbbbbbbbbbbbbb	50.00	1.8000	2	0.00	0
deec0caf-e861-4798-80e6-8766ff75c430	7ccb4865-8353-47ea-973e-b0b4d89ae5b3	hhhhhhhhhhhhhh	50.00	1.8000	1	0.00	0
b9c533c1-615d-4977-be08-2d3f1e974c12	7ccb4865-8353-47ea-973e-b0b4d89ae5b3	hjjjjjjjjjjjjjjj	50.00	1.8000	2	0.00	0
73f580d6-4d7c-49a9-b1f7-8ae428962cb5	f1ce0e2a-6842-4891-89f6-06e3d44b42a4	gg	50.00	1.8000	1	0.00	0
128ed6a0-340f-4254-b2fc-122f943c3ee2	f1ce0e2a-6842-4891-89f6-06e3d44b42a4	gg	50.00	1.8000	2	0.00	0
34f3075f-adba-436d-a987-c1c0bf80534f	d2893ddb-df50-4d29-b02d-13cc75219f09	se	50.00	1.8000	1	0.00	0
7641764b-aec9-41d2-b556-8edd150db496	d2893ddb-df50-4d29-b02d-13cc75219f09	de	50.00	1.8000	2	0.00	0
4e7036d9-214a-441a-9f70-bf0aa0f429ad	c791b884-5b5f-45c7-b8f5-b050dff7f019	Si	50.00	1.8000	1	0.00	0
ccd1e161-57de-4c75-a5f5-da523462f364	c791b884-5b5f-45c7-b8f5-b050dff7f019	sI	50.00	1.8000	2	0.00	0
d0fecf70-984e-420c-9224-6d0f239e56be	a6873154-fc4d-460e-90c6-001a9f3fed6e	df	50.00	1.8000	1	0.00	0
056e8cdc-7348-42b8-83e8-91a7e9d0c2fc	a6873154-fc4d-460e-90c6-001a9f3fed6e	fffff	50.00	1.8000	2	0.00	0
b0f38f17-7647-408f-8dcc-7cbcf8675ab8	cba66a72-98f9-4fd5-a1e4-a9411efe5819	dwdwd	50.00	1.8000	1	0.00	0
77a819d8-1430-4ce5-86ac-df9144eeed21	cba66a72-98f9-4fd5-a1e4-a9411efe5819	dwdwdw	50.00	1.8000	2	0.00	0
23829aa2-b8cc-4662-bc16-494166c6de17	fc125819-5758-4e2b-9368-e0428f52237e	ewe	50.00	1.8000	1	0.00	0
7bee5729-1224-4b1e-a862-dd22e40b1db9	fc125819-5758-4e2b-9368-e0428f52237e	ewe	50.00	1.8000	2	0.00	0
2a8706ca-ba66-4232-a6c7-0b935b3f9e66	20ee42a4-dd65-4176-b233-56e7d6e90e0e	dddd	50.00	1.8000	1	0.00	0
03d7002e-24a7-45be-9667-05183bcfb365	20ee42a4-dd65-4176-b233-56e7d6e90e0e	llllllllllllllllll	50.00	1.8000	2	0.00	0
a982b3a6-2a25-4ea3-a0c2-7f9c930c545d	463dbb7e-8ebf-4f89-89a5-00a2a4f1f42c	ffffff	50.00	1.8000	1	0.00	0
87101dbb-844a-4ede-8eb9-a67c1c0e6df1	463dbb7e-8ebf-4f89-89a5-00a2a4f1f42c	fffffff	50.00	1.8000	2	0.00	0
3571d649-464a-4e12-9df4-ea77e56ffbc5	834b5a3d-24b6-46b0-85ac-42934419adc3	Si	50.00	1.8000	1	0.00	0
586a8e45-61e9-408c-b322-c62fb36e17c6	834b5a3d-24b6-46b0-85ac-42934419adc3	No	50.00	1.8000	2	0.00	0
56efb677-9740-4a8b-92d5-31b41d8b7bae	9a7a7d09-be98-4aaa-8063-ae2d31f68cbb	Equipo B	30.00	3.0000	2	234.00	1
7e997163-090a-4670-908b-f5d803609974	f23b2994-79ac-46a9-a782-0b46e53a504c	gfg	50.00	1.8000	1	0.00	0
010236bd-41d9-442c-a491-056b7d889e5e	f23b2994-79ac-46a9-a782-0b46e53a504c	gfg	50.00	1.8000	2	0.00	0
2f09cdab-1355-4a32-b2e7-c5ed6931fe10	b975c2c6-d92b-488c-9d9d-d09c4ff5c693	No	10.00	9.0000	2	110.00	1
2bcd6efe-fad7-4247-bb68-aeca1a5d37c0	b975c2c6-d92b-488c-9d9d-d09c4ff5c693	Si	90.00	1.0000	1	120.00	1
b09a89e2-c09d-4243-85f8-7cffa70d0b81	3adb74f4-fe7d-4e82-9689-149a4a502123	Si	50.00	1.8000	1	0.00	0
d01737f6-db98-4e8c-8222-2e3ce6c6617d	3adb74f4-fe7d-4e82-9689-149a4a502123	no	50.00	1.8000	2	0.00	0
8d9d0fe5-e15c-4733-b2c4-81635e0487d9	e0c6154c-eccd-4b47-a7a5-72bd46487fdc	No	50.00	1.8000	2	0.00	0
ac8ba4a3-6228-4987-91cd-7691baf52fb3	e0c6154c-eccd-4b47-a7a5-72bd46487fdc	Si	50.00	1.8000	1	100.00	1
86becf33-3853-4566-bf79-fb377c9c547f	8d2842a0-83ad-4d2a-8118-406275c72efc	Claro que si	50.00	1.8000	1	105.00	1
d22db155-b71a-4bf5-9729-f1f73725c37c	8d2842a0-83ad-4d2a-8118-406275c72efc	Claro que no	50.00	1.8000	2	101.00	1
d8adae31-c353-4448-9bff-432bd7cb58ed	e6d7fcab-c5f1-433f-a1b5-43cde0863664	Si	50.00	1.8000	1	56.00	1
1f475e3e-d691-44db-8123-0f6d4a000a9a	e6d7fcab-c5f1-433f-a1b5-43cde0863664	No	50.00	1.8000	2	107.00	2
9e3afc26-bab1-4b2e-83e2-dc5170d3170d	9b889aea-3704-49d5-b577-d4dd6a3641c7	Opcion A	50.00	1.8000	1	0.00	0
48d67405-4aa1-46a0-9309-54326f5893fc	9b889aea-3704-49d5-b577-d4dd6a3641c7	Opcion B	50.00	1.8000	2	0.00	0
bef92309-ed22-454b-bf17-adf032a0abe3	0eee0a0a-4716-4342-af7e-62d5dc4de1a2	Parte 1 es si	50.00	1.8000	1	54.00	1
3ec2e7a3-7465-457d-b50e-2f9dac13e7ef	0eee0a0a-4716-4342-af7e-62d5dc4de1a2	Parte 2 es Si	50.00	1.8000	2	53.00	1
8dae8d49-3359-4322-9e0a-04af00f41252	8cff988e-b86c-492d-bc86-cdc408d27c95	rw	50.00	1.8000	2	0.00	0
a8a6f6ea-795b-4703-ad74-8c2cc5edd493	9bccf277-1e16-44b1-98c1-420f1105e73f	Clementiza	30.00	3.0000	2	51.00	1
fd022ec1-6545-4fb1-a493-6477a2317410	2e15b71d-42fa-4b35-9f78-c12add655c4d	No	50.00	1.8000	2	0.00	0
2d513b97-169b-461c-a263-4b3838c3ebd0	2e15b71d-42fa-4b35-9f78-c12add655c4d	Si	50.00	1.8000	1	51.00	1
8651239d-efa2-43b6-accb-2cf13949ad14	58cb2d3d-f32f-452e-9df2-75bd5dcf6b83	si	50.00	1.8000	1	51.00	1
bea82530-6766-4041-8cfb-b426383eeadd	58cb2d3d-f32f-452e-9df2-75bd5dcf6b83	no	50.00	1.8000	2	53.00	1
ed013075-8a5b-4906-98c6-5413b8ca3271	74b70bb3-9ae4-44f8-ad20-3b0df84595d1	si	50.00	1.8000	1	0.00	0
86d2b69f-1fcd-4305-8c6a-4ace13329f6e	74b70bb3-9ae4-44f8-ad20-3b0df84595d1	no	50.00	1.8000	2	0.00	0
19c369ed-69db-4cc2-9ab1-9a202fa9a0a4	1f96b894-b149-4e62-b944-47b1c2842c55	no	50.00	1.8000	2	0.00	0
55fe7182-41de-4eca-a887-0d5ef7eb03c1	1f96b894-b149-4e62-b944-47b1c2842c55	si	50.00	1.8000	1	50.00	1
346a82cc-e86e-4290-85b1-9682fc61b3df	9b42c01d-6056-4214-be85-2d27a5a132b7	No	50.00	1.8000	2	0.00	0
d42c076e-8ffa-4f5b-9ea6-1ebf8ea6a375	9b42c01d-6056-4214-be85-2d27a5a132b7	Si	50.00	1.8000	1	50.00	1
9fce2181-b2d8-41f1-8181-acc83217b43b	474b6abb-5366-4658-b872-6624bc8e7b38	Si puede apostar	90.00	1.0000	1	0.00	0
d6e9602d-0b9f-4034-a1b0-168bc54a0386	474b6abb-5366-4658-b872-6624bc8e7b38	No puede apostar	10.00	9.0000	2	0.00	0
58a300e5-b749-4b24-86ca-656f016a94aa	a20eb344-61d8-46f8-b060-c29a95504ff3	SI	10.00	9.0000	1	0.00	0
d93760fc-239a-4b58-8b7b-754de935f748	a20eb344-61d8-46f8-b060-c29a95504ff3	NO	90.00	1.0000	2	0.00	0
138aafb9-3b2a-4fa5-a9f3-b9759b7bf6ed	2cc79f68-6738-4b80-b9bf-929c9089673a	Si	1.00	90.0000	1	0.00	0
67463c71-478f-454b-8e4f-1b7b3b7cf89c	2cc79f68-6738-4b80-b9bf-929c9089673a	No	99.00	0.9091	2	0.00	0
f95787a2-fa72-468e-88f3-0c1bc9cde7d5	ea9d5938-0ba0-44ed-90c3-96c323ac529e	No	10.00	9.0000	2	0.00	0
3d31a1f6-6cbd-4488-9855-fc23d9c18e76	ea9d5938-0ba0-44ed-90c3-96c323ac529e	Si	90.00	1.0000	1	50.00	1
8d1eacc8-15b4-42fb-b97b-0e7d39422a5c	4c0ced9a-f094-458d-bf61-43bed3c6f38b	No	40.00	2.2500	2	0.00	0
3557b141-23ac-4cf7-94da-e10c8c870d37	4c0ced9a-f094-458d-bf61-43bed3c6f38b	Si	60.00	1.5000	1	50.00	1
6cbbf109-c274-4d9e-9f72-21f20a692843	0841b73a-b7e3-4fe2-b00d-9bcc56c0f64d	Si	50.00	1.8000	1	50.00	1
26516b8d-e765-467f-9ed6-b7e655da8e8f	0841b73a-b7e3-4fe2-b00d-9bcc56c0f64d	nO	50.00	1.8000	2	50.00	1
822ef5f4-25fe-4bec-a231-8286a2644f54	0dfa4026-c7cf-4b46-ade4-6b3f67fa716d	sI	50.00	1.8000	1	50.00	1
9cc6fe9d-646f-45b1-b5d2-31125da5dc75	0dfa4026-c7cf-4b46-ade4-6b3f67fa716d	nO	50.00	1.8000	2	50.00	1
3bdb17a5-96e1-45c6-9fe8-dadff3562995	a6db3985-33e0-40ab-a324-19c174c9135a	Si	40.00	2.2500	1	150.00	3
1cbd03cb-eeae-4fc3-93dc-f027ddb35225	9a7a7d09-be98-4aaa-8063-ae2d31f68cbb	Equipo A	50.00	1.8000	1	101.00	2
dd921192-5c63-43fb-81ef-71e1e88625c9	8cff988e-b86c-492d-bc86-cdc408d27c95	ew	50.00	1.8000	1	50.00	1
423e9f7b-ecb2-447f-be4c-87fa678bdad7	9be0d25d-f848-437e-9ae0-70de3a4b4145	FS	50.00	1.8000	2	0.00	0
7a7ca71d-efdf-4ab6-8623-17c8e71a84a4	9be0d25d-f848-437e-9ae0-70de3a4b4145	SD	50.00	1.8000	1	50.00	1
9c8de5b0-bb3d-4ff5-83ab-8754de6708ea	512a936c-cd30-4070-a5d4-9e3094266fec	no	50.00	1.8000	2	0.00	0
d61c153c-a0dc-450f-93ca-cb65df629911	512a936c-cd30-4070-a5d4-9e3094266fec	SI	50.00	1.8000	1	50.00	1
57e9c065-eace-435d-aed0-44b614eb7c51	71872968-582d-4196-969d-6d1d8960c49a	no	50.00	1.8000	2	0.00	0
4955a9b5-3602-4b66-ab56-72d05e660969	71872968-582d-4196-969d-6d1d8960c49a	Si	50.00	1.8000	1	200.00	1
b9b3b962-25f4-4277-9250-968b26ba4650	a6db3985-33e0-40ab-a324-19c174c9135a	No	60.00	1.5000	2	0.00	0
3d09180b-7413-4aea-b3d2-fe5ee2b0ee73	470403e1-131b-4391-b3b2-34f4e895876f	No	50.00	1.8000	2	0.00	0
30a5991e-cac9-4587-bc15-d8b98bc759d3	9bccf277-1e16-44b1-98c1-420f1105e73f	El Tigre	50.00	1.8000	1	201.00	3
09628ed2-ba74-4e1b-a19a-bf298e60044d	d4e7aba6-445c-4b55-8811-de1249dfb9a8	Si	40.00	2.2500	1	50.00	1
393670db-5d16-4fdf-85d3-f75ae368fca5	d4e7aba6-445c-4b55-8811-de1249dfb9a8	No	60.00	1.5000	2	50.00	1
1d224a6e-d687-4612-b4f4-be64450425d8	470403e1-131b-4391-b3b2-34f4e895876f	Si	50.00	1.8000	1	50.00	1
213bbc01-ae7c-4d55-befa-43de733c66cf	93688c1a-f27d-4fa6-8b1b-de8f0938126f	Shi	50.00	1.8000	1	0.00	0
d55f49c9-53fa-4d31-8128-d86950654334	93688c1a-f27d-4fa6-8b1b-de8f0938126f	Ño	50.00	1.8000	2	0.00	0
53e4cbd9-04f8-4571-8993-6f8a602713a4	6fc076eb-8c6d-497b-bca0-2793c9ef42a6	Si	50.00	1.8000	1	50.00	1
f6987f61-9a43-441e-b965-85e41ca7d45f	6fc076eb-8c6d-497b-bca0-2793c9ef42a6	No	50.00	1.8000	2	50.00	1
756b1af8-9a2d-413d-ba60-36a9236e3d20	a56972be-883d-4bf1-8b90-07eca9c49986	Si	50.00	1.8000	1	50.00	1
c94e4c6b-5800-484b-9a83-6c07b0023c55	a56972be-883d-4bf1-8b90-07eca9c49986	No	50.00	1.8000	2	50.00	1
a0b41a1d-e01f-454e-9824-58ae1ffca8d0	ad1e6c2e-eea9-4557-8514-a31b714dcb0d	Juas	50.00	1.8000	2	100.00	1
004a7b63-a6a1-4da6-adc0-b742bfaa7a53	ad1e6c2e-eea9-4557-8514-a31b714dcb0d	Kappa	50.00	1.8000	1	300.00	2
\.


--
-- TOC entry 5250 (class 0 OID 17628)
-- Dependencies: 223
-- Data for Name: participaciones; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.participaciones (id, usuario_id, apuesta_id, opcion_id, monto, ganancia_proyectada, estado, ganancia, fecha_participacion) FROM stdin;
1bad57c3-5a2e-4296-a043-763a0aa9b1ba	9d11f875-d0bf-4afa-9940-e10513a83efa	92f6c050-8143-4e7a-86d0-427374ecd910	31ff8fbe-e468-4c82-b960-58b672aa6208	100.00	180.00	ganadora	180.00	2026-04-11 15:46:35.608071
f62b749b-1fc0-472a-9e05-672a8c1ca94e	9d11f875-d0bf-4afa-9940-e10513a83efa	9a7a7d09-be98-4aaa-8063-ae2d31f68cbb	0e46cca4-9363-454b-a221-7b2d1eb4839d	60.00	270.00	activa	\N	2026-04-20 02:59:33.584897
2f20f83c-56be-44db-ae49-8ddd1be20380	2bed359b-90d4-4251-806b-6076b7c0a1bd	9a7a7d09-be98-4aaa-8063-ae2d31f68cbb	56efb677-9740-4a8b-92d5-31b41d8b7bae	234.00	702.00	activa	\N	2026-04-20 06:55:56.130137
a6c80a15-c459-4a23-a15a-68d3b1f52e86	99856cdf-3124-4a8b-930c-86b9e6087866	9a7a7d09-be98-4aaa-8063-ae2d31f68cbb	1cbd03cb-eeae-4fc3-93dc-f027ddb35225	51.00	91.80	activa	\N	2026-04-20 15:07:23.316124
37b635c2-8280-479c-beb4-0e70fb277cc7	9d11f875-d0bf-4afa-9940-e10513a83efa	8d2842a0-83ad-4d2a-8118-406275c72efc	86becf33-3853-4566-bf79-fb377c9c547f	105.00	189.00	activa	\N	2026-05-06 15:20:46.070167
e636ec98-68b2-4fdc-99c2-27226c4aea2c	2bed359b-90d4-4251-806b-6076b7c0a1bd	8d2842a0-83ad-4d2a-8118-406275c72efc	d22db155-b71a-4bf5-9729-f1f73725c37c	101.00	181.80	activa	\N	2026-05-06 15:21:23.69125
2f642238-42f0-4a42-a7c0-5dea515b94d2	9d11f875-d0bf-4afa-9940-e10513a83efa	07c27706-c498-4458-bd2e-b0288cc3bb27	33c78a50-7688-48d1-999e-a356600fa825	80.00	90.00	ganadora	90.00	2026-04-20 03:22:04.408387
f9903714-b181-4f9b-9b22-dbfc4d57d42e	99856cdf-3124-4a8b-930c-86b9e6087866	e6d7fcab-c5f1-433f-a1b5-43cde0863664	1f475e3e-d691-44db-8123-0f6d4a000a9a	52.00	93.60	ganadora	93.60	2026-05-06 16:03:01.046538
aec9e4c4-71ee-4216-9e8f-7a6b827ab9bc	9d11f875-d0bf-4afa-9940-e10513a83efa	e6d7fcab-c5f1-433f-a1b5-43cde0863664	1f475e3e-d691-44db-8123-0f6d4a000a9a	55.00	99.00	ganadora	99.00	2026-05-06 16:04:03.642808
c6b65176-4770-4f54-b55d-94618c044864	2bed359b-90d4-4251-806b-6076b7c0a1bd	e6d7fcab-c5f1-433f-a1b5-43cde0863664	d8adae31-c353-4448-9bff-432bd7cb58ed	56.00	100.80	perdedora	\N	2026-05-06 16:02:44.116601
0821e211-f267-4795-8fdd-9bc7b5d75cc9	2bed359b-90d4-4251-806b-6076b7c0a1bd	0eee0a0a-4716-4342-af7e-62d5dc4de1a2	bef92309-ed22-454b-bf17-adf032a0abe3	54.00	97.20	ganadora	97.20	2026-05-24 15:31:39.523956
32da875d-8aff-426d-be17-b25ff3b60420	99856cdf-3124-4a8b-930c-86b9e6087866	0eee0a0a-4716-4342-af7e-62d5dc4de1a2	3ec2e7a3-7465-457d-b50e-2f9dac13e7ef	53.00	95.40	perdedora	\N	2026-05-24 15:33:21.321158
961c5c67-ebb2-476c-8424-7ee8b6ead299	99856cdf-3124-4a8b-930c-86b9e6087866	9bccf277-1e16-44b1-98c1-420f1105e73f	30a5991e-cac9-4587-bc15-d8b98bc759d3	51.00	91.80	activa	\N	2026-05-24 16:45:29.797172
7a3b0652-ca61-4d60-83df-dae4211822dd	2bed359b-90d4-4251-806b-6076b7c0a1bd	9bccf277-1e16-44b1-98c1-420f1105e73f	a8a6f6ea-795b-4703-ad74-8c2cc5edd493	51.00	153.00	activa	\N	2026-05-24 16:57:11.040916
4ea9fa49-f626-4c69-83a7-470f2ad1c208	99856cdf-3124-4a8b-930c-86b9e6087866	58cb2d3d-f32f-452e-9df2-75bd5dcf6b83	bea82530-6766-4041-8cfb-b426383eeadd	53.00	95.40	ganadora	95.40	2026-05-24 17:20:22.628299
b6432994-c7cb-4a68-94ad-d52aa38747fd	99856cdf-3124-4a8b-930c-86b9e6087866	58cb2d3d-f32f-452e-9df2-75bd5dcf6b83	8651239d-efa2-43b6-accb-2cf13949ad14	51.00	91.80	perdedora	\N	2026-05-24 17:19:26.271082
9c2c272c-3e4a-475b-8ac3-f5e3073adb29	2bed359b-90d4-4251-806b-6076b7c0a1bd	2e15b71d-42fa-4b35-9f78-c12add655c4d	2d513b97-169b-461c-a263-4b3838c3ebd0	51.00	91.80	ganadora	91.80	2026-05-24 17:11:44.940874
5bbdaee2-893b-4fc0-80ad-4c88888940d2	99856cdf-3124-4a8b-930c-86b9e6087866	1f96b894-b149-4e62-b944-47b1c2842c55	55fe7182-41de-4eca-a887-0d5ef7eb03c1	50.00	90.00	activa	\N	2026-05-24 17:38:36.628065
fed3eba3-9b29-40ba-b88f-8deab6c90c52	99856cdf-3124-4a8b-930c-86b9e6087866	9b42c01d-6056-4214-be85-2d27a5a132b7	d42c076e-8ffa-4f5b-9ea6-1ebf8ea6a375	50.00	90.00	activa	\N	2026-05-24 20:09:34.349679
437d917c-e519-4198-9a00-56129bbb7d16	37d4b325-2151-4683-8003-c2990c23b6fd	ea9d5938-0ba0-44ed-90c3-96c323ac529e	3d31a1f6-6cbd-4488-9855-fc23d9c18e76	50.00	50.00	activa	\N	2026-05-25 04:46:14.973008
319b7415-afbf-43c6-b35d-29ad92e6e17c	37d4b325-2151-4683-8003-c2990c23b6fd	9bccf277-1e16-44b1-98c1-420f1105e73f	30a5991e-cac9-4587-bc15-d8b98bc759d3	100.00	180.00	activa	\N	2026-05-25 06:11:36.943016
46ae42aa-1801-4355-9a43-f48165e90eb7	37d4b325-2151-4683-8003-c2990c23b6fd	9a7a7d09-be98-4aaa-8063-ae2d31f68cbb	1cbd03cb-eeae-4fc3-93dc-f027ddb35225	50.00	90.00	activa	\N	2026-05-25 06:16:44.962271
dc72c5f8-30dd-47bf-b15c-f1f14ea4a0e0	37d4b325-2151-4683-8003-c2990c23b6fd	512a936c-cd30-4070-a5d4-9e3094266fec	d61c153c-a0dc-450f-93ca-cb65df629911	50.00	90.00	ganadora	90.00	2026-05-25 06:26:36.313256
79d08cf5-b6ed-4bc4-879d-97a9ad1dcee3	37d4b325-2151-4683-8003-c2990c23b6fd	9be0d25d-f848-437e-9ae0-70de3a4b4145	7a7ca71d-efdf-4ab6-8623-17c8e71a84a4	50.00	90.00	ganadora	90.00	2026-05-25 06:25:43.864558
4f265ead-47e1-4c9b-a490-29c6171bd7b6	37d4b325-2151-4683-8003-c2990c23b6fd	8cff988e-b86c-492d-bc86-cdc408d27c95	dd921192-5c63-43fb-81ef-71e1e88625c9	50.00	90.00	ganadora	90.00	2026-05-25 06:22:43.732923
4a97690f-950c-4746-a4c9-cd9e4ec9c116	37d4b325-2151-4683-8003-c2990c23b6fd	0dfa4026-c7cf-4b46-ade4-6b3f67fa716d	9cc6fe9d-646f-45b1-b5d2-31125da5dc75	50.00	90.00	ganadora	90.00	2026-05-25 05:55:34.204857
14ebb993-f415-4d76-a48d-5a087745e352	2bed359b-90d4-4251-806b-6076b7c0a1bd	0dfa4026-c7cf-4b46-ade4-6b3f67fa716d	822ef5f4-25fe-4bec-a231-8286a2644f54	50.00	90.00	perdedora	\N	2026-05-25 05:55:23.805525
a01acc6c-cc18-4330-8bbd-e58f59b4be8a	2bed359b-90d4-4251-806b-6076b7c0a1bd	0841b73a-b7e3-4fe2-b00d-9bcc56c0f64d	6cbbf109-c274-4d9e-9f72-21f20a692843	50.00	90.00	ganadora	90.00	2026-05-25 05:54:26.40087
19ba3cff-50d8-4b75-9cff-5605512e292b	37d4b325-2151-4683-8003-c2990c23b6fd	0841b73a-b7e3-4fe2-b00d-9bcc56c0f64d	26516b8d-e765-467f-9ed6-b7e655da8e8f	50.00	90.00	perdedora	\N	2026-05-25 05:54:38.905356
76179d38-e83d-4a1a-841c-3881a093af79	37d4b325-2151-4683-8003-c2990c23b6fd	4c0ced9a-f094-458d-bf61-43bed3c6f38b	3557b141-23ac-4cf7-94da-e10c8c870d37	50.00	75.00	perdedora	\N	2026-05-25 05:33:20.930096
05ddaf28-9c65-4472-848a-a435cd012951	37d4b325-2151-4683-8003-c2990c23b6fd	71872968-582d-4196-969d-6d1d8960c49a	4955a9b5-3602-4b66-ab56-72d05e660969	200.00	360.00	ganadora	360.00	2026-05-27 06:06:51.328336
2aaefa26-9646-4de3-9773-f161872d38a3	9c4aaf43-8b29-46d4-a410-b7bc8d9dfe81	e0c6154c-eccd-4b47-a7a5-72bd46487fdc	ac8ba4a3-6228-4987-91cd-7691baf52fb3	100.00	180.00	ganadora	180.00	2026-04-20 14:26:47.772458
7a8ee242-40d4-4f21-9ca2-ea4a062c69ab	9c4aaf43-8b29-46d4-a410-b7bc8d9dfe81	b975c2c6-d92b-488c-9d9d-d09c4ff5c693	2f09cdab-1355-4a32-b2e7-c5ed6931fe10	110.00	990.00	ganadora	990.00	2026-04-20 13:59:54.317558
9b9fe60a-367a-4ad8-b6e7-c2adfc1338a0	9d11f875-d0bf-4afa-9940-e10513a83efa	b975c2c6-d92b-488c-9d9d-d09c4ff5c693	2bcd6efe-fad7-4247-bb68-aeca1a5d37c0	120.00	120.00	perdedora	\N	2026-04-20 14:00:26.2312
a2fdbdc9-9efa-4317-92d2-9e5d55c5318b	37d4b325-2151-4683-8003-c2990c23b6fd	d4e7aba6-445c-4b55-8811-de1249dfb9a8	09628ed2-ba74-4e1b-a19a-bf298e60044d	50.00	112.50	activa	\N	2026-05-27 23:01:58.027422
38fc4111-9b92-4c00-8858-2e513eae7bb5	756529dc-d9a3-418d-b2fd-eeb49737123e	d4e7aba6-445c-4b55-8811-de1249dfb9a8	393670db-5d16-4fdf-85d3-f75ae368fca5	50.00	75.00	activa	\N	2026-05-28 00:49:27.811921
e51608a2-96ce-4dcc-987d-dfd8fd5e47a7	756529dc-d9a3-418d-b2fd-eeb49737123e	470403e1-131b-4391-b3b2-34f4e895876f	1d224a6e-d687-4612-b4f4-be64450425d8	50.00	90.00	activa	\N	2026-05-28 01:05:48.01069
3b4580d4-6547-42c8-91d6-368d5b298692	212415cd-d7c7-4dab-97bd-d94bfd7d7ff0	9bccf277-1e16-44b1-98c1-420f1105e73f	30a5991e-cac9-4587-bc15-d8b98bc759d3	50.00	90.00	activa	\N	2026-05-28 01:06:21.090307
6ead78c7-9176-4497-9285-57e846a9114c	37d4b325-2151-4683-8003-c2990c23b6fd	a6db3985-33e0-40ab-a324-19c174c9135a	3bdb17a5-96e1-45c6-9fe8-dadff3562995	50.00	112.50	devuelta	\N	2026-05-27 06:19:25.205137
9a882c30-00c4-49a5-80e2-2097ac11e6f3	2bed359b-90d4-4251-806b-6076b7c0a1bd	a6db3985-33e0-40ab-a324-19c174c9135a	3bdb17a5-96e1-45c6-9fe8-dadff3562995	50.00	112.50	devuelta	\N	2026-05-27 06:34:54.945328
bb7e6c5a-067c-429a-8a77-30f12c7d4cac	756529dc-d9a3-418d-b2fd-eeb49737123e	a6db3985-33e0-40ab-a324-19c174c9135a	3bdb17a5-96e1-45c6-9fe8-dadff3562995	50.00	112.50	devuelta	\N	2026-05-28 01:39:45.20458
27f8e8d8-729e-4fee-bfd7-3dc81cc0fae3	756529dc-d9a3-418d-b2fd-eeb49737123e	6fc076eb-8c6d-497b-bca0-2793c9ef42a6	53e4cbd9-04f8-4571-8993-6f8a602713a4	50.00	90.00	ganadora	90.00	2026-05-30 15:13:07.391017
4537dae5-8162-4a14-a74e-2e2dfed25fc9	37d4b325-2151-4683-8003-c2990c23b6fd	6fc076eb-8c6d-497b-bca0-2793c9ef42a6	f6987f61-9a43-441e-b965-85e41ca7d45f	50.00	90.00	perdedora	\N	2026-05-30 15:13:41.434664
ad76f44c-fc53-4e2e-8f31-b957c93b20cc	37d4b325-2151-4683-8003-c2990c23b6fd	a56972be-883d-4bf1-8b90-07eca9c49986	756b1af8-9a2d-413d-ba60-36a9236e3d20	50.00	90.00	devuelta	\N	2026-05-30 23:54:28.243681
0eb49b4a-d98d-4b10-91b7-caf51b03e21c	756529dc-d9a3-418d-b2fd-eeb49737123e	a56972be-883d-4bf1-8b90-07eca9c49986	c94e4c6b-5800-484b-9a83-6c07b0023c55	50.00	90.00	devuelta	\N	2026-05-30 23:54:43.814703
f90dca7f-41df-497f-af91-a29466cfbb1c	756529dc-d9a3-418d-b2fd-eeb49737123e	ad1e6c2e-eea9-4557-8514-a31b714dcb0d	004a7b63-a6a1-4da6-adc0-b742bfaa7a53	100.00	180.00	ganadora	180.00	2026-05-31 00:03:18.77715
8d3cd302-27fc-417f-9df6-300275a8b3a2	212415cd-d7c7-4dab-97bd-d94bfd7d7ff0	ad1e6c2e-eea9-4557-8514-a31b714dcb0d	004a7b63-a6a1-4da6-adc0-b742bfaa7a53	200.00	360.00	ganadora	360.00	2026-05-31 00:04:52.045697
300a1e21-e9e3-4b5f-aa3a-8c44921a48f3	37d4b325-2151-4683-8003-c2990c23b6fd	ad1e6c2e-eea9-4557-8514-a31b714dcb0d	a0b41a1d-e01f-454e-9824-58ae1ffca8d0	100.00	180.00	perdedora	\N	2026-05-31 00:03:47.223692
\.


--
-- TOC entry 5253 (class 0 OID 17711)
-- Dependencies: 226
-- Data for Name: recargas; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.recargas (id, usuario_id, monto, metodo, ultimos_4_digitos, descripcion, fecha) FROM stdin;
bbf2929c-9425-4171-ac3e-f3faedf2bef3	9d11f875-d0bf-4afa-9940-e10513a83efa	200.00	tarjeta_ficticia	\N	\N	2026-04-11 22:23:11.175926
1ca5582a-652b-4591-b6e2-6ea03a83e4cc	37d4b325-2151-4683-8003-c2990c23b6fd	100.00	tarjeta_ficticia	\N	\N	2026-05-27 06:22:25.690757
f6f574f1-40c6-403c-a958-f3cd41fcb66f	37d4b325-2151-4683-8003-c2990c23b6fd	100.00	tarjeta_ficticia	\N	\N	2026-05-27 06:31:09.564812
\.


--
-- TOC entry 5251 (class 0 OID 17659)
-- Dependencies: 224
-- Data for Name: resultados_apuesta; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.resultados_apuesta (id, apuesta_id, opcion_ganadora_id, propuesto_por, confirmado_por, estado, motivo_rechazo, fecha_propuesta, fecha_confirmacion, evidencia) FROM stdin;
790a6c78-62c2-4705-9134-bbb28bfc0619	92f6c050-8143-4e7a-86d0-427374ecd910	31ff8fbe-e468-4c82-b960-58b672aa6208	9d11f875-d0bf-4afa-9940-e10513a83efa	9d11f875-d0bf-4afa-9940-e10513a83efa	confirmado	\N	2026-04-11 16:42:42.541114	2026-04-11 16:52:08.037061	\N
b5fd2cfe-aeca-48b5-8039-b2483c5a68cd	8d2842a0-83ad-4d2a-8118-406275c72efc	86becf33-3853-4566-bf79-fb377c9c547f	9d11f875-d0bf-4afa-9940-e10513a83efa	\N	propuesto	\N	2026-05-06 15:48:20.100033	\N	\N
516555d6-7a95-493e-a9fb-23e102bf20ea	07c27706-c498-4458-bd2e-b0288cc3bb27	33c78a50-7688-48d1-999e-a356600fa825	9d11f875-d0bf-4afa-9940-e10513a83efa	9d11f875-d0bf-4afa-9940-e10513a83efa	confirmado	\N	2026-05-06 15:59:49.156156	2026-05-06 15:59:49.212305	\N
0ad94be8-a779-492e-a792-4bdccbbe5469	e6d7fcab-c5f1-433f-a1b5-43cde0863664	1f475e3e-d691-44db-8123-0f6d4a000a9a	2bed359b-90d4-4251-806b-6076b7c0a1bd	9d11f875-d0bf-4afa-9940-e10513a83efa	confirmado	\N	2026-05-06 16:10:02.497083	2026-05-06 16:10:02.53694	\N
804c84c4-1360-43d3-a26f-c6a6df426783	c791b884-5b5f-45c7-b8f5-b050dff7f019	ccd1e161-57de-4c75-a5f5-da523462f364	9d11f875-d0bf-4afa-9940-e10513a83efa	9d11f875-d0bf-4afa-9940-e10513a83efa	confirmado	\N	2026-05-13 15:20:53.870094	2026-05-13 15:20:53.884886	\N
f9a21def-e366-4fba-a814-255088df211f	d2893ddb-df50-4d29-b02d-13cc75219f09	34f3075f-adba-436d-a987-c1c0bf80534f	9d11f875-d0bf-4afa-9940-e10513a83efa	9d11f875-d0bf-4afa-9940-e10513a83efa	confirmado	\N	2026-05-13 15:21:00.195919	2026-05-13 15:21:00.197088	\N
47b0f2bc-7869-4555-ba5b-afe93dab1557	7ccb4865-8353-47ea-973e-b0b4d89ae5b3	deec0caf-e861-4798-80e6-8766ff75c430	9d11f875-d0bf-4afa-9940-e10513a83efa	9d11f875-d0bf-4afa-9940-e10513a83efa	confirmado	\N	2026-05-13 15:32:03.335474	2026-05-13 15:32:03.355007	\N
6d9dc30c-8f5b-441e-bd65-472bb7ae8c31	6162ccae-65d8-437c-8231-6fe1dbd992a6	562df5ed-8b14-41b2-a328-3083a0a797b1	9d11f875-d0bf-4afa-9940-e10513a83efa	9d11f875-d0bf-4afa-9940-e10513a83efa	confirmado	\N	2026-05-24 05:37:39.103132	2026-05-24 05:37:39.131266	\N
cefb9be0-5caf-4569-8475-cbadd6a361e2	a6873154-fc4d-460e-90c6-001a9f3fed6e	d0fecf70-984e-420c-9224-6d0f239e56be	9d11f875-d0bf-4afa-9940-e10513a83efa	9d11f875-d0bf-4afa-9940-e10513a83efa	confirmado	\N	2026-05-24 15:41:01.191465	2026-05-24 15:41:01.205114	\N
bf8e522d-8d85-4197-9ab2-b5e05c82461d	0eee0a0a-4716-4342-af7e-62d5dc4de1a2	bef92309-ed22-454b-bf17-adf032a0abe3	2bed359b-90d4-4251-806b-6076b7c0a1bd	9d11f875-d0bf-4afa-9940-e10513a83efa	confirmado	\N	2026-05-24 15:51:51.586696	2026-05-24 15:51:51.607064	\N
3445f494-3535-4e1c-be98-fa5180b4297d	58cb2d3d-f32f-452e-9df2-75bd5dcf6b83	bea82530-6766-4041-8cfb-b426383eeadd	99856cdf-3124-4a8b-930c-86b9e6087866	9d11f875-d0bf-4afa-9940-e10513a83efa	confirmado	\N	2026-05-24 17:31:43.372422	2026-05-24 17:31:43.423348	\N
f56a41ec-6bdb-48fb-b317-7b869b3670cc	2e15b71d-42fa-4b35-9f78-c12add655c4d	2d513b97-169b-461c-a263-4b3838c3ebd0	99856cdf-3124-4a8b-930c-86b9e6087866	9d11f875-d0bf-4afa-9940-e10513a83efa	confirmado	\N	2026-05-24 17:32:25.715162	2026-05-24 17:32:25.719837	\N
d2df7646-76cb-4652-b3ca-07750e919f50	512a936c-cd30-4070-a5d4-9e3094266fec	d61c153c-a0dc-450f-93ca-cb65df629911	37d4b325-2151-4683-8003-c2990c23b6fd	9d11f875-d0bf-4afa-9940-e10513a83efa	confirmado	\N	2026-05-25 06:28:20.260483	2026-05-25 06:28:20.270376	\N
1ed0f889-5f96-4c70-90f6-1ad84abf616c	9be0d25d-f848-437e-9ae0-70de3a4b4145	7a7ca71d-efdf-4ab6-8623-17c8e71a84a4	37d4b325-2151-4683-8003-c2990c23b6fd	9d11f875-d0bf-4afa-9940-e10513a83efa	confirmado	\N	2026-05-25 06:28:30.21019	2026-05-25 06:28:30.212744	\N
e466b5c8-cb28-4e5b-af63-41f7b02afe7a	8cff988e-b86c-492d-bc86-cdc408d27c95	dd921192-5c63-43fb-81ef-71e1e88625c9	2bed359b-90d4-4251-806b-6076b7c0a1bd	9d11f875-d0bf-4afa-9940-e10513a83efa	confirmado	\N	2026-05-25 06:28:53.364155	2026-05-25 06:28:53.371183	\N
befdd707-39f5-4e72-9f83-3d8f978ff9dd	0dfa4026-c7cf-4b46-ade4-6b3f67fa716d	9cc6fe9d-646f-45b1-b5d2-31125da5dc75	2bed359b-90d4-4251-806b-6076b7c0a1bd	9d11f875-d0bf-4afa-9940-e10513a83efa	confirmado	\N	2026-05-25 06:32:14.962409	2026-05-25 06:32:14.973539	\N
cc756588-0d18-488f-9f11-0e3981266142	0841b73a-b7e3-4fe2-b00d-9bcc56c0f64d	6cbbf109-c274-4d9e-9f72-21f20a692843	2bed359b-90d4-4251-806b-6076b7c0a1bd	9d11f875-d0bf-4afa-9940-e10513a83efa	confirmado	\N	2026-05-25 06:32:30.616182	2026-05-25 06:32:30.623015	\N
84bdabf8-30f5-408e-8ba1-ada9b46c063e	4c0ced9a-f094-458d-bf61-43bed3c6f38b	8d1eacc8-15b4-42fb-b97b-0e7d39422a5c	37d4b325-2151-4683-8003-c2990c23b6fd	9d11f875-d0bf-4afa-9940-e10513a83efa	confirmado	\N	2026-05-25 06:32:39.185711	2026-05-25 06:32:39.187261	\N
444ef2fa-f256-437c-af6c-5f4e6282feaa	71872968-582d-4196-969d-6d1d8960c49a	4955a9b5-3602-4b66-ab56-72d05e660969	37d4b325-2151-4683-8003-c2990c23b6fd	9d11f875-d0bf-4afa-9940-e10513a83efa	confirmado	\N	2026-05-27 06:37:36.439313	2026-05-27 06:37:36.447923	\N
be35d833-7bc5-4da1-a0f8-88936a75e421	e0c6154c-eccd-4b47-a7a5-72bd46487fdc	ac8ba4a3-6228-4987-91cd-7691baf52fb3	9d11f875-d0bf-4afa-9940-e10513a83efa	9d11f875-d0bf-4afa-9940-e10513a83efa	confirmado	\N	2026-05-27 06:46:30.278284	2026-05-27 06:46:30.290775	\N
ae0030b0-1e14-474c-a148-105ba80f1b89	b975c2c6-d92b-488c-9d9d-d09c4ff5c693	2f09cdab-1355-4a32-b2e7-c5ed6931fe10	9c4aaf43-8b29-46d4-a410-b7bc8d9dfe81	9d11f875-d0bf-4afa-9940-e10513a83efa	confirmado	\N	2026-05-27 06:49:58.238045	2026-05-27 06:49:58.2651	\N
002df09a-363b-48bf-be7a-3a2bcf19fed0	2cc79f68-6738-4b80-b9bf-929c9089673a	67463c71-478f-454b-8e4f-1b7b3b7cf89c	37d4b325-2151-4683-8003-c2990c23b6fd	\N	propuesto	\N	2026-05-30 10:05:56.325796	\N	hghghghgh
ce8ee480-b9a0-4e98-9e7e-b238a17aacc0	ea9d5938-0ba0-44ed-90c3-96c323ac529e	f95787a2-fa72-468e-88f3-0c1bc9cde7d5	37d4b325-2151-4683-8003-c2990c23b6fd	\N	propuesto	\N	2026-05-30 10:08:54.481388	\N	fdfdfdf
7561bf8b-1b82-4a5f-aacb-9cdbe67bcb78	a20eb344-61d8-46f8-b060-c29a95504ff3	58a300e5-b749-4b24-86ca-656f016a94aa	37d4b325-2151-4683-8003-c2990c23b6fd	\N	propuesto	\N	2026-05-30 10:18:56.263665	\N	fdfdfdfdf
e9a7a4d5-ecdf-40c3-a4db-48fbc74dd01c	474b6abb-5366-4658-b872-6624bc8e7b38	9fce2181-b2d8-41f1-8181-acc83217b43b	37d4b325-2151-4683-8003-c2990c23b6fd	\N	propuesto	\N	2026-05-30 10:39:43.934467	\N	rerere
65b20d97-82e1-404f-bd27-bf1f7e02f9ec	6fc076eb-8c6d-497b-bca0-2793c9ef42a6	53e4cbd9-04f8-4571-8993-6f8a602713a4	756529dc-d9a3-418d-b2fd-eeb49737123e	9d11f875-d0bf-4afa-9940-e10513a83efa	confirmado	\N	2026-05-30 15:18:07.466273	2026-05-30 15:32:24.255457	El partido terminó 2-1, fuente: ESPN.com
c9301c6c-8280-4e2b-8c3b-18bb284bc34a	ad1e6c2e-eea9-4557-8514-a31b714dcb0d	004a7b63-a6a1-4da6-adc0-b742bfaa7a53	756529dc-d9a3-418d-b2fd-eeb49737123e	9d11f875-d0bf-4afa-9940-e10513a83efa	confirmado	\N	2026-05-31 00:08:52.978668	2026-05-31 00:09:55.982937	Kappa 2 - 1 Juas
\.


--
-- TOC entry 5254 (class 0 OID 17726)
-- Dependencies: 227
-- Data for Name: retiros; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.retiros (id, usuario_id, monto_solicitado, comision, monto_neto, metodo_retiro, estado, motivo_rechazo, procesado_por, fecha_solicitud, fecha_procesado) FROM stdin;
19ce287c-1bf9-40f5-8c22-6b8e373d181e	9d11f875-d0bf-4afa-9940-e10513a83efa	100.00	4.00	96.00	transferencia_bancaria	pendiente	\N	\N	2026-04-11 22:25:05.21862	\N
b00cdff6-5cc2-4cda-81d6-d39816760214	37d4b325-2151-4683-8003-c2990c23b6fd	100.00	4.00	96.00	monedero	pendiente	\N	\N	2026-05-27 06:22:16.536103	\N
9ec9f256-1335-4d82-b09d-e5159e5723bb	756529dc-d9a3-418d-b2fd-eeb49737123e	100.00	4.00	96.00	transferencia_bancaria	pendiente	\N	\N	2026-05-30 15:52:08.577043	\N
\.


--
-- TOC entry 5247 (class 0 OID 17565)
-- Dependencies: 220
-- Data for Name: saldos; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.saldos (id, usuario_id, saldo_disponible, fecha_actualizacion) FROM stdin;
c4b29868-60f4-4b14-ae4d-1f55d34d573d	3f507fb0-512f-4b63-b5b7-7950c5d1d2d2	500.00	2026-04-10 02:39:51.473691
0d75a3c0-5ba9-42e8-89f9-0bd96dee4f17	fec57d62-02cc-413d-a720-ac4be0506a7d	500.00	2026-04-20 01:25:42.728255
fd51c1cb-5971-472a-8d67-5921154d8f29	37d4b325-2151-4683-8003-c2990c23b6fd	420.00	2026-05-31 00:03:47.223692
d8d5f4b6-839e-4f64-b635-66991c3ce649	756529dc-d9a3-418d-b2fd-eeb49737123e	852.00	2026-05-31 00:09:55.982937
61ed5729-7ea3-4cc5-83eb-6e7c0f6684a9	212415cd-d7c7-4dab-97bd-d94bfd7d7ff0	610.00	2026-05-31 00:09:55.982937
d8d43401-e831-4108-bd09-f49785655a29	9d11f875-d0bf-4afa-9940-e10513a83efa	449.00	2026-05-06 16:10:02.53694
8bc7ce42-b236-43c8-a596-ee3d82a31173	216dafa9-5f81-4bac-8880-9186725d4657	500.00	2026-05-24 16:36:06.343289
c419eafb-00c2-4d91-beb3-14992d8b90b8	99856cdf-3124-4a8b-930c-86b9e6087866	278.00	2026-05-24 20:09:34.349679
1cd9f51c-5aaa-4e52-8fc9-0e2b1dc4cf68	d546048a-a343-4865-9123-ce49208cd45a	500.00	2026-05-24 21:05:40.922104
f03da4ff-451a-4091-b06a-0e48dd591871	9c4aaf43-8b29-46d4-a410-b7bc8d9dfe81	1460.00	2026-05-27 06:49:58.2651
7327c7c6-e325-4899-98da-38a7066627f4	c83ee6d7-d883-421d-a68b-6f8ac5838c6c	500.00	2026-05-27 22:36:26.410166
f3cde9b7-2494-41e6-a4e6-2653d16deb44	2bed359b-90d4-4251-806b-6076b7c0a1bd	132.00	2026-05-28 01:40:27.037336
\.


--
-- TOC entry 5252 (class 0 OID 17693)
-- Dependencies: 225
-- Data for Name: transacciones; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.transacciones (id, usuario_id, tipo, monto, saldo_anterior, saldo_posterior, referencia_id, descripcion, fecha) FROM stdin;
adc95875-f904-491f-b9fd-7d4b5f2ef7c0	9d11f875-d0bf-4afa-9940-e10513a83efa	bienvenida	500.00	0.00	500.00	\N	Saldo de bienvenida asignado al registrarse	2026-04-10 01:38:13.114877
93dd161f-7554-4a68-9889-7c5f89e230a5	3f507fb0-512f-4b63-b5b7-7950c5d1d2d2	bienvenida	500.00	0.00	500.00	\N	Saldo de bienvenida asignado al registrarse	2026-04-10 02:39:51.473691
ba9c3fa5-17b2-41c5-910e-287ea4e50e4e	9d11f875-d0bf-4afa-9940-e10513a83efa	apuesta_deduccion	100.00	500.00	400.00	1bad57c3-5a2e-4296-a043-763a0aa9b1ba	Apuesta en: "¿Quién ganará el partido?" · opción: "Equipo A" · cuota ×1.8000 · ganancia proyectada: $180.00	2026-04-11 15:46:35.608071
9496c9e1-af1c-4797-9b70-32d8d35387fe	9d11f875-d0bf-4afa-9940-e10513a83efa	ganancia	180.00	400.00	580.00	1bad57c3-5a2e-4296-a043-763a0aa9b1ba	Ganancia en: "¿Quién ganará el partido?" · cuota ×1.8000	2026-04-11 16:52:08.037061
b8c7b549-e617-4b94-9afe-c729af78ec30	9d11f875-d0bf-4afa-9940-e10513a83efa	recarga	200.00	580.00	780.00	bbf2929c-9425-4171-ac3e-f3faedf2bef3	Recarga ficticia · método: tarjeta_ficticia	2026-04-11 22:23:11.175926
2d00ae4e-8ff2-4be6-8166-c0c415e30293	9d11f875-d0bf-4afa-9940-e10513a83efa	retiro	100.00	780.00	680.00	19ce287c-1bf9-40f5-8c22-6b8e373d181e	Retiro solicitado · comisión 4%: $4.00 · monto neto: $96.00	2026-04-11 22:25:05.21862
6f1420e0-f7ab-44c3-b870-1c1578d00ffb	2bed359b-90d4-4251-806b-6076b7c0a1bd	bienvenida	500.00	0.00	500.00	\N	Saldo de bienvenida asignado al registrarse	2026-04-13 16:31:50.6733
5f738ab3-a05e-4b80-a01e-957b5a8b4dbd	fec57d62-02cc-413d-a720-ac4be0506a7d	bienvenida	500.00	0.00	500.00	\N	Saldo de bienvenida asignado al registrarse	2026-04-20 01:25:42.728255
6e30df1d-6585-4c3e-bc5d-a8d3bc8eb173	9d11f875-d0bf-4afa-9940-e10513a83efa	apuesta_deduccion	60.00	680.00	620.00	f62b749b-1fc0-472a-9e05-672a8c1ca94e	Apuesta en: "¿Quién ganará el partido?" · opción: "Empate" · cuota ×4.5000 · ganancia proyectada: $270.00	2026-04-20 02:59:33.584897
0cff4e71-d0de-466c-b0d2-ebecaf82646a	9d11f875-d0bf-4afa-9940-e10513a83efa	apuesta_deduccion	80.00	620.00	540.00	2f642238-42f0-4a42-a7c0-5dea515b94d2	Apuesta en: "¿Quien es la mejor Zoe?" · opción: "Zacatar" · cuota ×1.1250 · ganancia proyectada: $90.00	2026-04-20 03:22:04.408387
b7d4f263-948b-4798-995c-cee8e086cf4b	2bed359b-90d4-4251-806b-6076b7c0a1bd	apuesta_deduccion	234.00	500.00	266.00	2f20f83c-56be-44db-ae49-8ddd1be20380	Apuesta en: "¿Quién ganará el partido?" · opción: "Equipo B" · cuota ×3.0000 · ganancia proyectada: $702.00	2026-04-20 06:55:56.130137
569e2d1f-840b-432d-b3c1-5cc55e5dcbed	9c4aaf43-8b29-46d4-a410-b7bc8d9dfe81	bienvenida	500.00	0.00	500.00	\N	Saldo de bienvenida asignado al registrarse	2026-04-20 13:50:19.458387
1e79d02d-5371-4440-8033-a6bec869cfed	9c4aaf43-8b29-46d4-a410-b7bc8d9dfe81	apuesta_deduccion	110.00	500.00	390.00	7a8ee242-40d4-4f21-9ca2-ea4a062c69ab	Apuesta en: "Joel pasara la materia de TESEBADA?" · opción: "No" · cuota ×9.0000 · ganancia proyectada: $990.00	2026-04-20 13:59:54.317558
5772edf8-d7ba-47d8-9386-40fa3b8095aa	9d11f875-d0bf-4afa-9940-e10513a83efa	apuesta_deduccion	120.00	540.00	420.00	9b9fe60a-367a-4ad8-b6e7-c2adfc1338a0	Apuesta en: "Joel pasara la materia de TESEBADA?" · opción: "Si" · cuota ×1.0000 · ganancia proyectada: $120.00	2026-04-20 14:00:26.2312
48b49d63-ce72-4772-9efa-d6cf41310f7e	9c4aaf43-8b29-46d4-a410-b7bc8d9dfe81	apuesta_deduccion	100.00	390.00	290.00	2aaefa26-9646-4de3-9773-f161872d38a3	Apuesta en: "Prueba 2 de historial" · opción: "Si" · cuota ×1.8000 · ganancia proyectada: $180.00	2026-04-20 14:26:47.772458
772c4852-a019-42e9-9f16-b06de1b48f25	99856cdf-3124-4a8b-930c-86b9e6087866	bienvenida	500.00	0.00	500.00	\N	Saldo de bienvenida asignado al registrarse	2026-04-20 15:03:16.955112
a3466f63-abba-4e90-b50c-3838d541b1fe	99856cdf-3124-4a8b-930c-86b9e6087866	apuesta_deduccion	51.00	500.00	449.00	a6c80a15-c459-4a23-a15a-68d3b1f52e86	Apuesta en: "¿Quién ganará el partido?" · opción: "Equipo A" · cuota ×1.8000 · ganancia proyectada: $91.80	2026-04-20 15:07:23.316124
e432ba6c-bcdd-47c9-a3bb-0ede8c91d56c	9d11f875-d0bf-4afa-9940-e10513a83efa	apuesta_deduccion	105.00	420.00	315.00	37b635c2-8280-479c-beb4-0e70fb277cc7	Apuesta en: "Puedo intentar una remontada epica del semestre?" · opción: "Claro que si" · cuota ×1.8000 · ganancia proyectada: $189.00	2026-05-06 15:20:46.070167
4b698c20-8447-450a-8aad-0e3c45bcd2cf	2bed359b-90d4-4251-806b-6076b7c0a1bd	apuesta_deduccion	101.00	266.00	165.00	e636ec98-68b2-4fdc-99c2-27226c4aea2c	Apuesta en: "Puedo intentar una remontada epica del semestre?" · opción: "Claro que no" · cuota ×1.8000 · ganancia proyectada: $181.80	2026-05-06 15:21:23.69125
3b5997f8-b77a-4da8-8335-5a8809b1ad41	9d11f875-d0bf-4afa-9940-e10513a83efa	ganancia	90.00	315.00	405.00	2f642238-42f0-4a42-a7c0-5dea515b94d2	Ganancia en: "¿Quien es la mejor Zoe?" · cuota ×1.1250	2026-05-06 15:59:49.212305
55b1dbe1-086d-4cff-9848-e390a1c7b80c	2bed359b-90d4-4251-806b-6076b7c0a1bd	apuesta_deduccion	56.00	165.00	109.00	c6b65176-4770-4f54-b55d-94618c044864	Apuesta en: "Prueba de resultados" · opción: "Si" · cuota ×1.8000 · ganancia proyectada: $100.80	2026-05-06 16:02:44.116601
60c3ab19-90c4-4e39-8c41-9a70ace33dbb	99856cdf-3124-4a8b-930c-86b9e6087866	apuesta_deduccion	52.00	449.00	397.00	f9903714-b181-4f9b-9b22-dbfc4d57d42e	Apuesta en: "Prueba de resultados" · opción: "No" · cuota ×1.8000 · ganancia proyectada: $93.60	2026-05-06 16:03:01.046538
3e4e9fdf-ef7d-4677-89de-f5e7ae6497d8	9d11f875-d0bf-4afa-9940-e10513a83efa	apuesta_deduccion	55.00	405.00	350.00	aec9e4c4-71ee-4216-9e8f-7a6b827ab9bc	Apuesta en: "Prueba de resultados" · opción: "No" · cuota ×1.8000 · ganancia proyectada: $99.00	2026-05-06 16:04:03.642808
267ba151-2b90-4fc8-8a51-d25a8d52052e	99856cdf-3124-4a8b-930c-86b9e6087866	ganancia	93.60	397.00	490.60	f9903714-b181-4f9b-9b22-dbfc4d57d42e	Ganancia en: "Prueba de resultados" · cuota ×1.8000	2026-05-06 16:10:02.53694
5c32edbc-98c8-4ae3-bcd9-79816761c0a9	9d11f875-d0bf-4afa-9940-e10513a83efa	ganancia	99.00	350.00	449.00	aec9e4c4-71ee-4216-9e8f-7a6b827ab9bc	Ganancia en: "Prueba de resultados" · cuota ×1.8000	2026-05-06 16:10:02.53694
9fccfe60-5230-47bd-a670-6b51a8aef9b9	2bed359b-90d4-4251-806b-6076b7c0a1bd	apuesta_deduccion	54.00	109.00	55.00	0821e211-f267-4795-8fdd-9bc7b5d75cc9	Apuesta en: "Prueba general" · opción: "Parte 1 es si" · cuota ×1.8000 · ganancia proyectada: $97.20	2026-05-24 15:31:39.523956
47e36260-d71e-4ba0-a5fe-7db3c55a36ce	99856cdf-3124-4a8b-930c-86b9e6087866	apuesta_deduccion	53.00	490.60	437.60	32da875d-8aff-426d-be17-b25ff3b60420	Apuesta en: "Prueba general" · opción: "Parte 2 es Si" · cuota ×1.8000 · ganancia proyectada: $95.40	2026-05-24 15:33:21.321158
5ef10a32-0f0e-4e86-bee4-c2435da70b40	2bed359b-90d4-4251-806b-6076b7c0a1bd	ganancia	97.20	55.00	152.20	0821e211-f267-4795-8fdd-9bc7b5d75cc9	Ganancia en: "Prueba general" · cuota ×1.8000	2026-05-24 15:51:51.607064
56008d64-bbb8-4ea8-88fe-ee1af3bf2a76	216dafa9-5f81-4bac-8880-9186725d4657	bienvenida	500.00	0.00	500.00	\N	Saldo de bienvenida asignado al registrarse	2026-05-24 16:36:06.343289
e5464fa5-ad0f-4999-82c2-1dad3c91383f	99856cdf-3124-4a8b-930c-86b9e6087866	apuesta_deduccion	51.00	437.60	386.60	961c5c67-ebb2-476c-8424-7ee8b6ead299	Apuesta en: "¿Quién ganara la batalla 1 a 1 entre Ricardo y Clemente?" · opción: "El Tigre" · cuota ×1.8000 · ganancia proyectada: $91.80	2026-05-24 16:45:29.797172
b73b3668-88ef-46a9-a4f6-2463dc31ab99	2bed359b-90d4-4251-806b-6076b7c0a1bd	apuesta_deduccion	51.00	152.20	101.20	7a3b0652-ca61-4d60-83df-dae4211822dd	Apuesta en: "¿Quién ganara la batalla 1 a 1 entre Ricardo y Clemente?" · opción: "Clementiza" · cuota ×3.0000 · ganancia proyectada: $153.00	2026-05-24 16:57:11.040916
a23060bc-6216-42e5-bfb6-efec29dc6f84	2bed359b-90d4-4251-806b-6076b7c0a1bd	apuesta_deduccion	51.00	101.20	50.20	9c2c272c-3e4a-475b-8ac3-f5e3073adb29	Apuesta en: "Prueba de participantes" · opción: "Si" · cuota ×1.8000 · ganancia proyectada: $91.80	2026-05-24 17:11:44.940874
7a1ef656-173a-44b8-8c4d-44ab5f61e4a3	99856cdf-3124-4a8b-930c-86b9e6087866	apuesta_deduccion	51.00	386.60	335.60	b6432994-c7cb-4a68-94ad-d52aa38747fd	Apuesta en: "Prueba de los segundos" · opción: "si" · cuota ×1.8000 · ganancia proyectada: $91.80	2026-05-24 17:19:26.271082
481b3a91-e121-45ce-b762-93903fbd5f1a	99856cdf-3124-4a8b-930c-86b9e6087866	apuesta_deduccion	53.00	335.60	282.60	4ea9fa49-f626-4c69-83a7-470f2ad1c208	Apuesta en: "Prueba de los segundos" · opción: "no" · cuota ×1.8000 · ganancia proyectada: $95.40	2026-05-24 17:20:22.628299
b797c4dd-be40-4337-9e51-95f292a6fe68	99856cdf-3124-4a8b-930c-86b9e6087866	ganancia	95.40	282.60	378.00	4ea9fa49-f626-4c69-83a7-470f2ad1c208	Ganancia en: "Prueba de los segundos" · cuota ×1.8000	2026-05-24 17:31:43.423348
c90dad22-5a9f-4bab-85e8-c2a729eb33a3	2bed359b-90d4-4251-806b-6076b7c0a1bd	ganancia	91.80	50.20	142.00	9c2c272c-3e4a-475b-8ac3-f5e3073adb29	Ganancia en: "Prueba de participantes" · cuota ×1.8000	2026-05-24 17:32:25.719837
366f7bd9-5a49-4125-8194-3d962503a8c1	99856cdf-3124-4a8b-930c-86b9e6087866	apuesta_deduccion	50.00	378.00	328.00	5bbdaee2-893b-4fc0-80ad-4c88888940d2	Apuesta en: "Prueba de montos" · opción: "si" · cuota ×1.8000 · ganancia proyectada: $90.00	2026-05-24 17:38:36.628065
8b2a6bba-3d72-43b5-a2a8-3239755cc23c	99856cdf-3124-4a8b-930c-86b9e6087866	apuesta_deduccion	50.00	328.00	278.00	fed3eba3-9b29-40ba-b88f-8deab6c90c52	Apuesta en: "Apuesta prueba Bloqueo" · opción: "Si" · cuota ×1.8000 · ganancia proyectada: $90.00	2026-05-24 20:09:34.349679
20bafc79-95ba-42a4-abd1-0805f3d0bf41	d546048a-a343-4865-9123-ce49208cd45a	bienvenida	500.00	0.00	500.00	\N	Saldo de bienvenida asignado al registrarse	2026-05-24 21:05:40.922104
32254074-35bc-4f39-9800-b9a67a5e0dc1	37d4b325-2151-4683-8003-c2990c23b6fd	bienvenida	500.00	0.00	500.00	\N	Saldo de bienvenida asignado al registrarse	2026-05-25 04:15:04.741772
6a60e6e7-d6d9-4cfa-bd32-bb657b7473aa	37d4b325-2151-4683-8003-c2990c23b6fd	apuesta_deduccion	50.00	500.00	450.00	437d917c-e519-4198-9a00-56129bbb7d16	Apuesta en: "Prueba de apuesta ganancias" · opción: "Si" · cuota ×1.0000 · ganancia proyectada: $50.00	2026-05-25 04:46:14.973008
77226551-3af2-40c5-ac04-25bbc5b33f3f	37d4b325-2151-4683-8003-c2990c23b6fd	apuesta_deduccion	50.00	450.00	400.00	76179d38-e83d-4a1a-841c-3881a093af79	Apuesta en: "Verificador de cuenta regresiva" · opción: "Si" · cuota ×1.5000 · ganancia proyectada: $75.00	2026-05-25 05:33:20.930096
3292694a-eb81-4803-87e0-05d73dbbdc32	2bed359b-90d4-4251-806b-6076b7c0a1bd	apuesta_deduccion	50.00	142.00	92.00	a01acc6c-cc18-4330-8bbd-e58f59b4be8a	Apuesta en: "Visualizacion apuesta" · opción: "Si" · cuota ×1.8000 · ganancia proyectada: $90.00	2026-05-25 05:54:26.40087
5fa88aae-b5c6-4362-81d9-d592cb44210b	37d4b325-2151-4683-8003-c2990c23b6fd	apuesta_deduccion	50.00	400.00	350.00	19ba3cff-50d8-4b75-9cff-5605512e292b	Apuesta en: "Visualizacion apuesta" · opción: "nO" · cuota ×1.8000 · ganancia proyectada: $90.00	2026-05-25 05:54:38.905356
8e973abe-c135-4680-94d9-e5fdcdd3b2ce	2bed359b-90d4-4251-806b-6076b7c0a1bd	apuesta_deduccion	50.00	92.00	42.00	14ebb993-f415-4d76-a48d-5a087745e352	Apuesta en: "dddddddddd" · opción: "sI" · cuota ×1.8000 · ganancia proyectada: $90.00	2026-05-25 05:55:23.805525
c4d8b135-bf23-4438-b090-9a23501605d3	37d4b325-2151-4683-8003-c2990c23b6fd	apuesta_deduccion	50.00	350.00	300.00	4a97690f-950c-4746-a4c9-cd9e4ec9c116	Apuesta en: "dddddddddd" · opción: "nO" · cuota ×1.8000 · ganancia proyectada: $90.00	2026-05-25 05:55:34.204857
2159d144-76bb-470e-b3ac-d548bdae956f	37d4b325-2151-4683-8003-c2990c23b6fd	apuesta_deduccion	100.00	300.00	200.00	319b7415-afbf-43c6-b35d-29ad92e6e17c	Apuesta en: "¿Quién ganara la batalla 1 a 1 entre Ricardo y Clemente?" · opción: "El Tigre" · cuota ×1.8000 · ganancia proyectada: $180.00	2026-05-25 06:11:36.943016
d87dff8f-802c-4bce-b1a2-688bf213d208	37d4b325-2151-4683-8003-c2990c23b6fd	apuesta_deduccion	50.00	200.00	150.00	46ae42aa-1801-4355-9a43-f48165e90eb7	Apuesta en: "¿Quién ganará el partido?" · opción: "Equipo A" · cuota ×1.8000 · ganancia proyectada: $90.00	2026-05-25 06:16:44.962271
69219760-520d-463e-9570-316117ea99c8	37d4b325-2151-4683-8003-c2990c23b6fd	apuesta_deduccion	50.00	150.00	100.00	4f265ead-47e1-4c9b-a490-29c6171bd7b6	Apuesta en: "Prueba de actualizacion de saldos automaticamente" · opción: "ew" · cuota ×1.8000 · ganancia proyectada: $90.00	2026-05-25 06:22:43.732923
49ed0e03-4845-46fe-bca1-fd14c94b4e02	37d4b325-2151-4683-8003-c2990c23b6fd	apuesta_deduccion	50.00	100.00	50.00	79d08cf5-b6ed-4bc4-879d-97a9ad1dcee3	Apuesta en: "SJJSJSJSJSJSJ" · opción: "SD" · cuota ×1.8000 · ganancia proyectada: $90.00	2026-05-25 06:25:43.864558
a6f74ee5-965f-4243-87a5-299fc37eb149	37d4b325-2151-4683-8003-c2990c23b6fd	apuesta_deduccion	50.00	50.00	0.00	dc72c5f8-30dd-47bf-b15c-f1f14ea4a0e0	Apuesta en: "DDDDDDDDDDDDDD" · opción: "SI" · cuota ×1.8000 · ganancia proyectada: $90.00	2026-05-25 06:26:36.313256
38f2c65a-4396-4cf5-a54f-9a2bdc7ad5cf	37d4b325-2151-4683-8003-c2990c23b6fd	ganancia	90.00	0.00	90.00	dc72c5f8-30dd-47bf-b15c-f1f14ea4a0e0	Ganancia en: "DDDDDDDDDDDDDD" · cuota ×1.8000	2026-05-25 06:28:20.270376
d77fa8fc-4b3c-4739-8c6a-3bc599edf0b1	37d4b325-2151-4683-8003-c2990c23b6fd	ganancia	90.00	90.00	180.00	79d08cf5-b6ed-4bc4-879d-97a9ad1dcee3	Ganancia en: "SJJSJSJSJSJSJ" · cuota ×1.8000	2026-05-25 06:28:30.212744
68f9e00f-4e8e-493a-ab99-bd2cd8fc4f1b	37d4b325-2151-4683-8003-c2990c23b6fd	ganancia	90.00	180.00	270.00	4f265ead-47e1-4c9b-a490-29c6171bd7b6	Ganancia en: "Prueba de actualizacion de saldos automaticamente" · cuota ×1.8000	2026-05-25 06:28:53.371183
980c49d9-87f6-44d4-8041-9d14fd6ca258	37d4b325-2151-4683-8003-c2990c23b6fd	ganancia	90.00	270.00	360.00	4a97690f-950c-4746-a4c9-cd9e4ec9c116	Ganancia en: "dddddddddd" · cuota ×1.8000	2026-05-25 06:32:14.973539
8d377efd-3820-4692-8352-479704ec2b5e	2bed359b-90d4-4251-806b-6076b7c0a1bd	ganancia	90.00	42.00	132.00	a01acc6c-cc18-4330-8bbd-e58f59b4be8a	Ganancia en: "Visualizacion apuesta" · cuota ×1.8000	2026-05-25 06:32:30.623015
1645b347-d88e-48b6-acbd-d6b776d81d3e	37d4b325-2151-4683-8003-c2990c23b6fd	apuesta_deduccion	200.00	360.00	160.00	05ddaf28-9c65-4472-848a-a435cd012951	Apuesta en: "Apuestas universales" · opción: "Si" · cuota ×1.8000 · ganancia proyectada: $360.00	2026-05-27 06:06:51.328336
323750ad-4a3d-4577-8044-b14b596d5938	37d4b325-2151-4683-8003-c2990c23b6fd	apuesta_deduccion	50.00	160.00	110.00	6ead78c7-9176-4497-9285-57e846a9114c	Apuesta en: "Apuesta total pruebas" · opción: "Si" · cuota ×2.2500 · ganancia proyectada: $112.50	2026-05-27 06:19:25.205137
f7dfff67-4074-4e59-ab86-dad65e90068e	37d4b325-2151-4683-8003-c2990c23b6fd	retiro	100.00	110.00	10.00	b00cdff6-5cc2-4cda-81d6-d39816760214	Retiro solicitado · comisión 4%: $4.00 · monto neto: $96.00	2026-05-27 06:22:16.536103
8852c250-144e-4f18-ba20-5b5f4c01adf2	37d4b325-2151-4683-8003-c2990c23b6fd	recarga	100.00	10.00	110.00	1ca5582a-652b-4591-b6e2-6ea03a83e4cc	Recarga ficticia · método: tarjeta_ficticia	2026-05-27 06:22:25.690757
4b5a16bc-7915-47e8-aab9-d78a0c777f74	37d4b325-2151-4683-8003-c2990c23b6fd	recarga	100.00	110.00	210.00	f6f574f1-40c6-403c-a958-f3cd41fcb66f	Recarga ficticia · método: tarjeta_ficticia	2026-05-27 06:31:09.564812
e868fc66-494f-46eb-8f9d-28ee17b5ebe7	2bed359b-90d4-4251-806b-6076b7c0a1bd	apuesta_deduccion	50.00	132.00	82.00	9a882c30-00c4-49a5-80e2-2097ac11e6f3	Apuesta en: "Apuesta total pruebas" · opción: "Si" · cuota ×2.2500 · ganancia proyectada: $112.50	2026-05-27 06:34:54.945328
1f11f01c-623a-4ff8-a29b-4068f6ea8b1e	37d4b325-2151-4683-8003-c2990c23b6fd	ganancia	360.00	210.00	570.00	05ddaf28-9c65-4472-848a-a435cd012951	Ganancia en: "Apuestas universales" · cuota ×1.8000	2026-05-27 06:37:36.447923
9668920b-0da7-4e07-bff2-d874cc0c04d4	9c4aaf43-8b29-46d4-a410-b7bc8d9dfe81	ganancia	180.00	290.00	470.00	2aaefa26-9646-4de3-9773-f161872d38a3	Ganancia en: "Prueba 2 de historial" · cuota ×1.8000	2026-05-27 06:46:30.290775
a0791c96-8e03-4294-b376-b9379ab932a6	9c4aaf43-8b29-46d4-a410-b7bc8d9dfe81	ganancia	990.00	470.00	1460.00	7a8ee242-40d4-4f21-9ca2-ea4a062c69ab	Ganancia en: "Joel pasara la materia de TESEBADA?" · cuota ×9.0000	2026-05-27 06:49:58.2651
46ef9423-ddcf-4475-9bd2-b900065b3e98	756529dc-d9a3-418d-b2fd-eeb49737123e	bienvenida	500.00	0.00	500.00	\N	Saldo de bienvenida asignado al registrarse	2026-05-27 22:16:10.332184
2eb94cb4-1b53-475c-9d03-d4d09619a7ca	c83ee6d7-d883-421d-a68b-6f8ac5838c6c	bienvenida	500.00	0.00	500.00	\N	Saldo de bienvenida asignado al registrarse	2026-05-27 22:36:26.410166
311453cb-21a0-49a8-a1a7-abe7eb781d57	37d4b325-2151-4683-8003-c2990c23b6fd	apuesta_deduccion	50.00	570.00	520.00	a2fdbdc9-9efa-4317-92d2-9e5d55c5318b	Apuesta en: "Prueba Concreta" · opción: "Si" · cuota ×2.2500 · ganancia proyectada: $112.50	2026-05-27 23:01:58.027422
e366bd4d-99e0-4e87-a827-a3a82bb7917a	756529dc-d9a3-418d-b2fd-eeb49737123e	apuesta_deduccion	50.00	500.00	450.00	38fc4111-9b92-4c00-8858-2e513eae7bb5	Apuesta en: "Prueba Concreta" · opción: "No" · cuota ×1.5000 · ganancia proyectada: $75.00	2026-05-28 00:49:27.811921
01d152ee-1fe5-4a1c-9f86-b43e2a8e1208	212415cd-d7c7-4dab-97bd-d94bfd7d7ff0	bienvenida	500.00	0.00	500.00	\N	Saldo de bienvenida asignado al registrarse	2026-05-28 00:55:09.470324
ce410e5c-cad7-4851-a46c-e8ece2ab0381	756529dc-d9a3-418d-b2fd-eeb49737123e	apuesta_deduccion	50.00	450.00	400.00	e51608a2-96ce-4dcc-987d-dfd8fd5e47a7	Apuesta en: "Prueba correcta" · opción: "Si" · cuota ×1.8000 · ganancia proyectada: $90.00	2026-05-28 01:05:48.01069
ff330bc3-6e80-4038-a52d-cd214c9fca06	212415cd-d7c7-4dab-97bd-d94bfd7d7ff0	apuesta_deduccion	50.00	500.00	450.00	3b4580d4-6547-42c8-91d6-368d5b298692	Apuesta en: "¿Quién ganara la batalla 1 a 1 entre Ricardo y Clemente?" · opción: "El Tigre" · cuota ×1.8000 · ganancia proyectada: $90.00	2026-05-28 01:06:21.090307
a5c1a8a7-e1c7-4393-9aed-85d81ac50ef0	756529dc-d9a3-418d-b2fd-eeb49737123e	apuesta_deduccion	50.00	400.00	350.00	bb7e6c5a-067c-429a-8a77-30f12c7d4cac	Apuesta en: "Apuesta total pruebas" · opción: "Si" · cuota ×2.2500 · ganancia proyectada: $112.50	2026-05-28 01:39:45.20458
41f2295a-57b5-4c1a-ab78-28cf37c49512	37d4b325-2151-4683-8003-c2990c23b6fd	devolucion	50.00	520.00	570.00	6ead78c7-9176-4497-9285-57e846a9114c	Reembolso por cancelación de apuesta: "Apuesta total pruebas"	2026-05-28 01:40:27.037336
eba6eb1d-0d58-478b-be3e-1f3908d24eb1	2bed359b-90d4-4251-806b-6076b7c0a1bd	devolucion	50.00	82.00	132.00	9a882c30-00c4-49a5-80e2-2097ac11e6f3	Reembolso por cancelación de apuesta: "Apuesta total pruebas"	2026-05-28 01:40:27.037336
ed9dadbd-8adf-47a9-a3f0-f3061ee2f3bb	756529dc-d9a3-418d-b2fd-eeb49737123e	devolucion	50.00	350.00	400.00	bb7e6c5a-067c-429a-8a77-30f12c7d4cac	Reembolso por cancelación de apuesta: "Apuesta total pruebas"	2026-05-28 01:40:27.037336
5c8c4ee4-6a41-4ff7-b0f8-4fd8b41e5743	756529dc-d9a3-418d-b2fd-eeb49737123e	apuesta_deduccion	50.00	400.00	350.00	27f8e8d8-729e-4fee-bfd7-3dc81cc0fae3	Apuesta en: "Apuesta Probar Funcionalidad" · opción: "Si" · cuota ×1.8000 · ganancia proyectada: $90.00	2026-05-30 15:13:07.391017
fb9cd5c6-507d-4df8-b315-d4425a0881d1	37d4b325-2151-4683-8003-c2990c23b6fd	apuesta_deduccion	50.00	570.00	520.00	4537dae5-8162-4a14-a74e-2e2dfed25fc9	Apuesta en: "Apuesta Probar Funcionalidad" · opción: "No" · cuota ×1.8000 · ganancia proyectada: $90.00	2026-05-30 15:13:41.434664
5772f066-21f4-4d23-98e4-b3f6c4f3ac52	756529dc-d9a3-418d-b2fd-eeb49737123e	ganancia	90.00	350.00	440.00	27f8e8d8-729e-4fee-bfd7-3dc81cc0fae3	Ganancia en: "Apuesta Probar Funcionalidad" · cuota ×1.8000	2026-05-30 15:32:24.255457
7055dff9-7fbd-4118-9add-2284c1c3aa92	756529dc-d9a3-418d-b2fd-eeb49737123e	retiro	100.00	440.00	340.00	9ec9f256-1335-4d82-b09d-e5159e5723bb	Retiro solicitado · comisión 4%: $4.00 · monto neto: $96.00	2026-05-30 15:52:08.577043
3afd629a-8347-4f74-9077-e48eabcc93ea	756529dc-d9a3-418d-b2fd-eeb49737123e	recarga	32.00	340.00	372.00	\N	sdddd	2026-05-30 23:28:58.890354
56bca522-225c-4d15-a16f-b95a29dbb019	756529dc-d9a3-418d-b2fd-eeb49737123e	recarga	500.00	372.00	872.00	\N	Bono de bienvenida-Abonado	2026-05-30 23:35:10.701229
54faef73-be43-4852-8cf7-36c0a7ae97c4	756529dc-d9a3-418d-b2fd-eeb49737123e	retiro	100.00	872.00	772.00	\N	Penalización por mal uso	2026-05-30 23:38:55.142141
ad82e546-d8fb-4c0f-b164-ce9f5883a006	37d4b325-2151-4683-8003-c2990c23b6fd	apuesta_deduccion	50.00	520.00	470.00	ad76f44c-fc53-4e2e-8f31-b957c93b20cc	Apuesta en: "Apuesta Prueba reembolso" · opción: "Si" · cuota ×1.8000 · ganancia proyectada: $90.00	2026-05-30 23:54:28.243681
d98cf573-36f9-4d0c-96ed-31d21fda4174	756529dc-d9a3-418d-b2fd-eeb49737123e	apuesta_deduccion	50.00	772.00	722.00	0eb49b4a-d98d-4b10-91b7-caf51b03e21c	Apuesta en: "Apuesta Prueba reembolso" · opción: "No" · cuota ×1.8000 · ganancia proyectada: $90.00	2026-05-30 23:54:43.814703
b2e002e4-4b97-4eb9-b34b-8c644f22c14a	37d4b325-2151-4683-8003-c2990c23b6fd	devolucion	50.00	470.00	520.00	ad76f44c-fc53-4e2e-8f31-b957c93b20cc	Reembolso por cancelación de apuesta: "Apuesta Prueba reembolso"	2026-05-30 23:56:11.512837
89c86660-4edd-4c89-a5c7-9e973ee2c369	756529dc-d9a3-418d-b2fd-eeb49737123e	devolucion	50.00	722.00	772.00	0eb49b4a-d98d-4b10-91b7-caf51b03e21c	Reembolso por cancelación de apuesta: "Apuesta Prueba reembolso"	2026-05-30 23:56:11.512837
796d094c-157b-46d2-96a5-415e09e96fb1	756529dc-d9a3-418d-b2fd-eeb49737123e	apuesta_deduccion	100.00	772.00	672.00	f90dca7f-41df-497f-af91-a29466cfbb1c	Apuesta en: "Prueba de ganadores" · opción: "Kappa" · cuota ×1.8000 · ganancia proyectada: $180.00	2026-05-31 00:03:18.77715
fef8f464-2c7d-4752-8e47-e43a7e4c81f9	37d4b325-2151-4683-8003-c2990c23b6fd	apuesta_deduccion	100.00	520.00	420.00	300a1e21-e9e3-4b5f-aa3a-8c44921a48f3	Apuesta en: "Prueba de ganadores" · opción: "Juas" · cuota ×1.8000 · ganancia proyectada: $180.00	2026-05-31 00:03:47.223692
b9ae376f-bcc3-4012-844f-d27b6c57b867	212415cd-d7c7-4dab-97bd-d94bfd7d7ff0	apuesta_deduccion	200.00	450.00	250.00	8d3cd302-27fc-417f-9df6-300275a8b3a2	Apuesta en: "Prueba de ganadores" · opción: "Kappa" · cuota ×1.8000 · ganancia proyectada: $360.00	2026-05-31 00:04:52.045697
2d5840bf-0d25-457a-ab20-b57163c0b716	756529dc-d9a3-418d-b2fd-eeb49737123e	ganancia	180.00	672.00	852.00	f90dca7f-41df-497f-af91-a29466cfbb1c	Ganancia en: "Prueba de ganadores" · cuota ×1.8000	2026-05-31 00:09:55.982937
f50f3b6d-42d8-4416-919d-ab165b6bcb50	212415cd-d7c7-4dab-97bd-d94bfd7d7ff0	ganancia	360.00	250.00	610.00	8d3cd302-27fc-417f-9df6-300275a8b3a2	Ganancia en: "Prueba de ganadores" · cuota ×1.8000	2026-05-31 00:09:55.982937
\.


--
-- TOC entry 5245 (class 0 OID 17512)
-- Dependencies: 218
-- Data for Name: usuarios; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.usuarios (id, nombre, apellido_paterno, apellido_materno, fecha_nacimiento, telefono, alias, correo, password_hash, estado, rol, intentos_fallidos, bloqueado_hasta, acepto_terminos, fecha_registro, fecha_actualizacion, token_invalidado_en) FROM stdin;
99856cdf-3124-4a8b-930c-86b9e6087866	ricardo	rodriguez	valerio	2003-09-29	6672680804	gambler67	correo@gmail.com	$2a$10$dx3qkGaejE9vIJacIDz5yOXLuDzNmnEXSlGCvuAJS3N8uU1KP0NlW	verificada	usuario	0	\N	t	2026-04-20 15:03:16.955112	2026-05-24 17:32:14.064808	\N
d546048a-a343-4865-9123-ce49208cd45a	<script>alert('XSS')</script>	test	Lopez	2001-07-19	6673489405	Ladron	ladron@gmail.com	$2a$10$8ic5r8hBLCbm65IXCvNfX.5OaycZXxasfPFOFKpDwQ70fjoyeh20q	no_verificado	usuario	0	\N	t	2026-05-24 21:05:40.922104	2026-05-30 17:28:41.862815	\N
756529dc-d9a3-418d-b2fd-eeb49737123e	Sujeto	Principal		2000-06-23	6673497878	usuario A	usuarioa@gmail.com	$2a$10$XSvs6X0mjMbjMcdPzkl50u8VYpFH2Z4vjN6pffzhb4kS/zbNDSXje	verificada	usuario	0	\N	t	2026-05-27 22:16:10.332184	2026-05-31 10:45:37.944986	\N
37d4b325-2151-4683-8003-c2990c23b6fd	Registro	Usuario		2003-12-19	6673489527	Registro-Prueba	pruebaregistro@gmail.com	$2a$10$TisMtvzWfWMBUXEi5XbSguZfS.5l4qVgyGwAKLgZKqYBsZlvadFSm	verificada	usuario	0	\N	t	2026-05-25 04:15:04.741772	2026-05-31 10:45:46.414517	\N
9d11f875-d0bf-4afa-9940-e10513a83efa	Juan	Pérez	\N	2000-01-15	6671234567	juanp	juan@ejemplo.com	$2a$10$J2..46caxcxTu7IFYx5kfOa3q3OmUw8Coul6MBl1bmPO6UE4CLolK	no_verificado	administrador	0	\N	t	2026-04-10 01:38:13.114877	2026-05-31 10:52:23.145916	\N
212415cd-d7c7-4dab-97bd-d94bfd7d7ff0	Usuario	Cazares		2007-01-30	6654789524	usuario C	usuarioc@gmail.com	$2a$10$mTVZgZQ8dqLbYG8gM948g.hSBheueiGSsdZaeRgQon0dkj7Ea9GNu	verificada	usuario	0	\N	t	2026-05-28 00:55:09.470324	2026-05-31 10:52:29.647022	\N
3f507fb0-512f-4b63-b5b7-7950c5d1d2d2	Pablo	Ponce	\N	2000-10-19	6673489405	Zacatar	pablo2@ejemplo.com	$2a$10$FqL2OS3Z4JLxcp5ZUoh1.ukKPe9prmgmxzaHb5tOanAJpUvh2st2K	no_verificado	usuario	0	\N	t	2026-04-10 02:39:51.473691	2026-04-19 15:25:27.87993	\N
2bed359b-90d4-4251-806b-6076b7c0a1bd	PabloZac	pon	Lopez	2001-10-19	6673489403	Zacatar1	pabloponcelopez12@gmail.com	$2a$10$sX.TknIaqkAgEK./j3hyIOspTw5QeIXytrF0KR4WoAQKcttLjcFYy	bloqueada	usuario	5	2026-05-31 01:12:33.67694	t	2026-04-13 16:31:50.6733	2026-05-31 00:42:33.67694	\N
fec57d62-02cc-413d-a720-ac4be0506a7d	Carlos	Lopez	Garcia	2000-05-15	6671234568	carlosg	carlos@ejemplo.com	$2a$10$jgwcwlrDw49ILxvSZDv0XeAMhoq1hE7OGlue8GGrIy1RYj1OGvC8e	no_verificado	usuario	0	\N	t	2026-04-20 01:25:42.728255	2026-04-20 01:27:08.606851	\N
9c4aaf43-8b29-46d4-a410-b7bc8d9dfe81	Daniel	Lopez	Ponce	2000-10-19	6678429304	Daniel-Ska	dan12@hotmail.com	$2a$10$cOzx5LjDCtOGnE7RUNUsveLi8XY8FRSiKJAyak8etflayqKHlVe4.	no_verificado	usuario	0	\N	t	2026-04-20 13:50:19.458387	2026-05-27 06:46:11.105014	\N
216dafa9-5f81-4bac-8880-9186725d4657	Roman	Ponce		2001-07-26	6673488596	Roman	roman@gmail.com	$2a$10$9dU9aR26SixkFGjqwpf6cuTq7x/wVMWS.ndx69ujIpZD/RXahaGz6	no_verificado	usuario	0	\N	t	2026-05-24 16:36:06.343289	2026-05-24 16:36:54.998451	\N
c83ee6d7-d883-421d-a68b-6f8ac5838c6c	Usuario	Bernardo		2002-06-05	4498759805	usuario B	usuariob@gmail.com	$2a$10$SRgcjp.jJyqMgoTdxwIKjO2sRZLt0Yc/hmEWbj13agW0sR1LJo06m	no_verificado	usuario	0	\N	t	2026-05-27 22:36:26.410166	2026-05-28 01:14:04.986255	\N
\.


--
-- TOC entry 5016 (class 2606 OID 17600)
-- Name: apuestas apuestas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.apuestas
    ADD CONSTRAINT apuestas_pkey PRIMARY KEY (id);


--
-- TOC entry 5065 (class 2606 OID 25583)
-- Name: categorias categorias_nombre_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categorias
    ADD CONSTRAINT categorias_nombre_key UNIQUE (nombre);


--
-- TOC entry 5067 (class 2606 OID 25581)
-- Name: categorias categorias_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categorias
    ADD CONSTRAINT categorias_pkey PRIMARY KEY (id);


--
-- TOC entry 4989 (class 2606 OID 17511)
-- Name: configuracion_sistema configuracion_sistema_clave_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.configuracion_sistema
    ADD CONSTRAINT configuracion_sistema_clave_key UNIQUE (clave);


--
-- TOC entry 4991 (class 2606 OID 17509)
-- Name: configuracion_sistema configuracion_sistema_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.configuracion_sistema
    ADD CONSTRAINT configuracion_sistema_pkey PRIMARY KEY (id);


--
-- TOC entry 5002 (class 2606 OID 17547)
-- Name: documentos_identidad documentos_identidad_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documentos_identidad
    ADD CONSTRAINT documentos_identidad_pkey PRIMARY KEY (id);


--
-- TOC entry 5004 (class 2606 OID 17549)
-- Name: documentos_identidad documentos_identidad_usuario_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documentos_identidad
    ADD CONSTRAINT documentos_identidad_usuario_id_key UNIQUE (usuario_id);


--
-- TOC entry 5061 (class 2606 OID 17778)
-- Name: intentos_fraude intentos_fraude_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intentos_fraude
    ADD CONSTRAINT intentos_fraude_pkey PRIMARY KEY (id);


--
-- TOC entry 5056 (class 2606 OID 17760)
-- Name: intentos_login intentos_login_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intentos_login
    ADD CONSTRAINT intentos_login_pkey PRIMARY KEY (id);


--
-- TOC entry 5063 (class 2606 OID 25550)
-- Name: logs_admin logs_admin_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.logs_admin
    ADD CONSTRAINT logs_admin_pkey PRIMARY KEY (id);


--
-- TOC entry 5024 (class 2606 OID 17621)
-- Name: opciones_apuesta opciones_apuesta_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.opciones_apuesta
    ADD CONSTRAINT opciones_apuesta_pkey PRIMARY KEY (id);


--
-- TOC entry 5030 (class 2606 OID 17637)
-- Name: participaciones participaciones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.participaciones
    ADD CONSTRAINT participaciones_pkey PRIMARY KEY (id);


--
-- TOC entry 5047 (class 2606 OID 17719)
-- Name: recargas recargas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recargas
    ADD CONSTRAINT recargas_pkey PRIMARY KEY (id);


--
-- TOC entry 5036 (class 2606 OID 17670)
-- Name: resultados_apuesta resultados_apuesta_apuesta_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resultados_apuesta
    ADD CONSTRAINT resultados_apuesta_apuesta_id_key UNIQUE (apuesta_id);


--
-- TOC entry 5038 (class 2606 OID 17668)
-- Name: resultados_apuesta resultados_apuesta_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resultados_apuesta
    ADD CONSTRAINT resultados_apuesta_pkey PRIMARY KEY (id);


--
-- TOC entry 5051 (class 2606 OID 17738)
-- Name: retiros retiros_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.retiros
    ADD CONSTRAINT retiros_pkey PRIMARY KEY (id);


--
-- TOC entry 5012 (class 2606 OID 17573)
-- Name: saldos saldos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.saldos
    ADD CONSTRAINT saldos_pkey PRIMARY KEY (id);


--
-- TOC entry 5014 (class 2606 OID 17575)
-- Name: saldos saldos_usuario_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.saldos
    ADD CONSTRAINT saldos_usuario_id_key UNIQUE (usuario_id);


--
-- TOC entry 5044 (class 2606 OID 17701)
-- Name: transacciones transacciones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transacciones
    ADD CONSTRAINT transacciones_pkey PRIMARY KEY (id);


--
-- TOC entry 5009 (class 2606 OID 17551)
-- Name: documentos_identidad uq_numero_documento; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documentos_identidad
    ADD CONSTRAINT uq_numero_documento UNIQUE (numero_documento);


--
-- TOC entry 5032 (class 2606 OID 17639)
-- Name: participaciones uq_usuario_opcion; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.participaciones
    ADD CONSTRAINT uq_usuario_opcion UNIQUE (usuario_id, opcion_id);


--
-- TOC entry 4996 (class 2606 OID 17531)
-- Name: usuarios usuarios_alias_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_alias_key UNIQUE (alias);


--
-- TOC entry 4998 (class 2606 OID 17533)
-- Name: usuarios usuarios_correo_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_correo_key UNIQUE (correo);


--
-- TOC entry 5000 (class 2606 OID 17529)
-- Name: usuarios usuarios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_pkey PRIMARY KEY (id);


--
-- TOC entry 5017 (class 1259 OID 17610)
-- Name: idx_apuestas_activas; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_apuestas_activas ON public.apuestas USING btree (fecha_finalizacion, estado) WHERE (estado = 'activa'::public.estado_apuesta);


--
-- TOC entry 5018 (class 1259 OID 17607)
-- Name: idx_apuestas_creador; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_apuestas_creador ON public.apuestas USING btree (creador_id);


--
-- TOC entry 5019 (class 1259 OID 17606)
-- Name: idx_apuestas_estado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_apuestas_estado ON public.apuestas USING btree (estado);


--
-- TOC entry 5020 (class 1259 OID 17608)
-- Name: idx_apuestas_fecha_fin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_apuestas_fecha_fin ON public.apuestas USING btree (fecha_finalizacion);


--
-- TOC entry 5021 (class 1259 OID 17609)
-- Name: idx_apuestas_tendencia; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_apuestas_tendencia ON public.apuestas USING btree (es_tendencia) WHERE (es_tendencia = true);


--
-- TOC entry 5005 (class 1259 OID 17563)
-- Name: idx_docs_estado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_docs_estado ON public.documentos_identidad USING btree (estado);


--
-- TOC entry 5006 (class 1259 OID 17564)
-- Name: idx_docs_numero; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_docs_numero ON public.documentos_identidad USING btree (numero_documento);


--
-- TOC entry 5007 (class 1259 OID 17562)
-- Name: idx_docs_usuario; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_docs_usuario ON public.documentos_identidad USING btree (usuario_id);


--
-- TOC entry 5057 (class 1259 OID 17791)
-- Name: idx_fraude_sin_rev; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fraude_sin_rev ON public.intentos_fraude USING btree (revisado) WHERE (revisado = false);


--
-- TOC entry 5058 (class 1259 OID 17790)
-- Name: idx_fraude_tipo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fraude_tipo ON public.intentos_fraude USING btree (tipo);


--
-- TOC entry 5059 (class 1259 OID 17789)
-- Name: idx_fraude_usuario; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fraude_usuario ON public.intentos_fraude USING btree (usuario_id);


--
-- TOC entry 5052 (class 1259 OID 17768)
-- Name: idx_login_fecha; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_login_fecha ON public.intentos_login USING btree (fecha);


--
-- TOC entry 5053 (class 1259 OID 17767)
-- Name: idx_login_ip; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_login_ip ON public.intentos_login USING btree (ip_address);


--
-- TOC entry 5054 (class 1259 OID 17766)
-- Name: idx_login_usuario; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_login_usuario ON public.intentos_login USING btree (usuario_id);


--
-- TOC entry 5022 (class 1259 OID 17627)
-- Name: idx_opciones_apuesta_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_opciones_apuesta_id ON public.opciones_apuesta USING btree (apuesta_id);


--
-- TOC entry 5025 (class 1259 OID 17656)
-- Name: idx_part_apuesta; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_part_apuesta ON public.participaciones USING btree (apuesta_id);


--
-- TOC entry 5026 (class 1259 OID 17658)
-- Name: idx_part_estado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_part_estado ON public.participaciones USING btree (estado);


--
-- TOC entry 5027 (class 1259 OID 17657)
-- Name: idx_part_opcion; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_part_opcion ON public.participaciones USING btree (opcion_id);


--
-- TOC entry 5028 (class 1259 OID 17655)
-- Name: idx_part_usuario; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_part_usuario ON public.participaciones USING btree (usuario_id);


--
-- TOC entry 5045 (class 1259 OID 17725)
-- Name: idx_recargas_usuario; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_recargas_usuario ON public.recargas USING btree (usuario_id);


--
-- TOC entry 5033 (class 1259 OID 17691)
-- Name: idx_resultados_apuesta; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_resultados_apuesta ON public.resultados_apuesta USING btree (apuesta_id);


--
-- TOC entry 5034 (class 1259 OID 17692)
-- Name: idx_resultados_estado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_resultados_estado ON public.resultados_apuesta USING btree (estado);


--
-- TOC entry 5048 (class 1259 OID 17750)
-- Name: idx_retiros_estado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_retiros_estado ON public.retiros USING btree (estado);


--
-- TOC entry 5049 (class 1259 OID 17749)
-- Name: idx_retiros_usuario; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_retiros_usuario ON public.retiros USING btree (usuario_id);


--
-- TOC entry 5010 (class 1259 OID 17581)
-- Name: idx_saldos_usuario; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_saldos_usuario ON public.saldos USING btree (usuario_id);


--
-- TOC entry 5039 (class 1259 OID 17709)
-- Name: idx_tx_fecha; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tx_fecha ON public.transacciones USING btree (fecha);


--
-- TOC entry 5040 (class 1259 OID 17710)
-- Name: idx_tx_referencia; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tx_referencia ON public.transacciones USING btree (referencia_id);


--
-- TOC entry 5041 (class 1259 OID 17708)
-- Name: idx_tx_tipo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tx_tipo ON public.transacciones USING btree (tipo);


--
-- TOC entry 5042 (class 1259 OID 17707)
-- Name: idx_tx_usuario; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tx_usuario ON public.transacciones USING btree (usuario_id);


--
-- TOC entry 4992 (class 1259 OID 17535)
-- Name: idx_usuarios_alias; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_usuarios_alias ON public.usuarios USING btree (alias);


--
-- TOC entry 4993 (class 1259 OID 17534)
-- Name: idx_usuarios_correo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_usuarios_correo ON public.usuarios USING btree (correo);


--
-- TOC entry 4994 (class 1259 OID 17536)
-- Name: idx_usuarios_estado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_usuarios_estado ON public.usuarios USING btree (estado);


--
-- TOC entry 5092 (class 2620 OID 17801)
-- Name: apuestas trg_apuestas_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_apuestas_updated_at BEFORE UPDATE ON public.apuestas FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- TOC entry 5094 (class 2620 OID 17803)
-- Name: resultados_apuesta trg_finalizar_en_confirmacion; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_finalizar_en_confirmacion BEFORE UPDATE ON public.resultados_apuesta FOR EACH ROW EXECUTE FUNCTION public.fn_finalizar_apuesta_al_confirmar();


--
-- TOC entry 5090 (class 2620 OID 17798)
-- Name: usuarios trg_saldo_bienvenida; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_saldo_bienvenida AFTER INSERT ON public.usuarios FOR EACH ROW EXECUTE FUNCTION public.fn_crear_saldo_bienvenida();


--
-- TOC entry 5093 (class 2620 OID 17805)
-- Name: participaciones trg_tendencia; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_tendencia AFTER INSERT OR UPDATE ON public.participaciones FOR EACH STATEMENT EXECUTE FUNCTION public.fn_recalcular_tendencia();


--
-- TOC entry 5091 (class 2620 OID 17800)
-- Name: usuarios trg_usuarios_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_usuarios_updated_at BEFORE UPDATE ON public.usuarios FOR EACH ROW EXECUTE FUNCTION public.fn_set_updated_at();


--
-- TOC entry 5071 (class 2606 OID 25584)
-- Name: apuestas apuestas_categoria_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.apuestas
    ADD CONSTRAINT apuestas_categoria_id_fkey FOREIGN KEY (categoria_id) REFERENCES public.categorias(id);


--
-- TOC entry 5072 (class 2606 OID 17601)
-- Name: apuestas apuestas_creador_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.apuestas
    ADD CONSTRAINT apuestas_creador_id_fkey FOREIGN KEY (creador_id) REFERENCES public.usuarios(id) ON DELETE RESTRICT;


--
-- TOC entry 5068 (class 2606 OID 17557)
-- Name: documentos_identidad documentos_identidad_revisado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documentos_identidad
    ADD CONSTRAINT documentos_identidad_revisado_por_fkey FOREIGN KEY (revisado_por) REFERENCES public.usuarios(id);


--
-- TOC entry 5069 (class 2606 OID 17552)
-- Name: documentos_identidad documentos_identidad_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documentos_identidad
    ADD CONSTRAINT documentos_identidad_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE RESTRICT;


--
-- TOC entry 5086 (class 2606 OID 17784)
-- Name: intentos_fraude intentos_fraude_revisado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intentos_fraude
    ADD CONSTRAINT intentos_fraude_revisado_por_fkey FOREIGN KEY (revisado_por) REFERENCES public.usuarios(id);


--
-- TOC entry 5087 (class 2606 OID 17779)
-- Name: intentos_fraude intentos_fraude_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intentos_fraude
    ADD CONSTRAINT intentos_fraude_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE SET NULL;


--
-- TOC entry 5085 (class 2606 OID 17761)
-- Name: intentos_login intentos_login_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intentos_login
    ADD CONSTRAINT intentos_login_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE SET NULL;


--
-- TOC entry 5088 (class 2606 OID 25551)
-- Name: logs_admin logs_admin_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.logs_admin
    ADD CONSTRAINT logs_admin_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.usuarios(id);


--
-- TOC entry 5089 (class 2606 OID 25556)
-- Name: logs_admin logs_admin_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.logs_admin
    ADD CONSTRAINT logs_admin_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id);


--
-- TOC entry 5073 (class 2606 OID 17622)
-- Name: opciones_apuesta opciones_apuesta_apuesta_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.opciones_apuesta
    ADD CONSTRAINT opciones_apuesta_apuesta_id_fkey FOREIGN KEY (apuesta_id) REFERENCES public.apuestas(id) ON DELETE CASCADE;


--
-- TOC entry 5074 (class 2606 OID 17645)
-- Name: participaciones participaciones_apuesta_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.participaciones
    ADD CONSTRAINT participaciones_apuesta_id_fkey FOREIGN KEY (apuesta_id) REFERENCES public.apuestas(id) ON DELETE RESTRICT;


--
-- TOC entry 5075 (class 2606 OID 17650)
-- Name: participaciones participaciones_opcion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.participaciones
    ADD CONSTRAINT participaciones_opcion_id_fkey FOREIGN KEY (opcion_id) REFERENCES public.opciones_apuesta(id) ON DELETE RESTRICT;


--
-- TOC entry 5076 (class 2606 OID 17640)
-- Name: participaciones participaciones_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.participaciones
    ADD CONSTRAINT participaciones_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE RESTRICT;


--
-- TOC entry 5082 (class 2606 OID 17720)
-- Name: recargas recargas_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recargas
    ADD CONSTRAINT recargas_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE RESTRICT;


--
-- TOC entry 5077 (class 2606 OID 17671)
-- Name: resultados_apuesta resultados_apuesta_apuesta_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resultados_apuesta
    ADD CONSTRAINT resultados_apuesta_apuesta_id_fkey FOREIGN KEY (apuesta_id) REFERENCES public.apuestas(id) ON DELETE RESTRICT;


--
-- TOC entry 5078 (class 2606 OID 17686)
-- Name: resultados_apuesta resultados_apuesta_confirmado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resultados_apuesta
    ADD CONSTRAINT resultados_apuesta_confirmado_por_fkey FOREIGN KEY (confirmado_por) REFERENCES public.usuarios(id);


--
-- TOC entry 5079 (class 2606 OID 17676)
-- Name: resultados_apuesta resultados_apuesta_opcion_ganadora_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resultados_apuesta
    ADD CONSTRAINT resultados_apuesta_opcion_ganadora_id_fkey FOREIGN KEY (opcion_ganadora_id) REFERENCES public.opciones_apuesta(id);


--
-- TOC entry 5080 (class 2606 OID 17681)
-- Name: resultados_apuesta resultados_apuesta_propuesto_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resultados_apuesta
    ADD CONSTRAINT resultados_apuesta_propuesto_por_fkey FOREIGN KEY (propuesto_por) REFERENCES public.usuarios(id);


--
-- TOC entry 5083 (class 2606 OID 17744)
-- Name: retiros retiros_procesado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.retiros
    ADD CONSTRAINT retiros_procesado_por_fkey FOREIGN KEY (procesado_por) REFERENCES public.usuarios(id);


--
-- TOC entry 5084 (class 2606 OID 17739)
-- Name: retiros retiros_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.retiros
    ADD CONSTRAINT retiros_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE RESTRICT;


--
-- TOC entry 5070 (class 2606 OID 17576)
-- Name: saldos saldos_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.saldos
    ADD CONSTRAINT saldos_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE RESTRICT;


--
-- TOC entry 5081 (class 2606 OID 17702)
-- Name: transacciones transacciones_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transacciones
    ADD CONSTRAINT transacciones_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE RESTRICT;


-- Completed on 2026-06-01 12:53:09

--
-- PostgreSQL database dump complete
--

\unrestrict CvbJx3gUXDa0qRxqqBI32GNBPcWJ2kDmFs5fmEEn5apmsfLdeBvtCELi3Hzs0jN

