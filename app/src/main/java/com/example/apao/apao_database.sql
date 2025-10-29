-- =====================================================
-- BASE DE DATOS SQLITE PARA APLICACIÓN "APAÑO"
-- =====================================================
-- Script SQLite para Android
-- Usar con Room Database
-- =====================================================

-- =====================================================
-- TABLA 1: USUARIOS
-- =====================================================
CREATE TABLE IF NOT EXISTS usuarios (
    id TEXT PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    name TEXT NOT NULL,
    profile_image TEXT,
    bio TEXT,
    fecha_registro INTEGER DEFAULT (strftime('%s', 'now')),
    estado TEXT DEFAULT 'ACTIVO' CHECK (estado IN ('ACTIVO', 'INACTIVO'))
);

-- =====================================================
-- TABLA 2: DEPORTES_FAVORITOS
-- =====================================================
CREATE TABLE IF NOT EXISTS deportes_favoritos (
    id TEXT PRIMARY KEY,
    usuario_id TEXT NOT NULL,
    deporte TEXT NOT NULL,
    fecha_agregado INTEGER DEFAULT (strftime('%s', 'now')),
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
);

-- =====================================================
-- TABLA 3: EVENTOS
-- =====================================================
CREATE TABLE IF NOT EXISTS eventos (
    id TEXT PRIMARY KEY,
    titulo TEXT NOT NULL,
    descripcion TEXT NOT NULL,
    deporte TEXT NOT NULL,
    ubicacion TEXT NOT NULL,
    fecha_evento INTEGER NOT NULL,
    hora TEXT NOT NULL,
    max_participantes INTEGER NOT NULL,
    participantes_actuales INTEGER DEFAULT 0,
    organizador_id TEXT NOT NULL,
    organizador_nombre TEXT NOT NULL,
    imagen_url TEXT,
    fecha_creacion INTEGER DEFAULT (strftime('%s', 'now')),
    estado TEXT DEFAULT 'ACTIVO' CHECK (estado IN ('ACTIVO', 'CANCELADO', 'COMPLETADO')),
    FOREIGN KEY (organizador_id) REFERENCES usuarios(id)
);

-- =====================================================
-- TABLA 4: LIKES
-- =====================================================
CREATE TABLE IF NOT EXISTS likes (
    id TEXT PRIMARY KEY,
    evento_id TEXT NOT NULL,
    usuario_id TEXT NOT NULL,
    fecha_like INTEGER DEFAULT (strftime('%s', 'now')),
    FOREIGN KEY (evento_id) REFERENCES eventos(id) ON DELETE CASCADE,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    UNIQUE(evento_id, usuario_id)
);

-- =====================================================
-- TABLA 5: COMENTARIOS
-- =====================================================
CREATE TABLE IF NOT EXISTS comentarios (
    id TEXT PRIMARY KEY,
    evento_id TEXT NOT NULL,
    usuario_id TEXT NOT NULL,
    usuario_nombre TEXT NOT NULL,
    texto TEXT NOT NULL,
    timestamp INTEGER DEFAULT (strftime('%s', 'now')),
    FOREIGN KEY (evento_id) REFERENCES eventos(id) ON DELETE CASCADE,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
);

-- =====================================================
-- TABLA 6: MENSAJES
-- =====================================================
CREATE TABLE IF NOT EXISTS mensajes (
    id TEXT PRIMARY KEY,
    remitente_id TEXT NOT NULL,
    destinatario_id TEXT NOT NULL,
    evento_id TEXT,
    texto TEXT NOT NULL,
    timestamp INTEGER DEFAULT (strftime('%s', 'now')),
    leido INTEGER DEFAULT 0 CHECK (leido IN (0, 1)),
    FOREIGN KEY (remitente_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    FOREIGN KEY (destinatario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    FOREIGN KEY (evento_id) REFERENCES eventos(id) ON DELETE CASCADE
);

-- =====================================================
-- ÍNDICES PARA OPTIMIZACIÓN
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_usuarios_email ON usuarios(email);
CREATE INDEX IF NOT EXISTS idx_eventos_organizador ON eventos(organizador_id);
CREATE INDEX IF NOT EXISTS idx_eventos_fecha ON eventos(fecha_evento);
CREATE INDEX IF NOT EXISTS idx_likes_evento ON likes(evento_id);
CREATE INDEX IF NOT EXISTS idx_likes_usuario ON likes(usuario_id);
CREATE INDEX IF NOT EXISTS idx_comentarios_evento ON comentarios(evento_id);
CREATE INDEX IF NOT EXISTS idx_mensajes_destinatario ON mensajes(destinatario_id);
CREATE INDEX IF NOT EXISTS idx_mensajes_remitente ON mensajes(remitente_id);
CREATE INDEX IF NOT EXISTS idx_deportes_favoritos_usuario ON deportes_favoritos(usuario_id);

-- =====================================================
-- DATOS DE PRUEBA (OPCIONAL)
-- =====================================================

-- Insertar usuarios de prueba
INSERT OR IGNORE INTO usuarios (id, email, password, name, bio) VALUES 
('user1', 'juan@email.com', 'password123', 'Juan Pérez', 'Amante del fútbol'),
('user2', 'maria@email.com', 'password456', 'María García', 'Entusiasta del baloncesto');

-- Insertar eventos de prueba
INSERT OR IGNORE INTO eventos (id, titulo, descripcion, deporte, ubicacion, fecha_evento, hora, max_participantes, organizador_id, organizador_nombre) VALUES 
('event1', 'Partido de Fútbol', 'Partido amistoso en el parque central', 'Fútbol', 'Parque Central', strftime('%s', 'now', '+7 days'), '18:00', 22, 'user1', 'Juan Pérez'),
('event2', 'Torneo de Baloncesto', 'Torneo eliminatorio de baloncesto', 'Baloncesto', 'Cancha Municipal', strftime('%s', 'now', '+14 days'), '16:00', 20, 'user2', 'María García');

-- Insertar likes de prueba
INSERT OR IGNORE INTO likes (id, evento_id, usuario_id) VALUES 
('like1', 'event1', 'user1'),
('like2', 'event1', 'user2'),
('like3', 'event2', 'user1');

-- Insertar deportes favoritos
INSERT OR IGNORE INTO deportes_favoritos (id, usuario_id, deporte) VALUES 
('df1', 'user1', 'Fútbol'),
('df2', 'user1', 'Baloncesto'),
('df3', 'user2', 'Baloncesto'),
('df4', 'user2', 'Tenis');

-- =====================================================
-- CONSULTAS ÚTILES
-- =====================================================

-- Consulta: Eventos con estadísticas
-- SELECT e.*, COUNT(DISTINCT l.usuario_id) as total_likes, 
--        COUNT(DISTINCT c.id) as total_comentarios
-- FROM eventos e
-- LEFT JOIN likes l ON e.id = l.evento_id
-- LEFT JOIN comentarios c ON e.id = c.evento_id
-- GROUP BY e.id;

-- Consulta: Usuarios con estadísticas
-- SELECT u.*, COUNT(DISTINCT e.id) as eventos_creados,
--        COUNT(DISTINCT l.evento_id) as likes_dados,
--        COUNT(DISTINCT c.id) as comentarios_realizados
-- FROM usuarios u
-- LEFT JOIN eventos e ON u.id = e.organizador_id
-- LEFT JOIN likes l ON u.id = l.usuario_id
-- LEFT JOIN comentarios c ON u.id = c.usuario_id
-- GROUP BY u.id;


