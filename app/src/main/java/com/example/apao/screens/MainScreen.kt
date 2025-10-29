package com.example.apao.screens

import androidx.compose.animation.*
import androidx.compose.animation.core.*
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
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
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
    viewModel: EventViewModel,
    onNavigateToProfile: () -> Unit,
    onNavigateToCreateEvent: () -> Unit,
    onNavigateToMessages: (String) -> Unit
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
                        AnimatedIconButton(
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
                        AnimatedIconButton(
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
            items(
                items = events,
                key = { it.id }
            ) { event ->
                AnimatedEventCard(
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

// Animación de entrada para las cards de eventos
@Composable
fun AnimatedEventCard(
    event: Event,
    currentUserId: String,
    onLikeClick: () -> Unit,
    onMessageClick: () -> Unit,
    onSkipClick: () -> Unit
) {
    var visible by remember { mutableStateOf(false) }
    
    LaunchedEffect(Unit) {
        visible = true
    }
    
    AnimatedVisibility(
        visible = visible,
        enter = fadeIn(animationSpec = tween(300)) + 
                slideInVertically(
                    initialOffsetY = { it / 2 },
                    animationSpec = tween(300, easing = FastOutSlowInEasing)
                ),
        exit = fadeOut(animationSpec = tween(200)) + 
               slideOutVertically(animationSpec = tween(200))
    ) {
        EventPostCard(
            event = event,
            currentUserId = currentUserId,
            onLikeClick = onLikeClick,
            onMessageClick = onMessageClick,
            onSkipClick = onSkipClick
        )
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
    
    // Animación del contador de likes
    val likeCount by animateIntAsState(
        targetValue = event.likes.size,
        animationSpec = tween(300, easing = FastOutSlowInEasing),
        label = "likeCount"
    )
    
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
            
            // Contador de likes animado
            Text(
                text = "$likeCount Likes",
                fontSize = 14.sp,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(start = 52.dp)
            )
            
            // Botones de acción
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                // Botón Like animado
                AnimatedLikeButton(
                    isLiked = isLiked,
                    onClick = onLikeClick,
                    modifier = Modifier.weight(1f)
                )
                
                // Botón Mensaje animado
                AnimatedActionButton(
                    text = "Mensaje",
                    onClick = onMessageClick,
                    modifier = Modifier.weight(1f)
                )
                
                // Botón Omitir animado
                AnimatedActionButton(
                    text = "Omitir",
                    onClick = onSkipClick,
                    modifier = Modifier.weight(1f)
                )
            }
        }
    }
}

// Botón de Like con animación
@Composable
fun AnimatedLikeButton(
    isLiked: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    var isPressed by remember { mutableStateOf(false) }
    
    val scale by animateFloatAsState(
        targetValue = if (isPressed) 0.9f else 1f,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = Spring.StiffnessHigh
        ),
        label = "buttonScale"
    )
    
    val color by animateColorAsState(
        targetValue = if (isLiked) Color.Red else MaterialTheme.colorScheme.primary,
        animationSpec = tween(300),
        label = "buttonColor"
    )
    
    OutlinedButton(
        onClick = {
            onClick()
        },
        modifier = modifier.scale(scale),
        colors = ButtonDefaults.outlinedButtonColors(
            contentColor = color
        )
    ) {
        Text("Like")
    }
}

// Botón de acción genérico con animación
@Composable
fun AnimatedActionButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    var isPressed by remember { mutableStateOf(false) }
    
    val scale by animateFloatAsState(
        targetValue = if (isPressed) 0.95f else 1f,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = Spring.StiffnessHigh
        ),
        label = "buttonScale"
    )
    
    OutlinedButton(
        onClick = {
            onClick()
        },
        modifier = modifier.scale(scale)
    ) {
        Text(text)
    }
}

// IconButton animado
@Composable
fun AnimatedIconButton(
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit
) {
    var isPressed by remember { mutableStateOf(false) }
    
    val scale by animateFloatAsState(
        targetValue = if (isPressed) 0.8f else 1f,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = Spring.StiffnessHigh
        ),
        label = "iconButtonScale"
    )
    
    IconButton(
        onClick = {
            onClick()
        },
        modifier = modifier.scale(scale)
    ) {
        content()
    }
}
