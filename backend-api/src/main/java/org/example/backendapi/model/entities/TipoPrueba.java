package org.example.backendapi.model.entities;

/**
 * Diferencia el tipo de Prueba que el profesor crea desde la pantalla de
 * "Nueva entrega". Permite que el cliente sepa qué pantalla abrir cuando
 * un alumno habla con el NPC correspondiente.
 */
public enum TipoPrueba {
    /** Actividad simple: solo título + adjunto, sin preguntas. */
    ACTIVIDAD,
    /** Examen tradicional: lista de preguntas con puntuación objetivo. */
    EXAMEN,
    /** Minijuego del NPC de Actividades: banco de preguntas + niveles. */
    MINIJUEGO,
    /** Contenedor sintético por aula para las notas manuales del profesor. */
    NOTA_MANUAL,
    /** NPC parlante: solo muestra un texto fijo al alumno, sin preguntas. */
    DIALOGO
}
