package org.example.backendapi.model.entities;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.ColumnDefault;

import java.time.Instant;

@Data
@Entity
@Table(name = "pruebas")
public class Prueba {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, length = 36)
    private String id;

    @Column(name = "titulo", nullable = false, length = 100)
    private String titulo;

    @Enumerated(EnumType.STRING)
    @Column(name = "tipo", nullable = false)
    private TipoPrueba tipo;

    @Column(name = "contenido", columnDefinition = "TEXT")
    private String contenido;

    @Column(name = "puntuacion_maxima", nullable = false)
    private Integer puntuacionMaxima;

    @ColumnDefault("current_timestamp()")
    @Column(name = "fecha_creacion")
    private Instant fechaCreacion;

    @JsonIgnore
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "aula_id", nullable = false)
    private Aula aula;
}