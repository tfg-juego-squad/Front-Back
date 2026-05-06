package org.example.backendapi.model.dao;

import org.example.backendapi.model.entities.RespuestaAlumno;
import org.springframework.data.repository.CrudRepository;

import java.util.List;
import java.util.Optional;

public interface IRespuestaAlumnoDAO extends CrudRepository<RespuestaAlumno, Long> {
    List<RespuestaAlumno> findByPregunta_Prueba_IdAndAlumno_Id(Long pruebaId, Long alumnoId);
    Optional<RespuestaAlumno> findByPregunta_IdAndAlumno_Id(Long preguntaId, Long alumnoId);
}
