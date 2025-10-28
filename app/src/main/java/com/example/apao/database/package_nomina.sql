-- =====================================================
-- PACKAGE PKG_NOMINA - ESPECIFICACIÓN
-- =====================================================
-- Package integral que centraliza la lógica de nómina
-- Especificación pública del package
-- =====================================================

CREATE OR REPLACE PACKAGE PKG_NOMINA AS
    -- =====================================================
    -- PROCEDIMIENTOS PÚBLICOS
    -- =====================================================
    
    -- Procedimiento principal para calcular período completo
    PROCEDURE calcular_periodo(p_periodo_id IN NUMBER);
    
    -- Procedimiento para calcular trabajador específico
    PROCEDURE calcular_trabajador(p_periodo_id IN NUMBER, p_trabajador_id IN NUMBER);
    
    -- =====================================================
    -- FUNCIONES PÚBLICAS
    -- =====================================================
    
    -- Función para obtener líquido de un trabajador
    FUNCTION get_liquido(p_trabajador_id IN NUMBER, p_periodo_id IN NUMBER) RETURN NUMBER;
    
    -- Función para obtener resumen de liquidación
    FUNCTION get_resumen_liquidacion(p_trabajador_id IN NUMBER, p_periodo_id IN NUMBER) RETURN VARCHAR2;
    
    -- Función para validar período
    FUNCTION validar_periodo(p_periodo_id IN NUMBER) RETURN BOOLEAN;
    
    -- Función para obtener estadísticas del período
    FUNCTION get_estadisticas_periodo(p_periodo_id IN NUMBER) RETURN VARCHAR2;
    
    -- =====================================================
    -- CONSTANTES PÚBLICAS
    -- =====================================================
    
    -- Códigos de error
    c_error_trabajador_no_existe CONSTANT NUMBER := -20010;
    c_error_periodo_no_existe CONSTANT NUMBER := -20011;
    c_error_liquidacion_existe CONSTANT NUMBER := -20012;
    c_error_calculo_liquidacion CONSTANT NUMBER := -20013;
    
    -- Estados
    c_estado_procesado CONSTANT VARCHAR2(20) := 'PROCESADO';
    c_estado_anulado CONSTANT VARCHAR2(20) := 'ANULADO';
    c_estado_abierto CONSTANT VARCHAR2(20) := 'ABIERTO';
    c_estado_cerrado CONSTANT VARCHAR2(20) := 'CERRADO';
    
END PKG_NOMINA;
/

-- =====================================================
-- PACKAGE PKG_NOMINA - CUERPO
-- =====================================================
-- Implementación del package con lógica privada y pública
-- =====================================================

