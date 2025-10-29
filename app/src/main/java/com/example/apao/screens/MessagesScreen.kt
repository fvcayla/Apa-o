package com.example.apao.screens

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.scale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.apao.viewmodel.EventViewModel
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MessagesScreen(
    receiverId: String,
    eventId: String,
    onNavigateBack: () -> Unit,
    viewModel: EventViewModel = viewModel()
) {
    val messages by viewModel.messages.collectAsState()
    val currentUser by viewModel.currentUser.collectAsState()
    
    // Filtrar mensajes entre el usuario actual y el receptor
    val conversationMessages = messages.filter { 
        (it.senderId == currentUser?.id && it.receiverId == receiverId) ||
        (it.senderId == receiverId && it.receiverId == currentUser?.id)
    }.sortedBy { it.timestamp }
    
    var messageText by remember { mutableStateOf("") }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Mensajes") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Volver")
                    }
                }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Lista de mensajes
            LazyColumn(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth()
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
                reverseLayout = true
            ) {
                items(
                    items = conversationMessages.reversed(),
                    key = { it.id }
                ) { message ->
                    AnimatedMessageBubble(
                        message = message,
                        isFromCurrentUser = message.senderId == currentUser?.id
                    )
                }
                
                if (conversationMessages.isEmpty()) {
                    item {
                        Box(
                            modifier = Modifier.fillMaxWidth(),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = "No hay mensajes aún.\nEnvía el primer mensaje.",
                                fontSize = 14.sp,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                modifier = Modifier.padding(16.dp)
                            )
                        }
                    }
                }
            }
            
            // Campo de entrada y botón de enviar
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                OutlinedTextField(
                    value = messageText,
                    onValueChange = { messageText = it },
                    modifier = Modifier.weight(1f),
                    placeholder = { Text("Escribe un mensaje...") },
                    singleLine = false,
                    maxLines = 4
                )
                
                // Animación del botón de envío
                var isSending by remember { mutableStateOf(false) }
                val buttonScale by animateFloatAsState(
                    targetValue = if (isSending) 0.95f else 1f,
                    animationSpec = spring(
                        dampingRatio = Spring.DampingRatioMediumBouncy,
                        stiffness = Spring.StiffnessHigh
                    ),
                    label = "sendButtonScale"
                )
                
                Button(
                    onClick = {
                        if (messageText.isNotBlank() && currentUser != null) {
                            isSending = true
                            viewModel.sendMessage(
                                receiverId = receiverId,
                                eventId = eventId,
                                text = messageText
                            )
                            messageText = ""
                            isSending = false
                        }
                    },
                    enabled = messageText.isNotBlank(),
                    modifier = Modifier.scale(buttonScale)
                ) {
                    Text("Enviar")
                }
            }
        }
    }
}

// Componente animado para mensajes
@Composable
fun AnimatedMessageBubble(
    message: com.example.apao.data.Message,
    isFromCurrentUser: Boolean
) {
    var visible by remember { mutableStateOf(false) }
    
    LaunchedEffect(Unit) {
        visible = true
    }
    
    AnimatedVisibility(
        visible = visible,
        enter = fadeIn(animationSpec = tween(300)) + 
                slideInHorizontally(
                    initialOffsetX = { if (isFromCurrentUser) it else -it },
                    animationSpec = tween(300, easing = FastOutSlowInEasing)
                ),
        exit = fadeOut(animationSpec = tween(200))
    ) {
        MessageBubble(
            message = message,
            isFromCurrentUser = isFromCurrentUser
        )
    }
}

@Composable
fun MessageBubble(
    message: com.example.apao.data.Message,
    isFromCurrentUser: Boolean
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = if (isFromCurrentUser) Arrangement.End else Arrangement.Start
    ) {
        Card(
            modifier = Modifier.widthIn(max = 280.dp),
            colors = CardDefaults.cardColors(
                containerColor = if (isFromCurrentUser) 
                    MaterialTheme.colorScheme.primaryContainer 
                else 
                    MaterialTheme.colorScheme.surfaceVariant
            ),
            shape = RoundedCornerShape(
                topStart = 12.dp,
                topEnd = 12.dp,
                bottomStart = if (isFromCurrentUser) 12.dp else 4.dp,
                bottomEnd = if (isFromCurrentUser) 4.dp else 12.dp
            )
        ) {
            Column(
                modifier = Modifier.padding(12.dp)
            ) {
                Text(
                    text = message.text,
                    fontSize = 14.sp,
                    color = if (isFromCurrentUser)
                        MaterialTheme.colorScheme.onPrimaryContainer
                    else
                        MaterialTheme.colorScheme.onSurfaceVariant
                )
                Text(
                    text = SimpleDateFormat("HH:mm", Locale.getDefault()).format(message.timestamp),
                    fontSize = 10.sp,
                    color = if (isFromCurrentUser)
                        MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.7f)
                    else
                        MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f),
                    modifier = Modifier.padding(top = 4.dp)
                )
            }
        }
    }
}

