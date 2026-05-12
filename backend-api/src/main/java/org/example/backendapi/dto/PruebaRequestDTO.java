package org.example.backendapi.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.time.Instant;

@Data
public class PruebaRequestDTO {

    @NotNull(message = "El ID del aula es obligatorio")
    private Long aulaId;

    @NotBlank(message = "El título de la prueba es obligatorio")
    private String titulo;

    @NotNull(message = "La fecha límite es obligatoria")
    private Instant fechaLimite;
}