package org.example.backendapi.model.dao;

import org.example.backendapi.model.entities.Token;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import java.util.List;
import java.util.Optional;

public interface ITokenDAO extends JpaRepository<Token, Long> {
    Optional<Token> findByToken(String token);

    // Sirve para buscar todos los tokens activos de un usuario y así poder revocarlos al hacer un nuevo login
    @Query(value = """
      select token from Token token inner join Usuario usuario on token.usuario.id = usuario.id
      where usuario.id = :usuarioId and (token.expired = false or token.revoked = false)
      """)
    List<Token> findAllValidTokensByUsuario(Long usuarioId);
}
