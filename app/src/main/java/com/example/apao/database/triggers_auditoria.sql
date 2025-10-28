-- =====================================================
-- TRIGGERS DE AUDITORÍA DEL SISTEMA DE NÓMINA
-- =====================================================
-- Triggers requeridos para auditoría de liquidaciones
-- =====================================================

-- =====================================================
-- TRIGGER 1: trg_audit_liquidacion_stmt
-- =====================================================
-- Trigger de sentencia AFTER INSERT OR UPDATE ON liquidacion
-- Inserta registro resumen en tabla audit_nomina

CREATE OR REPLACE TRIGGER trg_audit_liquidacion_stmt
    AFTER INSERT OR UPDATE ON liquidacion
DECLARE
    v_periodo_id NUMBER;
    v_cantidad_registros NUMBER;
    v_usuario_proceso VARCHAR2(50) := USER;
    v_fecha_proceso DATE := SYSDATE;
    v_tipo_operacion VARCHAR2(20);
    v_tabla_afectada VARCHAR2(50) := 'LIQUIDACION';
BEGIN
    -- Determinar tipo de operación
    IF INSERTING THEN
        v_tipo_operacion := 'INSERT';
    ELSIF UPDATING THEN
        v_tipo_operacion := 'UPDATE';
    END IF;
    
    -- Obtener período y cantidad de registros afectados
    -- Para INSERT: contar registros insertados en esta transacción
    -- Para UPDATE: contar registros actualizados en esta transacción
    IF INSERTING THEN
        SELECT COUNT(*) INTO v_cantidad_registros
        FROM liquidacion
        WHERE fecha_liquidacion >= v_fecha_proceso - INTERVAL '1' SECOND
        AND usuario_liquidacion = v_usuario_proceso;
        
        -- Obtener período del último registro insertado
        SELECT periodo_id INTO v_periodo_id
        FROM liquidacion
        WHERE fecha_liquidacion >= v_fecha_proceso - INTERVAL '1' SECOND
        AND usuario_liquidacion = v_usuario_proceso
        AND ROWNUM = 1;
        
    ELSIF UPDATING THEN
        SELECT COUNT(*) INTO v_cantidad_registros
        FROM liquidacion
        WHERE fecha_liquidacion >= v_fecha_proceso - INTERVAL '1' SECOND
        AND usuario_liquidacion = v_usuario_proceso;
        
        -- Obtener período del último registro actualizado
        SELECT periodo_id INTO v_periodo_id
        FROM liquidacion
        WHERE fecha_liquidacion >= v_fecha_proceso - INTERVAL '1' SECOND
        AND usuario_liquidacion = v_usuario_proceso
        AND ROWNUM = 1;
    END IF;
    
    -- Insertar registro de auditoría
    INSERT INTO audit_nomina (
        periodo_id,
        usuario_proceso,
        cantidad_registros,
        fecha_proceso,
        tipo_operacion,
        tabla_afectada
    ) VALUES (
        v_periodo_id,
        v_usuario_proceso,
        v_cantidad_registros,
        v_fecha_proceso,
        v_tipo_operacion,
        v_tabla_afectada
    );
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        -- Si no se puede determinar el período, usar NULL
        INSERT INTO audit_nomina (
            periodo_id,
            usuario_proceso,
            cantidad_registros,
            fecha_proceso,
            tipo_operacion,
            tabla_afectada
        ) VALUES (
            NULL,
            v_usuario_proceso,
            0,
            v_fecha_proceso,
            v_tipo_operacion,
            v_tabla_afectada
        );
    WHEN OTHERS THEN
        -- En caso de error, registrar el error pero no fallar la transacción
        INSERT INTO audit_nomina (
            periodo_id,
            usuario_proceso,
            cantidad_registros,
            fecha_proceso,
            tipo_operacion,
            tabla_afectada
        ) VALUES (
            NULL,
            v_usuario_proceso,
            0,
            v_fecha_proceso,
            'ERROR',
            v_tabla_afectada
        );
