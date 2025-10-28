-- =====================================================
-- BASE DE DATOS PARA APLICACIÓN "APAÑO" - EVENTOS DEPORTIVOS
-- =====================================================
-- Script SQL para SQL Developer
-- Basado en las pantallas: Login, Main, Create Event, Profile, Messages
-- =====================================================

-- Crear usuario de base de datos
CREATE USER apao_user IDENTIFIED BY apao123;
GRANT CONNECT, RESOURCE, CREATE VIEW, CREATE SEQUENCE TO apao_user;

CONNECT apao_user/apao123;

-- =====================================================
-- TABLA 1: USUARIOS
-- =====================================================
-- Corresponde a: LoginScreen, ProfileScreen
-- Modelo: User.kt (id, email, password, name, profileImage, bio, sports)
CREATE TABLE usuarios (
    id VARCHAR2(50) PRIMARY KEY,
    email VARCHAR2(100) UNIQUE NOT NULL,
    password VARCHAR2(255) NOT NULL,
    name VARCHAR2(100) NOT NULL,
    profile_image VARCHAR2(500),
    bio VARCHAR2(1000),
    fecha_registro DATE DEFAULT SYSDATE,
    estado VARCHAR2(20) DEFAULT 'ACTIVO' CHECK (estado IN ('ACTIVO', 'INACTIVO'))
);

-- =====================================================
-- TABLA 2: DEPORTES_FAVORITOS (Relación muchos a muchos)
-- =====================================================
-- Para almacenar los deportes favoritos de cada usuario
CREATE TABLE deportes_favoritos (
    id VARCHAR2(50) PRIMARY KEY,
    usuario_id VARCHAR2(50) NOT NULL,
    deporte VARCHAR2(100) NOT NULL,
    fecha_agregado DATE DEFAULT SYSDATE,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
);

-- =====================================================
-- TABLA 3: EVENTOS
-- =====================================================
-- Corresponde a: MainScreen, CreateEventScreen, ProfileScreen
-- Modelo: Event.kt
CREATE TABLE eventos (
    id VARCHAR2(50) PRIMARY KEY,
    titulo VARCHAR2(200) NOT NULL,
    descripcion VARCHAR2(1000) NOT NULL,
    deporte VARCHAR2(100) NOT NULL,
    ubicacion VARCHAR2(200) NOT NULL,
    fecha_evento DATE NOT NULL,
    hora VARCHAR2(5) NOT NULL,
    max_participantes NUMBER(4) NOT NULL,
    participantes_actuales NUMBER(4) DEFAULT 0,
    organizador_id VARCHAR2(50) NOT NULL,
    organizador_nombre VARCHAR2(100) NOT NULL,
    imagen_url VARCHAR2(500),
    fecha_creacion DATE DEFAULT SYSDATE,
    estado VARCHAR2(20) DEFAULT 'ACTIVO' CHECK (estado IN ('ACTIVO', 'CANCELADO', 'COMPLETADO')),
    FOREIGN KEY (organizador_id) REFERENCES usuarios(id)
);

-- =====================================================
-- TABLA 4: LIKES (Relación muchos a muchos)
-- =====================================================
-- Corresponde a: MainScreen (sistema de likes en eventos)
-- Almacena los likes de usuarios en eventos
CREATE TABLE likes (
    id VARCHAR2(50) PRIMARY KEY,
    evento_id VARCHAR2(50) NOT NULL,
    usuario_id VARCHAR2(50) NOT NULL,
    fecha_like DATE DEFAULT SYSDATE,
    FOREIGN KEY (evento_id) REFERENCES eventos(id) ON DELETE CASCADE,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    UNIQUE(evento_id, usuario_id)
);

-- =====================================================
-- TABLA 5: COMENTARIOS
-- =====================================================
-- Corresponde a: MainScreen (sistema de comentarios)
-- Modelo: Comment.kt (id, userId, userName, text, timestamp)
CREATE TABLE comentarios (
    id VARCHAR2(50) PRIMARY KEY,
    evento_id VARCHAR2(50) NOT NULL,
    usuario_id VARCHAR2(50) NOT NULL,
    usuario_nombre VARCHAR2(100) NOT NULL,
    texto VARCHAR2(1000) NOT NULL,
    timestamp DATE DEFAULT SYSDATE,
    FOREIGN KEY (evento_id) REFERENCES eventos(id) ON DELETE CASCADE,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
);

