-- =====================================================
-- SISTEMA DE NÓMINA - ESQUEMA COMPLETO
-- =====================================================
-- Desarrollado para Oracle Database
-- Requisitos: Sistema completo de liquidación de nómina
-- =====================================================

-- Crear el esquema de la base de datos
CREATE USER nomina_user IDENTIFIED BY nomina123;
GRANT CONNECT, RESOURCE TO nomina_user;
GRANT CREATE VIEW TO nomina_user;
GRANT CREATE SEQUENCE TO nomina_user;
GRANT CREATE PROCEDURE TO nomina_user;
GRANT CREATE FUNCTION TO nomina_user;
GRANT CREATE PACKAGE TO nomina_user;
GRANT CREATE TRIGGER TO nomina_user;

-- Conectar como nomina_user
CONNECT nomina_user/nomina123;

-- =====================================================
-- TABLAS PRINCIPALES DEL SISTEMA DE NÓMINA
-- =====================================================

-- 1. TABLA DE TRABAJADORES
CREATE TABLE trabajadores (
    trabajador_id NUMBER(10) PRIMARY KEY,
    rut VARCHAR2(12) UNIQUE NOT NULL,
    nombre VARCHAR2(100) NOT NULL,
    apellido_paterno VARCHAR2(100) NOT NULL,
    apellido_materno VARCHAR2(100),
    fecha_nacimiento DATE NOT NULL,
    fecha_ingreso DATE NOT NULL,
    cargo VARCHAR2(100) NOT NULL,
    sueldo_base NUMBER(12,2) NOT NULL,
    estado VARCHAR2(20) DEFAULT 'ACTIVO' CHECK (estado IN ('ACTIVO', 'INACTIVO', 'SUSPENDIDO')),
    afp_id NUMBER(10),
    salud_id NUMBER(10),
    carga_familiar NUMBER(2) DEFAULT 0,
    fecha_creacion DATE DEFAULT SYSDATE,
    usuario_creacion VARCHAR2(50) DEFAULT USER
);

-- 2. TABLA DE PERIODOS DE NÓMINA
CREATE TABLE periodos_nomina (
    periodo_id NUMBER(10) PRIMARY KEY,
    anio NUMBER(4) NOT NULL,
    mes NUMBER(2) NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    estado VARCHAR2(20) DEFAULT 'ABIERTO' CHECK (estado IN ('ABIERTO', 'CERRADO', 'PROCESADO')),
    fecha_cierre DATE,
    usuario_cierre VARCHAR2(50),
    fecha_creacion DATE DEFAULT SYSDATE,
    UNIQUE(anio, mes)
);

-- 3. TABLA DE CONCEPTOS DE NÓMINA
CREATE TABLE conceptos_nomina (
    concepto_id NUMBER(10) PRIMARY KEY,
    codigo VARCHAR2(10) UNIQUE NOT NULL,
    nombre VARCHAR2(100) NOT NULL,
    tipo VARCHAR2(20) NOT NULL CHECK (tipo IN ('IMPONIBLE', 'NO_IMPONIBLE', 'DESCUENTO')),
    categoria VARCHAR2(30) NOT NULL CHECK (categoria IN ('SUELDO', 'HORAS_EXTRA', 'BONO', 'LICENCIA', 'VACACIONES', 'AFP', 'SALUD', 'AFC', 'IMPUESTO', 'OTROS')),
    aplica_afp CHAR(1) DEFAULT 'Y' CHECK (aplica_afp IN ('Y', 'N')),
    aplica_salud CHAR(1) DEFAULT 'Y' CHECK (aplica_salud IN ('Y', 'N')),
    aplica_impuesto CHAR(1) DEFAULT 'Y' CHECK (aplica_impuesto IN ('Y', 'N')),
    estado VARCHAR2(20) DEFAULT 'ACTIVO' CHECK (estado IN ('ACTIVO', 'INACTIVO')),
    fecha_creacion DATE DEFAULT SYSDATE
);