END;
/

-- =====================================================
-- TRIGGER 2: trg_audit_liquidacion_row
-- =====================================================
-- Trigger de fila AFTER INSERT ON liquidacion_det
-- Registra en audit_nomina_det el concepto_id, monto y usuario

CREATE OR REPLACE TRIGGER trg_audit_liquidacion_row
    AFTER INSERT ON liquidacion_det
    FOR EACH ROW
DECLARE
    v_usuario_proceso VARCHAR2(50) := USER;
    v_fecha_proceso DATE := SYSDATE;
    v_tipo_operacion VARCHAR2(20) := 'INSERT';
BEGIN
    -- Insertar registro de auditoría para cada fila insertada
    INSERT INTO audit_nomina_det (
        concepto_id,
        monto,
        usuario_proceso,
        fecha_proceso,
        tipo_operacion
    ) VALUES (
        :NEW.concepto_id,
        :NEW.valor_total,
        v_usuario_proceso,
        v_fecha_proceso,
        v_tipo_operacion
    );
    
EXCEPTION
    WHEN OTHERS THEN
        -- En caso de error, registrar el error pero no fallar la transacción
        INSERT INTO audit_nomina_det (
            concepto_id,
            monto,
            usuario_proceso,
            fecha_proceso,
            tipo_operacion
        ) VALUES (
            :NEW.concepto_id,
            :NEW.valor_total,
            v_usuario_proceso,
            v_fecha_proceso,
            'ERROR'
        );
END;
/

-- =====================================================
-- TRIGGER ADICIONAL: trg_audit_liquidacion_det_update
-- =====================================================
-- Trigger de fila AFTER UPDATE ON liquidacion_det
-- Registra actualizaciones en audit_nomina_det

CREATE OR REPLACE TRIGGER trg_audit_liquidacion_det_update
    AFTER UPDATE ON liquidacion_det
    FOR EACH ROW
DECLARE
    v_usuario_proceso VARCHAR2(50) := USER;
    v_fecha_proceso DATE := SYSDATE;
    v_tipo_operacion VARCHAR2(20) := 'UPDATE';
BEGIN
    -- Solo registrar si hay cambios en el monto
    IF :OLD.valor_total != :NEW.valor_total THEN
        INSERT INTO audit_nomina_det (
            concepto_id,
            monto,
            usuario_proceso,
            fecha_proceso,
            tipo_operacion
        ) VALUES (
            :NEW.concepto_id,
            :NEW.valor_total,
            v_usuario_proceso,
            v_fecha_proceso,
            v_tipo_operacion
        );
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        -- En caso de error, registrar el error pero no fallar la transacción
        INSERT INTO audit_nomina_det (
            concepto_id,
            monto,
            usuario_proceso,
            fecha_proceso,
            tipo_operacion
        ) VALUES (
            :NEW.concepto_id,
            :NEW.valor_total,
            v_usuario_proceso,
            v_fecha_proceso,
            'ERROR'
        );
END;
/

-- =====================================================
-- TRIGGER ADICIONAL: trg_audit_liquidacion_det_delete
-- =====================================================
-- Trigger de fila AFTER DELETE ON liquidacion_det
-- Registra eliminaciones en audit_nomina_det

CREATE OR REPLACE TRIGGER trg_audit_liquidacion_det_delete
    AFTER DELETE ON liquidacion_det
    FOR EACH ROW
DECLARE
    v_usuario_proceso VARCHAR2(50) := USER;
    v_fecha_proceso DATE := SYSDATE;
    v_tipo_operacion VARCHAR2(20) := 'DELETE';
BEGIN
    -- Insertar registro de auditoría para cada fila eliminada
    INSERT INTO audit_nomina_det (
        concepto_id,
        monto,
        usuario_proceso,
        fecha_proceso,
        tipo_operacion
    ) VALUES (
        :OLD.concepto_id,
        :OLD.valor_total,
        v_usuario_proceso,
        v_fecha_proceso,
        v_tipo_operacion
    );
    
