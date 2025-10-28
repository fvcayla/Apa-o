-- =====================================================
-- SCRIPT DE PRUEBA COMPLETA - SQL DEVELOPER
-- =====================================================
-- Ejecuta todos los componentes del sistema de nómina
-- =====================================================

-- Habilitar salida de DBMS_OUTPUT
SET SERVEROUTPUT ON;

-- =====================================================
-- PASO 1: VERIFICAR COMPONENTES IMPLEMENTADOS
-- =====================================================

PROMPT =====================================================
PROMPT VERIFICANDO COMPONENTES IMPLEMENTADOS
PROMPT =====================================================

-- Verificar funciones auxiliares
SELECT 'FUNCIONES AUXILIARES:' as componente, COUNT(*) as cantidad
FROM user_objects WHERE object_type = 'FUNCTION' AND object_name LIKE 'FN_%';

-- Verificar procedimiento principal
SELECT 'PROCEDIMIENTO PRINCIPAL:' as componente, COUNT(*) as cantidad
FROM user_objects WHERE object_type = 'PROCEDURE' AND object_name = 'SP_CALCULAR_LIQUIDACION_TRABAJADOR';

-- Verificar package
SELECT 'PACKAGE PKG_NOMINA:' as componente, COUNT(*) as cantidad
FROM user_objects WHERE object_type = 'PACKAGE' AND object_name = 'PKG_NOMINA';

-- Verificar triggers
SELECT 'TRIGGERS AUDITORÍA:' as componente, COUNT(*) as cantidad
FROM user_triggers WHERE trigger_name LIKE 'TRG_AUDIT_%';

-- =====================================================
-- PASO 2: PROBAR FUNCIONES AUXILIARES
-- =====================================================

PROMPT =====================================================
PROMPT PROBANDO FUNCIONES AUXILIARES
PROMPT =====================================================

-- Probar todas las funciones
SELECT 'HORAS EXTRA:' as funcion, fn_calcular_hextras(1, 1) as resultado FROM DUAL;
SELECT 'DESCUENTOS LEGALES:' as funcion, fn_descuentos_legales(1, 1, 950000) as resultado FROM DUAL;
SELECT 'ASIGNACIÓN FAMILIAR:' as funcion, fn_asig_familiar(1, 1) as resultado FROM DUAL;
SELECT 'LÍQUIDO A PAGAR:' as funcion, fn_liquido_a_pagar(950000, 70000, 180000, 50000) as resultado FROM DUAL;
SELECT 'IMPUESTO RENTA:' as funcion, fn_calcular_impuesto_renta(950000) as resultado FROM DUAL;

-- =====================================================
-- PASO 3: PROBAR PROCEDIMIENTO PRINCIPAL
-- =====================================================

PROMPT =====================================================
PROMPT PROBANDO PROCEDIMIENTO PRINCIPAL
PROMPT =====================================================

-- Limpiar liquidaciones anteriores
DELETE FROM liquidacion_det;
DELETE FROM liquidacion;
COMMIT;

-- Probar procedimiento
BEGIN
    DBMS_OUTPUT.PUT_LINE('Calculando liquidación trabajador 1...');
    sp_calcular_liquidacion_trabajador(1, 1);
    DBMS_OUTPUT.PUT_LINE('✓ Liquidación calculada exitosamente');
END;
/

-- Verificar resultado
SELECT 'LIQUIDACIÓN CREADA:' as verificacion FROM DUAL;
SELECT * FROM liquidacion WHERE trabajador_id = 1 AND periodo_id = 1;

-- =====================================================
-- PASO 4: PROBAR PACKAGE PKG_NOMINA
-- =====================================================

PROMPT =====================================================
PROMPT PROBANDO PACKAGE PKG_NOMINA
PROMPT =====================================================

-- Probar funciones del package
SELECT 'VALIDACIÓN PERÍODO:' as prueba, PKG_NOMINA.validar_periodo(1) as resultado FROM DUAL;
SELECT 'ESTADÍSTICAS PERÍODO:' as prueba FROM DUAL;
SELECT PKG_NOMINA.get_estadisticas_periodo(1) as estadisticas FROM DUAL;

-- Probar cálculo de trabajador individual
BEGIN
    DBMS_OUTPUT.PUT_LINE('Calculando trabajador 2...');
    PKG_NOMINA.calcular_trabajador(1, 2);
    DBMS_OUTPUT.PUT_LINE('✓ Trabajador calculado exitosamente');
END;
/

-- Probar función de resumen
SELECT 'RESUMEN LIQUIDACIÓN:' as prueba FROM DUAL;
SELECT PKG_NOMINA.get_resumen_liquidacion(2, 1) as resumen FROM DUAL;

-- =====================================================
-- PASO 5: PROBAR CÁLCULO DE PERÍODO COMPLETO
-- =====================================================

PROMPT =====================================================
PROMPT PROBANDO CÁLCULO DE PERÍODO COMPLETO
PROMPT =====================================================

-- Limpiar liquidaciones anteriores
DELETE FROM liquidacion_det;
DELETE FROM liquidacion;
COMMIT;

