package org.example.backendapi.model.dao;

import org.example.backendapi.model.entities.Prueba;
import org.springframework.data.repository.CrudRepository;

import java.util.List;
import java.util.Optional;

public interface IPruebaDAO extends CrudRepository<Prueba, String>{
    Optional<Prueba> findPruebaById(String id);

    List<Prueba> findPruebaByDescripcion(String descripcion);

    List<Prueba> findPruebaByNombre(String nombre);

    List<Prueba> findPruebaByPuntuacionMaxima(Integer puntuacionMaxima);
}
