package org.example.backendapi.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class PuntuacionRequestDTO {
    @NotNull(message = "Los puntos obtenidos son obligatorios")
    private Integer puntosObtenidos;

    @NotBlank(message = "El ID del alumno es obligatorio")
    private Long idAlumno;

    @NotBlank(message = "El ID de la prueba es obligatorio")
    private Long idPrueba;
}
