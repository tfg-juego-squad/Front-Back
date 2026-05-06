package org.example.backendapi.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class GenerarAlumnosRequestDTO {
    @NotNull(message = "La cantidad es obligatoria")
    @Min(value = 1, message = "Debe generar al menos 1 alumno")
    private Integer cantidad;
}