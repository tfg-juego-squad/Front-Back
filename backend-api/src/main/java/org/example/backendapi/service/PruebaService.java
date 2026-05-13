package org.example.backendapi.service;

import lombok.RequiredArgsConstructor;
import org.example.backendapi.dto.EstadisticaPreguntaDTO;
import org.example.backendapi.dto.PruebaRequestDTO;
import org.example.backendapi.dto.PruebaResponseDTO;
import org.example.backendapi.exception.BadRequestException;
import org.example.backendapi.exception.ForbiddenException;
import org.example.backendapi.exception.ResourceNotFoundException;
import org.example.backendapi.mapper.PruebaMapper;
import org.example.backendapi.model.dao.IAulaDAO;
import org.example.backendapi.model.dao.IPruebaDAO;
import org.example.backendapi.model.dao.IRespuestaAlumnoDAO;
import org.example.backendapi.model.dao.IUsuarioDAO;
import org.example.backendapi.model.entities.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Servicio encargado de la lógica de negocio de las Pruebas (Exámenes).
 * Gestiona la creación, modificación, borrado y consulta de los exámenes
 * asignados a un aula, controlando los permisos de acceso.
 */
@Service
@RequiredArgsConstructor
public class PruebaService {

    private final IPruebaDAO pruebaDAO;
    private final IAulaDAO aulaDAO;
    private final PruebaMapper pruebaMapper;
    private final IUsuarioDAO usuarioDAO;
    private final IRespuestaAlumnoDAO respuestaAlumnoDAO;

    /**
     * Crea un examen en un aula. Solo el profesor del aula puede hacerlo.
     */
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
        nuevaPrueba.setPreguntas(new ArrayList<>());
        nuevaPrueba.setFechaLimite(request.getFechaLimite());
        nuevaPrueba.setFechaCreacion(Instant.now());
        nuevaPrueba.setNpcId(request.getNpcId());
        nuevaPrueba.setTipo(parseTipo(request.getTipo()));
        nuevaPrueba.setNivelesMinijuego(request.getNivelesMinijuego());
        nuevaPrueba.setSubtipoMinijuego(request.getSubtipoMinijuego());
        nuevaPrueba.setEvaluable(request.getEvaluable() == null ? Boolean.TRUE : request.getEvaluable());
        nuevaPrueba.setTexto(request.getTexto());
        nuevaPrueba.setNivelMinimo(request.getNivelMinimo() == null ? 1 : Math.max(1, request.getNivelMinimo()));
        nuevaPrueba.setXpRecompensa(request.getXpRecompensa() == null ? 10 : Math.max(0, request.getXpRecompensa()));

