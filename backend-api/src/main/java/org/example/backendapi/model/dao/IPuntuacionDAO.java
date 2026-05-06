package org.example.backendapi.model.dao;

import org.example.backendapi.model.entities.Puntuacion;
import org.springframework.data.repository.CrudRepository;

import java.util.List;
import java.util.Optional;

public interface IPuntuacionDAO extends CrudRepository<Puntuacion, Integer> {
    Optional<Puntuacion> findPuntuacionById(Integer id);

    List<Puntuacion> findPuntuacionByPrueba_Aula_Id(Integer pruebaAulaId);
}
