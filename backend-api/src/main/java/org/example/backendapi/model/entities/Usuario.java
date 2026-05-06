package org.example.backendapi.model.entities;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.ColumnDefault;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.time.Instant;
import java.util.Collection;
import java.util.List;

@Data
@Entity
@Table(name = "usuarios")
public class Usuario implements UserDetails {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    private Long id;

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

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        // Transformamos el enum TipoRol (ROL_PROFESOR o ROL_ESTUDIANTE)
        // en un objeto de autoridad que Spring Security entienda.
        return List.of(new SimpleGrantedAuthority(this.rol.name()));
    }

    @Override
    public String getPassword() {
        return this.hashContrasena;
    }

    @Override
    public String getUsername() {
        return this.nombreUsuario;
    }

    @Override
    public boolean isAccountNonExpired() { return true; }

    @Override
    public boolean isAccountNonLocked() { return true; }

    @Override
    public boolean isCredentialsNonExpired() { return true; }

    @Override
    public boolean isEnabled() { return true; }
}