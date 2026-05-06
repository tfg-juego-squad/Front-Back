package org.example.backendapi.model.dao;

import org.example.backendapi.model.entities.Prueba;
import org.springframework.data.repository.CrudRepository;

import java.util.List;

public interface IPruebaDAO extends CrudRepository<Prueba, Integer>{
    List<Prueba> findByAula_Id(Integer aulaId);
}
