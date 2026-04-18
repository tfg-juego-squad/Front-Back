package org.example.backendapi.model.entities;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.ColumnDefault;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import java.time.Instant;

@Data
@Entity
@Table(name = "puntuaciones")
public class Puntuaciones {
    @Id
    @Column(name = "id", nullable = false, length = 36)
    private String id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @OnDelete(action = OnDeleteAction.CASCADE)
    @JoinColumn(name = "prueba_id", nullable = false)
    private Prueba prueba;

    @Column(name = "puntos_obtenidos", nullable = false)
    private Integer puntosObtenidos;

    @ColumnDefault("current_timestamp()")
    @Column(name = "fecha_completado")
    private Instant fechaCompletado;
}