package com.example.apao.navigation

import android.app.Application
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import com.example.apao.screens.*
import com.example.apao.viewmodel.EventViewModel

@Composable
fun AppNavigation(navController: NavHostController) {
    val context = LocalContext.current
    val application = context.applicationContext as Application
    val viewModel: EventViewModel = viewModel(
        factory = viewModelFactory {
            initializer {
                EventViewModel(application)
            }
        }
    )
    val isLoggedIn by viewModel.isLoggedIn.collectAsState()
    
    NavHost(
        navController = navController,
        startDestination = if (isLoggedIn) "main" else "login"
    ) {
        composable("login") {
            LoginScreen(
                onLoginSuccess = {
                    navController.navigate("main") {
                        popUpTo("login") { inclusive = true }
                    }
                }
            )
        }
        
        composable("main") {
            MainScreen(
                onNavigateToProfile = {
                    navController.navigate("profile")
                },
                onNavigateToCreateEvent = {
                    navController.navigate("create_event")
                },
                onNavigateToMessages = { receiverId ->
                    navController.navigate("messages/$receiverId")
                }
            )
        }
        
        composable("profile") {
            ProfileScreen(
                onNavigateBack = {
                    navController.popBackStack()
                },
                onLogout = {
                    viewModel.logout()
                    navController.navigate("login") {
                        popUpTo(0) { inclusive = true }
                    }
                }
            )
        }
        
        composable("create_event") {
            CreateEventScreen(
                onNavigateBack = {
                    navController.popBackStack()
                },
                onEventCreated = {
                    navController.popBackStack()
                }
            )
        }
        
        composable("messages/{receiverId}") { backStackEntry ->
            val receiverId = backStackEntry.arguments?.getString("receiverId") ?: ""
            val events by viewModel.events.collectAsState()
            val event = events.firstOrNull { it.organizerId == receiverId }
            
            MessagesScreen(
                receiverId = receiverId,
                eventId = event?.id ?: "",
                onNavigateBack = {
                    navController.popBackStack()
                }
            )
        }
    }
}


