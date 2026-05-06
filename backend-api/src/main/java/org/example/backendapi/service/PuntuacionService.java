package org.example.backendapi.service;

import lombok.RequiredArgsConstructor;
import org.example.backendapi.dto.PuntuacionRequestDTO;
import org.example.backendapi.dto.PuntuacionResponseDTO;
import org.example.backendapi.exception.ResourceNotFoundException;
import org.example.backendapi.mapper.PuntuacionMapper;
import org.example.backendapi.model.dao.IPruebaDAO;
import org.example.backendapi.model.dao.IPuntuacionDAO;
import org.example.backendapi.model.dao.IUsuarioDAO;
import org.example.backendapi.model.entities.Prueba;
import org.example.backendapi.model.entities.Puntuacion;
import org.example.backendapi.model.entities.Usuario;
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
    private final PuntuacionMapper puntuacionMapper;

    public PuntuacionResponseDTO buscarPorId(String id) {
        return puntuacionDAO.findPuntuacionById(id)
                .map(puntuacionMapper::toResponseDTO)
                .orElseThrow(() -> new ResourceNotFoundException("Puntuación no encontrada con ID: " + id));
    }

    public List<PuntuacionResponseDTO> buscarPorAula(String aulaId) {
        List<Puntuacion> puntuaciones = puntuacionDAO.findPuntuacionByPrueba_Aula_Id(aulaId);
        return puntuacionMapper.toResponseDTOList(puntuaciones);
    }

    @Transactional
    public PuntuacionResponseDTO crearPuntuacion(PuntuacionRequestDTO request) {
        Usuario alumno = usuarioDAO.findById(request.getIdAlumno())
                .orElseThrow(() -> new ResourceNotFoundException("Alumno no encontrado"));

        Prueba prueba = pruebaDAO.findById(request.getIdPrueba())
                .orElseThrow(() -> new ResourceNotFoundException("Prueba no encontrada"));

        Puntuacion nueva = new Puntuacion();
        nueva.setPuntosObtenidos(request.getPuntosObtenidos());
        nueva.setAlumno(alumno);
        nueva.setPrueba(prueba);
        nueva.setFechaCompletado(Instant.now());
        alumno.ganarExperiencia(request.getPuntosObtenidos());

        usuarioDAO.save(alumno);
        Puntuacion guardada = puntuacionDAO.save(nueva);

        return puntuacionMapper.toResponseDTO(guardada);
    }

    @Transactional
    public void borrarPuntuacion(String id) {
        if (!puntuacionDAO.existsById(id)) {
            throw new ResourceNotFoundException("No se puede borrar. Puntuación no encontrada.");
        }
        puntuacionDAO.deleteById(id);
    }
}