package org.example.backendapi.mapper;

import org.example.backendapi.dto.RespuestaPosibleResponseDTO;
import org.example.backendapi.model.entities.RespuestaPosible;
import org.mapstruct.Mapper;
import org.mapstruct.MappingConstants;

import java.util.List;

@Mapper(componentModel = MappingConstants.ComponentModel.SPRING)
public interface RespuestaPosibleMapper {
    RespuestaPosibleResponseDTO toResponseDTO(RespuestaPosible respuesta);
    List<RespuestaPosibleResponseDTO> toResponseDTOList(List<RespuestaPosible> respuestas);
}
