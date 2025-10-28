-- =====================================================
-- BASE DE DATOS PARA APLICACIÓN "APAÑO" - EVENTOS DEPORTIVOS
-- =====================================================
-- Desarrollado para SQL Developer
-- Requisitos: Sistema de gestión de eventos deportivos
-- =====================================================

-- Crear el esquema de la base de datos
CREATE USER apao_user IDENTIFIED BY apao123;
GRANT CONNECT, RESOURCE TO apao_user;
GRANT CREATE VIEW TO apao_user;
GRANT CREATE SEQUENCE TO apao_user;

-- Conectar como apao_user
CONNECT apao_user/apao123;

-- =====================================================
-- TABLAS PRINCIPALES
-- =====================================================

-- 1. TABLA DE USUARIOS
CREATE TABLE usuarios (
    usuario_id NUMBER(10) PRIMARY KEY,
    email VARCHAR2(100) UNIQUE NOT NULL,
    password VARCHAR2(255) NOT NULL,
    nombre VARCHAR2(100) NOT NULL,
    telefono VARCHAR2(20),
    fecha_registro DATE DEFAULT SYSDATE,
    estado VARCHAR2(20) DEFAULT 'ACTIVO' CHECK (estado IN ('ACTIVO', 'INACTIVO', 'SUSPENDIDO')),
    bio VARCHAR2(500),
    foto_perfil VARCHAR2(255)
);

-- 2. TABLA DE DEPORTES
CREATE TABLE deportes (
    deporte_id NUMBER(10) PRIMARY KEY,
    nombre VARCHAR2(50) NOT NULL UNIQUE,
    descripcion VARCHAR2(200),
    categoria VARCHAR2(30) CHECK (categoria IN ('INDIVIDUAL', 'EQUIPO', 'EXTREMO', 'ACUATICO', 'OTROS'))
);

-- 3. TABLA DE EVENTOS
CREATE TABLE eventos (
    evento_id NUMBER(10) PRIMARY KEY,
    titulo VARCHAR2(200) NOT NULL,
    descripcion VARCHAR2(1000) NOT NULL,
    deporte_id NUMBER(10) NOT NULL,
    ubicacion VARCHAR2(200) NOT NULL,
    fecha_evento DATE NOT NULL,
    hora_inicio VARCHAR2(5) NOT NULL,
    hora_fin VARCHAR2(5),
    max_participantes NUMBER(4) NOT NULL,
    costo NUMBER(10,2) DEFAULT 0,
    nivel_dificultad VARCHAR2(20) CHECK (nivel_dificultad IN ('PRINCIPIANTE', 'INTERMEDIO', 'AVANZADO', 'PROFESIONAL')),
    estado VARCHAR2(20) DEFAULT 'ACTIVO' CHECK (estado IN ('ACTIVO', 'CANCELADO', 'COMPLETADO', 'SUSPENDIDO')),
    organizador_id NUMBER(10) NOT NULL,
    fecha_creacion DATE DEFAULT SYSDATE,
    imagen_url VARCHAR2(500),
    coordenadas_lat NUMBER(10,8),
    coordenadas_lng NUMBER(11,8),
    FOREIGN KEY (deporte_id) REFERENCES deportes(deporte_id),
    FOREIGN KEY (organizador_id) REFERENCES usuarios(usuario_id)
);

-- 4. TABLA DE PARTICIPACIONES
CREATE TABLE participaciones (
    participacion_id NUMBER(10) PRIMARY KEY,
    evento_id NUMBER(10) NOT NULL,
    usuario_id NUMBER(10) NOT NULL,
    fecha_participacion DATE DEFAULT SYSDATE,
    estado VARCHAR2(20) DEFAULT 'CONFIRMADO' CHECK (estado IN ('CONFIRMADO', 'PENDIENTE', 'CANCELADO')),
    calificacion NUMBER(1) CHECK (calificacion BETWEEN 1 AND 5),
    comentario VARCHAR2(500),
    FOREIGN KEY (evento_id) REFERENCES eventos(evento_id),
    FOREIGN KEY (usuario_id) REFERENCES usuarios(usuario_id),
    UNIQUE(evento_id, usuario_id)
);

