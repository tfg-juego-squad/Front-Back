package org.example.backendapi.mapper;

import org.example.backendapi.dto.PruebaResponseDTO;
import org.example.backendapi.model.entities.Prueba;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingConstants;

import java.util.List;

@Mapper(componentModel = MappingConstants.ComponentModel.SPRING)
public interface PruebaMapper {
    @Mapping(source = "aula.id", target = "aulaId")
    PruebaResponseDTO toResponseDTO(Prueba prueba);

    List<PruebaResponseDTO> toResponseDTOList(List<Prueba> pruebas);
}