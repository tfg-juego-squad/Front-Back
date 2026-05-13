package org.example.backendapi.dto;

import lombok.Data;
import java.time.Instant;

@Data
public class PruebaResponseDTO {
    private Long id;
    private String titulo;
    private Instant fechaCreacion;
    private Instant fechaLimite;
    private Long aulaId;
    private String npcId;
    private String tipo;
    private Integer nivelesMinijuego;
    private String subtipoMinijuego;
    private Boolean evaluable;
    private String texto;
}