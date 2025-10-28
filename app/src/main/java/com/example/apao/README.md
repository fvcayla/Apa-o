# Apaño - Aplicación de Eventos Deportivos

## Descripción
Apaño es una aplicación Android desarrollada con Jetpack Compose que permite a los usuarios publicar, descubrir y participar en eventos deportivos. La aplicación facilita la conexión entre personas interesadas en actividades deportivas.

## Características Principales

### 🔐 Autenticación
- **Registro de usuarios**: Los usuarios pueden crear una cuenta con email, contraseña y nombre
- **Inicio de sesión**: Sistema de login seguro para usuarios existentes
- **Gestión de sesión**: Mantiene la sesión del usuario durante el uso de la aplicación

### 📱 Pantalla Principal (Muro de Eventos)
- **Visualización de eventos**: Lista de todos los eventos deportivos publicados
- **Información detallada**: Cada evento muestra título, descripción, deporte, ubicación, fecha, hora y participantes
- **Interacción social**: Los usuarios pueden dar like a eventos que les interesen
- **Sistema de comentarios**: Los usuarios pueden comentar en eventos para interactuar

### 💬 Sistema de Mensajería
- **Mensajes directos**: Los usuarios pueden enviar mensajes a los organizadores de eventos
- **Chat en tiempo real**: Interfaz de chat intuitiva con burbujas de mensaje
- **Historial de conversaciones**: Mantiene el historial de mensajes por evento

### 👤 Perfil de Usuario
- **Información personal**: Muestra datos del usuario como nombre, email y estadísticas
- **Estadísticas**: Contador de eventos creados, participaciones y likes recibidos
- **Deportes favoritos**: Lista de deportes de interés del usuario
- **Mis eventos**: Visualización de todos los eventos creados por el usuario

### ➕ Crear Eventos
- **Formulario completo**: Campos para título, descripción, deporte, ubicación, fecha, hora y participantes máximos
- **Selector de deportes**: Dropdown con deportes populares
- **Selector de fecha**: Calendario integrado para seleccionar fechas
- **Validación**: Verificación de campos obligatorios antes de crear el evento

## Arquitectura Técnica

### 🏗️ Patrón de Arquitectura
- **MVVM (Model-View-ViewModel)**: Separación clara de responsabilidades
- **Repository Pattern**: Abstracción de la capa de datos
- **State Management**: Uso de StateFlow para manejo reactivo del estado

### 📦 Componentes Principales

#### Modelos de Datos (`data/`)
- `User.kt`: Modelo de usuario con información personal y preferencias
- `Event.kt`: Modelo de evento deportivo con todos sus atributos
- `Message.kt`: Modelo de mensaje y chat para el sistema de mensajería

#### Repositorio (`repository/`)
- `EventRepository.kt`: Maneja todas las operaciones de datos (CRUD de eventos, usuarios, mensajes)

#### ViewModels (`viewmodel/`)
- `EventViewModel.kt`: Lógica de negocio y estado de la aplicación

#### Pantallas (`screens/`)
- `LoginScreen.kt`: Pantalla de registro e inicio de sesión
- `MainScreen.kt`: Muro principal con lista de eventos
- `ProfileScreen.kt`: Perfil del usuario
- `CreateEventScreen.kt`: Formulario para crear eventos
- `MessagesScreen.kt`: Chat de mensajes

#### Navegación (`navigation/`)
- `AppNavigation.kt`: Configuración de navegación entre pantallas

### 🎨 UI/UX
- **Material Design 3**: Uso de componentes modernos de Material Design
- **Jetpack Compose**: Interfaz completamente declarativa
- **Tema personalizado**: Colores y tipografías consistentes
- **Responsive Design**: Adaptable a diferentes tamaños de pantalla

## Funcionalidades Implementadas

✅ **Registro y Login de usuarios**
✅ **Muro de eventos con información completa**
✅ **Sistema de likes en eventos**
✅ **Comentarios en eventos**
✅ **Mensajería directa entre usuarios**
✅ **Perfil de usuario con estadísticas**
✅ **Creación de eventos deportivos**
✅ **Navegación fluida entre pantallas**
✅ **Validación de formularios**
✅ **Manejo de estado reactivo**

## Tecnologías Utilizadas

- **Kotlin**: Lenguaje de programación principal
- **Jetpack Compose**: Framework de UI moderno
- **Navigation Compose**: Navegación entre pantallas
- **ViewModel**: Gestión del estado de la UI
- **StateFlow**: Flujo de datos reactivo
- **Material Design 3**: Sistema de diseño
- **Android Architecture Components**: Componentes de arquitectura

## Estructura del Proyecto

```
app/src/main/java/com/example/apao/
├── data/
│   ├── User.kt
│   ├── Event.kt
│   └── Message.kt
├── repository/
│   └── EventRepository.kt
├── viewmodel/
│   └── EventViewModel.kt
├── screens/
│   ├── LoginScreen.kt
│   ├── MainScreen.kt
│   ├── ProfileScreen.kt
│   ├── CreateEventScreen.kt
│   └── MessagesScreen.kt
├── navigation/
│   └── AppNavigation.kt
├── ui/theme/
│   ├── Color.kt
│   ├── Theme.kt
│   └── Type.kt
└── MainActivity.kt
```

## Instalación y Uso

1. **Clonar el repositorio**
2. **Abrir en Android Studio**
3. **Sincronizar dependencias**
4. **Ejecutar en dispositivo o emulador**

### Requisitos
- Android Studio Arctic Fox o superior
- SDK mínimo: API 29 (Android 10)
- SDK objetivo: API 36

## Próximas Mejoras

- 🔄 **Persistencia de datos**: Integración con base de datos local (Room) o remota (Firebase)
- 📸 **Imágenes**: Subida y visualización de imágenes en eventos
- 🔔 **Notificaciones**: Push notifications para nuevos eventos y mensajes
- 🗺️ **Mapas**: Integración con Google Maps para ubicaciones
- 👥 **Participación**: Sistema para unirse a eventos
- ⭐ **Calificaciones**: Sistema de calificación de eventos y usuarios
- 🔍 **Búsqueda**: Filtros y búsqueda avanzada de eventos
- 🌐 **Sincronización**: Sincronización en tiempo real con servidor

## Contribución

Esta aplicación está diseñada como una base sólida para una aplicación de eventos deportivos. Las mejoras y nuevas funcionalidades son bienvenidas.

---

**Desarrollado con ❤️ usando Jetpack Compose**