-- 4. TABLA DE EVENTOS DE NÓMINA (horas extra, bonos, licencias, etc.)
CREATE TABLE eventos_nomina (
    evento_id NUMBER(10) PRIMARY KEY,
    trabajador_id NUMBER(10) NOT NULL,
    periodo_id NUMBER(10) NOT NULL,
    concepto_id NUMBER(10) NOT NULL,
    cantidad NUMBER(10,2) DEFAULT 1,
    valor_unitario NUMBER(12,2) NOT NULL,
    valor_total NUMBER(12,2) NOT NULL,
    observaciones VARCHAR2(500),
    fecha_evento DATE DEFAULT SYSDATE,
    usuario_creacion VARCHAR2(50) DEFAULT USER,
    fecha_creacion DATE DEFAULT SYSDATE,
    FOREIGN KEY (trabajador_id) REFERENCES trabajadores(trabajador_id),
    FOREIGN KEY (periodo_id) REFERENCES periodos_nomina(periodo_id),
    FOREIGN KEY (concepto_id) REFERENCES conceptos_nomina(concepto_id)
);

-- 5. TABLA DE LIQUIDACIONES (resumen por trabajador y periodo)
CREATE TABLE liquidacion (
    liquidacion_id NUMBER(10) PRIMARY KEY,
    trabajador_id NUMBER(10) NOT NULL,
    periodo_id NUMBER(10) NOT NULL,
    sueldo_base NUMBER(12,2) NOT NULL,
    total_imponible NUMBER(12,2) NOT NULL,
    total_no_imponible NUMBER(12,2) DEFAULT 0,
    total_descuentos NUMBER(12,2) NOT NULL,
    total_impuesto NUMBER(12,2) DEFAULT 0,
    liquido_a_pagar NUMBER(12,2) NOT NULL,
    fecha_liquidacion DATE DEFAULT SYSDATE,
    usuario_liquidacion VARCHAR2(50) DEFAULT USER,
    estado VARCHAR2(20) DEFAULT 'PROCESADO' CHECK (estado IN ('PROCESADO', 'ANULADO')),
    FOREIGN KEY (trabajador_id) REFERENCES trabajadores(trabajador_id),
    FOREIGN KEY (periodo_id) REFERENCES periodos_nomina(periodo_id),
    UNIQUE(trabajador_id, periodo_id)
);

-- 6. TABLA DE DETALLE DE LIQUIDACIONES
CREATE TABLE liquidacion_det (
    detalle_id NUMBER(10) PRIMARY KEY,
    liquidacion_id NUMBER(10) NOT NULL,
    concepto_id NUMBER(10) NOT NULL,
    cantidad NUMBER(10,2) DEFAULT 1,
    valor_unitario NUMBER(12,2) NOT NULL,
    valor_total NUMBER(12,2) NOT NULL,
    tipo_concepto VARCHAR2(20) NOT NULL,
    categoria_concepto VARCHAR2(30) NOT NULL,
    fecha_creacion DATE DEFAULT SYSDATE,
    FOREIGN KEY (liquidacion_id) REFERENCES liquidacion(liquidacion_id),
    FOREIGN KEY (concepto_id) REFERENCES conceptos_nomina(concepto_id)
);

-- 7. TABLA DE AUDITORÍA DE NÓMINA (para triggers)
CREATE TABLE audit_nomina (
    audit_id NUMBER(10) PRIMARY KEY,
    periodo_id NUMBER(10) NOT NULL,
    usuario_proceso VARCHAR2(50) NOT NULL,
    cantidad_registros NUMBER(10) NOT NULL,
    fecha_proceso DATE DEFAULT SYSDATE,
    tipo_operacion VARCHAR2(20) NOT NULL CHECK (tipo_operacion IN ('INSERT', 'UPDATE', 'DELETE')),
    tabla_afectada VARCHAR2(50) NOT NULL,
    FOREIGN KEY (periodo_id) REFERENCES periodos_nomina(periodo_id)
);

-- 8. TABLA DE AUDITORÍA DE DETALLE DE NÓMINA
CREATE TABLE audit_nomina_det (
    audit_det_id NUMBER(10) PRIMARY KEY,
    concepto_id NUMBER(10) NOT NULL,
    monto NUMBER(12,2) NOT NULL,
    usuario_proceso VARCHAR2(50) NOT NULL,
    fecha_proceso DATE DEFAULT SYSDATE,
    tipo_operacion VARCHAR2(20) NOT NULL CHECK (tipo_operacion IN ('INSERT', 'UPDATE', 'DELETE')),
    FOREIGN KEY (concepto_id) REFERENCES conceptos_nomina(concepto_id)
);

