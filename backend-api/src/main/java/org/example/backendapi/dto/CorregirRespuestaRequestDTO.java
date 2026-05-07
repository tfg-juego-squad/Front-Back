package org.example.backendapi.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class CorregirRespuestaRequestDTO {
    @NotNull(message = "Los puntos son obligatorios")
    private Integer puntos;
}
