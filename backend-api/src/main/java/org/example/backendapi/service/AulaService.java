package org.example.backendapi.service;

import lombok.RequiredArgsConstructor;
import org.example.backendapi.dto.AulaRequestDTO;
import org.example.backendapi.dto.AulaResponseDTO;
import org.example.backendapi.dto.CredencialesResponseDTO;
import org.example.backendapi.dto.UsuarioResponseDTO;
import org.example.backendapi.exception.BadRequestException;
import org.example.backendapi.exception.ForbiddenException;
import org.example.backendapi.exception.ResourceNotFoundException;
import org.example.backendapi.mapper.AulaMapper;
import org.example.backendapi.mapper.UsuarioMapper;
import org.example.backendapi.model.dao.IAulaDAO;
import org.example.backendapi.model.dao.IUsuarioDAO;
import org.example.backendapi.model.entities.Aula;
import org.example.backendapi.model.entities.TipoRol;
import org.example.backendapi.model.entities.Usuario;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Servicio encargado de gestionar las Aulas y los Alumnos que pertenecen a ellas.
 * Maneja la creación de aulas, generación masiva de alumnos (manual o por CSV) y listados.
 */
@Service
@RequiredArgsConstructor
public class AulaService {

    private final IAulaDAO aulaDAO;
    private final IUsuarioDAO usuarioDAO;
    private final SecurityService securityService;
    private final AulaMapper aulaMapper;
    private final UsuarioMapper usuarioMapper;

    /**
     * Obtiene la lista de aulas creadas por un profesor específico.
     * Seguridad: Un profesor solo puede ver sus propias aulas.
     */
    public List<AulaResponseDTO> obtenerAulasPorProfesor(Long profesorId, Usuario usuarioLogueado) {
        if (!usuarioLogueado.getId().equals(profesorId)) {
            throw new ForbiddenException("No puedes ver las aulas de otro profesor.");
        }
        List<Aula> aulas = aulaDAO.findAulasByProfesorId(profesorId);
        return aulaMapper.toResponseDTOList(aulas);
    }

    /**
     * Obtiene todos los alumnos matriculados en un aula concreta.
     * Seguridad: El profesor debe ser el dueño del aula.
     */
    public List<UsuarioResponseDTO> obtenerAlumnosPorAula(Long aulaId, Usuario usuarioLogueado) {
        Aula aula = aulaDAO.findById(aulaId)
                .orElseThrow(() -> new ResourceNotFoundException("Aula no encontrada con ID: " + aulaId));

        // Seguridad Profesor: Debe ser el propietario del aula
        if (usuarioLogueado.getRol() == TipoRol.ROL_PROFESOR && !aula.getProfesor().getId().equals(usuarioLogueado.getId())) {
            throw new ForbiddenException("No puedes ver los alumnos de un aula que no es tuya.");
        }
        
        // Seguridad Estudiante: Debe estar matriculado en esa misma aula
        if (usuarioLogueado.getRol() == TipoRol.ROL_ESTUDIANTE) {
            if (usuarioLogueado.getAula() == null || !usuarioLogueado.getAula().getId().equals(aulaId)) {
                throw new ForbiddenException("No puedes ver los alumnos de un aula a la que no perteneces.");
            }
        }

        List<Usuario> alumnos = usuarioDAO.findByAulaIdAndRol(aulaId, TipoRol.ROL_ESTUDIANTE);

        return usuarioMapper.toResponseDTOList(alumnos);
    }

    /**
     * Crea una nueva aula asociada a un profesor y genera un código de invitación aleatorio.
     */
    @Transactional
    public AulaResponseDTO crearAula(AulaRequestDTO request, Usuario usuarioLogueado) {
        // Evitar que un profesor cree un aula a nombre de otro
        if (!request.getProfesorId().equals(usuarioLogueado.getId())) {
            throw new ForbiddenException("No puedes crear un aula a nombre de otro profesor.");
        }

        Usuario profesor = usuarioDAO.findById(request.getProfesorId())
                .orElseThrow(() -> new ResourceNotFoundException("Profesor no encontrado"));

        Aula aula = new Aula();
        aula.setNombre(request.getNombre());
        aula.setProfesor(profesor);
        // Generar un código corto y en mayúsculas (ej: A4F9K)
        aula.setCodigoInvitacion(UUID.randomUUID().toString().substring(0, 5).toUpperCase());

        Aula guardada = aulaDAO.save(aula);
        return aulaMapper.toResponseDTO(guardada);
    }

