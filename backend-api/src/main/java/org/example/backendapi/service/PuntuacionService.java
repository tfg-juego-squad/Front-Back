package org.example.backendapi.service;

import lombok.RequiredArgsConstructor;
import org.example.backendapi.dto.PuntuacionRequestDTO;
import org.example.backendapi.dto.PuntuacionResponseDTO;
import org.example.backendapi.exception.ResourceNotFoundException;
import org.example.backendapi.exception.ForbiddenException;
import org.example.backendapi.mapper.PuntuacionMapper;
import org.example.backendapi.model.dao.*;
import org.example.backendapi.model.entities.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;

/**
 * Servicio encargado de gestionar las Puntuaciones globales (las notas de los exámenes terminados).
 * Cuando un alumno termina un examen, este servicio consolida sus puntos basándose en las
 * respuestas guardadas, lo que previene cualquier intento de falsificar la nota.
 */
@Service
@RequiredArgsConstructor
public class PuntuacionService {

    private final IPuntuacionDAO puntuacionDAO;
    private final IUsuarioDAO usuarioDAO;
    private final IPruebaDAO pruebaDAO;
    private final IAulaDAO aulaDAO;
    private final IRespuestaAlumnoDAO respuestaAlumnoDAO;
    private final PuntuacionMapper puntuacionMapper;

    /**
     * Busca una puntuación global por su ID.
     * Seguridad: Un alumno solo puede ver su propia nota final. El profesor solo las de su aula.
     */
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

    /**
     * Obtiene el listado de todas las notas finales de un aula (pensado para el boletín del profesor).
     */
    public List<PuntuacionResponseDTO> buscarPorAula(Long aulaId, Usuario usuarioLogueado) {
        Aula aula = aulaDAO.findById(aulaId)
                .orElseThrow(() -> new ResourceNotFoundException("Aula no encontrada"));

        if (!aula.getProfesor().getId().equals(usuarioLogueado.getId())) {
            throw new ForbiddenException("No puedes ver puntuaciones de un aula que no te pertenece.");
        }

        List<Puntuacion> puntuaciones = puntuacionDAO.findPuntuacionByPrueba_Aula_Id(aulaId);
        return puntuacionMapper.toResponseDTOList(puntuaciones);
    }

