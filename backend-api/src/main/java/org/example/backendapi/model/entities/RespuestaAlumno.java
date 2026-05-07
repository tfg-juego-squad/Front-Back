package org.example.backendapi.model.entities;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.ColumnDefault;

import java.time.Instant;

@Data
@Entity
@Table(name = "respuestas_alumno")
public class RespuestaAlumno {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "alumno_id", nullable = false)
    private Usuario alumno;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "pregunta_id", nullable = false)
    private Pregunta pregunta;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "respuesta_elegida_id", nullable = true) // Null si no contestó a tiempo o es DESARROLLO
    private RespuestaPosible respuestaElegida;

    @Column(name = "texto_respuesta", columnDefinition = "TEXT")
    private String textoRespuesta;

    @Column(name = "tiempo_respuesta_segundos")
    private Integer tiempoRespuestaSegundos;

    @ColumnDefault("current_timestamp()")
    @Column(name = "fecha_respuesta")
    private Instant fechaRespuesta;
    
    @Column(name = "puntos_asignados")
    private Integer puntosAsignados; // Null hasta que se corrija (si es desarrollo) o calculado (si es test)
}
