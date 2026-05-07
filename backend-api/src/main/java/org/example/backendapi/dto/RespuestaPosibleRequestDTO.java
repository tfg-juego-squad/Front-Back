package org.example.backendapi.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class RespuestaPosibleRequestDTO {
    @NotBlank(message = "El texto de la respuesta no puede estar vacío")
    private String texto;

    @NotNull(message = "Debe especificar si la respuesta es correcta o no")
    private Boolean esCorrecta;
}
