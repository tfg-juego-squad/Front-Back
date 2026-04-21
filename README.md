# 🎮 Pokeducation - Frontend (Godot 4)

Somos David y Alex estudiantes de **2º de DAM** y este es nuestro proyecto de fin de grado (**TFG**). **POKEDUCATION** es una plataforma educativa gamificada que busca motivar a los alumnos mediante mecánicas de RPG y una interfaz moderna estilo Dark Neon.

## Estado Actual del Desarrollo
A día de hoy, el proyecto se encuentra en una fase muy sólida de **UX/UI y sistemas básicos de juego**:

- [x] **Sistema de Login**: Pantalla inicial funcional conectada (placeholder) con lógica de navegación.
- [x] **Panel del Profesor**: Dashboard completo para gestionar alumnos y crear nuevas entregas.
- [x] **Constructor de Actividades**: Interfaz avanzada "Nueva Entrega" con soporte para adjuntos y configuración de exámenes tipo test/desarrollo.
- [x] **HUD del Alumno**: Interfaz de juego con barra de progreso de experiencia (XP) y lista de tareas interactiva (Toggle con `TAB`).
- [x] **Menú de Pausa**: Sistema de pausa funcional (tecla `ESC`) con opciones de reanudar, volver al menú o cerrar.
- [x] **Físicas y Colisiones**: Mapa del Nivel 1 configurado con límites físicos y colisiones para el personaje.
- [x] **Sistema de Notificaciones**: Motor global de avisos "Premium Glassmorphism" para feedback en tiempo real.

## Cómo Ejecutar el Proyecto
Para ver el proyecto en funcionamiento, sigue estos pasos:

1.  **Instalar Godot 4.(VERSIÓN STABLE)**: Asegúrate de tener la versión estable más reciente (la estándar o .NET, aunque usamos GDScript).
2.  **Clonar el repo**:
    ```bash
    git clone https://github.com/tfg-juego-squad/godot-frontend.git
    ```
3.  **Importar**: Abre Godot, pulsa en "Import" y selecciona el archivo `project.godot`.
4.  **Play!**: Pulsa `F5` para iniciar desde la pantalla de Login.

## Estructura de Componentes
El proyecto está organizado siguiendo las mejores prácticas que hemos visto en clase:

- `res://Global/`: Contiene los **Autoloads** (Singletons) como el `Notificador.gd`, disponible desde cualquier script.
- `res://Niveles/`: Escenas del mundo de juego, incluyendo el `HUDAlumno.tscn` y el `MenuPausa.tscn`.
- `res://Pantallas/`: Toda la interfaz de usuario de "menú" (`login.tscn`, `profesor_dashboard.tscn`, `nueva_entrega.tscn`).
- `res://Assets/`: Recursos gráficos, sprites del personaje y texturas de los tilesets.
- `res://Funciones/`: Scripts de utilidad y lógica reusable.

## Decisiones Técnicas Relevantes
Como buenos estudiantes de DAM, hemos intentado que el código sea limpio y escalable:

1.  **Estética Dark Neon**: Hemos optado por una paleta de colores vibrantes (Cian, Magenta, Dorado) con fondos oscuros para reducir la fatiga visual y dar un toque moderno "gaming".
2.  **Uso de Tweens**: En lugar de animaciones pesadas, usamos la clase `Tween` de Godot 4 para que las transiciones de las notificaciones y el HUD sean ultra suaves por código.
3.  **Modularidad**: El HUD y el Menú de Pausa son escenas independientes que se instancian en los niveles. Así, si cambio algo en una, se actualiza en todos los niveles del tirón.
4.  **Escalado UI**: Se han usado contenedores (`VBoxContainer`, `MarginContainer`, etc.) para que la interfaz se adapte correctamente a diferentes resoluciones de pantalla sin romperse.

---
*Proyecto desarrollado para el TFG de DAM - 2026*
