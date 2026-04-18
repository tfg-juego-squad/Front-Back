package org.example.backendapi.model.dao;

import org.example.backendapi.model.entities.Usuario;
import org.springframework.data.repository.CrudRepository;

import java.util.List;
import java.util.Optional;

public interface IUsuarioDAO extends CrudRepository<Usuario, String> {
    Optional<Usuario> findUsuarioById(String id);
    List<Usuario> findUsuarioByNombreUsuario(String nombreUsuario);
}
