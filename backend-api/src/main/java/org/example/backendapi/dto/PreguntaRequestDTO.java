package org.example.backendapi.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.List;

@Data
public class PreguntaRequestDTO {
    @NotBlank(message = "El enunciado no puede estar vacío")
    private String enunciado;

    @NotBlank(message = "El tipo de pregunta es obligatorio (TEST o DESARROLLO)")
    private String tipo;

    private Integer tiempoLimiteSegundos = 30;

    @NotNull(message = "La pregunta debe pertenecer a una prueba")
    private Long pruebaId;

    @Valid
    private List<RespuestaPosibleRequestDTO> respuestasPosibles;
}
