package org.example.backendapi.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class AulaRequestDTO {
    @NotBlank(message = "El nombre del aula es obligatorio")
    private String nombre;

    @NotBlank(message = "El ID del profesor es obligatorio")
    private Long profesorId;
}