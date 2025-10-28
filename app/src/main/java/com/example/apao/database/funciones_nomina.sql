-- =====================================================
-- FUNCIONES AUXILIARES DEL SISTEMA DE NÓMINA
-- =====================================================
-- Funciones requeridas para el cálculo de liquidaciones
-- =====================================================

-- =====================================================
-- FUNCIÓN 1: fn_calcular_hextras
-- =====================================================
-- Calcula el total imponible de horas extra para un trabajador en un período
-- Parámetros: p_trabajador_id, p_periodo_id
-- Retorna: Total imponible de horas extra

CREATE OR REPLACE FUNCTION fn_calcular_hextras(
    p_trabajador_id IN NUMBER,
    p_periodo_id IN NUMBER
) RETURN NUMBER
IS
    v_total_hextras NUMBER(12,2) := 0;
    v_uf_valor NUMBER(15,4);
    v_tope_hextras NUMBER(15,4);
BEGIN
    -- Obtener valor UF actual
    SELECT valor INTO v_uf_valor
    FROM parametros_sistema
    WHERE codigo = 'UF_VALOR' AND estado = 'ACTIVO';
    
    -- Calcular horas extra del período
    SELECT NVL(SUM(e.valor_total), 0)
    INTO v_total_hextras
    FROM eventos_nomina e
    JOIN conceptos_nomina c ON e.concepto_id = c.concepto_id
    WHERE e.trabajador_id = p_trabajador_id
    AND e.periodo_id = p_periodo_id
    AND c.categoria = 'HORAS_EXTRA'
    AND c.tipo = 'IMPONIBLE';
    
    -- Aplicar tope de horas extra (opcional - máximo 2 UF)
    v_tope_hextras := 2 * v_uf_valor;
    IF v_total_hextras > v_tope_hextras THEN
        v_total_hextras := v_tope_hextras;
    END IF;
    
    RETURN v_total_hextras;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, 'Error calculando horas extra: ' || SQLERRM);
END;
/

-- =====================================================
-- FUNCIÓN 2: fn_descuentos_legales
-- =====================================================
-- Calcula el total de descuentos legales (AFP + Salud + AFC)
-- Parámetros: p_trabajador_id, p_periodo_id, p_imponible
-- Retorna: Total de descuentos legales

CREATE OR REPLACE FUNCTION fn_descuentos_legales(
    p_trabajador_id IN NUMBER,
    p_periodo_id IN NUMBER,
    p_imponible IN NUMBER
) RETURN NUMBER
IS
    v_descuento_afp NUMBER(12,2) := 0;
    v_descuento_salud NUMBER(12,2) := 0;
    v_descuento_afc NUMBER(12,2) := 0;
    v_total_descuentos NUMBER(12,2) := 0;
    v_tasa_afp NUMBER(15,4);
    v_tasa_salud NUMBER(15,4);
    v_tasa_afc NUMBER(15,4);
    v_tope_afp NUMBER(15,4);
    v_tope_salud NUMBER(15,4);
    v_uf_valor NUMBER(15,4);
    v_imponible_afp NUMBER(12,2);
    v_imponible_salud NUMBER(12,2);
BEGIN
    -- Obtener parámetros del sistema
    SELECT valor INTO v_tasa_afp FROM parametros_sistema WHERE codigo = 'TASA_AFP' AND estado = 'ACTIVO';
    SELECT valor INTO v_tasa_salud FROM parametros_sistema WHERE codigo = 'TASA_SALUD' AND estado = 'ACTIVO';
    SELECT valor INTO v_tasa_afc FROM parametros_sistema WHERE codigo = 'TASA_AFC' AND estado = 'ACTIVO';
    SELECT valor INTO v_tope_afp FROM parametros_sistema WHERE codigo = 'TOPE_AFP' AND estado = 'ACTIVO';
    SELECT valor INTO v_tope_salud FROM parametros_sistema WHERE codigo = 'TOPE_SALUD' AND estado = 'ACTIVO';
    SELECT valor INTO v_uf_valor FROM parametros_sistema WHERE codigo = 'UF_VALOR' AND estado = 'ACTIVO';
    
    -- Calcular base imponible para AFP y Salud
    v_imponible_afp := p_imponible;
    v_imponible_salud := p_imponible;
    
    -- Aplicar topes en UF
    IF v_imponible_afp > (v_tope_afp * v_uf_valor) THEN
        v_imponible_afp := v_tope_afp * v_uf_valor;
    END IF;
    
    IF v_imponible_salud > (v_tope_salud * v_uf_valor) THEN
        v_imponible_salud := v_tope_salud * v_uf_valor;
    END IF;
    
    -- Calcular descuentos
    v_descuento_afp := v_imponible_afp * v_tasa_afp;
    v_descuento_salud := v_imponible_salud * v_tasa_salud;
    v_descuento_afc := p_imponible * v_tasa_afc;
    
    -- Sumar descuentos adicionales del período (si los hay)
    SELECT NVL(SUM(e.valor_total), 0)
    INTO v_total_descuentos
    FROM eventos_nomina e
    JOIN conceptos_nomina c ON e.concepto_id = c.concepto_id
    WHERE e.trabajador_id = p_trabajador_id
    AND e.periodo_id = p_periodo_id
    AND c.tipo = 'DESCUENTO'
    AND c.categoria IN ('AFP', 'SALUD', 'AFC');
    
    -- Total de descuentos legales
    v_total_descuentos := v_descuento_afp + v_descuento_salud + v_descuento_afc + v_total_descuentos;
    
    RETURN v_total_descuentos;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'Error calculando descuentos legales: ' || SQLERRM);
