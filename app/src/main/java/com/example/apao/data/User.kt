package com.example.apao.data

data class User(
    val id: String = "",
    val email: String = "",
    val password: String = "",
    val name: String = "",
    val profileImage: String = "",
    val bio: String = "",
    val sports: List<String> = emptyList()
)


