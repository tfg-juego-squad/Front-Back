package org.example.backendapi.model.dao;

import org.example.backendapi.model.entities.TipoRol;
import org.example.backendapi.model.entities.Usuario;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.CrudRepository;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface IUsuarioDAO extends CrudRepository<Usuario, Long> {
    Optional<Usuario> findUsuarioById(Long id);
    List<Usuario> findUsuarioByNombreUsuario(String nombreUsuario);

    @Query("SELECT usuario FROM Usuario usuario WHERE usuario.aula.id = :aulaId AND usuario.rol = :rol")
    List<Usuario> findByAulaIdAndRol(
            @Param("aulaId") Long aulaId,
            @Param("rol") TipoRol rol
    );
}
