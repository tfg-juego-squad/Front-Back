package org.example.backendapi.dto;

import lombok.Data;

/**
 * Una fila de estadísticas de una pregunta dentro de una prueba.
 * El profesor la usa para ver cuáles preguntas se han saltado más.
 */
@Data
public class EstadisticaPreguntaDTO {
    private Long preguntaId;
    private String enunciado;
    private String tipo;
    /** Nº de alumnos que dejaron la pregunta sin responder (texto vacío y sin opción elegida). */
    private long saltadas;
    /** Nº de alumnos que sí respondieron. */
    private long contestadas;
    /** Suma de saltadas + contestadas (cuántos alumnos la han visto). */
    private long total;
}
