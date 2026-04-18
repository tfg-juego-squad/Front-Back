package org.example.backendapi.model.entities;

import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(name = "pruebas")
public class Prueba {
    @Id
    @Column(name = "id", nullable = false, length = 36)
    private String id;

    @Column(name = "nombre", nullable = false, length = 100)
    private String nombre;

    @Lob
    @Column(name = "descripcion")
    private String descripcion;

    @Column(name = "puntuacion_maxima", nullable = false)
    private Integer puntuacionMaxima;
}