CREATE OR REPLACE PACKAGE BODY PKG_NOMINA AS
    
    -- =====================================================
    -- VARIABLES Y CONSTANTES PRIVADAS
    -- =====================================================
    
    -- Variables para parámetros del sistema
    v_uf_valor NUMBER(15,4);
    v_tasa_afp NUMBER(15,4);
    v_tasa_salud NUMBER(15,4);
    v_tasa_afc NUMBER(15,4);
    v_tope_afp NUMBER(15,4);
    v_tope_salud NUMBER(15,4);
    
    -- Variables para control de proceso
    v_usuario_actual VARCHAR2(50) := USER;
    v_fecha_actual DATE := SYSDATE;
    
    -- Contadores para estadísticas
    v_total_trabajadores NUMBER := 0;
    v_trabajadores_procesados NUMBER := 0;
    v_trabajadores_con_error NUMBER := 0;
    
    -- =====================================================
    -- PROCEDIMIENTOS PRIVADOS
    -- =====================================================
    
    -- Procedimiento para cargar parámetros del sistema
    PROCEDURE cargar_parametros_sistema AS
    BEGIN
        SELECT valor INTO v_uf_valor FROM parametros_sistema WHERE codigo = 'UF_VALOR' AND estado = 'ACTIVO';
        SELECT valor INTO v_tasa_afp FROM parametros_sistema WHERE codigo = 'TASA_AFP' AND estado = 'ACTIVO';
        SELECT valor INTO v_tasa_salud FROM parametros_sistema WHERE codigo = 'TASA_SALUD' AND estado = 'ACTIVO';
        SELECT valor INTO v_tasa_afc FROM parametros_sistema WHERE codigo = 'TASA_AFC' AND estado = 'ACTIVO';
        SELECT valor INTO v_tope_afp FROM parametros_sistema WHERE codigo = 'TOPE_AFP' AND estado = 'ACTIVO';
        SELECT valor INTO v_tope_salud FROM parametros_sistema WHERE codigo = 'TOPE_SALUD' AND estado = 'ACTIVO';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20020, 'Parámetros del sistema no encontrados');
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20021, 'Error cargando parámetros: ' || SQLERRM);
    END cargar_parametros_sistema;
    
    -- Procedimiento para registrar detalle de liquidación
    PROCEDURE registrar_detalle(
        p_liquidacion_id IN NUMBER,
        p_concepto_id IN NUMBER,
        p_cantidad IN NUMBER,
        p_valor_unitario IN NUMBER,
        p_valor_total IN NUMBER,
        p_tipo_concepto IN VARCHAR2,
        p_categoria_concepto IN VARCHAR2
    ) AS
    BEGIN
        INSERT INTO liquidacion_det (
            liquidacion_id, concepto_id, cantidad, valor_unitario, valor_total,
            tipo_concepto, categoria_concepto
        ) VALUES (
            p_liquidacion_id, p_concepto_id, p_cantidad, p_valor_unitario, p_valor_total,
            p_tipo_concepto, p_categoria_concepto
        );
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20022, 'Error registrando detalle: ' || SQLERRM);
    END registrar_detalle;
    
    -- Procedimiento para validar topes legales
    PROCEDURE validar_topes(
        p_imponible IN NUMBER,
        p_tope_afp OUT NUMBER,
        p_tope_salud OUT NUMBER,
        p_imponible_afp OUT NUMBER,
        p_imponible_salud OUT NUMBER
    ) AS
    BEGIN
        p_tope_afp := v_tope_afp * v_uf_valor;
        p_tope_salud := v_tope_salud * v_uf_valor;
        
        p_imponible_afp := p_imponible;
        p_imponible_salud := p_imponible;
        
        IF p_imponible_afp > p_tope_afp THEN
            p_imponible_afp := p_tope_afp;
        END IF;
        
        IF p_imponible_salud > p_tope_salud THEN
            p_imponible_salud := p_tope_salud;
        END IF;
    END validar_topes;
    
    -- Procedimiento para calcular impuesto a la renta
    PROCEDURE calcular_impuesto(
        p_imponible IN NUMBER,
        p_impuesto OUT NUMBER
    ) AS
        v_imponible_uf NUMBER(15,4);
    BEGIN
        v_imponible_uf := p_imponible / v_uf_valor;
        p_impuesto := 0;
        
        -- Cálculo simplificado de impuesto
        IF v_imponible_uf > 13.5 THEN
            IF v_imponible_uf <= 30 THEN
                p_impuesto := (v_imponible_uf - 13.5) * v_uf_valor * 0.04;
            ELSIF v_imponible_uf <= 50 THEN
                p_impuesto := (30 - 13.5) * v_uf_valor * 0.04 + (v_imponible_uf - 30) * v_uf_valor * 0.08;
            ELSIF v_imponible_uf <= 70 THEN
                p_impuesto := (30 - 13.5) * v_uf_valor * 0.04 + (50 - 30) * v_uf_valor * 0.08 + (v_imponible_uf - 50) * v_uf_valor * 0.135;
            ELSE
                p_impuesto := (30 - 13.5) * v_uf_valor * 0.04 + (50 - 30) * v_uf_valor * 0.08 + (70 - 50) * v_uf_valor * 0.135 + (v_imponible_uf - 70) * v_uf_valor * 0.23;
            END IF;
        END IF;
    END calcular_impuesto;
    
    -- Procedimiento para procesar trabajador individual
    PROCEDURE procesar_trabajador(
        p_periodo_id IN NUMBER,
        p_trabajador_id IN NUMBER
    ) AS
        v_sueldo_base NUMBER(12,2);
        v_total_imponible NUMBER(12,2);
        v_total_no_imponible NUMBER(12,2);
        v_total_descuentos NUMBER(12,2);
        v_total_impuesto NUMBER(12,2);
        v_liquido_a_pagar NUMBER(12,2);
        v_liquidacion_id NUMBER;
        
        -- Cursor para eventos
        CURSOR c_eventos IS
            SELECT e.evento_id, e.concepto_id, c.codigo, c.nombre, c.tipo, c.categoria,
                   e.cantidad, e.valor_unitario, e.valor_total
            FROM eventos_nomina e
            JOIN conceptos_nomina c ON e.concepto_id = c.concepto_id
            WHERE e.trabajador_id = p_trabajador_id
            AND e.periodo_id = p_periodo_id
            ORDER BY c.tipo, c.categoria;
    BEGIN
        -- Obtener sueldo base
        SELECT sueldo_base INTO v_sueldo_base
        FROM trabajadores
        WHERE trabajador_id = p_trabajador_id;
        
        -- Calcular totales usando funciones auxiliares
        v_total_imponible := fn_calcular_total_imponible(p_trabajador_id, p_periodo_id);
        v_total_no_imponible := fn_calcular_total_no_imponible(p_trabajador_id, p_periodo_id);
        v_total_descuentos := fn_descuentos_legales(p_trabajador_id, p_periodo_id, v_total_imponible);
        v_total_impuesto := fn_calcular_impuesto_renta(v_total_imponible);
        v_liquido_a_pagar := fn_liquido_a_pagar(v_total_imponible, v_total_no_imponible, v_total_descuentos, v_total_impuesto);
        
        -- Insertar liquidación
        INSERT INTO liquidacion (
            trabajador_id, periodo_id, sueldo_base, total_imponible, total_no_imponible,
            total_descuentos, total_impuesto, liquido_a_pagar, fecha_liquidacion,
            usuario_liquidacion, estado
        ) VALUES (
            p_trabajador_id, p_periodo_id, v_sueldo_base, v_total_imponible, v_total_no_imponible,
            v_total_descuentos, v_total_impuesto, v_liquido_a_pagar, v_fecha_actual,
            v_usuario_actual, c_estado_procesado
        ) RETURNING liquidacion_id INTO v_liquidacion_id;
        
        -- Registrar detalle
        registrar_detalle(v_liquidacion_id, 
                         (SELECT concepto_id FROM conceptos_nomina WHERE codigo = 'SUELDO'),
                         1, v_sueldo_base, v_sueldo_base, 'IMPONIBLE', 'SUELDO');
        
        -- Procesar eventos
        FOR rec IN c_eventos LOOP
            registrar_detalle(v_liquidacion_id, rec.concepto_id, rec.cantidad, 
                            rec.valor_unitario, rec.valor_total, rec.tipo, rec.categoria);
        END LOOP;
        
        v_trabajadores_procesados := v_trabajadores_procesados + 1;
        
    EXCEPTION
        WHEN OTHERS THEN
            v_trabajadores_con_error := v_trabajadores_con_error + 1;
            RAISE;
    END procesar_trabajador;
    
    -- =====================================================
    -- PROCEDIMIENTOS PÚBLICOS
    -- =====================================================
    
    -- Procedimiento principal para calcular período completo
    PROCEDURE calcular_periodo(p_periodo_id IN NUMBER) AS
        v_periodo_existe NUMBER;
        v_total_trabajadores_periodo NUMBER;
    BEGIN
        -- Validar período
        SELECT COUNT(*) INTO v_periodo_existe
        FROM periodos_nomina
        WHERE periodo_id = p_periodo_id;
        
        IF v_periodo_existe = 0 THEN
            RAISE_APPLICATION_ERROR(c_error_periodo_no_existe, 'El período no existe');
        END IF;
        
        -- Cargar parámetros del sistema
        cargar_parametros_sistema;
        
        -- Inicializar contadores
        v_total_trabajadores := 0;
        v_trabajadores_procesados := 0;
        v_trabajadores_con_error := 0;
        
        -- Contar trabajadores activos
        SELECT COUNT(*) INTO v_total_trabajadores_periodo
        FROM trabajadores
        WHERE estado = 'ACTIVO';
        
        DBMS_OUTPUT.PUT_LINE('Iniciando cálculo de período ' || p_periodo_id);
        DBMS_OUTPUT.PUT_LINE('Total trabajadores a procesar: ' || v_total_trabajadores_periodo);
        
        -- Procesar todos los trabajadores activos usando bucle FOR
        FOR rec IN (
            SELECT trabajador_id, nombre, apellido_paterno
            FROM trabajadores
            WHERE estado = 'ACTIVO'
            ORDER BY trabajador_id
        ) LOOP
            BEGIN
                DBMS_OUTPUT.PUT_LINE('Procesando trabajador: ' || rec.nombre || ' ' || rec.apellido_paterno || ' (ID: ' || rec.trabajador_id || ')');
                
                -- Verificar si ya existe liquidación
                SELECT COUNT(*) INTO v_periodo_existe
                FROM liquidacion
                WHERE trabajador_id = rec.trabajador_id AND periodo_id = p_periodo_id;
                
                IF v_periodo_existe = 0 THEN
                    procesar_trabajador(p_periodo_id, rec.trabajador_id);
                    DBMS_OUTPUT.PUT_LINE('  ✓ Liquidación calculada exitosamente');
                ELSE
                    DBMS_OUTPUT.PUT_LINE('  ⚠ Liquidación ya existe, omitiendo');
                END IF;
                
            EXCEPTION
                WHEN OTHERS THEN
                    DBMS_OUTPUT.PUT_LINE('  ✗ Error procesando trabajador: ' || SQLERRM);
                    v_trabajadores_con_error := v_trabajadores_con_error + 1;
            END;
        END LOOP;
        
        -- Actualizar estado del período
        UPDATE periodos_nomina
        SET estado = c_estado_cerrado,
            fecha_cierre = v_fecha_actual,
            usuario_cierre = v_usuario_actual
        WHERE periodo_id = p_periodo_id;
        
        COMMIT;
        
        -- Mostrar resumen
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('=== RESUMEN DEL PROCESO ===');
        DBMS_OUTPUT.PUT_LINE('Total trabajadores: ' || v_total_trabajadores_periodo);
        DBMS_OUTPUT.PUT_LINE('Procesados exitosamente: ' || v_trabajadores_procesados);
        DBMS_OUTPUT.PUT_LINE('Con errores: ' || v_trabajadores_con_error);
        DBMS_OUTPUT.PUT_LINE('Período cerrado: ' || p_periodo_id);
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(c_error_calculo_liquidacion, 'Error calculando período: ' || SQLERRM);
    END calcular_periodo;
    
    -- Procedimiento para calcular trabajador específico
    PROCEDURE calcular_trabajador(p_periodo_id IN NUMBER, p_trabajador_id IN NUMBER) AS
        v_trabajador_existe NUMBER;
        v_liquidacion_existe NUMBER;
    BEGIN
        -- Validar trabajador
        SELECT COUNT(*) INTO v_trabajador_existe
        FROM trabajadores
        WHERE trabajador_id = p_trabajador_id AND estado = 'ACTIVO';
        
        IF v_trabajador_existe = 0 THEN
            RAISE_APPLICATION_ERROR(c_error_trabajador_no_existe, 'El trabajador no existe o está inactivo');
        END IF;
        
        -- Verificar si ya existe liquidación
        SELECT COUNT(*) INTO v_liquidacion_existe
        FROM liquidacion
        WHERE trabajador_id = p_trabajador_id AND periodo_id = p_periodo_id;
        
        IF v_liquidacion_existe > 0 THEN
            RAISE_APPLICATION_ERROR(c_error_liquidacion_existe, 'Ya existe una liquidación para este trabajador en el período');
        END IF;
        
        -- Cargar parámetros del sistema
        cargar_parametros_sistema;
        
        -- Procesar trabajador
        procesar_trabajador(p_periodo_id, p_trabajador_id);
        
        COMMIT;
        
        DBMS_OUTPUT.PUT_LINE('Liquidación calculada exitosamente para trabajador ' || p_trabajador_id || ' en período ' || p_periodo_id);
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END calcular_trabajador;
    
    -- =====================================================
    -- FUNCIONES PÚBLICAS
    -- =====================================================
    
    -- Función para obtener líquido de un trabajador
    FUNCTION get_liquido(p_trabajador_id IN NUMBER, p_periodo_id IN NUMBER) RETURN NUMBER AS
        v_liquido NUMBER(12,2);
    BEGIN
        SELECT liquido_a_pagar INTO v_liquido
        FROM liquidacion
        WHERE trabajador_id = p_trabajador_id AND periodo_id = p_periodo_id;
        
        RETURN v_liquido;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 0;
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20023, 'Error obteniendo líquido: ' || SQLERRM);
    END get_liquido;
    
    -- Función para obtener resumen de liquidación
    FUNCTION get_resumen_liquidacion(p_trabajador_id IN NUMBER, p_periodo_id IN NUMBER) RETURN VARCHAR2 AS
        v_resumen VARCHAR2(1000);
        v_liquidacion liquidacion%ROWTYPE;
        v_trabajador trabajadores%ROWTYPE;
    BEGIN
        SELECT * INTO v_liquidacion
        FROM liquidacion
        WHERE trabajador_id = p_trabajador_id AND periodo_id = p_periodo_id;
        
        SELECT * INTO v_trabajador
        FROM trabajadores
        WHERE trabajador_id = p_trabajador_id;
        
        v_resumen := 'TRABAJADOR: ' || v_trabajador.nombre || ' ' || v_trabajador.apellido_paterno || CHR(10) ||
                    'SUELDO BASE: $' || TO_CHAR(v_liquidacion.sueldo_base, '999,999,999') || CHR(10) ||
                    'TOTAL IMPONIBLE: $' || TO_CHAR(v_liquidacion.total_imponible, '999,999,999') || CHR(10) ||
                    'TOTAL NO IMPONIBLE: $' || TO_CHAR(v_liquidacion.total_no_imponible, '999,999,999') || CHR(10) ||
                    'TOTAL DESCUENTOS: $' || TO_CHAR(v_liquidacion.total_descuentos, '999,999,999') || CHR(10) ||
                    'TOTAL IMPUESTO: $' || TO_CHAR(v_liquidacion.total_impuesto, '999,999,999') || CHR(10) ||
                    'LÍQUIDO A PAGAR: $' || TO_CHAR(v_liquidacion.liquido_a_pagar, '999,999,999');
        
        RETURN v_resumen;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 'No se encontró liquidación para el trabajador y período especificados';
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20024, 'Error obteniendo resumen: ' || SQLERRM);
    END get_resumen_liquidacion;
    
    -- Función para validar período
    FUNCTION validar_periodo(p_periodo_id IN NUMBER) RETURN BOOLEAN AS
        v_existe NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_existe
        FROM periodos_nomina
        WHERE periodo_id = p_periodo_id;
        
        RETURN v_existe > 0;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END validar_periodo;
    
    -- Función para obtener estadísticas del período
    FUNCTION get_estadisticas_periodo(p_periodo_id IN NUMBER) RETURN VARCHAR2 AS
        v_estadisticas VARCHAR2(1000);
        v_total_liquidaciones NUMBER;
        v_total_imponible NUMBER;
        v_total_liquido NUMBER;
        v_periodo periodos_nomina%ROWTYPE;
    BEGIN
        SELECT * INTO v_periodo
        FROM periodos_nomina
        WHERE periodo_id = p_periodo_id;
        
        SELECT COUNT(*), NVL(SUM(total_imponible), 0), NVL(SUM(liquido_a_pagar), 0)
        INTO v_total_liquidaciones, v_total_imponible, v_total_liquido
        FROM liquidacion
        WHERE periodo_id = p_periodo_id;
        
        v_estadisticas := 'PERÍODO: ' || v_periodo.anio || '/' || v_periodo.mes || CHR(10) ||
                         'ESTADO: ' || v_periodo.estado || CHR(10) ||
                         'TOTAL LIQUIDACIONES: ' || v_total_liquidaciones || CHR(10) ||
                         'TOTAL IMPONIBLE: $' || TO_CHAR(v_total_imponible, '999,999,999') || CHR(10) ||
                         'TOTAL LÍQUIDO: $' || TO_CHAR(v_total_liquido, '999,999,999');
        
        RETURN v_estadisticas;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 'Período no encontrado';
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20025, 'Error obteniendo estadísticas: ' || SQLERRM);
    END get_estadisticas_periodo;
    
