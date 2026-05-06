package org.example.backendapi.dto;

import lombok.Data;
import java.time.Instant;

@Data
public class UsuarioResponseDTO {
    private Long id;
    private String nombreUsuario;
    private String nombreReal;
    private String apellidos;
    private String email;
    private String rol;
    private String token;
    private Instant fechaCreacion;
    private Long aulaId;
    private Integer nivelActual;
    private Integer experienciaActual;
}