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

@Service
@RequiredArgsConstructor
public class UsuarioService {

    private final IUsuarioDAO usuarioDAO;
    private final SecurityService securityService;
    private final JwtService jwtService;
    private final UsuarioMapper usuarioMapper;

    @Transactional
    public UsuarioResponseDTO registrarProfesor(UsuarioRegistroRequestDTO request) {
        if (!usuarioDAO.findUsuarioByNombreUsuario(request.getNombreUsuario()).isEmpty()) {
            throw new BadRequestException("El nombre de usuario ya está en uso");
        }

        Usuario profesor = new Usuario();
        profesor.setNombreUsuario(request.getNombreUsuario());
        profesor.setNombreReal(request.getNombreReal());
        profesor.setApellidos(request.getApellidos());
        profesor.setEmail(request.getEmail());

        profesor.setHashContrasena(securityService.hashPassword(request.getPasswordPlana()));
        profesor.setFechaCreacion(Instant.now());
        profesor.setRol(TipoRol.ROL_PROFESOR);

        Usuario guardado = usuarioDAO.save(profesor);

        return usuarioMapper.toResponseDTO(guardado);
    }

    public UsuarioResponseDTO hacerLogin(UsuarioLoginRequestDTO request) {
        List<Usuario> usuarios = usuarioDAO.findUsuarioByNombreUsuario(request.getNombreUsuario());

        if (usuarios.isEmpty()) {
            throw new ResourceNotFoundException("Usuario no encontrado");
        }

        Usuario usuario = usuarios.get(0);

        if (!securityService.checkPassword(request.getPasswordPlana(), usuario.getHashContrasena())) {
            throw new BadRequestException("Contraseña incorrecta");
        }

        String token = jwtService.generateToken(usuario);
        UsuarioResponseDTO responseDTO = usuarioMapper.toResponseDTO(usuario);
        responseDTO.setToken(token);

        return responseDTO;
    }

    public UsuarioResponseDTO buscarUsuarioPorId(Long id) {
        return usuarioDAO.findUsuarioById(id)
                .map(usuarioMapper::toResponseDTO)
                .orElseThrow(() -> new ResourceNotFoundException("No se encontró ningún usuario con el ID: " + id));
    }

    public List<UsuarioResponseDTO> buscarUsuariosPorNombre(String nombre) {
        List<Usuario> usuarios = usuarioDAO.findUsuarioByNombreUsuario(nombre);

        return usuarioMapper.toResponseDTOList(usuarios);
    }

    @Transactional
    public void borrarUsuario(Long id, Usuario usuarioLogueado) {
        if (!usuarioDAO.existsById(id)) {
            throw new ResourceNotFoundException("No se puede borrar. El usuario con ID " + id + " no existe.");
        }

        if (usuarioLogueado.getRol() == TipoRol.ROL_ESTUDIANTE && !usuarioLogueado.getId().equals(id)) {
            throw new ForbiddenException("No puedes borrar la cuenta de otro usuario.");
        }
        
        // TODO: Si es profesor, verificar si el alumno le pertenece (opcional)

        usuarioDAO.deleteById(id);
    }
}
