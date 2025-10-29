package com.example.apao.database

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey

// =====================================================
// ENTIDADES DE BASE DE DATOS SQLITE CON ROOM
// =====================================================

@Entity(tableName = "usuarios")
data class UsuarioEntity(
    @PrimaryKey val id: String,
    val email: String,
    val password: String,
    val name: String,
    val profileImage: String? = null,
    val bio: String? = null,
    val fechaRegistro: Long = System.currentTimeMillis(),
    val estado: String = "ACTIVO"
)

@Entity(
    tableName = "deportes_favoritos",
    foreignKeys = [
        ForeignKey(
            entity = UsuarioEntity::class,
            parentColumns = ["id"],
            childColumns = ["usuarioId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index(value = ["usuarioId"])]
)
data class DeporteFavoritoEntity(
    @PrimaryKey val id: String,
    val usuarioId: String,
    val deporte: String,
    val fechaAgregado: Long = System.currentTimeMillis()
)

@Entity(
    tableName = "eventos",
    foreignKeys = [
        ForeignKey(
            entity = UsuarioEntity::class,
            parentColumns = ["id"],
            childColumns = ["organizadorId"]
        )
    ],
    indices = [Index(value = ["organizadorId"]), Index(value = ["fechaEvento"])]
)
data class EventoEntity(
    @PrimaryKey val id: String,
    val titulo: String,
    val descripcion: String,
    val deporte: String,
    val ubicacion: String,
    val fechaEvento: Long,
    val hora: String,
    val maxParticipantes: Int,
    val participantesActuales: Int = 0,
    val organizadorId: String,
    val organizadorNombre: String,
    val imagenUrl: String? = null,
    val fechaCreacion: Long = System.currentTimeMillis(),
    val estado: String = "ACTIVO"
)

@Entity(
    tableName = "likes",
    foreignKeys = [
        ForeignKey(
            entity = EventoEntity::class,
            parentColumns = ["id"],
            childColumns = ["eventoId"],
            onDelete = ForeignKey.CASCADE
        ),
        ForeignKey(
            entity = UsuarioEntity::class,
            parentColumns = ["id"],
            childColumns = ["usuarioId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index(value = ["eventoId"]), Index(value = ["usuarioId"])]
)
data class LikeEntity(
    @PrimaryKey val id: String,
    val eventoId: String,
    val usuarioId: String,
    val fechaLike: Long = System.currentTimeMillis()
)

@Entity(
    tableName = "comentarios",
    foreignKeys = [
        ForeignKey(
            entity = EventoEntity::class,
            parentColumns = ["id"],
            childColumns = ["eventoId"],
            onDelete = ForeignKey.CASCADE
        ),
        ForeignKey(
            entity = UsuarioEntity::class,
            parentColumns = ["id"],
            childColumns = ["usuarioId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index(value = ["eventoId"]), Index(value = ["usuarioId"])]
)
data class ComentarioEntity(
    @PrimaryKey val id: String,
    val eventoId: String,
    val usuarioId: String,
    val usuarioNombre: String,
    val texto: String,
    val timestamp: Long = System.currentTimeMillis()
)

@Entity(
    tableName = "mensajes",
    foreignKeys = [
        ForeignKey(
            entity = UsuarioEntity::class,
            parentColumns = ["id"],
            childColumns = ["remitenteId"],
            onDelete = ForeignKey.CASCADE
        ),
        ForeignKey(
            entity = UsuarioEntity::class,
            parentColumns = ["id"],
            childColumns = ["destinatarioId"],
            onDelete = ForeignKey.CASCADE
        ),
        ForeignKey(
            entity = EventoEntity::class,
            parentColumns = ["id"],
            childColumns = ["eventoId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [
        Index(value = ["remitenteId"]),
        Index(value = ["destinatarioId"]),
        Index(value = ["eventoId"])
    ]
)
data class MensajeEntity(
    @PrimaryKey val id: String,
    val remitenteId: String,
    val destinatarioId: String,
    val eventoId: String? = null,
    val texto: String,
    val timestamp: Long = System.currentTimeMillis(),
    val leido: Boolean = false
)


