package com.example.apao.database

import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import android.content.Context

// =====================================================
// BASE DE DATOS ROOM
// =====================================================

@Database(
    entities = [
        UsuarioEntity::class,
        DeporteFavoritoEntity::class,
        EventoEntity::class,
        LikeEntity::class,
        ComentarioEntity::class,
        MensajeEntity::class
    ],
    version = 1,
    exportSchema = false
)
abstract class ApaoDatabase : RoomDatabase() {
    
    abstract fun apaoDao(): ApaoDao
    
    companion object {
        @Volatile
        private var INSTANCE: ApaoDatabase? = null
        
        fun getDatabase(context: Context): ApaoDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    ApaoDatabase::class.java,
                    "apao_database"
                )
                    .fallbackToDestructiveMigration() // Para pruebas, recrea la BD si hay cambios
                    .build()
                INSTANCE = instance
                instance
            }
        }
    }
}
