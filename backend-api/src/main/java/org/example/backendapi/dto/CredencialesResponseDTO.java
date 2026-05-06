package org.example.backendapi.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class CredencialesResponseDTO {
    private String alumnoReal; // null si es generado sin CSV
    private String usuario;
    private String password;
}