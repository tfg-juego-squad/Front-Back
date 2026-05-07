package org.example.backendapi.service;

import lombok.RequiredArgsConstructor;
import org.example.backendapi.dto.UsuarioLoginRequestDTO;
import org.example.backendapi.dto.UsuarioRegistroRequestDTO;
import org.example.backendapi.dto.UsuarioResponseDTO;
import org.example.backendapi.exception.BadRequestException;
import org.example.backendapi.mapper.UsuarioMapper;
import org.example.backendapi.model.dao.IUsuarioDAO;
import org.example.backendapi.model.entities.TipoRol;
import org.example.backendapi.model.entities.Usuario;
import org.example.backendapi.exception.ForbiddenException;
import org.springframework.stereotype.Service;
import org.example.backendapi.exception.ResourceNotFoundException;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.*;

/**
 * Servicio encargado de gestionar la lógica de negocio relacionada con los Usuarios (Profesores y Alumnos).
 * Maneja el registro, la autenticación (login) y las consultas de perfiles, asegurando que
 * las reglas de seguridad (IDOR) se cumplan.
 */
@Service
@RequiredArgsConstructor
public class UsuarioService {

    private final IUsuarioDAO usuarioDAO;
    private final SecurityService securityService;
    private final JwtService jwtService;
    private final UsuarioMapper usuarioMapper;

    /**
     * Registra un nuevo profesor en el sistema.
     * @param request Datos de registro del profesor.
     * @return DTO con la información del profesor creado.
     * @throws BadRequestException Si el nombre de usuario ya está en uso.
     */
    @Transactional
    public UsuarioResponseDTO registrarProfesor(UsuarioRegistroRequestDTO request) {
        // 1. Verificamos que el nombre de usuario esté libre
        if (!usuarioDAO.findUsuarioByNombreUsuario(request.getNombreUsuario()).isEmpty()) {
            throw new BadRequestException("El nombre de usuario ya está en uso");
        }

        Usuario profesor = new Usuario();
        profesor.setNombreUsuario(request.getNombreUsuario());
        profesor.setNombreReal(request.getNombreReal());
        profesor.setApellidos(request.getApellidos());
        profesor.setEmail(request.getEmail());

        // 2. Encriptamos la contraseña por seguridad antes de guardarla en BD
        profesor.setHashContrasena(securityService.hashPassword(request.getPasswordPlana()));
        profesor.setFechaCreacion(Instant.now());
        profesor.setRol(TipoRol.ROL_PROFESOR);

        Usuario guardado = usuarioDAO.save(profesor);

        return usuarioMapper.toResponseDTO(guardado);
    }

    /**
     * Valida las credenciales de un usuario e inicia sesión.
     * @param request Credenciales (usuario y contraseña).
     * @return DTO del usuario incluyendo el Token JWT generado para futuras peticiones.
     */
    public UsuarioResponseDTO hacerLogin(UsuarioLoginRequestDTO request) {
        // 1. Buscar usuario por nombre
        List<Usuario> usuarios = usuarioDAO.findUsuarioByNombreUsuario(request.getNombreUsuario());
        if (usuarios.isEmpty()) {
            throw new ResourceNotFoundException("Usuario no encontrado");
        }
        Usuario usuario = usuarios.get(0);

        // 2. Comprobar que la contraseña plana coincida con el hash almacenado
        if (!securityService.checkPassword(request.getPasswordPlana(), usuario.getHashContrasena())) {
            throw new BadRequestException("Contraseña incorrecta");
        }

        // 3. Generar el Token JWT que el cliente usará para autenticarse
        String token = jwtService.generateToken(usuario);
        UsuarioResponseDTO responseDTO = usuarioMapper.toResponseDTO(usuario);
        responseDTO.setToken(token);

        return responseDTO;
    }

    /**
     * Busca un usuario por su ID, aplicando filtros de seguridad para evitar IDOR.
     * Un estudiante solo puede verse a sí mismo. Un profesor puede verse a sí mismo y a sus alumnos.
     */
    public UsuarioResponseDTO buscarUsuarioPorId(Long id, Usuario usuarioLogueado) {
        Usuario usuarioEncontrado = usuarioDAO.findUsuarioById(id)
                .orElseThrow(() -> new ResourceNotFoundException("No se encontró ningún usuario con el ID: " + id));

        // Seguridad: Prevención de IDOR (Insecure Direct Object Reference)
        if (usuarioLogueado.getRol() == TipoRol.ROL_ESTUDIANTE) {
            // Un estudiante NO puede ver los perfiles de otros estudiantes o profesores
            if (!usuarioLogueado.getId().equals(usuarioEncontrado.getId())) {
                throw new ForbiddenException("No tienes permiso para ver el perfil de otro alumno.");
            }
        } else if (usuarioLogueado.getRol() == TipoRol.ROL_PROFESOR) {
            // Un profesor NO puede ver a alumnos que no sean suyos, ni a otros profesores
            if (!usuarioLogueado.getId().equals(usuarioEncontrado.getId())) {
                if (usuarioEncontrado.getRol() == TipoRol.ROL_ESTUDIANTE) {
                    if (usuarioEncontrado.getAula() == null || !usuarioEncontrado.getAula().getProfesor().getId().equals(usuarioLogueado.getId())) {
                        throw new ForbiddenException("No puedes ver a un alumno que no pertenece a ninguna de tus aulas.");
                    }
                } else {
                    throw new ForbiddenException("No puedes ver el perfil de otro profesor.");
                }
            }
        }

        return usuarioMapper.toResponseDTO(usuarioEncontrado);
    }

    /**
     * Busca usuarios por nombre de usuario.
     * Uso exclusivo para profesores (para buscar a sus propios alumnos).
     */
    public List<UsuarioResponseDTO> buscarUsuariosPorNombre(String nombre, Usuario usuarioLogueado) {
        if (usuarioLogueado.getRol() == TipoRol.ROL_ESTUDIANTE) {
            throw new ForbiddenException("Los alumnos no tienen permiso para buscar usuarios.");
        }

        List<Usuario> usuarios = usuarioDAO.findUsuarioByNombreUsuario(nombre);

        // Seguridad: El profesor solo debería poder ver a sus propios alumnos o a sí mismo en los resultados de búsqueda
        List<Usuario> usuariosFiltrados = usuarios.stream().filter(u -> {
            if (u.getId().equals(usuarioLogueado.getId())) return true;
            if (u.getRol() == TipoRol.ROL_ESTUDIANTE && u.getAula() != null) {
                return u.getAula().getProfesor().getId().equals(usuarioLogueado.getId());
            }
            return false;
        }).toList();

        return usuarioMapper.toResponseDTOList(usuariosFiltrados);
    }

    /**
     * Borra un usuario del sistema.
     */
    @Transactional
    public void borrarUsuario(Long id, Usuario usuarioLogueado) {
        if (!usuarioDAO.existsById(id)) {
            throw new ResourceNotFoundException("No se puede borrar. El usuario con ID " + id + " no existe.");
        }

        // Seguridad: Evitar que un estudiante borre la cuenta de otra persona
        if (usuarioLogueado.getRol() == TipoRol.ROL_ESTUDIANTE && !usuarioLogueado.getId().equals(id)) {
            throw new ForbiddenException("No puedes borrar la cuenta de otro usuario.");
        }

        usuarioDAO.deleteById(id);
    }
}
