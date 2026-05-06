package org.example.backendapi.mapper;

import org.example.backendapi.dto.AulaResponseDTO;
import org.example.backendapi.model.entities.Aula;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingConstants;

import java.util.List;

@Mapper(componentModel = MappingConstants.ComponentModel.SPRING)
public interface AulaMapper {
    @Mapping(source = "profesor.id", target = "profesorId")
    AulaResponseDTO toResponseDTO(Aula aula);

    List<AulaResponseDTO> toResponseDTOList(List<Aula> aulas);
}