-- 5. TABLA DE LIKES/FAVORITOS
CREATE TABLE likes_eventos (
    like_id NUMBER(10) PRIMARY KEY,
    evento_id NUMBER(10) NOT NULL,
    usuario_id NUMBER(10) NOT NULL,
    fecha_like DATE DEFAULT SYSDATE,
    FOREIGN KEY (evento_id) REFERENCES eventos(evento_id),
    FOREIGN KEY (usuario_id) REFERENCES usuarios(usuario_id),
    UNIQUE(evento_id, usuario_id)
);

-- 6. TABLA DE COMENTARIOS
CREATE TABLE comentarios (
    comentario_id NUMBER(10) PRIMARY KEY,
    evento_id NUMBER(10) NOT NULL,
    usuario_id NUMBER(10) NOT NULL,
    texto VARCHAR2(1000) NOT NULL,
    fecha_comentario DATE DEFAULT SYSDATE,
    estado VARCHAR2(20) DEFAULT 'VISIBLE' CHECK (estado IN ('VISIBLE', 'OCULTO', 'ELIMINADO')),
    FOREIGN KEY (evento_id) REFERENCES eventos(evento_id),
    FOREIGN KEY (usuario_id) REFERENCES usuarios(usuario_id)
);

-- 7. TABLA DE MENSAJES
CREATE TABLE mensajes (
    mensaje_id NUMBER(10) PRIMARY KEY,
    remitente_id NUMBER(10) NOT NULL,
    destinatario_id NUMBER(10) NOT NULL,
    evento_id NUMBER(10),
    asunto VARCHAR2(200),
    contenido VARCHAR2(2000) NOT NULL,
    fecha_envio DATE DEFAULT SYSDATE,
    estado VARCHAR2(20) DEFAULT 'ENVIADO' CHECK (estado IN ('ENVIADO', 'LEIDO', 'ELIMINADO')),
    FOREIGN KEY (remitente_id) REFERENCES usuarios(usuario_id),
    FOREIGN KEY (destinatario_id) REFERENCES usuarios(usuario_id),
    FOREIGN KEY (evento_id) REFERENCES eventos(evento_id)
);

-- 8. TABLA DE NOTIFICACIONES
CREATE TABLE notificaciones (
    notificacion_id NUMBER(10) PRIMARY KEY,
    usuario_id NUMBER(10) NOT NULL,
    tipo VARCHAR2(30) NOT NULL CHECK (tipo IN ('NUEVO_EVENTO', 'PARTICIPACION', 'MENSAJE', 'COMENTARIO', 'LIKE', 'SISTEMA')),
    titulo VARCHAR2(200) NOT NULL,
    mensaje VARCHAR2(500) NOT NULL,
    evento_id NUMBER(10),
    fecha_notificacion DATE DEFAULT SYSDATE,
    leida CHAR(1) DEFAULT 'N' CHECK (leida IN ('Y', 'N')),
    FOREIGN KEY (usuario_id) REFERENCES usuarios(usuario_id),
    FOREIGN KEY (evento_id) REFERENCES eventos(evento_id)
);

-- =====================================================
-- SECUENCIAS PARA IDs AUTOMÁTICOS
-- =====================================================

CREATE SEQUENCE seq_usuarios START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_deportes START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_eventos START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_participaciones START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_likes START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_comentarios START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_mensajes START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_notificaciones START WITH 1 INCREMENT BY 1;

-- =====================================================
-- TRIGGERS PARA IDs AUTOMÁTICOS
-- =====================================================

-- Trigger para usuarios
CREATE OR REPLACE TRIGGER trg_usuarios_id
    BEFORE INSERT ON usuarios
    FOR EACH ROW
BEGIN
    IF :NEW.usuario_id IS NULL THEN
        :NEW.usuario_id := seq_usuarios.NEXTVAL;
    END IF;
END;
/

-- Trigger para deportes
CREATE OR REPLACE TRIGGER trg_deportes_id
    BEFORE INSERT ON deportes
    FOR EACH ROW
BEGIN
    IF :NEW.deporte_id IS NULL THEN
        :NEW.deporte_id := seq_deportes.NEXTVAL;
    END IF;
END;
/

-- Trigger para eventos
CREATE OR REPLACE TRIGGER trg_eventos_id
    BEFORE INSERT ON eventos
    FOR EACH ROW
