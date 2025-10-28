package com.example.apao.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.apao.data.Event
import com.example.apao.data.User
import com.example.apao.data.Message
import com.example.apao.data.Comment
import com.example.apao.repository.EventRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.util.Date
import java.util.UUID

class EventViewModel : ViewModel() {
    private val repository = EventRepository()
    
    private val _isLoggedIn = MutableStateFlow(false)
    val isLoggedIn: StateFlow<Boolean> = _isLoggedIn.asStateFlow()
    
    private val _currentUser = MutableStateFlow<User?>(null)
    val currentUser: StateFlow<User?> = _currentUser.asStateFlow()
    
    private val _events = MutableStateFlow<List<Event>>(emptyList())
    val events: StateFlow<List<Event>> = _events.asStateFlow()
    
    private val _messages = MutableStateFlow<List<Message>>(emptyList())
    val messages: StateFlow<List<Message>> = _messages.asStateFlow()
    
    private val _loginError = MutableStateFlow<String?>(null)
    val loginError: StateFlow<String?> = _loginError.asStateFlow()
    
    private val _registrationSuccess = MutableStateFlow(false)
    val registrationSuccess: StateFlow<Boolean> = _registrationSuccess.asStateFlow()
    
    init {
        loadInitialData()
        observeRepository()
    }
    
    private fun loadInitialData() {
        // Cargar algunos eventos de ejemplo
        val sampleEvents = listOf(
            Event(
                id = "1",
                title = "Partido de Fútbol",
                description = "Partido amistoso en el parque central",
                sport = "Fútbol",
                location = "Parque Central",
                date = Date(),
                time = "18:00",
                maxParticipants = 22,
                currentParticipants = 15,
                organizerId = "org1",
                organizerName = "Juan Pérez",
                imageUrl = "",
                likes = listOf("user1", "user2"),
                comments = emptyList()
            ),
            Event(
                id = "2",
                title = "Torneo de Baloncesto",
                description = "Torneo eliminatorio de baloncesto",
                sport = "Baloncesto",
                location = "Cancha Municipal",
                date = Date(),
                time = "16:00",
                maxParticipants = 20,
                currentParticipants = 12,
                organizerId = "org2",
                organizerName = "María García",
                imageUrl = "",
                likes = listOf("user1"),
                comments = emptyList()
            )
        )
        
        viewModelScope.launch {
            sampleEvents.forEach { event ->
                repository.addEvent(event)
            }
        }
    }
    
    private fun observeRepository() {
        viewModelScope.launch {
            repository.events.collect { eventsList ->
                _events.value = eventsList
            }
        }
        
        viewModelScope.launch {
            repository.currentUser.collect { user ->
                _currentUser.value = user
                _isLoggedIn.value = user != null
            }
        }
        
        viewModelScope.launch {
            repository.messages.collect { messagesList ->
                _messages.value = messagesList
            }
        }
    }
    
    fun registerUser(email: String, password: String, name: String) {
        viewModelScope.launch {
            _loginError.value = null
            _registrationSuccess.value = false
            
            // Verificar si el email ya existe
            val existingUser = repository.getUserByEmail(email)
            if (existingUser != null) {
                _loginError.value = "Este email ya está registrado"
                return@launch
            }
            
            val user = User(
                id = UUID.randomUUID().toString(),
                email = email,
                password = password,
                name = name
            )
            repository.registerUser(user)
            _registrationSuccess.value = true
        }
    }
    
    fun loginUser(email: String, password: String) {
        viewModelScope.launch {
            _loginError.value = null
            
            val success = repository.loginUser(email, password)
            if (!success) {
                _loginError.value = "Email o contraseña incorrectos"
            }
        }
    }
    
    fun logout() {
        viewModelScope.launch {
            repository.logout()
        }
    }
    
    fun addEvent(
        title: String,
        description: String,
        sport: String,
        location: String,
        date: Date,
        time: String,
        maxParticipants: Int
    ) {
        viewModelScope.launch {
            val currentUser = _currentUser.value ?: return@launch
            val event = Event(
                id = UUID.randomUUID().toString(),
                title = title,
                description = description,
                sport = sport,
                location = location,
                date = date,
                time = time,
                maxParticipants = maxParticipants,
                currentParticipants = 0,
                organizerId = currentUser.id,
                organizerName = currentUser.name,
                imageUrl = "",
                likes = emptyList(),
                comments = emptyList()
            )
            repository.addEvent(event)
        }
    }
    
    fun likeEvent(eventId: String) {
        val currentUser = _currentUser.value ?: return
        viewModelScope.launch {
            repository.likeEvent(eventId, currentUser.id)
        }
    }
    
    fun addComment(eventId: String, text: String) {
        val currentUser = _currentUser.value ?: return
        viewModelScope.launch {
            val comment = Comment(
                id = UUID.randomUUID().toString(),
                userId = currentUser.id,
                userName = currentUser.name,
                text = text,
                timestamp = Date()
            )
            repository.addComment(eventId, comment)
        }
    }
    
    fun sendMessage(receiverId: String, eventId: String, text: String) {
        val currentUser = _currentUser.value ?: return
        viewModelScope.launch {
            val message = Message(
                id = UUID.randomUUID().toString(),
                senderId = currentUser.id,
                receiverId = receiverId,
                eventId = eventId,
                text = text,
                timestamp = Date(),
                isRead = false
            )
            repository.sendMessage(message)
        }
    }
}
