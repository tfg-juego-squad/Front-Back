package org.example.backendapi.dto;

import lombok.Data;

@Data
public class AulaResponseDTO {
    private Long id;
    private String nombre;
    private String codigoInvitacion;
    private Long profesorId;
}