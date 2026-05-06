package org.example.backendapi.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class RespuestaAlumnoRequestDTO {
    @NotNull(message = "El ID de la pregunta es obligatorio")
    private Long preguntaId;

    private Long respuestaElegidaId; // Para tipo TEST
    private String textoRespuesta;   // Para tipo DESARROLLO

    @NotNull(message = "El tiempo de respuesta es obligatorio")
    private Integer tiempoRespuestaSegundos;
}
