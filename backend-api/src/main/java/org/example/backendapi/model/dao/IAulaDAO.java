package org.example.backendapi.model.dao;

import org.example.backendapi.model.entities.Aula;
import org.springframework.data.repository.CrudRepository;

import java.util.List;
import java.util.Optional;

public interface IAulaDAO extends CrudRepository<Aula, Integer> {
    Optional<Aula> findAulaById(String id);
    List<Aula> findAulasByProfesorId(String profesorId);
    Optional<Aula> findAulaByCodigoInvitacion(String codigoInvitacion);
}
