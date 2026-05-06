package org.example.backendapi.dto;

import lombok.Data;

@Data
public class AulaResponseDTO {
    private Integer id;
    private String nombre;
    private String codigoInvitacion;
    private Integer profesorId;
}