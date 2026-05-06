package org.example.backendapi.model.entities;

import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(name = "respuestas_posibles")
public class RespuestaPosible {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    private Long id;

    @Column(name = "texto", nullable = false)
    private String texto;

    @Column(name = "es_correcta", nullable = false)
    private Boolean esCorrecta;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "pregunta_id", nullable = false)
    private Pregunta pregunta;
}
