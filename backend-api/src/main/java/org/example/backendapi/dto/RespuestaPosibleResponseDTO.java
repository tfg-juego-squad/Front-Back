package org.example.backendapi.dto;

import lombok.Data;

@Data
public class RespuestaPosibleResponseDTO {
    private Long id;
    private String texto;
    private Boolean esCorrecta; // Será ocultado (null) si lo pide un alumno
}