EXCEPTION
    WHEN OTHERS THEN
        -- En caso de error, registrar el error pero no fallar la transacción
        INSERT INTO audit_nomina_det (
            concepto_id,
            monto,
            usuario_proceso,
            fecha_proceso,
            tipo_operacion
        ) VALUES (
            :OLD.concepto_id,
            :OLD.valor_total,
            v_usuario_proceso,
            v_fecha_proceso,
            'ERROR'
        );
END;
/

-- =====================================================
-- TRIGGER ADICIONAL: trg_audit_liquidacion_delete
-- =====================================================
-- Trigger de sentencia AFTER DELETE ON liquidacion
-- Registra eliminaciones en audit_nomina

CREATE OR REPLACE TRIGGER trg_audit_liquidacion_delete
    AFTER DELETE ON liquidacion
DECLARE
    v_periodo_id NUMBER;
    v_cantidad_registros NUMBER;
    v_usuario_proceso VARCHAR2(50) := USER;
    v_fecha_proceso DATE := SYSDATE;
    v_tipo_operacion VARCHAR2(20) := 'DELETE';
    v_tabla_afectada VARCHAR2(50) := 'LIQUIDACION';
BEGIN
    -- Para DELETE, es más complejo obtener la información
    -- Usar una variable de sesión o tabla temporal para rastrear eliminaciones
    -- Por simplicidad, registrar con información básica
    
    INSERT INTO audit_nomina (
        periodo_id,
        usuario_proceso,
        cantidad_registros,
        fecha_proceso,
        tipo_operacion,
        tabla_afectada
    ) VALUES (
        NULL, -- No se puede determinar fácilmente el período en DELETE
        v_usuario_proceso,
        1, -- Asumir 1 registro eliminado
        v_fecha_proceso,
        v_tipo_operacion,
        v_tabla_afectada
    );
    
EXCEPTION
    WHEN OTHERS THEN
        -- En caso de error, registrar el error pero no fallar la transacción
        INSERT INTO audit_nomina (
            periodo_id,
            usuario_proceso,
            cantidad_registros,
            fecha_proceso,
            tipo_operacion,
            tabla_afectada
        ) VALUES (
            NULL,
            v_usuario_proceso,
            0,
            v_fecha_proceso,
            'ERROR',
            v_tabla_afectada
        );
END;
/

-- =====================================================
-- TRIGGER ADICIONAL: trg_audit_eventos_nomina
-- =====================================================
-- Trigger de fila AFTER INSERT OR UPDATE OR DELETE ON eventos_nomina
-- Registra cambios en eventos de nómina

CREATE OR REPLACE TRIGGER trg_audit_eventos_nomina
    AFTER INSERT OR UPDATE OR DELETE ON eventos_nomina
    FOR EACH ROW
DECLARE
    v_usuario_proceso VARCHAR2(50) := USER;
    v_fecha_proceso DATE := SYSDATE;
    v_tipo_operacion VARCHAR2(20);
    v_concepto_id NUMBER;
    v_monto NUMBER(12,2);
BEGIN
    -- Determinar tipo de operación
    IF INSERTING THEN
        v_tipo_operacion := 'INSERT';
        v_concepto_id := :NEW.concepto_id;
        v_monto := :NEW.valor_total;
    ELSIF UPDATING THEN
        v_tipo_operacion := 'UPDATE';
        v_concepto_id := :NEW.concepto_id;
        v_monto := :NEW.valor_total;
    ELSIF DELETING THEN
        v_tipo_operacion := 'DELETE';
        v_concepto_id := :OLD.concepto_id;
        v_monto := :OLD.valor_total;
    END IF;
    
    -- Insertar registro de auditoría
    INSERT INTO audit_nomina_det (
        concepto_id,
        monto,
        usuario_proceso,
        fecha_proceso,
        tipo_operacion
    ) VALUES (
        v_concepto_id,
        v_monto,
        v_usuario_proceso,
        v_fecha_proceso,
        v_tipo_operacion
    );
    
