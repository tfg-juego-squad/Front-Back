package org.example.backendapi.dto;

import lombok.Data;
import java.time.Instant;

@Data
public class PruebaResponseDTO {
    private String id;
    private String titulo;
    private String tipo;
    private String contenido;
    private Integer puntuacionMaxima;
    private Instant fechaCreacion;
    private Instant fechaLimite;
    private String aulaId;
}