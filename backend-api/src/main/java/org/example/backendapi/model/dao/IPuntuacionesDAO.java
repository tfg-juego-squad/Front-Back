package org.example.backendapi.model.dao;

import org.example.backendapi.model.entities.Prueba;
import org.example.backendapi.model.entities.Puntuaciones;
import org.springframework.data.repository.CrudRepository;

import java.util.List;
import java.util.Optional;

public interface IPuntuacionesDAO extends CrudRepository<Puntuaciones, String> {
    Optional<Puntuaciones> findPuntuacionesById(String id);

    List<Puntuaciones> findPuntuacionesByPrueba(Prueba prueba);

    List<Puntuaciones> findPuntuacionesByPrueba_Nombre(String pruebaNombre);

    List<Puntuaciones> findPuntuacionesByPuntosObtenidos(int puntosObtenidos);
}