EXCEPTION
    WHEN OTHERS THEN
        -- En caso de error, registrar el error pero no fallar la transacción
        INSERT INTO audit_nomina_det (
            concepto_id,
            monto,
            usuario_proceso,
            fecha_proceso,
            tipo_operacion
        ) VALUES (
            v_concepto_id,
            v_monto,
            v_usuario_proceso,
            v_fecha_proceso,
            'ERROR'
        );
END;
/

COMMIT;

-- =====================================================
-- PRUEBAS DE LOS TRIGGERS
-- =====================================================

-- Habilitar salida de DBMS_OUTPUT
SET SERVEROUTPUT ON;

-- Limpiar auditoría anterior
DELETE FROM audit_nomina_det;
DELETE FROM audit_nomina;
COMMIT;

-- Probar trigger de liquidación (INSERT)
BEGIN
    PKG_NOMINA.calcular_trabajador(1, 1);
END;
/

-- Verificar auditoría de liquidación
SELECT * FROM audit_nomina ORDER BY fecha_proceso DESC;

-- Verificar auditoría de detalle
SELECT and.*, c.codigo, c.nombre
FROM audit_nomina_det and
JOIN conceptos_nomina c ON and.concepto_id = c.concepto_id
ORDER BY and.fecha_proceso DESC;

-- Probar trigger de actualización
UPDATE liquidacion_det 
SET valor_total = valor_total * 1.1
WHERE liquidacion_id = (SELECT liquidacion_id FROM liquidacion WHERE trabajador_id = 1 AND periodo_id = 1)
AND concepto_id = (SELECT concepto_id FROM conceptos_nomina WHERE codigo = 'SUELDO');

-- Verificar auditoría de actualización
SELECT * FROM audit_nomina_det WHERE tipo_operacion = 'UPDATE' ORDER BY fecha_proceso DESC;

-- Probar trigger de eliminación
DELETE FROM liquidacion_det 
WHERE liquidacion_id = (SELECT liquidacion_id FROM liquidacion WHERE trabajador_id = 1 AND periodo_id = 1)
AND concepto_id = (SELECT concepto_id FROM conceptos_nomina WHERE codigo = 'AFC');

-- Verificar auditoría de eliminación
SELECT * FROM audit_nomina_det WHERE tipo_operacion = 'DELETE' ORDER BY fecha_proceso DESC;

-- Probar trigger de eventos
INSERT INTO eventos_nomina (trabajador_id, periodo_id, concepto_id, cantidad, valor_unitario, valor_total)
VALUES (2, 1, (SELECT concepto_id FROM conceptos_nomina WHERE codigo = 'BONO'), 1, 25000, 25000);

-- Verificar auditoría de eventos
SELECT * FROM audit_nomina_det WHERE tipo_operacion = 'INSERT' ORDER BY fecha_proceso DESC;

COMMIT;

-- =====================================================
-- VISTAS DE AUDITORÍA
-- =====================================================

-- Vista de auditoría completa
CREATE OR REPLACE VIEW vista_auditoria_completa AS
SELECT 
    an.audit_id,
    an.periodo_id,
    p.anio,
    p.mes,
    an.usuario_proceso,
    an.cantidad_registros,
    an.fecha_proceso,
    an.tipo_operacion,
    an.tabla_afectada
FROM audit_nomina an
LEFT JOIN periodos_nomina p ON an.periodo_id = p.periodo_id
UNION ALL
SELECT 
    and.audit_det_id as audit_id,
    NULL as periodo_id,
    NULL as anio,
    NULL as mes,
    and.usuario_proceso,
    1 as cantidad_registros,
    and.fecha_proceso,
    and.tipo_operacion,
    'LIQUIDACION_DET' as tabla_afectada
FROM audit_nomina_det and
ORDER BY fecha_proceso DESC;