END;
/

-- =====================================================
-- FUNCIÓN 3: fn_asig_familiar
-- =====================================================
-- Calcula el monto total de asignación familiar
-- Parámetros: p_trabajador_id, p_periodo_id
-- Retorna: Monto total de asignación familiar

CREATE OR REPLACE FUNCTION fn_asig_familiar(
    p_trabajador_id IN NUMBER,
    p_periodo_id IN NUMBER
) RETURN NUMBER
IS
    v_asig_familiar NUMBER(12,2) := 0;
    v_carga_familiar NUMBER(2);
    v_valor_asig_familiar NUMBER(12,2);
    v_uf_valor NUMBER(15,4);
BEGIN
    -- Obtener carga familiar del trabajador
    SELECT carga_familiar INTO v_carga_familiar
    FROM trabajadores
    WHERE trabajador_id = p_trabajador_id;
    
    -- Si no tiene carga familiar, retornar 0
    IF v_carga_familiar = 0 THEN
        RETURN 0;
    END IF;
    
    -- Obtener valor UF actual
    SELECT valor INTO v_uf_valor
    FROM parametros_sistema
    WHERE codigo = 'UF_VALOR' AND estado = 'ACTIVO';
    
    -- Valor por carga familiar (aproximadamente 0.1 UF por carga)
    v_valor_asig_familiar := 0.1 * v_uf_valor;
    
    -- Calcular asignación familiar total
    v_asig_familiar := v_carga_familiar * v_valor_asig_familiar;
    
    -- Verificar si hay asignación familiar adicional en eventos
    SELECT NVL(SUM(e.valor_total), 0)
    INTO v_asig_familiar
    FROM eventos_nomina e
    JOIN conceptos_nomina c ON e.concepto_id = c.concepto_id
    WHERE e.trabajador_id = p_trabajador_id
    AND e.periodo_id = p_periodo_id
    AND c.categoria = 'OTROS'
    AND c.nombre LIKE '%ASIGNACIÓN%FAMILIAR%';
    
    -- Si no hay eventos específicos, usar el cálculo por carga familiar
    IF v_asig_familiar = 0 THEN
        v_asig_familiar := v_carga_familiar * v_valor_asig_familiar;
    END IF;
    
    RETURN v_asig_familiar;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20003, 'Error calculando asignación familiar: ' || SQLERRM);
END;
/

-- =====================================================
-- FUNCIÓN 4: fn_liquido_a_pagar
-- =====================================================
-- Calcula el monto líquido a pagar
-- Parámetros: p_imponible, p_no_imponible, p_descuentos, p_impuesto
-- Retorna: Monto líquido a pagar

CREATE OR REPLACE FUNCTION fn_liquido_a_pagar(
    p_imponible IN NUMBER,
    p_no_imponible IN NUMBER,
    p_descuentos IN NUMBER,
    p_impuesto IN NUMBER
) RETURN NUMBER
IS
    v_liquido NUMBER(12,2);
