package org.example.backendapi.service;

import lombok.RequiredArgsConstructor;
import org.example.backendapi.dto.PruebaRequestDTO;
import org.example.backendapi.dto.PruebaResponseDTO;
import org.example.backendapi.exception.ResourceNotFoundException;
import org.example.backendapi.mapper.PruebaMapper;
import org.example.backendapi.model.dao.IAulaDAO;
import org.example.backendapi.model.dao.IPruebaDAO;
import org.example.backendapi.model.entities.Aula;
import org.example.backendapi.model.entities.Prueba;
import org.example.backendapi.model.entities.TipoPrueba;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;

@Service
@RequiredArgsConstructor
public class PruebaService {

    private final IPruebaDAO pruebaDAO;
    private final IAulaDAO aulaDAO;
    private final PruebaMapper pruebaMapper;

    @Transactional
    public PruebaResponseDTO crearPrueba(PruebaRequestDTO request) {
        Aula aula = aulaDAO.findAulaById(request.getAulaId())
                .orElseThrow(() -> new ResourceNotFoundException("Aula no encontrada con ID: " + request.getAulaId()));

        Prueba nuevaPrueba = new Prueba();
        nuevaPrueba.setAula(aula);
        nuevaPrueba.setTitulo(request.getTitulo());

        // Parseamos el String del DTO al Enum de la Entidad
        try {
            nuevaPrueba.setTipo(TipoPrueba.valueOf(request.getTipo()));
        } catch (IllegalArgumentException ex) {
            throw new IllegalArgumentException("Tipo de prueba no válido. Debe ser TIPO_TEST o DESARROLLO.");
        }

        nuevaPrueba.setContenido(request.getContenido());
        nuevaPrueba.setPuntuacionMaxima(request.getPuntuacionMaxima());
        nuevaPrueba.setFechaLimite(request.getFechaLimite());
        nuevaPrueba.setFechaCreacion(Instant.now());

        Prueba guardada = pruebaDAO.save(nuevaPrueba);
        return pruebaMapper.toResponseDTO(guardada);
    }

    public List<PruebaResponseDTO> obtenerPruebasPorAula(String aulaId) {
        List<Prueba> pruebas = pruebaDAO.findByAula_Id(aulaId);
        return pruebaMapper.toResponseDTOList(pruebas);
    }

    @Transactional
    public PruebaResponseDTO actualizarPrueba(String pruebaId, PruebaRequestDTO request) {
        Prueba prueba = pruebaDAO.findById(pruebaId)
                .orElseThrow(() -> new ResourceNotFoundException("Prueba no encontrada con ID: " + pruebaId));

        prueba.setTitulo(request.getTitulo());
        try {
            prueba.setTipo(TipoPrueba.valueOf(request.getTipo()));
        } catch (IllegalArgumentException ex) {
            throw new IllegalArgumentException("Tipo de prueba no válido.");
        }
        prueba.setContenido(request.getContenido());
        prueba.setPuntuacionMaxima(request.getPuntuacionMaxima());
        prueba.setFechaLimite(request.getFechaLimite());

        Prueba actualizada = pruebaDAO.save(prueba);
        return pruebaMapper.toResponseDTO(actualizada);
    }

    @Transactional
    public void eliminarPrueba(String pruebaId) {
        if (!pruebaDAO.existsById(pruebaId)) {
            throw new ResourceNotFoundException("No se puede borrar. Prueba no encontrada.");
        }
        pruebaDAO.deleteById(pruebaId);
    }
}