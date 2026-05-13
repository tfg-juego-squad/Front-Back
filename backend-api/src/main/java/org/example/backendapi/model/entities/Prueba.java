package org.example.backendapi.model.entities;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.ColumnDefault;
import java.time.Instant;
import java.util.List;

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

    @OneToMany(mappedBy = "prueba", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Pregunta> preguntas;

    @ColumnDefault("current_timestamp()")
    @Column(name = "fecha_creacion")
    private Instant fechaCreacion;

    @Column(name = "fecha_limite", nullable = false)
    private Instant fechaLimite;

    @Column(name = "npc_id", length = 50)
    private String npcId;

    /** Diferencia ACTIVIDAD / EXAMEN / MINIJUEGO (Avanzado). */
    @Enumerated(EnumType.STRING)
    @Column(name = "tipo", length = 20)
    private TipoPrueba tipo = TipoPrueba.EXAMEN;

    /** Niveles del minijuego (solo aplica si tipo = MINIJUEGO). */
    @Column(name = "niveles_minijuego")
    private Integer nivelesMinijuego;

    /** Subtipo de minijuego cuando tipo = MINIJUEGO (ej. SECUENCIA, ESQUIVA). */
    @Column(name = "subtipo_minijuego", length = 20)
    private String subtipoMinijuego;

    /** Si la actividad cuenta para nota o es solo formativa. Default true. */
    @ColumnDefault("1")
    @Column(name = "evaluable", nullable = false)
    private Boolean evaluable = true;

    /** Texto fijo que el NPC dirá al alumno cuando tipo = DIALOGO. */
    @Column(name = "texto", columnDefinition = "TEXT")
    private String texto;

    /** Nivel mínimo del alumno para poder hacer la prueba. 1 = sin restricción. */
    @ColumnDefault("1")
    @Column(name = "nivel_minimo", nullable = false)
    private Integer nivelMinimo = 1;

    /** XP que recibe el alumno al completar esta prueba (independiente de la nota). */
    @ColumnDefault("10")
    @Column(name = "xp_recompensa", nullable = false)
    private Integer xpRecompensa = 10;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "aula_id", nullable = false)
    private Aula aula;
}