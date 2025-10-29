package com.example.apao.screens

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.scale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.apao.viewmodel.EventViewModel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import androidx.compose.runtime.rememberCoroutineScope
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CreateEventScreen(
    viewModel: EventViewModel,
    onNavigateBack: () -> Unit,
    onEventCreated: () -> Unit
) {
    var title by remember { mutableStateOf("") }
    var description by remember { mutableStateOf("") }
    var sport by remember { mutableStateOf("") }
    var location by remember { mutableStateOf("") }
    var maxParticipants by remember { mutableStateOf("") }
    
    // Estados para DatePicker y TimePicker
    var selectedDate by remember { mutableStateOf(Date()) }
    var showDatePicker by remember { mutableStateOf(false) }
    var showTimePicker by remember { mutableStateOf(false) }
    
    var isLoading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf("") }
    var isGettingLocation by remember { mutableStateOf(false) }
    val coroutineScope = rememberCoroutineScope()
    
    val sports = listOf("Fútbol", "Baloncesto", "Tenis", "Voleibol", "Béisbol", "Natación", "Ciclismo", "Running", "Otro")
    var expandedSports by remember { mutableStateOf(false) }
    
    // TimePicker State (Material 3)
    val timePickerState = rememberTimePickerState(
        initialHour = Calendar.getInstance().get(Calendar.HOUR_OF_DAY),
        initialMinute = Calendar.getInstance().get(Calendar.MINUTE)
    )
    
    // Función simplificada para obtener ubicación (sin GPS por ahora, solo permite escribir)
    fun requestLocation() {
        // Nota: Para implementar GPS completo, necesitas agregar las dependencias
        // Por ahora, solo mostramos un mensaje informativo
        errorMessage = "Función GPS: Escribe la ubicación manualmente o agrega las dependencias de Google Play Services"
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Crear Evento") },
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
                .padding(16.dp)
                .verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Título del evento
            OutlinedTextField(
                value = title,
                onValueChange = { title = it },
                label = { Text("Título del Evento") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                leadingIcon = {
                    Icon(Icons.Default.Create, contentDescription = "Título")
                }
            )
            
            // Descripción
            OutlinedTextField(
                value = description,
                onValueChange = { description = it },
                label = { Text("Descripción") },
                modifier = Modifier.fillMaxWidth(),
                minLines = 3,
                maxLines = 5,
                leadingIcon = {
                    Icon(Icons.Default.Edit, contentDescription = "Descripción")
                }
            )
            
            // Deporte
            ExposedDropdownMenuBox(
                expanded = expandedSports,
                onExpandedChange = { expandedSports = !expandedSports }
            ) {
                OutlinedTextField(
                    value = sport,
                    onValueChange = { },
                    readOnly = true,
                    label = { Text("Deporte") },
                    leadingIcon = {
                        Icon(Icons.Default.Star, contentDescription = "Deporte")
                    },
                    trailingIcon = {
                        ExposedDropdownMenuDefaults.TrailingIcon(expanded = expandedSports)
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .menuAnchor()
                )
                
                ExposedDropdownMenu(
                    expanded = expandedSports,
                    onDismissRequest = { expandedSports = false }
                ) {
                    sports.forEach { sportOption ->
                        DropdownMenuItem(
                            text = { Text(sportOption) },
                            onClick = {
                                sport = sportOption
                                expandedSports = false
                            }
                        )
                    }
                }
            }
            
            // Ubicación con botón GPS (simplificado)
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                OutlinedTextField(
                    value = location,
                    onValueChange = { location = it },
                    label = { Text("Ubicación") },
                    modifier = Modifier.weight(1f),
                    singleLine = true,
                    leadingIcon = {
                        Icon(Icons.Default.LocationOn, contentDescription = "Ubicación")
                    },
                    placeholder = { Text("Escribe la ubicación") }
                )
                
                IconButton(
                    onClick = { requestLocation() },
                    enabled = !isGettingLocation
                ) {
                    if (isGettingLocation) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(24.dp),
                            strokeWidth = 2.dp
                        )
                    } else {
                        Icon(Icons.Default.LocationOn, contentDescription = "Usar GPS")
                    }
                }
            }
            
            // Fecha y hora con pickers
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                // Fecha con DatePicker
                OutlinedTextField(
                    value = SimpleDateFormat("dd/MM/yyyy", Locale.getDefault()).format(selectedDate),
                    onValueChange = { },
                    readOnly = true,
                    label = { Text("Fecha") },
                    modifier = Modifier.weight(1f),
                    leadingIcon = {
                        Icon(Icons.Default.DateRange, contentDescription = "Fecha")
                    },
                    trailingIcon = {
                        IconButton(onClick = { showDatePicker = true }) {
                            Icon(Icons.Default.DateRange, contentDescription = "Seleccionar fecha")
                        }
                    }
                )
                
                // Hora con TimePicker
                OutlinedTextField(
                    value = String.format("%02d:%02d", timePickerState.hour, timePickerState.minute),
                    onValueChange = { },
                    readOnly = true,
                    label = { Text("Hora") },
                    modifier = Modifier.weight(1f),
                    leadingIcon = {
                        Icon(Icons.Default.DateRange, contentDescription = "Hora")
                    },
                    trailingIcon = {
                        IconButton(onClick = { showTimePicker = true }) {
                            Icon(Icons.Default.DateRange, contentDescription = "Seleccionar hora")
                        }
                    }
                )
            }
            
            // Máximo de participantes
            OutlinedTextField(
                value = maxParticipants,
                onValueChange = { maxParticipants = it },
                label = { Text("Máximo de Participantes") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                leadingIcon = {
                    Icon(Icons.Default.Person, contentDescription = "Participantes")
                },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number)
            )
            
            // Mensaje de error animado
            AnimatedVisibility(
                visible = errorMessage.isNotEmpty(),
                enter = fadeIn(animationSpec = tween(300)) + 
                        slideInVertically(
                            initialOffsetY = { fullHeight -> -fullHeight / 2 },
                            animationSpec = tween(300)
                        ),
                exit = fadeOut(animationSpec = tween(200)) + 
                       slideOutVertically(animationSpec = tween(200))
            ) {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.errorContainer
                    )
                ) {
                    Text(
                        text = errorMessage,
                        color = MaterialTheme.colorScheme.onErrorContainer,
                        modifier = Modifier.padding(16.dp)
                    )
                }
            }
            
            // Botón crear evento animado
            val buttonScale by animateFloatAsState(
                targetValue = if (isLoading) 0.95f else 1f,
                animationSpec = spring(
                    dampingRatio = Spring.DampingRatioMediumBouncy,
                    stiffness = Spring.StiffnessHigh
                ),
                label = "buttonScale"
            )
            
            Button(
                onClick = {
                    if (validateForm(title, description, sport, location, maxParticipants)) {
                        isLoading = true
                        errorMessage = ""
                        
                        try {
                            val maxParticipantsInt = maxParticipants.toInt()
                            // Combinar fecha y hora seleccionadas
                            val combinedDateTime = Calendar.getInstance().apply {
                                time = selectedDate
                                set(Calendar.HOUR_OF_DAY, timePickerState.hour)
                                set(Calendar.MINUTE, timePickerState.minute)
                                set(Calendar.SECOND, 0)
                                set(Calendar.MILLISECOND, 0)
                            }.time
                            
                            val timeString = String.format("%02d:%02d", timePickerState.hour, timePickerState.minute)
                            
                            coroutineScope.launch {
                                viewModel.addEvent(
                                    title = title,
                                    description = description,
                                    sport = sport,
                                    location = location,
                                    date = combinedDateTime,
                                    time = timeString,
                                    maxParticipants = maxParticipantsInt
                                )
                                // Pequeño delay para asegurar que el evento se propague antes de navegar
                                delay(100)
                                isLoading = false
                                onEventCreated()
                            }
                        } catch (e: NumberFormatException) {
                            errorMessage = "El número de participantes debe ser válido"
                            isLoading = false
                        } catch (e: Exception) {
                            errorMessage = "Error al crear evento: ${e.message}"
                            isLoading = false
                        }
                    } else {
                        errorMessage = "Por favor completa todos los campos"
                    }
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .scale(buttonScale),
                enabled = !isLoading
            ) {
                if (isLoading) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(20.dp),
                        color = MaterialTheme.colorScheme.onPrimary
                    )
                } else {
                    Icon(Icons.Default.Add, contentDescription = "Crear")
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Crear Evento")
                }
            }
        }
    }
    
    // DatePicker Dialog
    if (showDatePicker) {
        val datePickerState = rememberDatePickerState(
            initialSelectedDateMillis = selectedDate.time
        )
        
        DatePickerDialog(
            onDismissRequest = { showDatePicker = false },
            confirmButton = {
                TextButton(
                    onClick = {
                        datePickerState.selectedDateMillis?.let { millis ->
                            selectedDate = Date(millis)
                        }
                        showDatePicker = false
                    }
                ) {
                    Text("Confirmar")
                }
            },
            dismissButton = {
                TextButton(onClick = { showDatePicker = false }) {
                    Text("Cancelar")
                }
            }
        ) {
            DatePicker(state = datePickerState)
        }
    }
    
    // TimePicker Dialog
    if (showTimePicker) {
        TimePickerDialog(
            onDismissRequest = { showTimePicker = false },
            onConfirm = {
                showTimePicker = false
            }
        ) {
            TimePicker(state = timePickerState)
        }
    }
}

@Composable
fun DatePickerDialog(
    onDismissRequest: () -> Unit,
    confirmButton: @Composable () -> Unit,
    dismissButton: @Composable () -> Unit,
    content: @Composable () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismissRequest,
        confirmButton = confirmButton,
        dismissButton = dismissButton,
        text = content,
        shape = RoundedCornerShape(28.dp)
    )
}

@Composable
fun TimePickerDialog(
    onDismissRequest: () -> Unit,
    onConfirm: () -> Unit,
    content: @Composable () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismissRequest,
        confirmButton = {
            TextButton(onClick = onConfirm) {
                Text("Confirmar")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismissRequest) {
                Text("Cancelar")
            }
        },
        text = content,
        shape = RoundedCornerShape(28.dp)
    )
}

private fun validateForm(
    title: String,
    description: String,
    sport: String,
    location: String,
    maxParticipants: String
): Boolean {
    return title.isNotEmpty() &&
            description.isNotEmpty() &&
            sport.isNotEmpty() &&
            location.isNotEmpty() &&
            maxParticipants.isNotEmpty() &&
            maxParticipants.toIntOrNull() != null &&
            maxParticipants.toInt() > 0
}