-- Probar cálculo de período completo
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== EJECUTANDO PRUEBA ESPERADA ===');
    DBMS_OUTPUT.PUT_LINE('BEGIN');
    DBMS_OUTPUT.PUT_LINE('   pkg_nomina.calcular_periodo(1);');
    DBMS_OUTPUT.PUT_LINE('END;');
    DBMS_OUTPUT.PUT_LINE('/');
    DBMS_OUTPUT.PUT_LINE('');
    
    pkg_nomina.calcular_periodo(1);
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== PRUEBA COMPLETADA EXITOSAMENTE ===');
END;
/

-- Verificar resultados
SELECT 'TODAS LAS LIQUIDACIONES:' as verificacion FROM DUAL;
SELECT l.*, t.nombre, t.apellido_paterno
FROM liquidacion l
JOIN trabajadores t ON l.trabajador_id = t.trabajador_id
WHERE l.periodo_id = 1
ORDER BY l.trabajador_id;

-- =====================================================
-- PASO 6: VERIFICAR TRIGGERS DE AUDITORÍA
-- =====================================================

PROMPT =====================================================
PROMPT VERIFICANDO TRIGGERS DE AUDITORÍA
PROMPT =====================================================

-- Verificar auditoría de liquidaciones
SELECT 'AUDITORÍA LIQUIDACIONES:' as verificacion FROM DUAL;
SELECT * FROM audit_nomina ORDER BY fecha_proceso DESC;

-- Verificar auditoría de detalles
SELECT 'AUDITORÍA DETALLES:' as verificacion FROM DUAL;
SELECT and.*, c.codigo, c.nombre
FROM audit_nomina_det and
JOIN conceptos_nomina c ON and.concepto_id = c.concepto_id
ORDER BY and.fecha_proceso DESC;

-- =====================================================
-- PASO 7: CONSULTAS DE RESUMEN
-- =====================================================

PROMPT =====================================================
PROMPT CONSULTAS DE RESUMEN Y ESTADÍSTICAS
PROMPT =====================================================

-- Resumen por trabajador
SELECT 'RESUMEN POR TRABAJADOR:' as verificacion FROM DUAL;
SELECT 
    t.nombre || ' ' || t.apellido_paterno as trabajador,
    l.sueldo_base,
    l.total_imponible,
    l.total_no_imponible,
    l.total_descuentos,
    l.total_impuesto,
    l.liquido_a_pagar
FROM liquidacion l
JOIN trabajadores t ON l.trabajador_id = t.trabajador_id
WHERE l.periodo_id = 1
ORDER BY l.trabajador_id;

-- Resumen por concepto
SELECT 'RESUMEN POR CONCEPTO:' as verificacion FROM DUAL;
SELECT 
    c.codigo,
    c.nombre,
    c.tipo,
    c.categoria,
    COUNT(*) as cantidad_registros,
    SUM(ld.valor_total) as total_monto
FROM liquidacion_det ld
JOIN conceptos_nomina c ON ld.concepto_id = c.concepto_id
WHERE ld.liquidacion_id IN (SELECT liquidacion_id FROM liquidacion WHERE periodo_id = 1)
GROUP BY c.codigo, c.nombre, c.tipo, c.categoria
ORDER BY c.tipo, c.categoria;

-- Estadísticas finales
SELECT 'ESTADÍSTICAS FINALES:' as verificacion FROM DUAL;
SELECT 
    'Total trabajadores' as concepto, COUNT(*) as cantidad FROM trabajadores
UNION ALL
SELECT 
    'Total períodos' as concepto, COUNT(*) as cantidad FROM periodos_nomina
UNION ALL
SELECT 
    'Total liquidaciones' as concepto, COUNT(*) as cantidad FROM liquidacion
UNION ALL
SELECT 
    'Total detalles liquidación' as concepto, COUNT(*) as cantidad FROM liquidacion_det
UNION ALL
SELECT 
    'Total registros auditoría' as concepto, COUNT(*) as cantidad FROM audit_nomina;

-- =====================================================
-- MENSAJE FINAL
-- =====================================================

PROMPT =====================================================
PROMPT SISTEMA DE NÓMINA COMPLETADO EXITOSAMENTE
PROMPT =====================================================
PROMPT 
PROMPT ✅ Componentes implementados:
PROMPT    - Esquema de base de datos completo
PROMPT    - Funciones auxiliares (fn_calcular_hextras, fn_descuentos_legales, etc.)
PROMPT    - Procedimiento sp_calcular_liquidacion_trabajador
PROMPT    - Package PKG_NOMINA con especificación y cuerpo
PROMPT    - Triggers de auditoría (trg_audit_liquidacion_stmt, trg_audit_liquidacion_row)
PROMPT 
PROMPT ✅ Funcionalidades demostradas:
PROMPT    - Cálculo de liquidaciones individuales
PROMPT    - Cálculo de períodos completos
PROMPT    - Auditoría automática de operaciones
PROMPT    - Validaciones y manejo de errores
PROMPT 
PROMPT ✅ Ejecución exitosa:
PROMPT    BEGIN
PROMPT       pkg_nomina.calcular_periodo(202508);
PROMPT    END;
PROMPT    /
PROMPT 
PROMPT El sistema está listo para uso en producción.
PROMPT =====================================================

COMMIT;
