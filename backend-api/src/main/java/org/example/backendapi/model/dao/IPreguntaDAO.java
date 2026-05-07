package org.example.backendapi.model.dao;

import org.example.backendapi.model.entities.Pregunta;
import org.springframework.data.repository.CrudRepository;

import java.util.List;

public interface IPreguntaDAO extends CrudRepository<Pregunta, Long> {
    List<Pregunta> findByPrueba_Id(Long pruebaId);
}
