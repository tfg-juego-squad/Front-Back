package org.example.backendapi.model.dao;

import org.example.backendapi.model.entities.Puntuacion;
import org.springframework.data.repository.CrudRepository;

import java.util.List;
import java.util.Optional;

public interface IPuntuacionDAO extends CrudRepository<Puntuacion, Long> {
    Optional<Puntuacion> findPuntuacionById(Long id);

    List<Puntuacion> findPuntuacionByPrueba_Aula_Id(Long pruebaAulaId);
    
    Optional<Puntuacion> findPuntuacionByPrueba_IdAndAlumno_Id(Long pruebaId, Long alumnoId);
}
