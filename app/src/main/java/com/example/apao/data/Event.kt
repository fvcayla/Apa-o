package com.example.apao.data

import java.util.Date

data class Event(
    val id: String = "",
    val title: String = "",
    val description: String = "",
    val sport: String = "",
    val location: String = "",
    val date: Date = Date(),
    val time: String = "",
    val maxParticipants: Int = 0,
    val currentParticipants: Int = 0,
    val organizerId: String = "",
    val organizerName: String = "",
    val imageUrl: String = "",
    val likes: List<String> = emptyList(),
    val comments: List<Comment> = emptyList()
)

data class Comment(
    val id: String = "",
    val userId: String = "",
    val userName: String = "",
    val text: String = "",
    val timestamp: Date = Date()
)
