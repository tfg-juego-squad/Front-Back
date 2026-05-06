package org.example.backendapi.dto;

import lombok.Data;

import java.time.Instant;

@Data
public class PuntuacionResponseDTO {
    private String id;
    private Instant fechaCompletado;
    private Integer puntosObtenidos;
    private String nombreUsuario;
    private String tituloPrueba;
}
