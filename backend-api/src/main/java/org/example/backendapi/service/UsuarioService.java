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
        // Comprobar si el nombre de usuario ya existe
        if (!usuarioDAO.findUsuarioByNombreUsuario(request.getNombreUsuario()).isEmpty()) {
            throw new BadRequestException("El nombre de usuario ya está en uso");
        }

        Usuario profesor = new Usuario();
        profesor.setNombreUsuario(request.getNombreUsuario());
        profesor.setNombreReal(request.getNombreReal());
        profesor.setApellidos(request.getApellidos());
        profesor.setEmail(request.getEmail());

        // Encriptar la contraseña antes de guardar
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
        List<Usuario> usuarios = usuarioDAO.findUsuarioByNombreUsuario(request.getNombreUsuario());
        if (usuarios.isEmpty()) {
            throw new ResourceNotFoundException("Usuario no encontrado");
        }
        Usuario usuario = usuarios.get(0);

        // Validar contraseña
        if (!securityService.checkPassword(request.getPasswordPlana(), usuario.getHashContrasena())) {
            throw new BadRequestException("Contraseña incorrecta");
        }

        // Generar JWT
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

        // Validaciones de seguridad para evitar que vean perfiles ajenos
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
     * Busca usuarios por nombre (solo para profesores).
     */
    public List<UsuarioResponseDTO> buscarUsuariosPorNombre(String nombre, Usuario usuarioLogueado) {
        if (usuarioLogueado.getRol() == TipoRol.ROL_ESTUDIANTE) {
            throw new ForbiddenException("Los alumnos no tienen permiso para buscar usuarios.");
        }

        List<Usuario> usuarios = usuarioDAO.findUsuarioByNombreUsuario(nombre);

        // El profesor solo debería poder ver a sus propios alumnos o a sí mismo en los resultados de búsqueda
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
     * Elimina un usuario comprobando permisos.
     */
    @Transactional
    public void borrarUsuario(Long id, Usuario usuarioLogueado) {
        if (!usuarioDAO.existsById(id)) {
            throw new ResourceNotFoundException("No se puede borrar. El usuario con ID " + id + " no existe.");
        }

        // Evitar que un estudiante borre la cuenta de otra persona o un profesor borre a un alumno que no es de su aula
        if (usuarioLogueado.getRol() == TipoRol.ROL_ESTUDIANTE && !usuarioLogueado.getId().equals(id)) {
            throw new ForbiddenException("No puedes borrar la cuenta de otro usuario.");
        } else if (usuarioLogueado.getRol() == TipoRol.ROL_PROFESOR) {
            Usuario usuarioABorrar = usuarioDAO.findById(id)
                    .orElseThrow(() -> new ResourceNotFoundException("Usuario no encontrado"));

            if (usuarioABorrar.getRol() == TipoRol.ROL_PROFESOR) {
                if (!usuarioABorrar.getId().equals(usuarioLogueado.getId())) {
                    throw new ForbiddenException("No tienes permisos para borrar a otros profesores.");
                }
            } else {
                if (usuarioABorrar.getAula() == null || !usuarioABorrar.getAula().getProfesor().getId().equals(usuarioLogueado.getId())) {
                    throw new ForbiddenException("No puedes borrar a un alumno que no pertenece a tu aula.");
                }
            }
        }

        usuarioDAO.deleteById(id);
    }
}
