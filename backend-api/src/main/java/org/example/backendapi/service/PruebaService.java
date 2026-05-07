package org.example.backendapi.service;

import lombok.RequiredArgsConstructor;
import org.example.backendapi.dto.PruebaRequestDTO;
import org.example.backendapi.dto.PruebaResponseDTO;
import org.example.backendapi.exception.BadRequestException;
import org.example.backendapi.exception.ForbiddenException;
import org.example.backendapi.exception.ResourceNotFoundException;
import org.example.backendapi.mapper.PruebaMapper;
import org.example.backendapi.model.dao.IAulaDAO;
import org.example.backendapi.model.dao.IPruebaDAO;
import org.example.backendapi.model.dao.IUsuarioDAO;
import org.example.backendapi.model.entities.*;
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
    private final IUsuarioDAO usuarioDAO;

    @Transactional
    public PruebaResponseDTO crearPrueba(PruebaRequestDTO request, Usuario usuarioLogueado) {
        Aula aula = aulaDAO.findById(request.getAulaId())
                .orElseThrow(() -> new ResourceNotFoundException("Aula no encontrada con ID: " + request.getAulaId()));

        if (!aula.getProfesor().getId().equals(usuarioLogueado.getId())) {
            throw new ForbiddenException("No puedes crear pruebas en un aula que no te pertenece.");
        }

        Prueba nuevaPrueba = new Prueba();
        nuevaPrueba.setAula(aula);
        nuevaPrueba.setTitulo(request.getTitulo());


        nuevaPrueba.setPuntuacionMaxima(request.getPuntuacionMaxima());
        nuevaPrueba.setFechaLimite(request.getFechaLimite());
        nuevaPrueba.setFechaCreacion(Instant.now());

        Prueba guardada = pruebaDAO.save(nuevaPrueba);
        return pruebaMapper.toResponseDTO(guardada);
    }

    public List<PruebaResponseDTO> obtenerPruebasPorAula(Long aulaId, Usuario usuarioLogueado) {
        Aula aula = aulaDAO.findById(aulaId)
                .orElseThrow(() -> new ResourceNotFoundException("Aula no encontrada con ID: " + aulaId));

        if (usuarioLogueado.getRol() == TipoRol.ROL_PROFESOR && !aula.getProfesor().getId().equals(usuarioLogueado.getId())) {
            throw new ForbiddenException("No puedes ver las pruebas de un aula que no te pertenece.");
        }

        List<Prueba> pruebas = pruebaDAO.findByAula_Id(aulaId);
        return pruebaMapper.toResponseDTOList(pruebas);
    }

    @Transactional
    public PruebaResponseDTO actualizarPrueba(Long pruebaId, PruebaRequestDTO request, Usuario usuarioLogueado) {
        Prueba prueba = pruebaDAO.findById(pruebaId)
                .orElseThrow(() -> new ResourceNotFoundException("Prueba no encontrada con ID: " + pruebaId));

        if (!prueba.getAula().getProfesor().getId().equals(usuarioLogueado.getId())) {
            throw new ForbiddenException("No puedes modificar una prueba de un aula que no te pertenece.");
        }

        prueba.setTitulo(request.getTitulo());

        prueba.setPuntuacionMaxima(request.getPuntuacionMaxima());
        prueba.setFechaLimite(request.getFechaLimite());

        Prueba actualizada = pruebaDAO.save(prueba);
        return pruebaMapper.toResponseDTO(actualizada);
    }

    public List<PruebaResponseDTO> obtenerPruebasPendientes(Long alumnoId, Usuario usuarioLogueado) {
        Usuario alumno = usuarioDAO.findById(alumnoId)
                .orElseThrow(() -> new ResourceNotFoundException("Alumno no encontrado con ID: " + alumnoId));

        if (alumno.getAula() == null) {
            throw new BadRequestException("El alumno no está asignado a ninguna aula.");
        }

        if (usuarioLogueado.getRol() == TipoRol.ROL_ESTUDIANTE) {
            if (!usuarioLogueado.getId().equals(alumnoId)) {
                throw new ForbiddenException("Acceso denegado: No puedes ver las pruebas de otros alumnos.");
            }
        }

        else if (usuarioLogueado.getRol() == TipoRol.ROL_PROFESOR) {
            Long idProfesorDelAlumno = alumno.getAula().getProfesor().getId();

            if (!usuarioLogueado.getId().equals(idProfesorDelAlumno)) {
                throw new ForbiddenException("Acceso denegado: Este alumno no pertenece a tu aula.");
            }
        }

        List<Prueba> pendientes = pruebaDAO.findPruebasPendientes(alumno.getAula().getId(), alumnoId);

        return pruebaMapper.toResponseDTOList(pendientes);
    }

    @Transactional
    public void eliminarPrueba(Long pruebaId, Usuario usuarioLogueado) {
        Prueba prueba = pruebaDAO.findById(pruebaId)
                .orElseThrow(() -> new ResourceNotFoundException("No se puede borrar. Prueba no encontrada."));

        if (!prueba.getAula().getProfesor().getId().equals(usuarioLogueado.getId())) {
            throw new ForbiddenException("No puedes borrar una prueba de un aula que no te pertenece.");
        }

        pruebaDAO.delete(prueba);
    }
}