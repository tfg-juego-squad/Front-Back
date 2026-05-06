package org.example.backendapi.service;

import lombok.RequiredArgsConstructor;
import org.example.backendapi.dto.PuntuacionRequestDTO;
import org.example.backendapi.dto.PuntuacionResponseDTO;
import org.example.backendapi.exception.ResourceNotFoundException;
import org.example.backendapi.exception.ForbiddenException;
import org.example.backendapi.mapper.PuntuacionMapper;
import org.example.backendapi.model.dao.IAulaDAO;
import org.example.backendapi.model.dao.IPruebaDAO;
import org.example.backendapi.model.dao.IPuntuacionDAO;
import org.example.backendapi.model.dao.IUsuarioDAO;
import org.example.backendapi.model.entities.Aula;
import org.example.backendapi.model.entities.Prueba;
import org.example.backendapi.model.entities.Puntuacion;
import org.example.backendapi.model.entities.Usuario;
import org.example.backendapi.model.entities.TipoRol;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;

@Service
@RequiredArgsConstructor
public class PuntuacionService {

    private final IPuntuacionDAO puntuacionDAO;
    private final IUsuarioDAO usuarioDAO;
    private final IPruebaDAO pruebaDAO;
    private final IAulaDAO aulaDAO;
    private final PuntuacionMapper puntuacionMapper;

    public PuntuacionResponseDTO buscarPorId(Long id, Usuario usuarioLogueado) {
        Puntuacion puntuacion = puntuacionDAO.findPuntuacionById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Puntuación no encontrada con ID: " + id));

        if (usuarioLogueado.getRol() == TipoRol.ROL_ESTUDIANTE) {
            if (!puntuacion.getAlumno().getId().equals(usuarioLogueado.getId())) {
                throw new ForbiddenException("No puedes ver la puntuación de otro alumno.");
            }
        } else {
            if (!puntuacion.getPrueba().getAula().getProfesor().getId().equals(usuarioLogueado.getId())) {
                throw new ForbiddenException("No puedes ver puntuaciones de un aula que no te pertenece.");
            }
        }

        return puntuacionMapper.toResponseDTO(puntuacion);
    }

    public List<PuntuacionResponseDTO> buscarPorAula(Long aulaId, Usuario usuarioLogueado) {
        Aula aula = aulaDAO.findById(aulaId)
                .orElseThrow(() -> new ResourceNotFoundException("Aula no encontrada"));

        if (!aula.getProfesor().getId().equals(usuarioLogueado.getId())) {
            throw new ForbiddenException("No puedes ver puntuaciones de un aula que no te pertenece.");
        }

        List<Puntuacion> puntuaciones = puntuacionDAO.findPuntuacionByPrueba_Aula_Id(aulaId);
        return puntuacionMapper.toResponseDTOList(puntuaciones);
    }

    @Transactional
    public PuntuacionResponseDTO crearPuntuacion(PuntuacionRequestDTO request, Usuario alumnoLogueado) {
        Prueba prueba = pruebaDAO.findById(request.getIdPrueba())
                .orElseThrow(() -> new ResourceNotFoundException("Prueba no encontrada"));

        Usuario alumnoCompleto = usuarioDAO.findById(alumnoLogueado.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Alumno no encontrado"));

        if (alumnoCompleto.getAula() == null || !alumnoCompleto.getAula().getId().equals(prueba.getAula().getId())) {
            throw new ForbiddenException("No puedes enviar puntuaciones a una prueba de un aula a la que no perteneces.");
        }

        Puntuacion nueva = new Puntuacion();
        nueva.setPuntosObtenidos(request.getPuntosObtenidos());
        nueva.setAlumno(alumnoCompleto);
        nueva.setPrueba(prueba);
        nueva.setFechaCompletado(Instant.now());
        alumnoCompleto.ganarExperiencia(request.getPuntosObtenidos());

        usuarioDAO.save(alumnoCompleto);
        Puntuacion guardada = puntuacionDAO.save(nueva);

        return puntuacionMapper.toResponseDTO(guardada);
    }

    @Transactional
    public void borrarPuntuacion(Long id, Usuario usuarioLogueado) {
        Puntuacion puntuacion = puntuacionDAO.findPuntuacionById(id)
                .orElseThrow(() -> new ResourceNotFoundException("No se puede borrar. Puntuación no encontrada."));

        if (!puntuacion.getPrueba().getAula().getProfesor().getId().equals(usuarioLogueado.getId())) {
            throw new ForbiddenException("No puedes borrar puntuaciones de un aula que no te pertenece.");
        }

        puntuacionDAO.delete(puntuacion);
    }
}