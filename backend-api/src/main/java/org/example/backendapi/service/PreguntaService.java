package org.example.backendapi.service;

import lombok.RequiredArgsConstructor;
import org.example.backendapi.dto.PreguntaRequestDTO;
import org.example.backendapi.dto.PreguntaResponseDTO;
import org.example.backendapi.dto.RespuestaPosibleRequestDTO;
import org.example.backendapi.exception.ForbiddenException;
import org.example.backendapi.exception.ResourceNotFoundException;
import org.example.backendapi.mapper.PreguntaMapper;
import org.example.backendapi.model.dao.IPreguntaDAO;
import org.example.backendapi.model.dao.IPruebaDAO;
import org.example.backendapi.model.entities.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

/**
 * Servicio encargado de gestionar las Preguntas de los exámenes (Pruebas).
 * Maneja tanto la creación de preguntas tipo TEST (con sus posibles respuestas)
 * como de tipo DESARROLLO, y se asegura de no revelar las respuestas correctas a los estudiantes.
 */
@Service
@RequiredArgsConstructor
public class PreguntaService {

    private final IPreguntaDAO preguntaDAO;
    private final IPruebaDAO pruebaDAO;
    private final PreguntaMapper preguntaMapper;

    /**
     * Crea una nueva pregunta y la asocia a un examen existente.
     * Si la pregunta es tipo TEST, también guarda sus posibles respuestas.
     */
    @Transactional
    public PreguntaResponseDTO crearPregunta(PreguntaRequestDTO request, Usuario usuarioLogueado) {
        Prueba prueba = pruebaDAO.findById(request.getPruebaId())
                .orElseThrow(() -> new ResourceNotFoundException("Prueba no encontrada con ID: " + request.getPruebaId()));

        // Seguridad: El profesor que crea la pregunta debe ser el dueño del examen
        if (!prueba.getAula().getProfesor().getId().equals(usuarioLogueado.getId())) {
            throw new ForbiddenException("No puedes añadir preguntas a un examen de un aula que no te pertenece.");
        }

        Pregunta pregunta = new Pregunta();
        pregunta.setEnunciado(request.getEnunciado());
        pregunta.setTiempoLimiteSegundos(request.getTiempoLimiteSegundos());
        pregunta.setValorPuntos(request.getValorPuntos());
        pregunta.setPrueba(prueba);

        // Validamos que el tipo enviado sea correcto (TEST o DESARROLLO)
        try {
            pregunta.setTipo(TipoPregunta.valueOf(request.getTipo()));
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("Tipo de pregunta inválido. Use TEST o DESARROLLO.");
        }

        // Si es tipo TEST, procesamos y enlazamos sus opciones de respuesta
        List<RespuestaPosible> respuestas = new ArrayList<>();
        if (pregunta.getTipo() == TipoPregunta.TEST && request.getRespuestasPosibles() != null) {
            for (RespuestaPosibleRequestDTO resDTO : request.getRespuestasPosibles()) {
                RespuestaPosible respuesta = new RespuestaPosible();
                respuesta.setTexto(resDTO.getTexto());
                respuesta.setEsCorrecta(resDTO.getEsCorrecta()); // Marca cuál es la buena para la auto-corrección
                respuesta.setPregunta(pregunta);
                respuestas.add(respuesta);
            }
        }
        pregunta.setRespuestasPosibles(respuestas);

        Pregunta guardada = preguntaDAO.save(pregunta);
        return preguntaMapper.toResponseDTO(guardada);
    }

    /**
     * Obtiene todas las preguntas de un examen.
     * ATENCIÓN: Si el que lo pide es un Estudiante, el campo "esCorrecta" de las respuestas
     * tipo TEST se oculta (se pone a null) para que no puedan ver la solución haciendo trampas.
     */
    public List<PreguntaResponseDTO> obtenerPreguntasPorPrueba(Long pruebaId, Usuario usuarioLogueado) {
        Prueba prueba = pruebaDAO.findById(pruebaId)
                .orElseThrow(() -> new ResourceNotFoundException("Prueba no encontrada"));

        // Validar acceso para el Profesor
        if (usuarioLogueado.getRol() == TipoRol.ROL_PROFESOR && !prueba.getAula().getProfesor().getId().equals(usuarioLogueado.getId())) {
            throw new ForbiddenException("No puedes ver las preguntas de un examen que no te pertenece.");
        }
        
        // Validar acceso para el Estudiante (IDOR protection)
        if (usuarioLogueado.getRol() == TipoRol.ROL_ESTUDIANTE) {
            if (usuarioLogueado.getAula() == null || !usuarioLogueado.getAula().getId().equals(prueba.getAula().getId())) {
                throw new ForbiddenException("No puedes ver las preguntas de un examen de un aula a la que no perteneces.");
            }
        }

        List<Pregunta> preguntas = preguntaDAO.findByPrueba_Id(pruebaId);
        List<PreguntaResponseDTO> responseDTOs = preguntaMapper.toResponseDTOList(preguntas);

        // Ocultar respuestas correctas si es un estudiante
        if (usuarioLogueado.getRol() == TipoRol.ROL_ESTUDIANTE) {
            responseDTOs.forEach(pregunta -> {
                if (pregunta.getRespuestasPosibles() != null) {
                    pregunta.getRespuestasPosibles().forEach(resp -> resp.setEsCorrecta(null));
                }
            });
        }

        return responseDTOs;
    }
    
    /**
     * Elimina una pregunta. Sus posibles respuestas se borrarán automáticamente (por Cascade en la DB).
     */
    @Transactional
    public void eliminarPregunta(Long preguntaId, Usuario usuarioLogueado) {
        Pregunta pregunta = preguntaDAO.findById(preguntaId)
                .orElseThrow(() -> new ResourceNotFoundException("Pregunta no encontrada"));
                
        if (!pregunta.getPrueba().getAula().getProfesor().getId().equals(usuarioLogueado.getId())) {
            throw new ForbiddenException("No puedes borrar una pregunta de un examen que no te pertenece.");
        }
        
        preguntaDAO.delete(pregunta);
    }
}