    /**
     * Registra la finalización de un examen por parte del alumno.
     * En lugar de creer la nota que envíe el cliente, el backend suma de nuevo
     * todos los puntos obtenidos de las respuestas de ese examen.
     */
    @Transactional
    public PuntuacionResponseDTO crearPuntuacion(PuntuacionRequestDTO request, Usuario alumnoLogueado) {
        Prueba prueba = pruebaDAO.findById(request.getIdPrueba())
                .orElseThrow(() -> new ResourceNotFoundException("Prueba no encontrada"));

        Usuario alumnoCompleto = usuarioDAO.findById(alumnoLogueado.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Alumno no encontrado"));

        if (alumnoCompleto.getAula() == null || !alumnoCompleto.getAula().getId().equals(prueba.getAula().getId())) {
            throw new ForbiddenException("No puedes enviar puntuaciones a una prueba de un aula a la que no perteneces.");
        }

        List<RespuestaAlumno> respuestas = 
                respuestaAlumnoDAO.findByPregunta_Prueba_IdAndAlumno_Id(prueba.getId(), alumnoCompleto.getId());

        // Sumamos los puntos asignados a cada respuesta individual.
        // Los de TEST ya se auto-calcularon en el servidor, y los de DESARROLLO estarán a 0 o con la nota del profesor.
        int puntosCalculados = respuestas.stream()
                .mapToInt(respuesta -> respuesta.getPuntosAsignados() != null ? respuesta.getPuntosAsignados() : 0)
                .sum();

        Puntuacion nueva = new Puntuacion();
        nueva.setPuntosObtenidos(puntosCalculados);
        nueva.setAlumno(alumnoCompleto);
        nueva.setPrueba(prueba);
        nueva.setFechaCompletado(Instant.now());
        
        // El alumno gana experiencia base para subir de nivel
        alumnoCompleto.ganarExperiencia(puntosCalculados);

        usuarioDAO.save(alumnoCompleto);
        Puntuacion guardada = puntuacionDAO.save(nueva);

        return puntuacionMapper.toResponseDTO(guardada);
    }

    /**
     * Da de alta una nota manual del profesor a un alumno: no necesita una
     * prueba previa. Internamente reutilizamos un Prueba sintético por aula
     * marcado como TipoPrueba.NOTA_MANUAL para no romper la FK NOT NULL.
     */
    @Transactional
    public PuntuacionResponseDTO crearPuntuacionManual(
            org.example.backendapi.dto.PuntuacionManualRequestDTO request,
            Usuario usuarioLogueado) {
        if (usuarioLogueado.getRol() != TipoRol.ROL_PROFESOR) {
            throw new ForbiddenException("Solo el profesor puede asignar notas manuales.");
        }
        Usuario alumno = usuarioDAO.findById(request.getAlumnoId())
                .orElseThrow(() -> new ResourceNotFoundException("Alumno no encontrado"));
        if (alumno.getAula() == null) {
            throw new org.example.backendapi.exception.BadRequestException(
                    "El alumno no está asignado a un aula");
        }
        Aula aula = alumno.getAula();
        if (!aula.getProfesor().getId().equals(usuarioLogueado.getId())) {
            throw new ForbiddenException("Ese alumno no pertenece a tu aula.");
        }

        Prueba contenedor = obtenerOCrearContenedorNotaManual(aula);

        int puntos = request.getPuntos() == null ? 0 : request.getPuntos();
        Puntuacion nueva = new Puntuacion();
        nueva.setAlumno(alumno);
        nueva.setPrueba(contenedor);
        nueva.setPuntosObtenidos(puntos);
        nueva.setMotivo(request.getMotivo());
        nueva.setFechaCompletado(Instant.now());

        if (puntos > 0) {
            alumno.ganarExperiencia(puntos);
            usuarioDAO.save(alumno);
        }
        Puntuacion guardada = puntuacionDAO.save(nueva);
        return puntuacionMapper.toResponseDTO(guardada);
    }

    /**
     * Devuelve (creándola si hace falta) la Prueba contenedora de notas
     * manuales para un aula. Es una entidad sintética que no se ve en la
     * pantalla del alumno porque no genera pendientes.
     */
    private Prueba obtenerOCrearContenedorNotaManual(Aula aula) {
        return pruebaDAO.findByAula_Id(aula.getId()).stream()
                .filter(p -> p.getTipo() == TipoPrueba.NOTA_MANUAL)
                .findFirst()
                .orElseGet(() -> {
                    Prueba p = new Prueba();
                    p.setAula(aula);
                    p.setTitulo("Nota manual");
                    p.setFechaCreacion(Instant.now());
                    // Fecha límite remota para que nunca aparezca como pendiente.
                    p.setFechaLimite(Instant.now().plusSeconds(60L * 60 * 24 * 365 * 10));
                    p.setTipo(TipoPrueba.NOTA_MANUAL);
                    return pruebaDAO.save(p);
                });
    }

    /**
     * Borra la nota de un alumno. Principalmente para casos excepcionales del profesor.
     */
    @Transactional
    public void borrarPuntuacion(Long id, Usuario usuarioLogueado) {
        Puntuacion puntuacion = puntuacionDAO.findPuntuacionById(id)
                .orElseThrow(() -> new ResourceNotFoundException("No se puede borrar. Puntuación no encontrada."));

        if (!puntuacion.getPrueba().getAula().getProfesor().getId().equals(usuarioLogueado.getId())) {
            throw new ForbiddenException("No puedes borrar puntuaciones de un aula que no te pertenece.");
        }

        puntuacionDAO.delete(puntuacion);
    }

    /**
     * Disparador que se llama cuando un profesor corrige manualmente una pregunta de DESARROLLO.
     * Busca la Puntuación final y la actualiza con los nuevos puntos, re-calculando la experiencia total del alumno.
     */
    @Transactional
    public void actualizarPuntuacionTotal(Long alumnoId, Long pruebaId) {
        // Buscamos la puntuación existente para esa prueba y alumno
        puntuacionDAO.findPuntuacionByPrueba_IdAndAlumno_Id(pruebaId, alumnoId).ifPresent(puntuacion -> {
            List<RespuestaAlumno> respuestas = respuestaAlumnoDAO.findByPregunta_Prueba_IdAndAlumno_Id(pruebaId, alumnoId);
            
            // Volvemos a sumar todas las notas (incluyendo la recién corregida por el profesor)
            int nuevaPuntuacion = respuestas.stream()
                    .mapToInt(respuesta -> respuesta.getPuntosAsignados() != null ? respuesta.getPuntosAsignados() : 0)
                    .sum();
            
            // Si la puntuación ha cambiado, la actualizamos y ajustamos la experiencia del alumno
            if (puntuacion.getPuntosObtenidos() != nuevaPuntuacion) {
                int diferencia = nuevaPuntuacion - puntuacion.getPuntosObtenidos(); // Ej: antes 10, ahora 15, dif = +5
                puntuacion.setPuntosObtenidos(nuevaPuntuacion);
                puntuacion.getAlumno().ganarExperiencia(diferencia);
                
                puntuacionDAO.save(puntuacion);
                usuarioDAO.save(puntuacion.getAlumno());
            }
        });
    }
}