package org.example.backendapi.dto;

import lombok.Data;
import java.time.Instant;

@Data
public class UsuarioResponseDTO {
    private String id;
    private String nombreUsuario;
    private String rol;
    private Instant fechaCreacion;
    private String aulaId;
}