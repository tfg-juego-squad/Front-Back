package org.example.backendapi.dto;

import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * Payload para actualizar parcialmente los datos de un usuario.
 * Todos los campos son opcionales: solo se aplican los que vengan no-null.
 * Sirve tanto para editar perfil como para resetear contraseña.
 */
@Data
public class UsuarioUpdateRequestDTO {

    @Size(min = 3, max = 50, message = "El nombre de usuario debe tener entre 3 y 50 caracteres")
    private String nombreUsuario;

    private String nombreReal;
    private String apellidos;
    private String email;

    @Size(min = 6, message = "La contraseña debe tener al menos 6 caracteres")
    private String passwordPlana;
}