    /**
     * Genera un número especificado de alumnos genéricos de forma automática para un aula.
     * Útil cuando el profesor no quiere subir un CSV sino simplemente crear N cuentas.
     * @return Lista de credenciales (usuario y contraseña plana) para que el profesor las reparta.
     */
    @Transactional
    public List<CredencialesResponseDTO> generarAlumnosParaAula(Long aulaId, Integer cantidad, Usuario usuarioLogueado) {
        Aula aula = aulaDAO.findById(aulaId)
                .orElseThrow(() -> new ResourceNotFoundException("Aula no encontrada"));

        // Seguridad: Solo el dueño del aula puede generar alumnos en ella
        if (!aula.getProfesor().getId().equals(usuarioLogueado.getId())) {
            throw new ForbiddenException("No puedes generar alumnos en un aula que no te pertenece.");
        }

        List<CredencialesResponseDTO> credencialesGeneradas = new ArrayList<>();

        for (int i = 1; i <= cantidad; i++) {
            String nombreUsuario = generarNombreUsuario(aula.getNombre(), i);
            String passwordPlana = securityService.generarPasswordAleatoria(6);

            String nombreReal = "Estudiante " + i;
            String apellidos = "Del Aula " + aula.getNombre();
            String email = nombreUsuario + "@ieszaidinvergeles.org"; // Email genérico

            crearYGuardarAlumno(nombreUsuario, passwordPlana, aula, nombreReal, apellidos, email);
            
            // Devolvemos la contraseña en plano SOLO ESTA VEZ para que el profesor pueda descargarla y repartirla
            credencialesGeneradas.add(new CredencialesResponseDTO(null, nombreUsuario, passwordPlana));
        }

        return credencialesGeneradas;
    }

    /**
     * Importa alumnos leyendo un archivo CSV. Espera formato: Nombre, Apellidos.
     * Genera usuarios y contraseñas automáticamente para cada fila del CSV.
     */
    @Transactional
    public List<CredencialesResponseDTO> importarAlumnosCSV(Long aulaId, MultipartFile file, Usuario usuarioLogueado) {
        Aula aula = aulaDAO.findById(aulaId)
                .orElseThrow(() -> new ResourceNotFoundException("Aula no encontrada"));

        if (!aula.getProfesor().getId().equals(usuarioLogueado.getId())) {
            throw new ForbiddenException("No puedes importar alumnos en un aula que no te pertenece.");
        }

        List<CredencialesResponseDTO> credencialesGeneradas = new ArrayList<>();

        try (BufferedReader br = new BufferedReader(new InputStreamReader(file.getInputStream(), StandardCharsets.UTF_8))) {
            String linea;
            boolean primeraLinea = true;

            // Leer el archivo CSV línea por línea
            while ((linea = br.readLine()) != null) {
                // Saltarnos la cabecera si existe
                boolean esCabecera = primeraLinea && linea.toLowerCase().contains("nombre");
                primeraLinea = false;

                if (!esCabecera) {
                    String[] datos = linea.split(",");

                    // Asegurarnos de que tenemos al menos nombre y apellidos
                    if (datos.length >= 2) {
                        String nombre = datos[0].trim();
                        String apellidos = datos[1].trim();

                        String nombreUsuario = generarNombreUsuarioCSV(nombre, apellidos);
                        String passwordPlana = securityService.generarPasswordAleatoria(6);
                        String email = nombreUsuario + "@ieszaidinvergeles.org";

                        crearYGuardarAlumno(nombreUsuario, passwordPlana, aula, nombre, apellidos, email);
                        
                        // Guardar la credencial generada
                        credencialesGeneradas.add(new CredencialesResponseDTO(nombre + " " + apellidos, nombreUsuario, passwordPlana));
                    }
                }
            }
        } catch (Exception e) {
            throw new BadRequestException("Error procesando el archivo CSV: " + e.getMessage());
        }

        return credencialesGeneradas;
    }

    /**
     * Método auxiliar privado para instanciar y persistir un alumno.
     */
    private void crearYGuardarAlumno(String nombreUsuario, String passwordPlana, Aula aula, String nombreReal, String apellidos, String email) {
        Usuario alumno = new Usuario();
        alumno.setNombreUsuario(nombreUsuario);
        alumno.setNombreReal(nombreReal);
        alumno.setApellidos(apellidos);
        alumno.setEmail(email);
        alumno.setHashContrasena(securityService.hashPassword(passwordPlana)); // Hash por seguridad
        alumno.setFechaCreacion(Instant.now());
        alumno.setAula(aula);
        alumno.setRol(TipoRol.ROL_ESTUDIANTE);
        usuarioDAO.save(alumno);
    }

    /**
     * Genera un nombre de usuario genérico usando el nombre del aula y un número secuencial.
     */
    private String generarNombreUsuario(String nombreAula, int numero) {
        String base = nombreAula.replaceAll("\\s+", "").toLowerCase();
        String sufijoUnico = UUID.randomUUID().toString().substring(0, 5);
        return base + "_alumno" + numero + "_" + sufijoUnico;
    }

    /**
     * Genera un nombre de usuario basado en el nombre y apellidos reales importados del CSV.
     */
    private String generarNombreUsuarioCSV(String nombre, String apellidos) {
        // Elimina espacios y caracteres especiales
        String base = (nombre + apellidos).replaceAll("[^a-zA-Z0-9]", "").toLowerCase();
        if (base.length() > 10) base = base.substring(0, 10);
        String sufijoUnico = UUID.randomUUID().toString().substring(0, 4);
        return base + "_" + sufijoUnico;
    }
}