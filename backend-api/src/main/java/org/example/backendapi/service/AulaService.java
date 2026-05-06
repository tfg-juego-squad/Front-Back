package org.example.backendapi.service;

import lombok.RequiredArgsConstructor;
import org.example.backendapi.dto.AulaRequestDTO;
import org.example.backendapi.dto.AulaResponseDTO;
import org.example.backendapi.dto.CredencialesResponseDTO;
import org.example.backendapi.dto.UsuarioResponseDTO;
import org.example.backendapi.exception.BadRequestException;
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
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AulaService {

    private final IAulaDAO aulaDAO;
    private final IUsuarioDAO usuarioDAO;
    private final SecurityService securityService;
    private final AulaMapper aulaMapper;
    private final UsuarioMapper usuarioMapper;

    public List<AulaResponseDTO> obtenerAulasPorProfesor(Integer profesorId) {
        List<Aula> aulas = aulaDAO.findAulasByProfesorId(profesorId);
        return aulaMapper.toResponseDTOList(aulas);
    }

    public List<UsuarioResponseDTO> obtenerAlumnosPorAula(Integer aulaId) {
        Aula aula = aulaDAO.findById(aulaId)
                .orElseThrow(() -> new ResourceNotFoundException("Aula no encontrada"));

        List<Usuario> alumnos = aula.getAlumnos().stream()
                .filter(usuario -> usuario.getRol() == TipoRol.ROL_ESTUDIANTE)
                .collect(Collectors.toList());

        return usuarioMapper.toResponseDTOList(alumnos);
    }

    @Transactional
    public AulaResponseDTO crearAula(AulaRequestDTO request) {
        Usuario profesor = usuarioDAO.findById(request.getProfesorId())
                .orElseThrow(() -> new ResourceNotFoundException("Profesor no encontrado"));

        Aula aula = new Aula();
        aula.setNombre(request.getNombre());
        aula.setProfesor(profesor);
        aula.setCodigoInvitacion(UUID.randomUUID().toString().substring(0, 5).toUpperCase());

        Aula guardada = aulaDAO.save(aula);
        return aulaMapper.toResponseDTO(guardada);
    }

    @Transactional
    public List<CredencialesResponseDTO> generarAlumnosParaAula(Integer aulaId, Integer cantidad) {
        Aula aula = aulaDAO.findById(aulaId)
                .orElseThrow(() -> new ResourceNotFoundException("Aula no encontrada"));

        List<CredencialesResponseDTO> credencialesGeneradas = new ArrayList<>();

        for (int i = 1; i <= cantidad; i++) {
            String nombreUsuario = generarNombreUsuario(aula.getNombre(), i);
            String passwordPlana = securityService.generarPasswordAleatoria(6);

            crearYGuardarAlumno(nombreUsuario, passwordPlana, aula);
            credencialesGeneradas.add(new CredencialesResponseDTO(null, nombreUsuario, passwordPlana));
        }

        return credencialesGeneradas;
    }

    @Transactional
    public List<CredencialesResponseDTO> importarAlumnosCSV(Integer aulaId, MultipartFile file) {
        Aula aula = aulaDAO.findById(aulaId)
                .orElseThrow(() -> new ResourceNotFoundException("Aula no encontrada"));

        List<CredencialesResponseDTO> credencialesGeneradas = new ArrayList<>();

        try (BufferedReader br = new BufferedReader(new InputStreamReader(file.getInputStream(), StandardCharsets.UTF_8))) {
            String linea;
            boolean primeraLinea = true;

            while ((linea = br.readLine()) != null) {
                boolean esCabecera = primeraLinea && linea.toLowerCase().contains("nombre");

                primeraLinea = false;

                if (!esCabecera) {
                    String[] datos = linea.split(",");

                    if (datos.length >= 2) {
                        String nombre = datos[0].trim();
                        String apellidos = datos[1].trim();

                        String nombreUsuario = generarNombreUsuarioCSV(nombre, apellidos);
                        String passwordPlana = securityService.generarPasswordAleatoria(6);

                        crearYGuardarAlumno(nombreUsuario, passwordPlana, aula);
                        credencialesGeneradas.add(new CredencialesResponseDTO(nombre + " " + apellidos, nombreUsuario, passwordPlana));
                    }
                }
            }
        } catch (Exception e) {
            throw new BadRequestException("Error procesando el archivo CSV: " + e.getMessage());
        }

        return credencialesGeneradas;
    }

    private void crearYGuardarAlumno(String nombreUsuario, String passwordPlana, Aula aula) {
        Usuario alumno = new Usuario();
        alumno.setNombreUsuario(nombreUsuario);
        alumno.setHashContrasena(securityService.hashPassword(passwordPlana));
        alumno.setFechaCreacion(Instant.now());
        alumno.setAula(aula);
        alumno.setRol(TipoRol.ROL_ESTUDIANTE);
        usuarioDAO.save(alumno);
    }

    private String generarNombreUsuario(String nombreAula, int numero) {
        String base = nombreAula.replaceAll("\\s+", "").toLowerCase();
        String sufijoUnico = UUID.randomUUID().toString().substring(0, 5);
        return base + "_alumno" + numero + "_" + sufijoUnico;
    }

    private String generarNombreUsuarioCSV(String nombre, String apellidos) {
        String base = (nombre + apellidos).replaceAll("[^a-zA-Z0-9]", "").toLowerCase();
        if (base.length() > 10) base = base.substring(0, 10);
        String sufijoUnico = UUID.randomUUID().toString().substring(0, 4);
        return base + "_" + sufijoUnico;
    }
}