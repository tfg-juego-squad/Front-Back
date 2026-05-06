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

@Service
@RequiredArgsConstructor
public class PreguntaService {

    private final IPreguntaDAO preguntaDAO;
    private final IPruebaDAO pruebaDAO;
    private final PreguntaMapper preguntaMapper;

    @Transactional
    public PreguntaResponseDTO crearPregunta(PreguntaRequestDTO request, Usuario usuarioLogueado) {
        Prueba prueba = pruebaDAO.findById(request.getPruebaId())
                .orElseThrow(() -> new ResourceNotFoundException("Prueba no encontrada con ID: " + request.getPruebaId()));

        if (!prueba.getAula().getProfesor().getId().equals(usuarioLogueado.getId())) {
            throw new ForbiddenException("No puedes añadir preguntas a un examen de un aula que no te pertenece.");
        }

        Pregunta pregunta = new Pregunta();
        pregunta.setEnunciado(request.getEnunciado());
        pregunta.setTiempoLimiteSegundos(request.getTiempoLimiteSegundos());
        pregunta.setPrueba(prueba);

        try {
            pregunta.setTipo(TipoPregunta.valueOf(request.getTipo()));
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("Tipo de pregunta inválido. Use TEST o DESARROLLO.");
        }

        List<RespuestaPosible> respuestas = new ArrayList<>();
        if (pregunta.getTipo() == TipoPregunta.TEST && request.getRespuestasPosibles() != null) {
            for (RespuestaPosibleRequestDTO resDTO : request.getRespuestasPosibles()) {
                RespuestaPosible respuesta = new RespuestaPosible();
                respuesta.setTexto(resDTO.getTexto());
                respuesta.setEsCorrecta(resDTO.getEsCorrecta());
                respuesta.setPregunta(pregunta);
                respuestas.add(respuesta);
            }
        }
        pregunta.setRespuestasPosibles(respuestas);

        Pregunta guardada = preguntaDAO.save(pregunta);
        return preguntaMapper.toResponseDTO(guardada);
    }

    public List<PreguntaResponseDTO> obtenerPreguntasPorPrueba(Long pruebaId, Usuario usuarioLogueado) {
        Prueba prueba = pruebaDAO.findById(pruebaId)
                .orElseThrow(() -> new ResourceNotFoundException("Prueba no encontrada"));

        // Validar acceso
        if (usuarioLogueado.getRol() == TipoRol.ROL_PROFESOR && !prueba.getAula().getProfesor().getId().equals(usuarioLogueado.getId())) {
            throw new ForbiddenException("No puedes ver las preguntas de un examen que no te pertenece.");
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