        Prueba guardada = pruebaDAO.save(nuevaPrueba);
        return pruebaMapper.toResponseDTO(guardada);
    }

    private TipoPrueba parseTipo(String raw) {
        if (raw == null || raw.isBlank()) {
            return TipoPrueba.EXAMEN;
        }
        try {
            return TipoPrueba.valueOf(raw.trim().toUpperCase());
        } catch (IllegalArgumentException ex) {
            throw new BadRequestException("Tipo de prueba inválido: " + raw);
        }
    }

    /**
     * Lista los exámenes de un aula validando los permisos del usuario.
     */
    public List<PruebaResponseDTO> obtenerPruebasPorAula(Long aulaId, Usuario usuarioLogueado) {
        Aula aula = aulaDAO.findById(aulaId)
                .orElseThrow(() -> new ResourceNotFoundException("Aula no encontrada con ID: " + aulaId));

        // Permisos para Profesor
        if (usuarioLogueado.getRol() == TipoRol.ROL_PROFESOR && !aula.getProfesor().getId().equals(usuarioLogueado.getId())) {
            throw new ForbiddenException("No puedes ver las pruebas de un aula que no te pertenece.");
        }

        // Permisos para Alumno
        if (usuarioLogueado.getRol() == TipoRol.ROL_ESTUDIANTE) {
            if (usuarioLogueado.getAula() == null || !usuarioLogueado.getAula().getId().equals(aulaId)) {
                throw new ForbiddenException("No puedes ver las pruebas de un aula a la que no perteneces.");
            }
        }

        List<Prueba> pruebas = pruebaDAO.findByAula_Id(aulaId);
        return pruebaMapper.toResponseDTOList(pruebas);
    }

    /**
     * Modifica una prueba existente.
     */
    @Transactional
    public PruebaResponseDTO actualizarPrueba(Long pruebaId, PruebaRequestDTO request, Usuario usuarioLogueado) {
        Prueba prueba = pruebaDAO.findById(pruebaId)
                .orElseThrow(() -> new ResourceNotFoundException("Prueba no encontrada con ID: " + pruebaId));

        if (!prueba.getAula().getProfesor().getId().equals(usuarioLogueado.getId())) {
            throw new ForbiddenException("No puedes modificar una prueba de un aula que no te pertenece.");
        }

        prueba.setTitulo(request.getTitulo());
        prueba.setFechaLimite(request.getFechaLimite());
        prueba.setNpcId(request.getNpcId());
        if (request.getTipo() != null) {
            prueba.setTipo(parseTipo(request.getTipo()));
        }
        if (request.getNivelesMinijuego() != null) {
            prueba.setNivelesMinijuego(request.getNivelesMinijuego());
        }
        if (request.getSubtipoMinijuego() != null) {
            prueba.setSubtipoMinijuego(request.getSubtipoMinijuego());
        }
        if (request.getEvaluable() != null) {
            prueba.setEvaluable(request.getEvaluable());
        }
        if (request.getTexto() != null) {
            prueba.setTexto(request.getTexto());
        }
        if (request.getNivelMinimo() != null) {
            prueba.setNivelMinimo(Math.max(1, request.getNivelMinimo()));
        }
        if (request.getXpRecompensa() != null) {
            prueba.setXpRecompensa(Math.max(0, request.getXpRecompensa()));
        }

        Prueba actualizada = pruebaDAO.save(prueba);
        return pruebaMapper.toResponseDTO(actualizada);
    }

    /**
     * Lista de exámenes que un alumno tiene pendientes de hacer.
     */
    public List<PruebaResponseDTO> obtenerPruebasPendientes(Long alumnoId, Usuario usuarioLogueado) {
        Usuario alumno = usuarioDAO.findById(alumnoId)
                .orElseThrow(() -> new ResourceNotFoundException("Alumno no encontrado con ID: " + alumnoId));

        if (alumno.getAula() == null) {
            throw new BadRequestException("El alumno no está asignado a ninguna aula.");
        }

        // Validar que el usuario logueado tiene permiso para ver esto
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

    /**
     * Elimina un examen del sistema.
     * Si el examen ya tiene respuestas de alumnos asociadas, la base de datos lanzará
     * una DataIntegrityViolationException (controlada por GlobalExceptionHandler)
     * para evitar borrar datos históricos accidentalmente.
     */
    @Transactional
    public void eliminarPrueba(Long pruebaId, Usuario usuarioLogueado) {
        Prueba prueba = pruebaDAO.findById(pruebaId)
                .orElseThrow(() -> new ResourceNotFoundException("No se puede borrar. Prueba no encontrada."));

        if (!prueba.getAula().getProfesor().getId().equals(usuarioLogueado.getId())) {
            throw new ForbiddenException("No puedes borrar una prueba de un aula que no te pertenece.");
        }

        pruebaDAO.delete(prueba);
    }

    /**
     * Estadísticas por pregunta para una prueba: cuántos alumnos la saltaron
     * (sin texto ni opción elegida) vs contestaron. Solo el profesor del aula.
     */
    public List<EstadisticaPreguntaDTO> obtenerEstadisticas(Long pruebaId, Usuario usuarioLogueado) {
        Prueba prueba = pruebaDAO.findById(pruebaId)
                .orElseThrow(() -> new ResourceNotFoundException("Prueba no encontrada"));
        if (usuarioLogueado.getRol() != TipoRol.ROL_PROFESOR
                || !prueba.getAula().getProfesor().getId().equals(usuarioLogueado.getId())) {
            throw new ForbiddenException("Solo el profesor del aula puede ver estadísticas.");
        }

        // Inicializamos una entrada por cada pregunta para que las que nadie
        // ha visto también salgan con saltadas=0/contestadas=0.
        Map<Long, EstadisticaPreguntaDTO> acc = new HashMap<>();
        List<Pregunta> preguntas = prueba.getPreguntas() == null ? List.of() : prueba.getPreguntas();
        for (Pregunta p : preguntas) {
            EstadisticaPreguntaDTO row = new EstadisticaPreguntaDTO();
            row.setPreguntaId(p.getId());
            row.setEnunciado(p.getEnunciado());
            row.setTipo(p.getTipo() == null ? null : p.getTipo().name());
            row.setSaltadas(0);
            row.setContestadas(0);
            row.setTotal(0);
            acc.put(p.getId(), row);
        }

        for (RespuestaAlumno r : respuestaAlumnoDAO.findByPregunta_Prueba_Id(pruebaId)) {
            EstadisticaPreguntaDTO row = acc.get(r.getPregunta().getId());
            if (row == null) {
                continue;
            }
            boolean saltada = r.getRespuestaElegida() == null
                    && (r.getTextoRespuesta() == null || r.getTextoRespuesta().isBlank());
            if (saltada) {
                row.setSaltadas(row.getSaltadas() + 1);
            } else {
                row.setContestadas(row.getContestadas() + 1);
            }
            row.setTotal(row.getSaltadas() + row.getContestadas());
        }

        // Ordenamos por más saltadas primero (lo que más interesa ver al profe).
        List<EstadisticaPreguntaDTO> out = new ArrayList<>(acc.values());
        out.sort((a, b) -> Long.compare(b.getSaltadas(), a.getSaltadas()));
        return out;
    }
}