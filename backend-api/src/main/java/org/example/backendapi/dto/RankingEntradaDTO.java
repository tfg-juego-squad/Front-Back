package org.example.backendapi.dto;

import lombok.Data;

/**
 * Una fila del ranking del aula. Empates comparten posición (1, 2, 2, 4).
 */
@Data
public class RankingEntradaDTO {
    private Integer posicion;
    private Long alumnoId;
    private String nombreUsuario;
    private String nombreReal;
    private Integer puntos;
    private Integer nivel;
    /** True si esta fila corresponde al alumno que hizo la petición. */
    private boolean esTuyo;
}
