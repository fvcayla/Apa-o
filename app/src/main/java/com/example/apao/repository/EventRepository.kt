package com.example.apao.repository

import android.content.Context
import com.example.apao.data.Event
import com.example.apao.data.User
import com.example.apao.data.Message
import com.example.apao.database.ApaoDatabase
import com.example.apao.database.UsuarioEntity
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow

class EventRepository(context: Context) {
    private val database = ApaoDatabase.getDatabase(context)
    private val dao = database.apaoDao()
    
    private val _events = MutableStateFlow<List<Event>>(emptyList())
    val events: Flow<List<Event>> = _events.asStateFlow()
    
    private val _currentUser = MutableStateFlow<User?>(null)
    val currentUser: Flow<User?> = _currentUser.asStateFlow()
    
    private val _messages = MutableStateFlow<List<Message>>(emptyList())
    val messages: Flow<List<Message>> = _messages.asStateFlow()
    
    // Convertir UsuarioEntity a User
    private fun UsuarioEntity.toUser(): User {
        return User(
            id = this.id,
            email = this.email,
            password = this.password,
            name = this.name,
            profileImage = this.profileImage ?: "",
            bio = this.bio ?: "",
            sports = emptyList() // Se puede cargar desde deportes_favoritos si es necesario
        )
    }
    
    // Convertir User a UsuarioEntity
    private fun User.toUsuarioEntity(): UsuarioEntity {
        return UsuarioEntity(
            id = this.id,
            email = this.email,
            password = this.password,
            name = this.name,
            profileImage = this.profileImage.takeIf { it.isNotEmpty() },
            bio = this.bio.takeIf { it.isNotEmpty() },
            fechaRegistro = System.currentTimeMillis(),
            estado = "ACTIVO"
        )
    }
    
    suspend fun addEvent(event: Event) {
        val currentEvents = _events.value.toMutableList()
        // Agregar el nuevo evento al principio de la lista (más recientes primero)
        currentEvents.add(0, event)
        _events.value = currentEvents
    }
    
    suspend fun updateEvent(event: Event) {
        val currentEvents = _events.value.toMutableList()
        val index = currentEvents.indexOfFirst { it.id == event.id }
        if (index != -1) {
            currentEvents[index] = event
            _events.value = currentEvents
        }
    }
    
    suspend fun likeEvent(eventId: String, userId: String) {
        val currentEvents = _events.value.toMutableList()
        val eventIndex = currentEvents.indexOfFirst { it.id == eventId }
        if (eventIndex != -1) {
            val event = currentEvents[eventIndex]
            val likes = event.likes.toMutableList()
            if (likes.contains(userId)) {
                likes.remove(userId)
            } else {
                likes.add(userId)
            }
            currentEvents[eventIndex] = event.copy(likes = likes)
            _events.value = currentEvents
        }
    }
    
    suspend fun addComment(eventId: String, comment: com.example.apao.data.Comment) {
        val currentEvents = _events.value.toMutableList()
        val eventIndex = currentEvents.indexOfFirst { it.id == eventId }
        if (eventIndex != -1) {
            val event = currentEvents[eventIndex]
            val comments = event.comments.toMutableList()
            comments.add(comment)
            currentEvents[eventIndex] = event.copy(comments = comments)
            _events.value = currentEvents
        }
    }
    
    suspend fun registerUser(user: User): Boolean {
        try {
            // Verificar si el email ya existe en la base de datos
            val existingUser = dao.getUsuarioByEmail(user.email)
            if (existingUser != null) {
                return false
            }
            
            // Convertir User a UsuarioEntity y guardar en la base de datos
            val usuarioEntity = user.toUsuarioEntity()
            dao.insertUsuario(usuarioEntity)
            
            // NO establecer _currentUser aquí - el usuario necesita iniciar sesión
            return true
        } catch (e: Exception) {
            return false
        }
    }
    
    suspend fun loginUser(email: String, password: String): Boolean {
        try {
            // Buscar usuario en la base de datos
            val usuarioEntity = dao.loginUsuario(email, password)
            return if (usuarioEntity != null) {
                val user = usuarioEntity.toUser()
                _currentUser.value = user
                true
            } else {
                false
            }
        } catch (e: Exception) {
            return false
        }
    }
    
    // Método para verificar usuarios registrados (para debug)
    suspend fun getUsersCount(): Int {
        // Esta función podría requerir agregar un método en el DAO si se necesita
        return 0 // Por ahora retornamos 0, ya que no tenemos un método para contar
    }
    
    suspend fun logout() {
        _currentUser.value = null
    }
    
    suspend fun getUserByEmail(email: String): User? {
        try {
            val usuarioEntity = dao.getUsuarioByEmail(email)
            return usuarioEntity?.toUser()
        } catch (e: Exception) {
            return null
        }
    }
    
    // Cargar el usuario actual desde SharedPreferences o mantenerlo en memoria
    suspend fun loadCurrentUser(userId: String) {
        try {
            val usuarioEntity = dao.getUsuarioById(userId)
            usuarioEntity?.let {
                _currentUser.value = it.toUser()
            }
        } catch (e: Exception) {
            // Error al cargar usuario
        }
    }
    
    suspend fun sendMessage(message: Message) {
        val currentMessages = _messages.value.toMutableList()
        currentMessages.add(message)
        _messages.value = currentMessages
    }
}
