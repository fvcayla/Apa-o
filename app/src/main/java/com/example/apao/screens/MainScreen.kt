package com.example.apao.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.apao.data.Event
import com.example.apao.viewmodel.EventViewModel
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MainScreen(
    onNavigateToProfile: () -> Unit,
    onNavigateToCreateEvent: () -> Unit,
    onNavigateToMessages: (String) -> Unit,
    viewModel: EventViewModel = viewModel()
) {
    val events by viewModel.events.collectAsState()
    val currentUser by viewModel.currentUser.collectAsState()
    
    Column(
        modifier = Modifier.fillMaxSize()
    ) {
        // Header con navegación
        Card(
            modifier = Modifier.fillMaxWidth(),
            elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
        ) {
            Column(
                modifier = Modifier.padding(16.dp)
            ) {
                // Título principal
                Text(
                    text = "Apaño",
                    fontSize = 24.sp,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.padding(bottom = 16.dp)
                )
                
                // Barra de navegación
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceEvenly
                ) {
                    // Crear
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        IconButton(
                            onClick = onNavigateToCreateEvent,
                            modifier = Modifier.size(48.dp)
                        ) {
                            Icon(
                                Icons.Default.Create,
                                contentDescription = "Crear",
                                modifier = Modifier.size(24.dp)
                            )
                        }
                        Text(
                            text = "Crear",
                            fontSize = 12.sp
                        )
                    }
                    
                    // Perfil
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        IconButton(
                            onClick = onNavigateToProfile,
                            modifier = Modifier.size(48.dp)
                        ) {
                            Icon(
                                Icons.Default.Person,
                                contentDescription = "Perfil",
                                modifier = Modifier.size(24.dp)
                            )
                        }
                        Text(
                            text = "Perfil",
                            fontSize = 12.sp
                        )
                    }
                }
            }
        }
        
        // Contenido principal - Muro de eventos
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            items(events) { event ->
                EventPostCard(
                    event = event,
                    currentUserId = currentUser?.id ?: "",
                    onLikeClick = { viewModel.likeEvent(event.id) },
                    onMessageClick = { 
                        viewModel.sendMessage(event.organizerId, event.id, "Hola! Me interesa participar en tu evento: ${event.title}")
                        onNavigateToMessages(event.organizerId)
                    },
                    onSkipClick = { /* Omitir evento */ }
                )
            }
        }
    }
}

@Composable
fun EventPostCard(
    event: Event,
    currentUserId: String,
    onLikeClick: () -> Unit,
    onMessageClick: () -> Unit,
    onSkipClick: () -> Unit
) {
    val isLiked = event.likes.contains(currentUserId)
    
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp),
        shape = RoundedCornerShape(12.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Header del post
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Avatar del usuario
                Surface(
                    modifier = Modifier
                        .size(40.dp)
                        .clip(RoundedCornerShape(20.dp)),
                    color = MaterialTheme.colorScheme.primaryContainer
                ) {
                    Box(
                        contentAlignment = Alignment.Center
                    ) {
                        Text("👤", fontSize = 20.sp)
                    }
                }
                
                Spacer(modifier = Modifier.width(12.dp))
                
                // Texto del evento
                Text(
                    text = event.title,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Medium,
                    modifier = Modifier.weight(1f)
                )
            }
            
            // Descripción del evento
            Text(
                text = event.description,
                fontSize = 14.sp,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(start = 52.dp)
            )
            
            // Mapa placeholder (simulado)
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(200.dp),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.surfaceVariant
                ),
                shape = RoundedCornerShape(8.dp)
            ) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text("🗺️", fontSize = 48.sp)
                        Text(
                            text = event.location,
                            fontSize = 16.sp,
                            fontWeight = FontWeight.Medium,
                            modifier = Modifier.padding(top = 8.dp)
                        )
                        Text(
                            text = "${event.sport} • ${SimpleDateFormat("dd/MM HH:mm", Locale.getDefault()).format(event.date)}",
                            fontSize = 12.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.padding(top = 4.dp)
                        )
                    }
                }
            }
            
            // Contador de likes
            Text(
                text = "${event.likes.size} Likes",
                fontSize = 14.sp,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(start = 52.dp)
            )
            
            // Botones de acción
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                // Botón Like
                OutlinedButton(
                    onClick = onLikeClick,
                    modifier = Modifier.weight(1f),
                    colors = ButtonDefaults.outlinedButtonColors(
                        contentColor = if (isLiked) Color.Red else MaterialTheme.colorScheme.primary
                    )
                ) {
                    Text("Like")
                }
                
                // Botón Mensaje
                OutlinedButton(
                    onClick = onMessageClick,
                    modifier = Modifier.weight(1f)
                ) {
                    Text("Mensaje")
                }
                
                // Botón Omitir
                OutlinedButton(
                    onClick = onSkipClick,
                    modifier = Modifier.weight(1f)
                ) {
                    Text("Omitir")
                }
            }
        }
    }
}