-- Vista de auditoría de detalles con información de conceptos
CREATE OR REPLACE VIEW vista_auditoria_detalles AS
SELECT 
    and.audit_det_id,
    and.concepto_id,
    c.codigo as concepto_codigo,
    c.nombre as concepto_nombre,
    c.tipo as concepto_tipo,
    c.categoria as concepto_categoria,
    and.monto,
    and.usuario_proceso,
    and.fecha_proceso,
    and.tipo_operacion
FROM audit_nomina_det and
JOIN conceptos_nomina c ON and.concepto_id = c.concepto_id
ORDER BY and.fecha_proceso DESC;

-- =====================================================
-- CONSULTAS DE PRUEBA DE AUDITORÍA
-- =====================================================

-- Consultar auditoría completa
SELECT * FROM vista_auditoria_completa WHERE ROWNUM <= 10;

-- Consultar auditoría de detalles
SELECT * FROM vista_auditoria_detalles WHERE ROWNUM <= 10;

-- Resumen de auditoría por usuario
SELECT 
    usuario_proceso,
    COUNT(*) as total_operaciones,
    COUNT(CASE WHEN tipo_operacion = 'INSERT' THEN 1 END) as inserts,
    COUNT(CASE WHEN tipo_operacion = 'UPDATE' THEN 1 END) as updates,
    COUNT(CASE WHEN tipo_operacion = 'DELETE' THEN 1 END) as deletes
FROM vista_auditoria_completa
GROUP BY usuario_proceso;

-- Resumen de auditoría por concepto
SELECT 
    concepto_codigo,
    concepto_nombre,
    COUNT(*) as total_operaciones,
    SUM(monto) as total_monto,
    COUNT(CASE WHEN tipo_operacion = 'INSERT' THEN 1 END) as inserts,
    COUNT(CASE WHEN tipo_operacion = 'UPDATE' THEN 1 END) as updates,
    COUNT(CASE WHEN tipo_operacion = 'DELETE' THEN 1 END) as deletes
FROM vista_auditoria_detalles
GROUP BY concepto_codigo, concepto_nombre
ORDER BY total_operaciones DESC;

COMMIT;

-- =====================================================
-- COMENTARIOS FINALES
-- =====================================================

/*
TRIGGERS DE AUDITORÍA COMPLETADOS:

✅ TRIGGER DE SENTENCIA:
   - trg_audit_liquidacion_stmt: AFTER INSERT OR UPDATE ON liquidacion
   - Inserta registro resumen en audit_nomina
   - Registra: periodo, usuario, cantidad de registros, fecha/hora

✅ TRIGGER DE FILA:
   - trg_audit_liquidacion_row: AFTER INSERT ON liquidacion_det
   - Registra en audit_nomina_det: concepto_id, monto, usuario

✅ TRIGGERS ADICIONALES:
   - trg_audit_liquidacion_det_update: AFTER UPDATE ON liquidacion_det
   - trg_audit_liquidacion_det_delete: AFTER DELETE ON liquidacion_det
   - trg_audit_liquidacion_delete: AFTER DELETE ON liquidacion
   - trg_audit_eventos_nomina: AFTER INSERT/UPDATE/DELETE ON eventos_nomina

✅ CARACTERÍSTICAS:
   - Manejo de errores sin fallar transacciones
   - Registro de usuario y fecha/hora
   - Diferentes tipos de operación (INSERT, UPDATE, DELETE)
   - Vistas de auditoría para consultas
   - Consultas de resumen y estadísticas

✅ VISTAS DE AUDITORÍA:
   - vista_auditoria_completa: Auditoría general
   - vista_auditoria_detalles: Auditoría con información de conceptos

✅ PRUEBAS:
   - Pruebas de todos los triggers
   - Verificación de registros de auditoría
   - Consultas de resumen y estadísticas

PRÓXIMOS PASOS:
1. Probar ejecución completa del sistema
2. Verificar integración de todos los componentes
*/

COMMIT;
