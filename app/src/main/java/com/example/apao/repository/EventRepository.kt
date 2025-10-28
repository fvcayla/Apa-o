package com.example.apao.repository

import com.example.apao.data.Event
import com.example.apao.data.User
import com.example.apao.data.Message
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow

class EventRepository {
    private val _events = MutableStateFlow<List<Event>>(emptyList())
    val events: Flow<List<Event>> = _events.asStateFlow()
    
    private val _users = MutableStateFlow<List<User>>(emptyList())
    val users: Flow<List<User>> = _users.asStateFlow()
    
    private val _currentUser = MutableStateFlow<User?>(null)
    val currentUser: Flow<User?> = _currentUser.asStateFlow()
    
    private val _messages = MutableStateFlow<List<Message>>(emptyList())
    val messages: Flow<List<Message>> = _messages.asStateFlow()
    
    suspend fun addEvent(event: Event) {
        val currentEvents = _events.value.toMutableList()
        currentEvents.add(event)
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
    
    suspend fun registerUser(user: User) {
        val currentUsers = _users.value.toMutableList()
        currentUsers.add(user)
        _users.value = currentUsers
        _currentUser.value = user
    }
    
    suspend fun loginUser(email: String, password: String): Boolean {
        val user = _users.value.find { it.email == email && it.password == password }
        return if (user != null) {
            _currentUser.value = user
            true
        } else {
            false
        }
    }
    
    suspend fun logout() {
        _currentUser.value = null
    }
    
    suspend fun getUserByEmail(email: String): User? {
        return _users.value.find { it.email == email }
    }
    
    suspend fun sendMessage(message: Message) {
        val currentMessages = _messages.value.toMutableList()
        currentMessages.add(message)
        _messages.value = currentMessages
    }
}