-- 9. TABLA DE PARÁMETROS DEL SISTEMA
CREATE TABLE parametros_sistema (
    parametro_id NUMBER(10) PRIMARY KEY,
    codigo VARCHAR2(50) UNIQUE NOT NULL,
    nombre VARCHAR2(100) NOT NULL,
    valor NUMBER(15,4) NOT NULL,
    descripcion VARCHAR2(200),
    fecha_vigencia DATE DEFAULT SYSDATE,
    estado VARCHAR2(20) DEFAULT 'ACTIVO' CHECK (estado IN ('ACTIVO', 'INACTIVO'))
);

-- =====================================================
-- SECUENCIAS PARA IDs AUTOMÁTICOS
-- =====================================================

CREATE SEQUENCE seq_trabajadores START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_periodos START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_conceptos START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_eventos START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_liquidacion START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_liquidacion_det START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_audit_nomina START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_audit_nomina_det START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_parametros START WITH 1 INCREMENT BY 1;

-- =====================================================
-- TRIGGERS PARA IDs AUTOMÁTICOS
-- =====================================================

-- Trigger para trabajadores
CREATE OR REPLACE TRIGGER trg_trabajadores_id
    BEFORE INSERT ON trabajadores
    FOR EACH ROW
BEGIN
    IF :NEW.trabajador_id IS NULL THEN
        :NEW.trabajador_id := seq_trabajadores.NEXTVAL;
    END IF;
END;
/

-- Trigger para periodos
CREATE OR REPLACE TRIGGER trg_periodos_id
    BEFORE INSERT ON periodos_nomina
    FOR EACH ROW
BEGIN
    IF :NEW.periodo_id IS NULL THEN
        :NEW.periodo_id := seq_periodos.NEXTVAL;
    END IF;
END;
/

-- Trigger para conceptos
CREATE OR REPLACE TRIGGER trg_conceptos_id
    BEFORE INSERT ON conceptos_nomina
    FOR EACH ROW
BEGIN
    IF :NEW.concepto_id IS NULL THEN
        :NEW.concepto_id := seq_conceptos.NEXTVAL;
    END IF;
END;
/

-- Trigger para eventos
CREATE OR REPLACE TRIGGER trg_eventos_id
    BEFORE INSERT ON eventos_nomina
    FOR EACH ROW
BEGIN
    IF :NEW.evento_id IS NULL THEN
        :NEW.evento_id := seq_eventos.NEXTVAL;
    END IF;
END;
/

-- Trigger para liquidaciones
CREATE OR REPLACE TRIGGER trg_liquidacion_id
    BEFORE INSERT ON liquidacion
    FOR EACH ROW
BEGIN
    IF :NEW.liquidacion_id IS NULL THEN
        :NEW.liquidacion_id := seq_liquidacion.NEXTVAL;
    END IF;
END;
/

-- Trigger para detalle de liquidaciones
CREATE OR REPLACE TRIGGER trg_liquidacion_det_id
    BEFORE INSERT ON liquidacion_det
    FOR EACH ROW
BEGIN
    IF :NEW.detalle_id IS NULL THEN
        :NEW.detalle_id := seq_liquidacion_det.NEXTVAL;
    END IF;
END;
/

-- Trigger para auditoría de nómina
CREATE OR REPLACE TRIGGER trg_audit_nomina_id
    BEFORE INSERT ON audit_nomina
    FOR EACH ROW
BEGIN
    IF :NEW.audit_id IS NULL THEN
        :NEW.audit_id := seq_audit_nomina.NEXTVAL;
    END IF;
END;
/

-- Trigger para auditoría de detalle
CREATE OR REPLACE TRIGGER trg_audit_nomina_det_id
    BEFORE INSERT ON audit_nomina_det
    FOR EACH ROW
BEGIN
    IF :NEW.audit_det_id IS NULL THEN
        :NEW.audit_det_id := seq_audit_nomina_det.NEXTVAL;
    END IF;
END;
/

-- Trigger para parámetros
CREATE OR REPLACE TRIGGER trg_parametros_id
    BEFORE INSERT ON parametros_sistema
    FOR EACH ROW
BEGIN
    IF :NEW.parametro_id IS NULL THEN
        :NEW.parametro_id := seq_parametros.NEXTVAL;
    END IF;
END;
/

-- =====================================================
-- DATOS INICIALES
-- =====================================================

-- Insertar conceptos básicos de nómina
INSERT INTO conceptos_nomina (codigo, nombre, tipo, categoria, aplica_afp, aplica_salud, aplica_impuesto) 
VALUES ('SUELDO', 'Sueldo Base', 'IMPONIBLE', 'SUELDO', 'Y', 'Y', 'Y');

