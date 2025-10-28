package com.example.apao.screens

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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.apao.viewmodel.EventViewModel
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CreateEventScreen(
    onNavigateBack: () -> Unit,
    onEventCreated: () -> Unit,
    viewModel: EventViewModel = viewModel()
) {
    var title by remember { mutableStateOf("") }
    var description by remember { mutableStateOf("") }
    var sport by remember { mutableStateOf("") }
    var location by remember { mutableStateOf("") }
    var time by remember { mutableStateOf("") }
    var maxParticipants by remember { mutableStateOf("") }
    var selectedDate by remember { mutableStateOf(Date()) }
    var showDatePicker by remember { mutableStateOf(false) }
    var isLoading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf("") }
    
    val sports = listOf("Fútbol", "Baloncesto", "Tenis", "Voleibol", "Béisbol", "Natación", "Ciclismo", "Running", "Otro")
    var expandedSports by remember { mutableStateOf(false) }
    
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
                // leadingIcon = {
                //     Icon(Icons.Default.Create, contentDescription = "Título")
                // }
            )
            
            // Descripción
            OutlinedTextField(
                value = description,
                onValueChange = { description = it },
                label = { Text("Descripción") },
                modifier = Modifier.fillMaxWidth(),
                minLines = 3,
                maxLines = 5,
                // leadingIcon = {
                //     Icon(Icons.Default.Create, contentDescription = "Descripción")
                // }
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
                    trailingIcon = {
                        ExposedDropdownMenuDefaults.TrailingIcon(expanded = expandedSports)
                    },
                    // leadingIcon = {
                    //     Icon(Icons.Default.Star, contentDescription = "Deporte")
                    // },
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
            
            // Ubicación
            OutlinedTextField(
                value = location,
                onValueChange = { location = it },
                label = { Text("Ubicación") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                // leadingIcon = {
                //     Icon(Icons.Default.LocationOn, contentDescription = "Ubicación")
                // }
            )
            
            // Fecha y hora
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                // Fecha
                OutlinedTextField(
                    value = java.text.SimpleDateFormat("dd/MM/yyyy", Locale.getDefault()).format(selectedDate),
                    onValueChange = { },
                    readOnly = true,
                    label = { Text("Fecha") },
                    modifier = Modifier.weight(1f),
                    // leadingIcon = {
                    //     Icon(Icons.Default.DateRange, contentDescription = "Fecha")
                    // },
                    // trailingIcon = {
                    //     IconButton(onClick = { showDatePicker = true }) {
                    //         Icon(Icons.Default.DateRange, contentDescription = "Seleccionar fecha")
                    //     }
                    // }
                )
                
                // Hora
                OutlinedTextField(
                    value = time,
                    onValueChange = { time = it },
                    label = { Text("Hora") },
                    modifier = Modifier.weight(1f),
                    singleLine = true,
                    placeholder = { Text("HH:MM") },
                    // leadingIcon = {
                    //     Icon(Icons.Default.Schedule, contentDescription = "Hora")
                    // },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number)
                )
            }
            
            // Máximo de participantes
            OutlinedTextField(
                value = maxParticipants,
                onValueChange = { maxParticipants = it },
                label = { Text("Máximo de Participantes") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                // leadingIcon = {
                //     Icon(Icons.Default.Group, contentDescription = "Participantes")
                // },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number)
            )
            
            // Mensaje de error
            if (errorMessage.isNotEmpty()) {
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
            
            // Botón crear evento
            Button(
                onClick = {
                    if (validateForm(title, description, sport, location, time, maxParticipants)) {
                        isLoading = true
                        errorMessage = ""
                        
                        try {
                            val maxParticipantsInt = maxParticipants.toInt()
                            viewModel.addEvent(
                                title = title,
                                description = description,
                                sport = sport,
                                location = location,
                                date = selectedDate,
                                time = time,
                                maxParticipants = maxParticipantsInt
                            )
                            onEventCreated()
                        } catch (e: NumberFormatException) {
                            errorMessage = "El número de participantes debe ser válido"
                            isLoading = false
                        }
                    } else {
                        errorMessage = "Por favor completa todos los campos"
                    }
                },
                modifier = Modifier.fillMaxWidth(),
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
    
    // DatePicker
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
        text = content
    )
}

private fun validateForm(
    title: String,
    description: String,
    sport: String,
    location: String,
    time: String,
    maxParticipants: String
): Boolean {
    return title.isNotEmpty() &&
            description.isNotEmpty() &&
            sport.isNotEmpty() &&
            location.isNotEmpty() &&
            time.isNotEmpty() &&
            maxParticipants.isNotEmpty() &&
            maxParticipants.toIntOrNull() != null &&
            maxParticipants.toInt() > 0
}
