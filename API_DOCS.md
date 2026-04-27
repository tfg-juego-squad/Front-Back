# Documentación de la API REST - Pokeducation (Core MVP)

**URL Base:** `http://localhost:8081/tfg`
**Formato de datos:** JSON (`application/json`)

---

## 1. Usuarios (Autenticación y Registro)

### 1.1 Registrar un Profesor
Da de alta a un nuevo profesor en el sistema. La contraseña se encriptará automáticamente en el backend.
* **Método:** `POST`
* **Ruta:** `/usuarios/profesor/alta`
* **Body:**
  ```json
    {
      "nombreUsuario": "profesor_oak",
      "hashContrasena": "password123"
    }
  ```

### 1.2 Iniciar Sesión (Login)
Valida las credenciales y devuelve los datos del usuario (incluyendo su ID y su Rol).
* **Método:** `POST`
* **Ruta:** `/usuarios/login`
* **Body:**
  ```json
    {
      "usuario": "profesor_oak",
      "password": "password123"
    }
  ```

---

## 2. Aulas y Alumnos

### 2.1 Crear un Aula
Crea una nueva clase asignada a un profesor.
* **Método:** `POST`
* **Ruta:** `/aulas/crear`
* **Body:**
  ```json
    {
      "nombreAula": "1A - Programación",
      "profesorId": "ID_DEL_PROFESOR"
    }
  ```

### 2.2 Listar Aulas de un Profesor
Devuelve la lista de clases que imparte un profesor (ideal para el `OptionButton` del Dashboard).
* **Método:** `GET`
* **Ruta:** `/aulas/profesor/{profesorId}`
* **Body:** Ninguno.

### 2.3 Generación Masiva de Alumnos
Autogenera un número específico de cuentas de estudiante para un aula y devuelve las credenciales en texto plano para el profesor.
* **Método:** `POST`
* **Ruta:** `/aulas/{aulaId}/generar-alumnos`
* **Body:**
  ```json
    {
      "cantidad": 5
    }
  ```

### 2.4 Listar Alumnos de un Aula
Devuelve todos los usuarios con rol `ROL_ESTUDIANTE` que pertenecen a una clase.
* **Método:** `GET`
* **Ruta:** `/aulas/{aulaId}/alumnos`
* **Body:** Ninguno.

---

## 3. Gestión de Pruebas (Tareas/Misiones)

### 3.1 Crear una Prueba (Profesor)
Crea una nueva tarea para una clase. El `contenido` puede ser texto plano o un JSON estructurado desde Godot.
* **Método:** `POST`
* **Ruta:** `/pruebas/crear`
* **Body:**
  ```json
    {
      "aulaId": "ID_DEL_AULA",
      "titulo": "Examen Final - Tema 1",
      "tipo": "TIPO_TEST",
      "contenido": "{\"preguntas\": [\"¿Qué es Godot?\"], \"opciones\": [\"Un motor\", \"Un coche\"]}",
      "puntuacionMaxima": 10
    }
  ```
*(Nota: Tipos permitidos -> `TIPO_TEST` o `DESARROLLO`)*

### 3.2 Listar Pruebas de un Aula
Devuelve todas las misiones/tareas disponibles para una clase concreta.
* **Método:** `GET`
* **Ruta:** `/pruebas/aula/{aulaId}`
* **Body:** Ninguno.

### 3.3 Actualizar una Prueba
Permite editar el título, contenido o nota máxima de una prueba.
* **Método:** `PUT`
* **Ruta:** `/pruebas/{pruebaId}`
* **Body:**
  ```json
    {
      "titulo": "Examen Final (Corregido)",
      "contenido": "Nuevo contenido...",
      "puntuacionMaxima": 10
    }
  ```

### 3.4 Eliminar una Prueba
Borra la prueba del sistema.
* **Método:** `DELETE`
* **Ruta:** `/pruebas/{pruebaId}`
* **Body:** Ninguno.

---

## 4. Puntuaciones (Calificaciones)

### 4.1 Guardar Nota (Alta)
Registra la calificación obtenida por un alumno al terminar un minijuego/prueba.
* **Método:** `POST`
* **Ruta:** `/puntuaciones/alta`
* **Body:**
  ```json
    {
      "puntosObtenidos": 8,
      "alumno": {
        "id": "ID_DEL_ALUMNO"
      },
        "prueba": {
        "id": "ID_DE_LA_PRUEBA"
      }
    }
  ```

### 4.2 Ver Notas por Prueba
Devuelve el listado de calificaciones de todos los alumnos que han realizado una prueba específica (ideal para la vista del profesor).
* **Método:** `GET`
* **Ruta:** `/puntuaciones/prueba/{pruebaId}`
* **Body:** Ninguno.