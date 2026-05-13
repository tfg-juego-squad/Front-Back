package org.example.backendapi.model.entities;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.ColumnDefault;

import java.time.Instant;

@Data
@Entity
@Table(name = "puntuaciones")
public class Puntuacion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    private Long id;

    @Column(name = "puntos_obtenidos", nullable = false)
    private Integer puntosObtenidos;

    @ColumnDefault("current_timestamp()")
    @Column(name = "fecha_completado")
    private Instant fechaCompletado;

    /** Texto libre del profesor para las notas manuales (opcional). */
    @Column(name = "motivo", length = 250)
    private String motivo;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "alumno_id", nullable = false)
    private Usuario alumno;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "prueba_id", nullable = false)
    private Prueba prueba;
}