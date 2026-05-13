package org.example.backendapi.model.dao;

import org.example.backendapi.model.entities.Prueba;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.CrudRepository;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface IPruebaDAO extends CrudRepository<Prueba, Long>{
    List<Prueba> findByAula_Id(Long aulaId);

    @Query("SELECT prueba FROM Prueba prueba WHERE prueba.aula.id = :aulaId" +
            " AND (prueba.tipo IS NULL OR prueba.tipo <> org.example.backendapi.model.entities.TipoPrueba.NOTA_MANUAL)" +
            " AND prueba.id NOT IN" +
            " (SELECT puntuacion.prueba.id FROM Puntuacion puntuacion WHERE puntuacion.alumno.id = :alumnoId)")
    List<Prueba> findPruebasPendientes(@Param("aulaId") Long aulaId, @Param("alumnoId") Long alumnoId);
}