-- =====================================================
-- TABLA 6: MENSAJES
-- =====================================================
-- Corresponde a: MessagesScreen, MainScreen
-- Modelo: Message.kt (id, senderId, receiverId, eventId, text, timestamp, isRead)
CREATE TABLE mensajes (
    id VARCHAR2(50) PRIMARY KEY,
    remitente_id VARCHAR2(50) NOT NULL,
    destinatario_id VARCHAR2(50) NOT NULL,
    evento_id VARCHAR2(50),
    texto VARCHAR2(2000) NOT NULL,
    timestamp DATE DEFAULT SYSDATE,
    leido CHAR(1) DEFAULT 'N' CHECK (leido IN ('Y', 'N')),
    FOREIGN KEY (remitente_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    FOREIGN KEY (destinatario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    FOREIGN KEY (evento_id) REFERENCES eventos(id) ON DELETE CASCADE
);

-- =====================================================
-- SECUENCIAS PARA GENERAR IDs (si es necesario)
-- =====================================================
CREATE SEQUENCE seq_usuarios START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_deportes START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_eventos START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_likes START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_comentarios START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_mensajes START WITH 1 INCREMENT BY 1;

-- =====================================================
-- VISTAS PARA FACILITAR CONSULTAS
-- =====================================================

-- Vista: Lista de eventos con estadísticas
CREATE OR REPLACE VIEW vista_eventos_completos AS
SELECT 
    e.id,
    e.titulo,
    e.descripcion,
    e.deporte,
    e.ubicacion,
    e.fecha_evento,
    e.hora,
    e.max_participantes,
    e.participantes_actuales,
    e.organizador_id,
    e.organizador_nombre,
    e.imagen_url,
    e.fecha_creacion,
    e.estado,
    COUNT(DISTINCT l.usuario_id) as total_likes,
    COUNT(DISTINCT c.id) as total_comentarios,
    CASE 
        WHEN e.max_participantes > 0 
        THEN ROUND((e.participantes_actuales / e.max_participantes) * 100, 2)
        ELSE 0 
    END as porcentaje_ocupacion
FROM eventos e
LEFT JOIN likes l ON e.id = l.evento_id
LEFT JOIN comentarios c ON e.id = c.evento_id
GROUP BY e.id, e.titulo, e.descripcion, e.deporte, e.ubicacion, e.fecha_evento,
         e.hora, e.max_participantes, e.participantes_actuales, e.organizador_id,
         e.organizador_nombre, e.imagen_url, e.fecha_creacion, e.estado;

-- Vista: Usuarios con estadísticas
CREATE OR REPLACE VIEW vista_usuarios_stats AS
SELECT 
    u.id,
    u.email,
    u.name,
    u.profile_image,
    u.bio,
    u.fecha_registro,
    u.estado,
    COUNT(DISTINCT e.id) as eventos_creados,
    COUNT(DISTINCT l.evento_id) as likes_dados,
    COUNT(DISTINCT c.id) as comentarios_realizados,
    COUNT(DISTINCT m.id) as mensajes_recibidos
FROM usuarios u
LEFT JOIN eventos e ON u.id = e.organizador_id
LEFT JOIN likes l ON u.id = l.usuario_id
LEFT JOIN comentarios c ON u.id = c.usuario_id
LEFT JOIN mensajes m ON u.id = m.destinatario_id
GROUP BY u.id, u.email, u.name, u.profile_image, u.bio, u.fecha_registro, u.estado;

-- Vista: Eventos de un usuario específico (para perfil)
CREATE OR REPLACE VIEW vista_eventos_usuario AS
SELECT 
    e.*,
    COUNT(DISTINCT l.usuario_id) as total_likes,
    COUNT(DISTINCT c.id) as total_comentarios
FROM eventos e
LEFT JOIN likes l ON e.id = l.evento_id
LEFT JOIN comentarios c ON e.id = c.evento_id
GROUP BY e.id, e.titulo, e.descripcion, e.deporte, e.ubicacion, e.fecha_evento,
         e.hora, e.max_participantes, e.participantes_actuales, e.organizador_id,
         e.organizador_nombre, e.imagen_url, e.fecha_creacion, e.estado;

-- =====================================================
-- DATOS DE PRUEBA
-- =====================================================

-- Insertar algunos usuarios de prueba
INSERT INTO usuarios (id, email, password, name, bio) VALUES ('user1', 'juan@email.com', 'password123', 'Juan Pérez', 'Amante del fútbol');
INSERT INTO usuarios (id, email, password, name, bio) VALUES ('user2', 'maria@email.com', 'password456', 'María García', 'Entusiasta del baloncesto');

-- Insertar eventos de prueba
INSERT INTO eventos (id, titulo, descripcion, deporte, ubicacion, fecha_evento, hora, max_participantes, organizador_id, organizador_nombre)
VALUES ('event1', 'Partido de Fútbol', 'Partido amistoso en el parque central', 'Fútbol', 'Parque Central', SYSDATE + 7, '18:00', 22, 'user1', 'Juan Pérez');

INSERT INTO eventos (id, titulo, descripcion, deporte, ubicacion, fecha_evento, hora, max_participantes, organizador_id, organizador_nombre)
VALUES ('event2', 'Torneo de Baloncesto', 'Torneo eliminatorio de baloncesto', 'Baloncesto', 'Cancha Municipal', SYSDATE + 14, '16:00', 20, 'user2', 'María García');

-- Insertar algunos likes de prueba
INSERT INTO likes (id, evento_id, usuario_id) VALUES ('like1', 'event1', 'user1');
INSERT INTO likes (id, evento_id, usuario_id) VALUES ('like2', 'event1', 'user2');
INSERT INTO likes (id, evento_id, usuario_id) VALUES ('like3', 'event2', 'user1');

-- Insertar deportes favoritos
INSERT INTO deportes_favoritos (id, usuario_id, deporte) VALUES ('df1', 'user1', 'Fútbol');
INSERT INTO deportes_favoritos (id, usuario_id, deporte) VALUES ('df2', 'user1', 'Baloncesto');
INSERT INTO deportes_favoritos (id, usuario_id, deporte) VALUES ('df3', 'user2', 'Baloncesto');
INSERT INTO deportes_favoritos (id, usuario_id, deporte) VALUES ('df4', 'user2', 'Tenis');

COMMIT;

-- =====================================================
-- CONSULTAS DE PRUEBA
-- =====================================================

-- Consulta 1: Todos los usuarios con sus eventos creados
SELECT 
    u.name as usuario,
    u.email,
    COUNT(e.id) as eventos_creados,
    SUM(e.max_participantes) as total_participantes
FROM usuarios u
LEFT JOIN eventos e ON u.id = e.organizador_id
GROUP BY u.name, u.email
ORDER BY eventos_creados DESC;

-- Consulta 2: Eventos con más likes
SELECT 
    e.titulo,
    e.deporte,
    COUNT(l.usuario_id) as total_likes,
    e.organizador_nombre
FROM eventos e
LEFT JOIN likes l ON e.id = l.evento_id
GROUP BY e.titulo, e.deporte, e.organizador_nombre
ORDER BY total_likes DESC;

-- Consulta 3: Usuarios con deportes favoritos
SELECT 
    u.name,
    u.email,
    LISTAGG(df.deporte, ', ') WITHIN GROUP (ORDER BY df.deporte) as deportes_favoritos
FROM usuarios u
LEFT JOIN deportes_favoritos df ON u.id = df.usuario_id
GROUP BY u.name, u.email;

-- Consulta 4: Estadísticas generales
SELECT 
    (SELECT COUNT(*) FROM usuarios) as total_usuarios,
    (SELECT COUNT(*) FROM eventos) as total_eventos,
    (SELECT COUNT(*) FROM likes) as total_likes,
    (SELECT COUNT(*) FROM comentarios) as total_comentarios,
    (SELECT COUNT(*) FROM mensajes) as total_mensajes;

-- =====================================================
-- PROCEDIMIENTOS ALMACENADOS
-- =====================================================

-- Procedimiento para registrar usuario (LoginScreen)
CREATE OR REPLACE PROCEDURE sp_registrar_usuario(
    p_email IN VARCHAR2,
    p_password IN VARCHAR2,
    p_name IN VARCHAR2,
    p_id OUT VARCHAR2,
    p_resultado OUT VARCHAR2
) AS
    v_count NUMBER;
BEGIN
    -- Verificar si el email ya existe
    SELECT COUNT(*) INTO v_count FROM usuarios WHERE email = p_email;
    
    IF v_count > 0 THEN
        p_resultado := 'ERROR: El email ya está registrado';
        p_id := NULL;
    ELSE
        -- Generar ID único
        SELECT 'user' || seq_usuarios.NEXTVAL INTO p_id FROM DUAL;
        
        INSERT INTO usuarios (id, email, password, name)
        VALUES (p_id, p_email, p_password, p_name);
        
        COMMIT;
        p_resultado := 'SUCCESS: Usuario registrado exitosamente';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_resultado := 'ERROR: ' || SQLERRM;
        p_id := NULL;
END;
/

-- Procedimiento para autenticar usuario (LoginScreen)
CREATE OR REPLACE PROCEDURE sp_login_usuario(
    p_email IN VARCHAR2,
    p_password IN VARCHAR2,
    p_id OUT VARCHAR2,
    p_name OUT VARCHAR2,
    p_resultado OUT VARCHAR2
) AS
BEGIN
    SELECT id, name INTO p_id, p_name
    FROM usuarios 
    WHERE email = p_email AND password = p_password AND estado = 'ACTIVO';
    
    p_resultado := 'SUCCESS: Usuario autenticado';
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_resultado := 'ERROR: Credenciales incorrectas';
        p_id := NULL;
        p_name := NULL;
    WHEN OTHERS THEN
        p_resultado := 'ERROR: ' || SQLERRM;
        p_id := NULL;
        p_name := NULL;
END;
/

-- Procedimiento para crear evento (CreateEventScreen)
CREATE OR REPLACE PROCEDURE sp_crear_evento(
    p_titulo IN VARCHAR2,
    p_descripcion IN VARCHAR2,
    p_deporte IN VARCHAR2,
    p_ubicacion IN VARCHAR2,
    p_fecha_evento IN DATE,
    p_hora IN VARCHAR2,
    p_max_participantes IN NUMBER,
    p_organizador_id IN VARCHAR2,
    p_organizador_nombre IN VARCHAR2,
    p_evento_id OUT VARCHAR2,
    p_resultado OUT VARCHAR2
) AS
BEGIN
    -- Generar ID único
    SELECT 'event' || seq_eventos.NEXTVAL INTO p_evento_id FROM DUAL;
    
    INSERT INTO eventos (id, titulo, descripcion, deporte, ubicacion, fecha_evento, 
                        hora, max_participantes, organizador_id, organizador_nombre)
    VALUES (p_evento_id, p_titulo, p_descripcion, p_deporte, p_ubicacion, p_fecha_evento,
            p_hora, p_max_participantes, p_organizador_id, p_organizador_nombre);
    
    COMMIT;
    p_resultado := 'SUCCESS: Evento creado exitosamente';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_resultado := 'ERROR: ' || SQLERRM;
        p_evento_id := NULL;
END;
/

-- Procedimiento para dar like a un evento (MainScreen)
CREATE OR REPLACE PROCEDURE sp_dar_like(
    p_evento_id IN VARCHAR2,
    p_usuario_id IN VARCHAR2,
    p_resultado OUT VARCHAR2
) AS
    v_count NUMBER;
BEGIN
    -- Verificar si ya existe el like
    SELECT COUNT(*) INTO v_count 
    FROM likes 
    WHERE evento_id = p_evento_id AND usuario_id = p_usuario_id;
    
    IF v_count > 0 THEN
        -- Eliminar like
        DELETE FROM likes 
        WHERE evento_id = p_evento_id AND usuario_id = p_usuario_id;
        p_resultado := 'SUCCESS: Like eliminado';
    ELSE
        -- Agregar like
        INSERT INTO likes (id, evento_id, usuario_id)
        VALUES ('like' || seq_likes.NEXTVAL, p_evento_id, p_usuario_id);
        p_resultado := 'SUCCESS: Like agregado';
    END IF;
    
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_resultado := 'ERROR: ' || SQLERRM;
END;
/

-- =====================================================
-- ÍNDICES PARA OPTIMIZACIÓN
-- =====================================================

CREATE INDEX idx_eventos_organizador ON eventos(organizador_id);
CREATE INDEX idx_eventos_fecha ON eventos(fecha_evento);
CREATE INDEX idx_likes_evento ON likes(evento_id);
CREATE INDEX idx_likes_usuario ON likes(usuario_id);
CREATE INDEX idx_comentarios_evento ON comentarios(evento_id);
CREATE INDEX idx_mensajes_destinatario ON mensajes(destinatario_id);
CREATE INDEX idx_mensajes_remitente ON mensajes(remitente_id);
CREATE INDEX idx_usuarios_email ON usuarios(email);

-- =====================================================
-- FIN DEL SCRIPT
-- =====================================================

/*
PANTALLAS Y SUS CORRESPONCIAS:

1. LOGIN_SCREEN → Tabla: usuarios, Procedimientos: sp_registrar_usuario, sp_login_usuario
2. MAIN_SCREEN → Tablas: eventos, likes, comentarios, Vista: vista_eventos_completos
3. CREATE_EVENT_SCREEN → Tabla: eventos, Procedimiento: sp_crear_evento
4. PROFILE_SCREEN → Tablas: usuarios, eventos, deportes_favoritos, Vista: vista_usuarios_stats
5. MESSAGES_SCREEN → Tabla: mensajes

MODELOS DE DATOS:
- User.kt → Tabla: usuarios + deportes_favoritos
- Event.kt → Tabla: eventos
- Comment.kt → Tabla: comentarios
- Message.kt → Tabla: mensajes
*/

COMMIT;
