package org.example.backendapi.mapper;

import org.example.backendapi.dto.PuntuacionResponseDTO;
import org.example.backendapi.model.entities.Puntuacion;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingConstants;

import java.util.List;

@Mapper(componentModel = MappingConstants.ComponentModel.SPRING)
public interface PuntuacionMapper {

    @Mapping(source = "alumno.nombreUsuario", target = "nombreUsuario")
    @Mapping(source = "alumno.id", target = "alumnoId")
    @Mapping(source = "prueba.titulo", target = "tituloPrueba")
    @Mapping(target = "tipoPrueba", expression = "java(puntuacion.getPrueba() != null && puntuacion.getPrueba().getTipo() != null ? puntuacion.getPrueba().getTipo().name() : null)")
    PuntuacionResponseDTO toResponseDTO(Puntuacion puntuacion);

    List<PuntuacionResponseDTO> toResponseDTOList(List<Puntuacion> puntuacion);
}