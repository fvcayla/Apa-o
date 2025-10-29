package com.example.apao.database

import androidx.room.*

// =====================================================
// DAO (DATA ACCESS OBJECT)
// =====================================================

@Dao
interface ApaoDao {
    
    // ==================== USUARIOS ====================
    @Query("SELECT * FROM usuarios WHERE email = :email AND password = :password")
    suspend fun loginUsuario(email: String, password: String): UsuarioEntity?
    
    @Query("SELECT * FROM usuarios WHERE email = :email")
    suspend fun getUsuarioByEmail(email: String): UsuarioEntity?
    
    @Query("SELECT * FROM usuarios WHERE id = :id")
    suspend fun getUsuarioById(id: String): UsuarioEntity?
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertUsuario(usuario: UsuarioEntity)
    
    @Update
    suspend fun updateUsuario(usuario: UsuarioEntity)
    
    @Delete
    suspend fun deleteUsuario(usuario: UsuarioEntity)
    
    // ==================== DEPORTES FAVORITOS ====================
    @Query("SELECT * FROM deportes_favoritos WHERE usuarioId = :usuarioId")
    suspend fun getDeportesFavoritos(usuarioId: String): List<DeporteFavoritoEntity>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertDeporteFavorito(deporte: DeporteFavoritoEntity)
    
    @Delete
    suspend fun deleteDeporteFavorito(deporte: DeporteFavoritoEntity)
    
    // ==================== EVENTOS ====================
    @Query("SELECT * FROM eventos ORDER BY fechaCreacion DESC")
    suspend fun getAllEventos(): List<EventoEntity>
    
    @Query("SELECT * FROM eventos WHERE organizadorId = :organizadorId ORDER BY fechaCreacion DESC")
    suspend fun getEventosByOrganizador(organizadorId: String): List<EventoEntity>
    
    @Query("SELECT * FROM eventos WHERE id = :id")
    suspend fun getEventoById(id: String): EventoEntity?
    
    @Query("SELECT * FROM eventos WHERE deporte = :deporte ORDER BY fechaEvento ASC")
    suspend fun getEventosByDeporte(deporte: String): List<EventoEntity>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertEvento(evento: EventoEntity)
    
    @Update
    suspend fun updateEvento(evento: EventoEntity)
    
    @Delete
    suspend fun deleteEvento(evento: EventoEntity)
    
    // ==================== LIKES ====================
    @Query("SELECT * FROM likes WHERE eventoId = :eventoId")
    suspend fun getLikesByEvento(eventoId: String): List<LikeEntity>
    
    @Query("SELECT COUNT(*) FROM likes WHERE eventoId = :eventoId")
    suspend fun getTotalLikes(eventoId: String): Int
    
    @Query("SELECT * FROM likes WHERE eventoId = :eventoId AND usuarioId = :usuarioId")
    suspend fun getLike(eventoId: String, usuarioId: String): LikeEntity?
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertLike(like: LikeEntity)
    
    @Delete
    suspend fun deleteLike(like: LikeEntity)
    
    @Query("DELETE FROM likes WHERE eventoId = :eventoId AND usuarioId = :usuarioId")
    suspend fun deleteLikeByEventoAndUsuario(eventoId: String, usuarioId: String)
    
    // ==================== COMENTARIOS ====================
    @Query("SELECT * FROM comentarios WHERE eventoId = :eventoId ORDER BY timestamp DESC")
    suspend fun getComentariosByEvento(eventoId: String): List<ComentarioEntity>
    
    @Query("SELECT COUNT(*) FROM comentarios WHERE eventoId = :eventoId")
    suspend fun getTotalComentarios(eventoId: String): Int
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertComentario(comentario: ComentarioEntity)
    
    @Delete
    suspend fun deleteComentario(comentario: ComentarioEntity)
    
    // ==================== MENSAJES ====================
    @Query("SELECT * FROM mensajes WHERE destinatarioId = :usuarioId OR remitenteId = :usuarioId ORDER BY timestamp DESC")
    suspend fun getMensajesByUsuario(usuarioId: String): List<MensajeEntity>
    
    @Query("SELECT * FROM mensajes WHERE (remitenteId = :usuarioId1 AND destinatarioId = :usuarioId2) OR (remitenteId = :usuarioId2 AND destinatarioId = :usuarioId1) ORDER BY timestamp ASC")
    suspend fun getMensajesBetweenUsuarios(usuarioId1: String, usuarioId2: String): List<MensajeEntity>
    
    @Query("SELECT COUNT(*) FROM mensajes WHERE destinatarioId = :usuarioId AND leido = 0")
    suspend fun getUnreadMensajesCount(usuarioId: String): Int
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertMensaje(mensaje: MensajeEntity)
    
    @Update
    suspend fun updateMensaje(mensaje: MensajeEntity)
    
    @Query("UPDATE mensajes SET leido = 1 WHERE id = :mensajeId")
    suspend fun marcarMensajeComoLeido(mensajeId: String)
}


