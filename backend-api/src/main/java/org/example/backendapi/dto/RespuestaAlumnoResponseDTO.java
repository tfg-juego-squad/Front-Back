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
}
