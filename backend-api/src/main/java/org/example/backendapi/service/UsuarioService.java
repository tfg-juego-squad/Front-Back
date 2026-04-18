package org.example.backendapi.service;

import org.example.backendapi.model.dao.IUsuarioDAO;
import org.example.backendapi.model.entities.TipoRol;
import org.example.backendapi.model.entities.Usuario;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.*;

@Service
public class UsuarioService {
    @Autowired
    private IUsuarioDAO usuarioDAO;

    @Autowired
    private SecurityService securityService;

    public Usuario registrarProfesor(Usuario profesor) {
        profesor.setHashContrasena(securityService.hashPassword(profesor.getHashContrasena()));
        profesor.setFechaCreacion(Instant.now());

        profesor.setRol(TipoRol.ROL_PROFESOR);

        return usuarioDAO.save(profesor);
    }

    public Usuario hacerLogin(String nombreUsuario, String passwordPlana) {
        List<Usuario> usuarios = usuarioDAO.findUsuarioByNombreUsuario(nombreUsuario);

        if (usuarios.isEmpty()) {
            throw new RuntimeException("Error: Usuario no encontrado");
        }

        Usuario usuario = usuarios.get(0);

        if (securityService.checkPassword(passwordPlana, usuario.getHashContrasena())) {
            return usuario;
        } else {
            throw new RuntimeException("Error: Contraseña incorrecta");
        }
    }
}