END PKG_NOMINA;
/

COMMIT;

-- =====================================================
-- PRUEBAS DEL PACKAGE
-- =====================================================

-- Habilitar salida de DBMS_OUTPUT
SET SERVEROUTPUT ON;

-- Probar función de validación de período
SELECT PKG_NOMINA.validar_periodo(1) as periodo_valido FROM DUAL;

-- Probar función de estadísticas
SELECT PKG_NOMINA.get_estadisticas_periodo(1) as estadisticas FROM DUAL;

-- Probar cálculo de trabajador individual
BEGIN
    PKG_NOMINA.calcular_trabajador(1, 3);
END;
/

-- Probar función de resumen
SELECT PKG_NOMINA.get_resumen_liquidacion(3, 1) as resumen FROM DUAL;

-- Probar función de líquido
SELECT PKG_NOMINA.get_liquido(3, 1) as liquido FROM DUAL;

-- Probar cálculo de período completo
BEGIN
    PKG_NOMINA.calcular_periodo(1);
END;
/

-- Verificar todas las liquidaciones del período
SELECT * FROM liquidacion WHERE periodo_id = 1;

-- Verificar estadísticas finales
SELECT PKG_NOMINA.get_estadisticas_periodo(1) as estadisticas_finales FROM DUAL;

COMMIT;

