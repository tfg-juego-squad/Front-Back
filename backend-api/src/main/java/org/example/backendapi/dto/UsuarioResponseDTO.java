package org.example.backendapi.dto;

import lombok.Data;
import java.time.Instant;

@Data
public class UsuarioResponseDTO {
    private Long id;
    private String nombreUsuario;
    private String rol;
    private Instant fechaCreacion;
    private Long aulaId;
    private Integer nivelActual;
    private Integer experienciaActual;
}