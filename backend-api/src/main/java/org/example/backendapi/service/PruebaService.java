package org.example.backendapi.service;

import org.example.backendapi.model.dao.IAulaDAO;
import org.example.backendapi.model.dao.IPruebaDAO;
import org.example.backendapi.model.entities.Aula;
import org.example.backendapi.model.entities.Prueba;
import org.example.backendapi.model.entities.TipoPrueba;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.List;

@Service
public class PruebaService {

    @Autowired
    private IPruebaDAO pruebaDAO;

    @Autowired
    private IAulaDAO aulaDAO;

    public Prueba crearPrueba(String aulaId, String titulo, TipoPrueba tipo, String contenido, int puntuacionMaxima) {
        Aula aula = aulaDAO.findAulaById(aulaId)
                .orElseThrow(() -> new RuntimeException("Error: Aula no encontrada"));

        Prueba nuevaPrueba = new Prueba();
        nuevaPrueba.setAula(aula);
        nuevaPrueba.setTitulo(titulo);
        nuevaPrueba.setTipo(tipo);
        nuevaPrueba.setContenido(contenido);
        nuevaPrueba.setPuntuacionMaxima(puntuacionMaxima);
        nuevaPrueba.setFechaCreacion(Instant.now());

        return pruebaDAO.save(nuevaPrueba);
    }

    public List<Prueba> obtenerPruebasPorAula(String aulaId) {
        return pruebaDAO.findByAula_Id(aulaId);
    }

    public Prueba actualizarPrueba(String pruebaId, String titulo, String contenido, int puntuacionMaxima) {
        Prueba prueba = pruebaDAO.findById(pruebaId)
                .orElseThrow(() -> new RuntimeException("Error: Prueba no encontrada"));

        prueba.setTitulo(titulo);
        prueba.setContenido(contenido);
        prueba.setPuntuacionMaxima(puntuacionMaxima);

        return pruebaDAO.save(prueba);
    }

    public void eliminarPrueba(String pruebaId) {
        if (!pruebaDAO.existsById(pruebaId)) {
            throw new RuntimeException("Error: Prueba no encontrada");
        }
        pruebaDAO.deleteById(pruebaId);
    }
}