package org.example.backendapi.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * Petición para que el profesor asigne una nota manual (puntos extra)
 * a un alumno sin necesidad de que exista una prueba completada.
 */
@Data
public class PuntuacionManualRequestDTO {

    @NotNull(message = "El ID del alumno es obligatorio")
    private Long alumnoId;

    @NotNull(message = "Los puntos son obligatorios")
    private Integer puntos;

    @Size(max = 250, message = "El motivo no puede superar 250 caracteres")
    private String motivo;
}
