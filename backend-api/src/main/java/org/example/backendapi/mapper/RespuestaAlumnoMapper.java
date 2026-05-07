package org.example.backendapi.mapper;

import org.example.backendapi.dto.RespuestaAlumnoResponseDTO;
import org.example.backendapi.model.entities.RespuestaAlumno;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingConstants;

import java.util.List;

@Mapper(componentModel = MappingConstants.ComponentModel.SPRING)
public interface RespuestaAlumnoMapper {
    @Mapping(source = "alumno.id", target = "alumnoId")
    @Mapping(source = "pregunta.id", target = "preguntaId")
    @Mapping(source = "respuestaElegida.id", target = "respuestaElegidaId")
    @Mapping(source = "puntosAsignados", target = "puntosAsignados")
    RespuestaAlumnoResponseDTO toResponseDTO(RespuestaAlumno respuesta);

    List<RespuestaAlumnoResponseDTO> toResponseDTOList(List<RespuestaAlumno> respuestas);
}
