package org.example.backendapi.mapper;

import org.example.backendapi.dto.PreguntaResponseDTO;
import org.example.backendapi.model.entities.Pregunta;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingConstants;

import java.util.List;

@Mapper(componentModel = MappingConstants.ComponentModel.SPRING)
public interface PreguntaMapper {
    @Mapping(source = "prueba.id", target = "pruebaId")
    PreguntaResponseDTO toResponseDTO(Pregunta pregunta);

    List<PreguntaResponseDTO> toResponseDTOList(List<Pregunta> preguntas);
}
