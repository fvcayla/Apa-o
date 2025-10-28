# Apaño - Sistema de Eventos Deportivos

## 📱 Descripción
Aplicación Android para la gestión de eventos deportivos que permite a los usuarios crear, descubrir y participar en eventos deportivos.

## 🗄️ Base de Datos

### Archivo: `apao_schema.sql`
Script SQL completo para SQL Developer con:
- **6 tablas principales** basadas en las pantallas reales
- **Procedimientos almacenados** para operaciones comunes
- **Vistas** para consultas complejas
- **Datos de prueba** listos para usar
- **Índices** para optimización

**Para usar:**
1. Abre SQL Developer
2. Ejecuta el archivo `apao_schema.sql`
3. Usuario: `apao_user` / Contraseña: `apao123`

### 📊 Tablas de la Base de Datos

| Tabla | Descripción | Relación con Pantallas |
|-------|-------------|----------------------|
| `usuarios` | Usuarios del sistema | LoginScreen, ProfileScreen |
| `deportes_favoritos` | Deportes favoritos del usuario | ProfileScreen |
| `eventos` | Eventos deportivos | MainScreen, CreateEventScreen |
| `likes` | Sistema de likes en eventos | MainScreen |
| `comentarios` | Comentarios en eventos | MainScreen |
| `mensajes` | Mensajería entre usuarios | MessagesScreen, MainScreen |

## 🎯 Funcionalidades Implementadas

- ✅ **Autenticación**: Login/Registro de usuarios
- ✅ **Muro de eventos**: Visualización con diseño tipo swipe cards
- ✅ **Crear eventos**: Formulario completo con validación
- ✅ **Sistema de likes**: Contador dinámico que se actualiza
- ✅ **Comentarios**: Comentarios en eventos
- ✅ **Mensajería**: Chat entre usuarios
- ✅ **Perfil de usuario**: Estadísticas y eventos creados
- ✅ **Navegación**: Flujo completo entre pantallas

## 🚀 Instalación

### Requisitos
- Android Studio Arctic Fox o superior
- SDK mínimo: API 29 (Android 10)
- SDK objetivo: API 36

### Pasos
1. Abrir en Android Studio
2. Sincronizar dependencias
3. Ejecutar en dispositivo o emulador

## 📊 Tecnologías Utilizadas

- **Kotlin**: Lenguaje principal
- **Jetpack Compose**: UI moderna
- **Material Design 3**: Sistema de diseño
- **Navigation Compose**: Navegación
- **ViewModel**: Estado de la UI
- **StateFlow**: Flujo de datos reactivo
- **Oracle Database**: Base de datos relacional

## 📱 Pantallas

1. **LoginScreen**: Registro e inicio de sesión
2. **MainScreen**: Muro con eventos deportivos
3. **CreateEventScreen**: Formulario para crear eventos
4. **ProfileScreen**: Perfil y estadísticas del usuario
5. **MessagesScreen**: Chat de mensajes

---

**Desarrollado con ❤️ usando Jetpack Compose**