INSERT INTO conceptos_nomina (codigo, nombre, tipo, categoria, aplica_afp, aplica_salud, aplica_impuesto) 
VALUES ('HEXTRA', 'Horas Extra', 'IMPONIBLE', 'HORAS_EXTRA', 'Y', 'Y', 'Y');

INSERT INTO conceptos_nomina (codigo, nombre, tipo, categoria, aplica_afp, aplica_salud, aplica_impuesto) 
VALUES ('BONO', 'Bono de Producción', 'IMPONIBLE', 'BONO', 'Y', 'Y', 'Y');

INSERT INTO conceptos_nomina (codigo, nombre, tipo, categoria, aplica_afp, aplica_salud, aplica_impuesto) 
VALUES ('ASIG_FAM', 'Asignación Familiar', 'NO_IMPONIBLE', 'OTROS', 'N', 'N', 'N');

INSERT INTO conceptos_nomina (codigo, nombre, tipo, categoria, aplica_afp, aplica_salud, aplica_impuesto) 
VALUES ('AFP', 'Descuento AFP', 'DESCUENTO', 'AFP', 'N', 'N', 'N');

INSERT INTO conceptos_nomina (codigo, nombre, tipo, categoria, aplica_afp, aplica_salud, aplica_impuesto) 
VALUES ('SALUD', 'Descuento Salud', 'DESCUENTO', 'SALUD', 'N', 'N', 'N');

INSERT INTO conceptos_nomina (codigo, nombre, tipo, categoria, aplica_afp, aplica_salud, aplica_impuesto) 
VALUES ('AFC', 'Descuento AFC', 'DESCUENTO', 'AFC', 'N', 'N', 'N');

INSERT INTO conceptos_nomina (codigo, nombre, tipo, categoria, aplica_afp, aplica_salud, aplica_impuesto) 
VALUES ('IMP_RENTA', 'Impuesto a la Renta', 'DESCUENTO', 'IMPUESTO', 'N', 'N', 'N');

-- Insertar parámetros del sistema
INSERT INTO parametros_sistema (codigo, nombre, valor, descripcion) 
VALUES ('TASA_AFP', 'Tasa AFP', 0.10, 'Tasa de descuento AFP (10%)');

INSERT INTO parametros_sistema (codigo, nombre, valor, descripcion) 
VALUES ('TASA_SALUD', 'Tasa Salud', 0.07, 'Tasa de descuento Salud (7%)');

INSERT INTO parametros_sistema (codigo, nombre, valor, descripcion) 
VALUES ('TASA_AFC', 'Tasa AFC', 0.01, 'Tasa de descuento AFC (1%)');

INSERT INTO parametros_sistema (codigo, nombre, valor, descripcion) 
VALUES ('UF_VALOR', 'Valor UF', 35000, 'Valor UF actual');

INSERT INTO parametros_sistema (codigo, nombre, valor, descripcion) 
VALUES ('TOPE_AFP', 'Tope AFP', 4.5, 'Tope AFP en UF');

INSERT INTO parametros_sistema (codigo, nombre, valor, descripcion) 
VALUES ('TOPE_SALUD', 'Tope Salud', 7.0, 'Tope Salud en UF');

-- Insertar trabajadores de prueba
INSERT INTO trabajadores (rut, nombre, apellido_paterno, apellido_materno, fecha_nacimiento, fecha_ingreso, cargo, sueldo_base, carga_familiar) 
VALUES ('12345678-9', 'Juan', 'Pérez', 'González', DATE '1985-03-15', DATE '2020-01-15', 'Desarrollador', 800000, 2);

INSERT INTO trabajadores (rut, nombre, apellido_paterno, apellido_materno, fecha_nacimiento, fecha_ingreso, cargo, sueldo_base, carga_familiar) 
VALUES ('98765432-1', 'María', 'Rodríguez', 'Silva', DATE '1990-07-22', DATE '2021-03-01', 'Analista', 750000, 1);

INSERT INTO trabajadores (rut, nombre, apellido_paterno, apellido_materno, fecha_nacimiento, fecha_ingreso, cargo, sueldo_base, carga_familiar) 
VALUES ('11223344-5', 'Carlos', 'López', 'Martínez', DATE '1988-11-10', DATE '2019-06-15', 'Gerente', 1200000, 3);

