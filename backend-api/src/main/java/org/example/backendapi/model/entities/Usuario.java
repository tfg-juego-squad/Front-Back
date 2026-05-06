package org.example.backendapi.model.entities;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.ColumnDefault;

import java.time.Instant;

@Data
@Entity
@Table(name = "usuarios")
public class Usuario {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, length = 36)
    private String id;

    @Column(name = "nombre_usuario", nullable = false, length = 50, unique = true)
    private String nombreUsuario;

    @Column(name = "hash_contrasena", nullable = false)
    private String hashContrasena;

    @Column(nullable = false)
    private Integer nivel = 1;

    @Column(nullable = false)
    private Integer experiencia = 0;

    @ColumnDefault("current_timestamp()")
    @Column(name = "fecha_creacion")
    private Instant fechaCreacion;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "aula_id")
    private Aula aula;

    @Enumerated(EnumType.STRING)
    @Column(name = "rol", nullable = false)
    private TipoRol rol;

    /**
     * Lógica RPG: Añade experiencia al usuario y calcula las subidas de nivel.
     */
    public void ganarExperiencia(int puntos) {
        if (this.rol == TipoRol.ROL_PROFESOR) {
            return;
        }

        this.experiencia += puntos;
        int xpRequeridaPorNivel = 100;

        if (this.experiencia >= xpRequeridaPorNivel) {
            int nivelesSubidos = this.experiencia / xpRequeridaPorNivel;
            this.nivel += nivelesSubidos;

            this.experiencia = this.experiencia % xpRequeridaPorNivel;
        }
    }
}