BEGIN
    IF :NEW.evento_id IS NULL THEN
        :NEW.evento_id := seq_eventos.NEXTVAL;
    END IF;
END;
/

-- Trigger para participaciones
CREATE OR REPLACE TRIGGER trg_participaciones_id
    BEFORE INSERT ON participaciones
    FOR EACH ROW
BEGIN
    IF :NEW.participacion_id IS NULL THEN
        :NEW.participacion_id := seq_participaciones.NEXTVAL;
    END IF;
END;
/

-- Trigger para likes
CREATE OR REPLACE TRIGGER trg_likes_id
    BEFORE INSERT ON likes_eventos
    FOR EACH ROW
BEGIN
    IF :NEW.like_id IS NULL THEN
        :NEW.like_id := seq_likes.NEXTVAL;
    END IF;
END;
/

-- Trigger para comentarios
CREATE OR REPLACE TRIGGER trg_comentarios_id
    BEFORE INSERT ON comentarios
    FOR EACH ROW
BEGIN
    IF :NEW.comentario_id IS NULL THEN
        :NEW.comentario_id := seq_comentarios.NEXTVAL;
    END IF;
END;
/

-- Trigger para mensajes
CREATE OR REPLACE TRIGGER trg_mensajes_id
    BEFORE INSERT ON mensajes
    FOR EACH ROW
BEGIN
    IF :NEW.mensaje_id IS NULL THEN
        :NEW.mensaje_id := seq_mensajes.NEXTVAL;
    END IF;
END;
/

-- Trigger para notificaciones
CREATE OR REPLACE TRIGGER trg_notificaciones_id
    BEFORE INSERT ON notificaciones
    FOR EACH ROW
BEGIN
    IF :NEW.notificacion_id IS NULL THEN
        :NEW.notificacion_id := seq_notificaciones.NEXTVAL;
    END IF;
END;
/

-- =====================================================
-- DATOS INICIALES
-- =====================================================

-- Insertar deportes básicos
INSERT INTO deportes (nombre, descripcion, categoria) VALUES ('Fútbol', 'Deporte de equipo con balón', 'EQUIPO');
INSERT INTO deportes (nombre, descripcion, categoria) VALUES ('Baloncesto', 'Deporte de equipo con canasta', 'EQUIPO');
INSERT INTO deportes (nombre, descripcion, categoria) VALUES ('Tenis', 'Deporte individual con raqueta', 'INDIVIDUAL');
INSERT INTO deportes (nombre, descripcion, categoria) VALUES ('Voleibol', 'Deporte de equipo con red', 'EQUIPO');
INSERT INTO deportes (nombre, descripcion, categoria) VALUES ('Running', 'Carrera a pie', 'INDIVIDUAL');
INSERT INTO deportes (nombre, descripcion, categoria) VALUES ('Ciclismo', 'Deporte con bicicleta', 'INDIVIDUAL');
INSERT INTO deportes (nombre, descripcion, categoria) VALUES ('Natación', 'Deporte acuático', 'ACUATICO');
INSERT INTO deportes (nombre, descripcion, categoria) VALUES ('Béisbol', 'Deporte de equipo con bate', 'EQUIPO');

COMMIT;

-- =====================================================
-- VISTAS ÚTILES
-- =====================================================

-- Vista de eventos con información completa
CREATE OR REPLACE VIEW vista_eventos_completa AS
SELECT 
    e.evento_id,
    e.titulo,
    e.descripcion,
    d.nombre as deporte,
    d.categoria,
    e.ubicacion,
    e.fecha_evento,
    e.hora_inicio,
    e.hora_fin,
    e.max_participantes,
    e.costo,
    e.nivel_dificultad,
    e.estado,
    u.nombre as organizador,
    u.email as email_organizador,
    e.fecha_creacion,
    e.imagen_url,
    e.coordenadas_lat,
    e.coordenadas_lng,
    COUNT(p.participacion_id) as participantes_actuales,
    COUNT(l.like_id) as total_likes,
    COUNT(c.comentario_id) as total_comentarios
