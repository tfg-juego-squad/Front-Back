# Pokeducation - Frontend (Godot)

Bienvenido al repositorio del **Cliente (Frontend)** de Pokeducation. 

Este proyecto es un videojuego 2D educativo desarrollado en **Godot**. Actúa como la interfaz visual e interactiva del sistema, comunicándose de forma asíncrona mediante peticiones HTTP REST con nuestra API en Spring Boot para gestionar usuarios, misiones y el inventario.

## Tecnologías y Herramientas

* **Motor de Videojuego:** Godot
* **Lenguaje de Scripting:** GDScript

## Requisitos Previos

Para poder abrir, editar y probar este proyecto, necesitas:

1. Descargar [Godot](https://godotengine.org/download/).
2. Tener el [Backend API](https://github.com/tfg-juego-squad/backend-api) encendido localmente si deseas probar el Login/Registro.

## Guía de Instalación y Clonado

### 1. Clonar el repositorio

Abre tu terminal y clona el proyecto en tu máquina:

```bash
git clone https://github.com/tfg-juego-squad/godot-frontend.git
cd godot-frontend
```

### 2. Importar en Godot Engine

1. Abre **Godot**.
2. En el Administrador de Proyectos, haz clic en el botón **"Importar"** (Import).
3. Navega hasta la carpeta `godot-frontend` que acabas de clonar.

## 📁 Estructura del Proyecto

El proyecto sigue una organización por directorios para mantener el orden en el equipo. **Norma del equipo:** Guardar cada nuevo archivo en su carpeta correspondiente:

* `res://assets/` : Recursos multimedia estáticos (imágenes, spritesheets, música, fuentes).
* `res://entities/` : Nodos y scripts de entidades interactivas (Jugador, NPCs, Enemigos).
* `res://scenes/` : Escenas principales que componen el juego (Niveles, Hub central).
* `res://scripts/` : Scripts globales (Autoloads/Singletons) o lógica reutilizable desconectada de una escena específica.
* `res://ui/` : Escenas de Interfaz de Usuario (Menú principal, Login, Registro, HUD, Inventario).

---
*Proyecto desarrollado para el Trabajo de Fin de Grado (TFG) - Ciclo Superior DAM.*
