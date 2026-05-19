package org.example.backendapi.dto;

import lombok.Data;

import java.time.Instant;

@Data
public class RespuestaAlumnoResponseDTO {
    private Long id;
    private Long alumnoId;
    private Long preguntaId;
    private Long respuestaElegidaId;
    private String textoRespuesta;
    private Integer tiempoRespuestaSegundos;
    private Instant fechaRespuesta;
    private Integer puntosAsignados;

    // Datos derivados para que la pantalla de corrección no tenga que hacer
    // peticiones extra por cada respuesta pendiente (alumno + pregunta + prueba).
    private String nombreUsuario;
    private String enunciadoPregunta;
    private Integer valorPuntosPregunta;
    private String tituloPrueba;
}
