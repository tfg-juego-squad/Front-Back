package org.example.backendapi.model.dao;

import org.example.backendapi.model.entities.Aula;
import org.springframework.data.repository.CrudRepository;

import java.util.List;
import java.util.Optional;

public interface IAulaDAO extends CrudRepository<Aula, Integer> {
    Optional<Aula> findAulaById(Integer id);
    List<Aula> findAulasByProfesorId(Integer profesorId);
}