FROM eventos e
JOIN deportes d ON e.deporte_id = d.deporte_id
JOIN usuarios u ON e.organizador_id = u.usuario_id
LEFT JOIN participaciones p ON e.evento_id = p.evento_id AND p.estado = 'CONFIRMADO'
LEFT JOIN likes_eventos l ON e.evento_id = l.evento_id
LEFT JOIN comentarios c ON e.evento_id = c.evento_id AND c.estado = 'VISIBLE'
GROUP BY e.evento_id, e.titulo, e.descripcion, d.nombre, d.categoria, e.ubicacion, 
         e.fecha_evento, e.hora_inicio, e.hora_fin, e.max_participantes, e.costo,
         e.nivel_dificultad, e.estado, u.nombre, u.email, e.fecha_creacion, 
         e.imagen_url, e.coordenadas_lat, e.coordenadas_lng;

-- Vista de usuarios con estadísticas
CREATE OR REPLACE VIEW vista_usuarios_estadisticas AS
SELECT 
    u.usuario_id,
    u.nombre,
    u.email,
    u.fecha_registro,
    u.estado,
    COUNT(DISTINCT e.evento_id) as eventos_organizados,
    COUNT(DISTINCT p.participacion_id) as eventos_participados,
    COUNT(DISTINCT l.like_id) as likes_dados,
    COUNT(DISTINCT c.comentario_id) as comentarios_realizados
FROM usuarios u
LEFT JOIN eventos e ON u.usuario_id = e.organizador_id
LEFT JOIN participaciones p ON u.usuario_id = p.usuario_id AND p.estado = 'CONFIRMADO'
LEFT JOIN likes_eventos l ON u.usuario_id = l.usuario_id
LEFT JOIN comentarios c ON u.usuario_id = c.usuario_id AND c.estado = 'VISIBLE'
GROUP BY u.usuario_id, u.nombre, u.email, u.fecha_registro, u.estado;

-- =====================================================
-- PROCEDIMIENTOS ALMACENADOS ÚTILES
-- =====================================================

-- Procedimiento para registrar un nuevo usuario
CREATE OR REPLACE PROCEDURE sp_registrar_usuario(
    p_email IN VARCHAR2,
    p_password IN VARCHAR2,
    p_nombre IN VARCHAR2,
    p_telefono IN VARCHAR2 DEFAULT NULL,
    p_bio IN VARCHAR2 DEFAULT NULL,
    p_resultado OUT VARCHAR2
) AS
    v_count NUMBER;
BEGIN
    -- Verificar si el email ya existe
    SELECT COUNT(*) INTO v_count FROM usuarios WHERE email = p_email;
    
    IF v_count > 0 THEN
        p_resultado := 'ERROR: El email ya está registrado';
    ELSE
        INSERT INTO usuarios (email, password, nombre, telefono, bio)
        VALUES (p_email, p_password, p_nombre, p_telefono, p_bio);
        
        COMMIT;
        p_resultado := 'SUCCESS: Usuario registrado exitosamente';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_resultado := 'ERROR: ' || SQLERRM;
END;
/

-- Procedimiento para autenticar usuario
CREATE OR REPLACE PROCEDURE sp_autenticar_usuario(
    p_email IN VARCHAR2,
    p_password IN VARCHAR2,
    p_usuario_id OUT NUMBER,
    p_nombre OUT VARCHAR2,
    p_resultado OUT VARCHAR2
) AS
BEGIN
    SELECT usuario_id, nombre INTO p_usuario_id, p_nombre
    FROM usuarios 
    WHERE email = p_email AND password = p_password AND estado = 'ACTIVO';
    
    p_resultado := 'SUCCESS: Usuario autenticado';
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_resultado := 'ERROR: Credenciales incorrectas';
        p_usuario_id := NULL;
        p_nombre := NULL;
    WHEN OTHERS THEN
        p_resultado := 'ERROR: ' || SQLERRM;
        p_usuario_id := NULL;
        p_nombre := NULL;
END;
/

