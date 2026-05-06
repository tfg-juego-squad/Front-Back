package org.example.backendapi.model.entities;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.ColumnDefault;

import java.time.Instant;

@Data
@Entity
@Table(name = "pruebas")
public class Prueba {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    private Long id;

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

    @Column(name = "fecha_limite", nullable = false)
    private Instant fechaLimite;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "aula_id", nullable = false)
    private Aula aula;
}