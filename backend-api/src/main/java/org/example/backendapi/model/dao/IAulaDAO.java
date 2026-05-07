package org.example.backendapi.model.dao;

import org.example.backendapi.model.entities.Aula;
import org.springframework.data.repository.CrudRepository;

import java.util.List;

public interface IAulaDAO extends CrudRepository<Aula, Long> {
    List<Aula> findAulasByProfesorId(Long profesorId);
}
