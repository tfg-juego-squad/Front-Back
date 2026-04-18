# Pokeducation - Backend API

Bienvenido al repositorio del **Backend** de Pokeducation, el ecosistema educativo gamificado. 

Esta API RESTful está construida con Spring Boot y actúa como el motor central del proyecto. Se encarga de gestionar toda la lógica de negocio, la autenticación de usuarios, el progreso de las misiones (pruebas) y el sistema de recompensas (inventario), conectándose de forma segura a una base de datos MariaDB.

## Tecnologías Utilizadas

* **Framework:** Spring Boot
* **Lenguaje:** Java
* **Base de Datos:** MariaDB
* **Despliegue local:** Docker & Docker Compose
* **ORM:** Spring Data JPA (Hibernate)

## Requisitos Previos

Para poder ejecutar este proyecto en tu máquina local y trabajar en él, necesitas tener instalado:

1.  [Java](https://adoptium.net/).
2.  [Docker Desktop](https://www.docker.com/products/docker-desktop/) (Obligatorio para levantar la base de datos).
3.  Git.

## Guía de Instalación y Arranque

Sigue estos pasos para levantar el entorno de desarrollo local en menos de 5 minutos:

### 1. Clonar el repositorio

Abre tu terminal y descárgate el código fuente:

```bash
git clone https://github.com/tfg-juego-squad/backend-api.git
cd backend-api
```

### 2. Levantar la Base de Datos (Docker)

El proyecto incluye un archivo `docker-compose.yaml` y un script `init.sql` que preparan la base de datos MariaDB automáticamente con las tablas necesarias.

Asegúrate de tener Docker abierto y ejecuta:

```bash
docker-compose up -d
```

*Nota: Esto levantará un contenedor en el puerto 3306. Asegúrate de no tener otro programa (como XAMPP o MySQL local) usando ese mismo puerto para evitar conflictos.*

## Estructura del Proyecto

El código sigue una arquitectura de 3 capas (Controlador - Servicio - Repositorio) para asegurar la escalabilidad:

* `src/main/java/.../control/` : Controladores REST que definen los Endpoints.
* `src/main/java/.../model/entities/` : Modelos de datos mapeados a la base de datos.
* `src/main/java/.../model/dao/` : Repositorios para la persistencia de datos (JPA).
* `docker-compose.yaml` : Configuración de la infraestructura de base de datos.
* `init.sql` : Script automático de creación de esquema relacional.

## Endpoints Principales

Actualmente la API expone los siguientes recursos base (soportando operaciones CRUD completas mediante GET, POST, PUT, DELETE):

* `/tfg/usuarios` : Gestión de registro, perfiles y roles (Profesor/Estudiante).
* `/tfg/pruebas` : Gestión de misiones, tareas y exámenes definidos por el docente.
* `/tfg/inventario` : Gestión de los objetos y recompensas obtenidos por los alumnos.
* `/tfg/puntuaciones` : Gestión de las puntuaciones.
---
*Proyecto desarrollado para el Trabajo de Fin de Grado (TFG) - Ciclo Superior DAM.*