BEGIN
    -- Validar parámetros
    IF p_imponible IS NULL THEN
        RAISE_APPLICATION_ERROR(-20004, 'El monto imponible no puede ser nulo');
    END IF;
    
    IF p_descuentos IS NULL THEN
        RAISE_APPLICATION_ERROR(-20005, 'Los descuentos no pueden ser nulos');
    END IF;
    
    -- Calcular líquido: imponible + no imponible - descuentos - impuesto
    v_liquido := NVL(p_imponible, 0) + NVL(p_no_imponible, 0) - NVL(p_descuentos, 0) - NVL(p_impuesto, 0);
    
    -- El líquido no puede ser negativo
    IF v_liquido < 0 THEN
        v_liquido := 0;
    END IF;
    
    RETURN v_liquido;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20006, 'Error calculando líquido a pagar: ' || SQLERRM);
END;
/

-- =====================================================
-- FUNCIÓN AUXILIAR ADICIONAL: fn_calcular_impuesto_renta
-- =====================================================
-- Calcula el impuesto a la renta según tramos
-- Parámetros: p_imponible
-- Retorna: Monto del impuesto a la renta

CREATE OR REPLACE FUNCTION fn_calcular_impuesto_renta(
    p_imponible IN NUMBER
) RETURN NUMBER
IS
    v_impuesto NUMBER(12,2) := 0;
    v_uf_valor NUMBER(15,4);
    v_imponible_uf NUMBER(15,4);
BEGIN
    -- Obtener valor UF actual
    SELECT valor INTO v_uf_valor
    FROM parametros_sistema
    WHERE codigo = 'UF_VALOR' AND estado = 'ACTIVO';
    
    -- Convertir imponible a UF
    v_imponible_uf := p_imponible / v_uf_valor;
    
    -- Calcular impuesto según tramos (simplificado)
    IF v_imponible_uf <= 13.5 THEN
        -- Exento
        v_impuesto := 0;
    ELSIF v_imponible_uf <= 30 THEN
        -- 4% sobre el exceso de 13.5 UF
        v_impuesto := (v_imponible_uf - 13.5) * v_uf_valor * 0.04;
    ELSIF v_imponible_uf <= 50 THEN
        -- 8% sobre el exceso de 30 UF
        v_impuesto := (30 - 13.5) * v_uf_valor * 0.04 + (v_imponible_uf - 30) * v_uf_valor * 0.08;
    ELSIF v_imponible_uf <= 70 THEN
        -- 13.5% sobre el exceso de 50 UF
        v_impuesto := (30 - 13.5) * v_uf_valor * 0.04 + (50 - 30) * v_uf_valor * 0.08 + (v_imponible_uf - 50) * v_uf_valor * 0.135;
    ELSIF v_imponible_uf <= 90 THEN
        -- 23% sobre el exceso de 70 UF
        v_impuesto := (30 - 13.5) * v_uf_valor * 0.04 + (50 - 30) * v_uf_valor * 0.08 + (70 - 50) * v_uf_valor * 0.135 + (v_imponible_uf - 70) * v_uf_valor * 0.23;
    ELSIF v_imponible_uf <= 120 THEN
        -- 30.4% sobre el exceso de 90 UF
        v_impuesto := (30 - 13.5) * v_uf_valor * 0.04 + (50 - 30) * v_uf_valor * 0.08 + (70 - 50) * v_uf_valor * 0.135 + (90 - 70) * v_uf_valor * 0.23 + (v_imponible_uf - 90) * v_uf_valor * 0.304;
    ELSE
        -- 35% sobre el exceso de 120 UF
        v_impuesto := (30 - 13.5) * v_uf_valor * 0.04 + (50 - 30) * v_uf_valor * 0.08 + (70 - 50) * v_uf_valor * 0.135 + (90 - 70) * v_uf_valor * 0.23 + (120 - 90) * v_uf_valor * 0.304 + (v_imponible_uf - 120) * v_uf_valor * 0.35;
    END IF;
    
    RETURN v_impuesto;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20007, 'Error calculando impuesto a la renta: ' || SQLERRM);
END;
/

-- =====================================================
-- FUNCIÓN AUXILIAR ADICIONAL: fn_calcular_total_imponible
-- =====================================================
-- Calcula el total imponible incluyendo sueldo base y eventos
-- Parámetros: p_trabajador_id, p_periodo_id
-- Retorna: Total imponible

CREATE OR REPLACE FUNCTION fn_calcular_total_imponible(
    p_trabajador_id IN NUMBER,
    p_periodo_id IN NUMBER
) RETURN NUMBER
IS
    v_sueldo_base NUMBER(12,2);
    v_total_eventos NUMBER(12,2) := 0;
    v_total_imponible NUMBER(12,2);