-- =====================================================
-- COMENTARIOS FINALES
-- =====================================================

/*
PACKAGE PKG_NOMINA COMPLETADO:

✅ ESPECIFICACIÓN PÚBLICA:
   - PROCEDURE calcular_periodo(p_periodo_id)
   - PROCEDURE calcular_trabajador(p_periodo_id, p_trabajador_id)
   - FUNCTION get_liquido(p_trabajador_id, p_periodo_id)
   - FUNCTION get_resumen_liquidacion(p_trabajador_id, p_periodo_id)
   - FUNCTION validar_periodo(p_periodo_id)
   - FUNCTION get_estadisticas_periodo(p_periodo_id)
   - Constantes públicas para errores y estados

✅ CUERPO PRIVADO:
   - Variables y constantes parametrizables
   - Procedimientos auxiliares internos:
     * cargar_parametros_sistema
     * registrar_detalle
     * validar_topes
     * calcular_impuesto
     * procesar_trabajador
   - Uso de cursor y bucle FOR para iterar trabajadores
   - Control de transacciones (COMMIT/ROLLBACK)
   - Manejo de errores y contadores

✅ CARACTERÍSTICAS:
   - Centralización de lógica de nómina
   - Reutilización de funciones auxiliares
   - Control de ejecución global
   - Estadísticas y reportes
   - Validaciones exhaustivas
   - Mensajes informativos

✅ EJECUCIÓN ESPERADA:
   BEGIN
      pkg_nomina.calcular_periodo(202508);
   END;
   /
   
   Procesa nómina completa y pobla tablas liquidacion y liquidacion_det

PRÓXIMOS PASOS:
1. Crear triggers de auditoría
2. Probar ejecución completa
*/

COMMIT;
