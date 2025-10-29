package com.example.apao.screens

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.apao.viewmodel.EventViewModel
import kotlinx.coroutines.delay

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LoginScreen(
    viewModel: EventViewModel,
    onLoginSuccess: () -> Unit
) {
    var name by remember { mutableStateOf("") }
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var confirmPassword by remember { mutableStateOf("") }
    var isLoginMode by remember { mutableStateOf(false) }
    var isLoading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf("") }
    var showSuccessMessage by remember { mutableStateOf(false) }
    
    val isLoggedIn by viewModel.isLoggedIn.collectAsState()
    val loginError by viewModel.loginError.collectAsState()
    val registrationSuccess by viewModel.registrationSuccess.collectAsState()
    
    LaunchedEffect(isLoggedIn) {
        if (isLoggedIn) {
            onLoginSuccess()
        }
    }
    
    LaunchedEffect(loginError) {
        loginError?.let { error ->
            errorMessage = error
            isLoading = false
        }
    }
    
    LaunchedEffect(registrationSuccess) {
        if (registrationSuccess) {
            isLoading = false
            errorMessage = ""
            showSuccessMessage = true
            delay(5000)
            showSuccessMessage = false
            viewModel.resetRegistrationSuccess()
        }
    }
    
    LaunchedEffect(isLoginMode) {
        errorMessage = ""
        showSuccessMessage = false
    }
    
    LaunchedEffect(isLoading) {
        if (isLoading) {
            delay(10000)
            if (isLoading) {
                isLoading = false
                errorMessage = "La operación está tardando demasiado. Por favor intenta nuevamente."
            }
        }
    }
    
    var logoVisible by remember { mutableStateOf(false) }
    var formVisible by remember { mutableStateOf(false) }
    
    LaunchedEffect(Unit) {
        logoVisible = true
        delay(200)
        formVisible = true
    }
    
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        AnimatedVisibility(
            visible = logoVisible,
            enter = fadeIn(animationSpec = tween(500)) + 
                    scaleIn(
                        initialScale = 0.8f,
                        animationSpec = spring(
                            dampingRatio = Spring.DampingRatioMediumBouncy,
                            stiffness = Spring.StiffnessLow
                        )
                    )
        ) {
            Text(
                text = "Apaño",
                fontSize = 32.sp,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.primary,
                modifier = Modifier.padding(bottom = 32.dp)
            )
        }
        
        AnimatedVisibility(
            visible = formVisible,
            enter = fadeIn(animationSpec = tween(500, delayMillis = 200)) + 
                    slideInVertically(
                        initialOffsetY = { it / 3 },
                        animationSpec = tween(500, delayMillis = 200, easing = FastOutSlowInEasing)
                    )
        ) {
            Card(
                modifier = Modifier.fillMaxWidth(),
                elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
            ) {
                Column(
                    modifier = Modifier.padding(24.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    if (isLoginMode) {
                        Text(
                            text = "Iniciar Sesión",
                            fontSize = 20.sp,
                            fontWeight = FontWeight.Bold,
                            modifier = Modifier.padding(bottom = 8.dp)
                        )
                        
                        OutlinedTextField(
                            value = email,
                            onValueChange = { email = it },
                            label = { Text("Email") },
                            placeholder = { Text("@email.com") },
                            modifier = Modifier.fillMaxWidth(),
                            singleLine = true,
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email)
                        )
                        
                        OutlinedTextField(
                            value = password,
                            onValueChange = { password = it },
                            label = { Text("Contraseña") },
                            modifier = Modifier.fillMaxWidth(),
                            singleLine = true,
                            visualTransformation = PasswordVisualTransformation(),
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password)
                        )
                        
                        Button(
                            onClick = {
                                if (email.isNotEmpty() && password.isNotEmpty()) {
                                    isLoading = true
                                    errorMessage = ""
                                    showSuccessMessage = false
                                    viewModel.loginUser(email, password)
                                } else {
                                    errorMessage = "Por favor completa todos los campos"
                                    showSuccessMessage = false
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
                                Text("Iniciar Sesión")
                            }
                        }
                        
                        TextButton(
                            onClick = { isLoginMode = false },
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Text("¿No tienes cuenta? Regístrate")
                        }
                        
                    } else {
                        Text(
                            text = "Registro",
                            fontSize = 20.sp,
                            fontWeight = FontWeight.Bold,
                            modifier = Modifier.padding(bottom = 8.dp)
                        )
                        
                        OutlinedTextField(
                            value = name,
                            onValueChange = { name = it },
                            label = { Text("Name") },
                            placeholder = { Text("username") },
                            modifier = Modifier.fillMaxWidth(),
                            singleLine = true
                        )
                        
                        OutlinedTextField(
                            value = email,
                            onValueChange = { email = it },
                            label = { Text("Email") },
                            placeholder = { Text("@email.com") },
                            modifier = Modifier.fillMaxWidth(),
                            singleLine = true,
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email)
                        )
                        
                        OutlinedTextField(
                            value = password,
                            onValueChange = { password = it },
                            label = { Text("Password") },
                            modifier = Modifier.fillMaxWidth(),
                            singleLine = true,
                            visualTransformation = PasswordVisualTransformation(),
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password)
                        )
                        
                        OutlinedTextField(
                            value = confirmPassword,
                            onValueChange = { confirmPassword = it },
                            label = { Text("Confirm Password") },
                            modifier = Modifier.fillMaxWidth(),
                            singleLine = true,
                            visualTransformation = PasswordVisualTransformation(),
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password)
                        )
                        
                        Button(
                            onClick = {
                                if (name.isNotEmpty() && email.isNotEmpty() && password.isNotEmpty() && confirmPassword.isNotEmpty()) {
                                    if (password == confirmPassword) {
                                        isLoading = true
                                        errorMessage = ""
                                        showSuccessMessage = false
                                        viewModel.registerUser(email, password, name)
                                    } else {
                                        errorMessage = "Las contraseñas no coinciden"
                                        showSuccessMessage = false
                                    }
                                } else {
                                    errorMessage = "Por favor completa todos los campos"
                                    showSuccessMessage = false
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
                                Text("Sign up")
                            }
                        }
                        
                        TextButton(
                            onClick = { isLoginMode = true },
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Text("already have an account? Login")
                        }
                    }
                    
                    AnimatedVisibility(
                        visible = showSuccessMessage && registrationSuccess,
                        enter = fadeIn(animationSpec = tween(400)) + 
                                slideInVertically(
                                    initialOffsetY = { -it / 2 },
                                    animationSpec = tween(400, easing = FastOutSlowInEasing)
                                ) + 
                                scaleIn(
                                    initialScale = 0.9f,
                                    animationSpec = spring(
                                        dampingRatio = Spring.DampingRatioMediumBouncy,
                                        stiffness = Spring.StiffnessLow
                                    )
                                ),
                        exit = fadeOut(animationSpec = tween(300)) + 
                               slideOutVertically(animationSpec = tween(300))
                    ) {
                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            colors = CardDefaults.cardColors(
                                containerColor = MaterialTheme.colorScheme.primaryContainer
                            )
                        ) {
                            Text(
                                text = "¡Registro exitoso! Ahora puedes iniciar sesión.",
                                color = MaterialTheme.colorScheme.onPrimaryContainer,
                                fontSize = 14.sp,
                                textAlign = TextAlign.Center,
                                modifier = Modifier.padding(16.dp),
                                fontWeight = FontWeight.Medium
                            )
                        }
                    }
                    
                    AnimatedVisibility(
                        visible = errorMessage.isNotEmpty() && !showSuccessMessage,
                        enter = fadeIn(animationSpec = tween(300)) + 
                                slideInVertically(
                                    initialOffsetY = { -it / 2 },
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
                                fontSize = 14.sp,
                                textAlign = TextAlign.Center,
                                modifier = Modifier.padding(16.dp)
                            )
                        }
                    }
                }
            }
        }
    }
}
