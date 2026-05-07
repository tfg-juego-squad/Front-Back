package org.example.backendapi.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class PuntuacionRequestDTO {
    @NotNull(message = "El ID de la prueba es obligatorio")
    private Long idPrueba;
}
