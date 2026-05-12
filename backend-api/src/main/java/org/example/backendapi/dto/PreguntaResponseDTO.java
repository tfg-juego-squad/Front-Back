package org.example.backendapi.dto;

import lombok.Data;
import java.util.List;

@Data
public class PreguntaResponseDTO {
    private Long id;
    private String enunciado;
    private String tipo;
    private Integer tiempoLimiteSegundos;
    private Integer valorPuntos;
    private Long pruebaId;
    private List<RespuestaPosibleResponseDTO> respuestasPosibles;
}
