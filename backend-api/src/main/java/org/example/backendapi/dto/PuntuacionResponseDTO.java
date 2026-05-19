package org.example.backendapi.dto;

import lombok.Data;

import java.time.Instant;

@Data
public class PuntuacionResponseDTO {
    private Long id;
    private Instant fechaCompletado;
    private Integer puntosObtenidos;
    private String nombreUsuario;
    private String nombreReal;
    private String apellidos;
    private String tituloPrueba;
    private Integer nivelActual;
    private Integer experienciaActual;
    private String motivo;
    private String tipoPrueba;
    private Long alumnoId;
    private Long pruebaId;
}