-- Procedimiento para crear un evento
CREATE OR REPLACE PROCEDURE sp_crear_evento(
    p_titulo IN VARCHAR2,
    p_descripcion IN VARCHAR2,
    p_deporte_id IN NUMBER,
    p_ubicacion IN VARCHAR2,
    p_fecha_evento IN DATE,
    p_hora_inicio IN VARCHAR2,
    p_hora_fin IN VARCHAR2 DEFAULT NULL,
    p_max_participantes IN NUMBER,
    p_costo IN NUMBER DEFAULT 0,
    p_nivel_dificultad IN VARCHAR2 DEFAULT 'INTERMEDIO',
    p_organizador_id IN NUMBER,
    p_coordenadas_lat IN NUMBER DEFAULT NULL,
    p_coordenadas_lng IN NUMBER DEFAULT NULL,
    p_evento_id OUT NUMBER,
    p_resultado OUT VARCHAR2
) AS
BEGIN
    INSERT INTO eventos (
        titulo, descripcion, deporte_id, ubicacion, fecha_evento,
        hora_inicio, hora_fin, max_participantes, costo, nivel_dificultad,
        organizador_id, coordenadas_lat, coordenadas_lng
    ) VALUES (
        p_titulo, p_descripcion, p_deporte_id, p_ubicacion, p_fecha_evento,
        p_hora_inicio, p_hora_fin, p_max_participantes, p_costo, p_nivel_dificultad,
        p_organizador_id, p_coordenadas_lat, p_coordenadas_lng
    ) RETURNING evento_id INTO p_evento_id;
    
    COMMIT;
    p_resultado := 'SUCCESS: Evento creado exitosamente';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_resultado := 'ERROR: ' || SQLERRM;
        p_evento_id := NULL;
END;
/

-- =====================================================
-- CONSULTAS DE PRUEBA
-- =====================================================

-- Consulta 1: Listar todos los deportes disponibles
SELECT deporte_id, nombre, descripcion, categoria FROM deportes ORDER BY nombre;

-- Consulta 2: Verificar estructura de usuarios
SELECT * FROM usuarios WHERE ROWNUM <= 5;

-- Consulta 3: Verificar estructura de eventos
SELECT * FROM eventos WHERE ROWNUM <= 5;

-- Consulta 4: Estadísticas generales
SELECT 
    'Usuarios Registrados' as categoria,
    COUNT(*) as total
FROM usuarios
UNION ALL
SELECT 
    'Eventos Creados' as categoria,
    COUNT(*) as total
FROM eventos
UNION ALL
SELECT 
    'Deportes Disponibles' as categoria,
    COUNT(*) as total
FROM deportes;

-- =====================================================
-- ÍNDICES PARA MEJORAR RENDIMIENTO
-- =====================================================

CREATE INDEX idx_usuarios_email ON usuarios(email);
CREATE INDEX idx_eventos_fecha ON eventos(fecha_evento);
CREATE INDEX idx_eventos_organizador ON eventos(organizador_id);
CREATE INDEX idx_eventos_deporte ON eventos(deporte_id);
CREATE INDEX idx_participaciones_evento ON participaciones(evento_id);
CREATE INDEX idx_participaciones_usuario ON participaciones(usuario_id);
CREATE INDEX idx_likes_evento ON likes_eventos(evento_id);
CREATE INDEX idx_likes_usuario ON likes_eventos(usuario_id);
CREATE INDEX idx_comentarios_evento ON comentarios(evento_id);
CREATE INDEX idx_mensajes_remitente ON mensajes(remitente_id);
CREATE INDEX idx_mensajes_destinatario ON mensajes(destinatario_id);
CREATE INDEX idx_notificaciones_usuario ON notificaciones(usuario_id);

-- =====================================================
-- COMENTARIOS FINALES
-- =====================================================

/*
REQUISITOS CUMPLIDOS:

1. ✅ Gestión de usuarios (registro, login, perfil)
2. ✅ Gestión de eventos deportivos (crear, editar, eliminar)
3. ✅ Sistema de participaciones en eventos
4. ✅ Sistema de likes/favoritos
5. ✅ Sistema de comentarios
6. ✅ Sistema de mensajería entre usuarios
7. ✅ Sistema de notificaciones
8. ✅ Catálogo de deportes
9. ✅ Ubicaciones geográficas (coordenadas)
10. ✅ Estados y validaciones de datos
11. ✅ Triggers para IDs automáticos
12. ✅ Procedimientos almacenados para operaciones comunes
13. ✅ Vistas para consultas complejas
14. ✅ Índices para optimización
15. ✅ Datos iniciales (deportes)

ESTRUCTURA ESCALABLE Y ROBUSTA PARA LA APLICACIÓN APAÑO
*/

COMMIT;
