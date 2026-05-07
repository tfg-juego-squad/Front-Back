package org.example.backendapi.service;

import lombok.RequiredArgsConstructor;
import org.example.backendapi.dto.RespuestaAlumnoRequestDTO;
import org.example.backendapi.dto.RespuestaAlumnoResponseDTO;
import org.example.backendapi.exception.BadRequestException;
import org.example.backendapi.exception.ForbiddenException;
import org.example.backendapi.exception.ResourceNotFoundException;
import org.example.backendapi.mapper.RespuestaAlumnoMapper;
import org.example.backendapi.model.dao.IPreguntaDAO;
import org.example.backendapi.model.dao.IRespuestaAlumnoDAO;
import org.example.backendapi.model.dao.IRespuestaPosibleDAO;
import org.example.backendapi.model.dao.IUsuarioDAO;
import org.example.backendapi.model.entities.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class RespuestaAlumnoService {

    private final IRespuestaAlumnoDAO respuestaAlumnoDAO;
    private final IPreguntaDAO preguntaDAO;
    private final IRespuestaPosibleDAO respuestaPosibleDAO;
    private final IUsuarioDAO usuarioDAO;
    private final RespuestaAlumnoMapper respuestaAlumnoMapper;
    private final PuntuacionService puntuacionService;

    @Transactional
    public RespuestaAlumnoResponseDTO responderPregunta(RespuestaAlumnoRequestDTO request, Usuario alumnoLogueadoToken) {
        Usuario alumno = usuarioDAO.findById(alumnoLogueadoToken.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Alumno no encontrado"));

        Pregunta pregunta = preguntaDAO.findById(request.getPreguntaId())
                .orElseThrow(() -> new ResourceNotFoundException("Pregunta no encontrada"));

        if (alumno.getAula() == null || !alumno.getAula().getId().equals(pregunta.getPrueba().getAula().getId())) {
            throw new ForbiddenException("No puedes responder preguntas de un examen que no pertenece a tu aula.");
        }
        
        // Evitar doble respuesta
        Optional<RespuestaAlumno> respuestaExistente = respuestaAlumnoDAO.findByPregunta_IdAndAlumno_Id(pregunta.getId(), alumno.getId());
        if (respuestaExistente.isPresent()) {
            throw new BadRequestException("Ya has respondido a esta pregunta.");
        }

        RespuestaAlumno respuesta = new RespuestaAlumno();
        respuesta.setAlumno(alumno);
        respuesta.setPregunta(pregunta);
        respuesta.setTiempoRespuestaSegundos(request.getTiempoRespuestaSegundos());
        respuesta.setFechaRespuesta(Instant.now());

        if (pregunta.getTipo() == TipoPregunta.TEST) {
            if (request.getRespuestaElegidaId() != null) {
                RespuestaPosible opcion = respuestaPosibleDAO.findById(request.getRespuestaElegidaId())
                        .orElseThrow(() -> new ResourceNotFoundException("Opción de respuesta no encontrada"));
                
                if (!opcion.getPregunta().getId().equals(pregunta.getId())) {
                    throw new BadRequestException("La opción de respuesta elegida no pertenece a esta pregunta.");
                }
                respuesta.setRespuestaElegida(opcion);

                // CÁLCULO AUTOMÁTICO DE PUNTOS PARA TEST
                if (opcion.getEsCorrecta()) {
                    int totalPreguntas = (int) pregunta.getPrueba().getPreguntas().size();
                    int puntosPorPregunta = pregunta.getPrueba().getPuntuacionMaxima() / (totalPreguntas > 0 ? totalPreguntas : 1);
                    respuesta.setPuntosAsignados(puntosPorPregunta);
                } else {
                    respuesta.setPuntosAsignados(0);
                }

            } else {
                throw new BadRequestException("Para preguntas tipo TEST, debes proporcionar un respuestaElegidaId.");
            }
        } else if (pregunta.getTipo() == TipoPregunta.DESARROLLO) {
            if (request.getTextoRespuesta() == null || request.getTextoRespuesta().trim().isEmpty()) {
                throw new BadRequestException("Para preguntas de DESARROLLO, debes enviar el texto de la respuesta.");
            }
            respuesta.setTextoRespuesta(request.getTextoRespuesta());
            respuesta.setPuntosAsignados(null); // Pendiente de corrección por el profesor
        }

        RespuestaAlumno guardada = respuestaAlumnoDAO.save(respuesta);
        return respuestaAlumnoMapper.toResponseDTO(guardada);
    }

    public List<RespuestaAlumnoResponseDTO> obtenerRespuestasPorPruebaYAlumno(Long pruebaId, Long alumnoId, Usuario usuarioLogueado) {
        if (usuarioLogueado.getRol() == TipoRol.ROL_ESTUDIANTE && !usuarioLogueado.getId().equals(alumnoId)) {
            throw new ForbiddenException("No puedes ver las respuestas de otro alumno.");
        }
        
        if (usuarioLogueado.getRol() == TipoRol.ROL_PROFESOR) {
            Usuario alumno = usuarioDAO.findById(alumnoId)
                    .orElseThrow(() -> new ResourceNotFoundException("Alumno no encontrado"));
            if (alumno.getAula() == null || !alumno.getAula().getProfesor().getId().equals(usuarioLogueado.getId())) {
                throw new ForbiddenException("No puedes ver las respuestas de un alumno que no pertenece a tu aula.");
            }
        }

        List<RespuestaAlumno> respuestas = respuestaAlumnoDAO.findByPregunta_Prueba_IdAndAlumno_Id(pruebaId, alumnoId);
        return respuestaAlumnoMapper.toResponseDTOList(respuestas);
    }

    public List<RespuestaAlumnoResponseDTO> obtenerPendientesCorreccion(Usuario profesorLogueado) {
        if (profesorLogueado.getRol() != TipoRol.ROL_PROFESOR) {
            throw new ForbiddenException("Solo los profesores pueden ver respuestas pendientes de corrección.");
        }
        List<RespuestaAlumno> pendientes = respuestaAlumnoDAO.findByPregunta_Prueba_Aula_Profesor_IdAndPuntosAsignadosIsNull(profesorLogueado.getId());
        return respuestaAlumnoMapper.toResponseDTOList(pendientes);
    }


    @Transactional
    public RespuestaAlumnoResponseDTO corregirRespuestaDesarrollo(Long respuestaId, Integer puntos, Usuario profesorLogueado) {
        RespuestaAlumno respuesta = respuestaAlumnoDAO.findById(respuestaId)
                .orElseThrow(() -> new ResourceNotFoundException("Respuesta no encontrada"));

        if (!respuesta.getPregunta().getPrueba().getAula().getProfesor().getId().equals(profesorLogueado.getId())) {
            throw new ForbiddenException("No puedes corregir respuestas de alumnos que no pertenecen a tus aulas.");
        }

        if (respuesta.getPregunta().getTipo() != TipoPregunta.DESARROLLO) {
            throw new BadRequestException("Solo se pueden corregir manualmente las preguntas de DESARROLLO.");
        }

        respuesta.setPuntosAsignados(puntos);
        RespuestaAlumno guardada = respuestaAlumnoDAO.save(respuesta);
        
        // Actualizamos la puntuación total del alumno para este examen
        puntuacionService.actualizarPuntuacionTotal(respuesta.getAlumno().getId(), respuesta.getPregunta().getPrueba().getId());
        
        return respuestaAlumnoMapper.toResponseDTO(guardada);
    }
}