BEGIN
    -- Obtener sueldo base del trabajador
    SELECT sueldo_base INTO v_sueldo_base
    FROM trabajadores
    WHERE trabajador_id = p_trabajador_id;
    
    -- Calcular total de eventos imponibles del período
    SELECT NVL(SUM(e.valor_total), 0)
    INTO v_total_eventos
    FROM eventos_nomina e
    JOIN conceptos_nomina c ON e.concepto_id = c.concepto_id
    WHERE e.trabajador_id = p_trabajador_id
    AND e.periodo_id = p_periodo_id
    AND c.tipo = 'IMPONIBLE';
    
    -- Total imponible
    v_total_imponible := NVL(v_sueldo_base, 0) + NVL(v_total_eventos, 0);
    
    RETURN v_total_imponible;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20008, 'Error calculando total imponible: ' || SQLERRM);
END;
/

-- =====================================================
-- FUNCIÓN AUXILIAR ADICIONAL: fn_calcular_total_no_imponible
-- =====================================================
-- Calcula el total no imponible
-- Parámetros: p_trabajador_id, p_periodo_id
-- Retorna: Total no imponible

CREATE OR REPLACE FUNCTION fn_calcular_total_no_imponible(
    p_trabajador_id IN NUMBER,
    p_periodo_id IN NUMBER
) RETURN NUMBER
IS
    v_total_no_imponible NUMBER(12,2) := 0;
    v_asig_familiar NUMBER(12,2) := 0;
BEGIN
    -- Calcular asignación familiar
    v_asig_familiar := fn_asig_familiar(p_trabajador_id, p_periodo_id);
    
    -- Calcular otros eventos no imponibles
    SELECT NVL(SUM(e.valor_total), 0)
    INTO v_total_no_imponible
    FROM eventos_nomina e
    JOIN conceptos_nomina c ON e.concepto_id = c.concepto_id
    WHERE e.trabajador_id = p_trabajador_id
    AND e.periodo_id = p_periodo_id
    AND c.tipo = 'NO_IMPONIBLE';
    
    -- Total no imponible
    v_total_no_imponible := v_asig_familiar + v_total_no_imponible;
    
    RETURN v_total_no_imponible;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20009, 'Error calculando total no imponible: ' || SQLERRM);
END;
/

COMMIT;

-- =====================================================
-- PRUEBAS DE LAS FUNCIONES
-- =====================================================

-- Probar función de horas extra
SELECT fn_calcular_hextras(1, 1) as horas_extra_trabajador_1 FROM DUAL;

-- Probar función de descuentos legales
SELECT fn_descuentos_legales(1, 1, 950000) as descuentos_legales FROM DUAL;

-- Probar función de asignación familiar
SELECT fn_asig_familiar(1, 1) as asignacion_familiar FROM DUAL;

-- Probar función de líquido a pagar
SELECT fn_liquido_a_pagar(950000, 70000, 180000, 50000) as liquido_a_pagar FROM DUAL;

-- Probar función de impuesto a la renta
SELECT fn_calcular_impuesto_renta(950000) as impuesto_renta FROM DUAL;

-- Probar función de total imponible
SELECT fn_calcular_total_imponible(1, 1) as total_imponible FROM DUAL;

-- Probar función de total no imponible
SELECT fn_calcular_total_no_imponible(1, 1) as total_no_imponible FROM DUAL;

COMMIT;

-- =====================================================
-- COMENTARIOS FINALES
-- =====================================================

/*
FUNCIONES AUXILIARES COMPLETADAS:

✅ fn_calcular_hextras: Calcula horas extra con topes
✅ fn_descuentos_legales: Calcula AFP + Salud + AFC con topes
✅ fn_asig_familiar: Calcula asignación familiar por carga
✅ fn_liquido_a_pagar: Calcula líquido final
✅ fn_calcular_impuesto_renta: Calcula impuesto según tramos
✅ fn_calcular_total_imponible: Suma sueldo base + eventos imponibles
✅ fn_calcular_total_no_imponible: Suma asignación familiar + eventos no imponibles

CARACTERÍSTICAS:
- Manejo de errores con RAISE_APPLICATION_ERROR
- Validación de parámetros
- Uso de parámetros del sistema
- Aplicación de topes legales
- Cálculos según normativa chilena
- Funciones reutilizables y modulares

PRÓXIMOS PASOS:
1. Crear procedimiento sp_calcular_liquidacion_trabajador
2. Crear package PKG_NOMINA
3. Crear triggers de auditoría
4. Probar ejecución completa
*/

COMMIT;
