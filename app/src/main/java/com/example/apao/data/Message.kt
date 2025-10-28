package com.example.apao.data

import java.util.Date

data class Message(
    val id: String = "",
    val senderId: String = "",
    val receiverId: String = "",
    val eventId: String = "",
    val text: String = "",
    val timestamp: Date = Date(),
    val isRead: Boolean = false
)

data class Chat(
    val id: String = "",
    val participants: List<String> = emptyList(),
    val eventId: String = "",
    val lastMessage: Message? = null,
    val unreadCount: Int = 0
)
