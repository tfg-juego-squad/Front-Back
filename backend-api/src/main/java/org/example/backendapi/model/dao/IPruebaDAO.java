package org.example.backendapi.model.dao;

import org.example.backendapi.model.entities.Prueba;
import org.springframework.data.repository.CrudRepository;

import java.util.List;

public interface IPruebaDAO extends CrudRepository<Prueba, String>{
    List<Prueba> findByAula_Id(String aulaId);
}
