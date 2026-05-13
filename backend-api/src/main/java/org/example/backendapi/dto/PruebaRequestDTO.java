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

    /** Identificador del NPC del mundo al que se asigna esta prueba.
     *  Opcional: si es null, la prueba aparece en el NPC general. */
    private String npcId;

    /** ACTIVIDAD / EXAMEN / MINIJUEGO. Por defecto EXAMEN si no se envía. */
    private String tipo;

    /** Solo para tipo = MINIJUEGO: nº de niveles del minijuego. */
    private Integer nivelesMinijuego;

    /** Subtipo de minijuego (SECUENCIA, ESQUIVA, ...). Opcional. */
    private String subtipoMinijuego;

    /** Si la actividad cuenta para nota. Default true. */
    private Boolean evaluable;

    /** Texto del NPC cuando tipo = DIALOGO. */
    private String texto;
}