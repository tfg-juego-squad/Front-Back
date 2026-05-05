package org.example.backendapi.mapper;

import org.example.backendapi.dto.UsuarioResponseDTO;
import org.example.backendapi.model.entities.Usuario;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingConstants;

import java.util.List;

@Mapper(componentModel = MappingConstants.ComponentModel.SPRING)
public interface UsuarioMapper {
    @Mapping(source = "aula.id", target = "aulaId")
    UsuarioResponseDTO toResponseDTO(Usuario usuario);

    List<UsuarioResponseDTO> toResponseDTOList(List<Usuario> usuarios);
}