-- Insertar período de prueba
INSERT INTO periodos_nomina (anio, mes, fecha_inicio, fecha_fin) 
VALUES (2025, 8, DATE '2025-08-01', DATE '2025-08-31');

-- Insertar eventos de prueba
INSERT INTO eventos_nomina (trabajador_id, periodo_id, concepto_id, cantidad, valor_unitario, valor_total) 
VALUES (1, 1, 2, 10, 15000, 150000); -- Horas extra para Juan

INSERT INTO eventos_nomina (trabajador_id, periodo_id, concepto_id, cantidad, valor_unitario, valor_total) 
VALUES (2, 1, 3, 1, 50000, 50000); -- Bono para María

COMMIT;

-- =====================================================
-- ÍNDICES PARA MEJORAR RENDIMIENTO
-- =====================================================

CREATE INDEX idx_trabajadores_rut ON trabajadores(rut);
CREATE INDEX idx_trabajadores_estado ON trabajadores(estado);
CREATE INDEX idx_periodos_anio_mes ON periodos_nomina(anio, mes);
CREATE INDEX idx_eventos_trabajador ON eventos_nomina(trabajador_id);
CREATE INDEX idx_eventos_periodo ON eventos_nomina(periodo_id);
CREATE INDEX idx_liquidacion_trabajador ON liquidacion(trabajador_id);
CREATE INDEX idx_liquidacion_periodo ON liquidacion(periodo_id);
CREATE INDEX idx_liquidacion_det_liquidacion ON liquidacion_det(liquidacion_id);
CREATE INDEX idx_conceptos_codigo ON conceptos_nomina(codigo);
CREATE INDEX idx_conceptos_tipo ON conceptos_nomina(tipo);
CREATE INDEX idx_parametros_codigo ON parametros_sistema(codigo);

-- =====================================================
-- VISTAS ÚTILES
-- =====================================================

-- Vista de liquidaciones completas
CREATE OR REPLACE VIEW vista_liquidaciones_completa AS
SELECT 
    l.liquidacion_id,
    t.rut,
    t.nombre || ' ' || t.apellido_paterno || ' ' || NVL(t.apellido_materno, '') as nombre_completo,
    p.anio,
    p.mes,
    l.sueldo_base,
    l.total_imponible,
    l.total_no_imponible,
    l.total_descuentos,
    l.total_impuesto,
    l.liquido_a_pagar,
    l.fecha_liquidacion,
    l.usuario_liquidacion
FROM liquidacion l
JOIN trabajadores t ON l.trabajador_id = t.trabajador_id
JOIN periodos_nomina p ON l.periodo_id = p.periodo_id;

-- Vista de eventos por trabajador y período
CREATE OR REPLACE VIEW vista_eventos_trabajador AS
SELECT 
    e.evento_id,
    t.rut,
    t.nombre || ' ' || t.apellido_paterno as nombre_trabajador,
    p.anio,
    p.mes,
    c.codigo as concepto_codigo,
    c.nombre as concepto_nombre,
    c.tipo as concepto_tipo,
    e.cantidad,
    e.valor_unitario,
    e.valor_total,
    e.observaciones,
    e.fecha_evento
FROM eventos_nomina e
JOIN trabajadores t ON e.trabajador_id = t.trabajador_id
JOIN periodos_nomina p ON e.periodo_id = p.periodo_id
JOIN conceptos_nomina c ON e.concepto_id = c.concepto_id;

COMMIT;

-- =====================================================
-- COMENTARIOS FINALES
-- =====================================================

/*
ESQUEMA DE NÓMINA COMPLETADO:

✅ Tablas principales:
- trabajadores: Información de empleados
- periodos_nomina: Períodos de liquidación
- conceptos_nomina: Conceptos de pago/descuento
- eventos_nomina: Eventos específicos del período
- liquidacion: Resumen de liquidaciones
- liquidacion_det: Detalle de liquidaciones
- audit_nomina: Auditoría de procesos
- audit_nomina_det: Auditoría de detalles
- parametros_sistema: Parámetros configurables

✅ Secuencias y triggers para IDs automáticos
✅ Datos iniciales de prueba
✅ Índices para optimización
✅ Vistas útiles para consultas
✅ Estructura preparada para procedimientos y funciones

PRÓXIMOS PASOS:
1. Crear funciones auxiliares
2. Crear procedimiento sp_calcular_liquidacion_trabajador
3. Crear package PKG_NOMINA
4. Crear triggers de auditoría
5. Probar ejecución completa
*/

COMMIT;
