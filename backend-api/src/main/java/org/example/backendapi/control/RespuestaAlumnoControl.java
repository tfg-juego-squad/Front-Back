package org.example.backendapi.control;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.example.backendapi.dto.CorregirRespuestaRequestDTO;
import org.example.backendapi.dto.RespuestaAlumnoRequestDTO;
import org.example.backendapi.dto.RespuestaAlumnoResponseDTO;
import org.example.backendapi.model.entities.Usuario;
import org.example.backendapi.service.RespuestaAlumnoService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/tfg/respuestas")
@RequiredArgsConstructor
public class RespuestaAlumnoControl {

    private final RespuestaAlumnoService respuestaAlumnoService;

    @PostMapping("/enviar")
    public ResponseEntity<RespuestaAlumnoResponseDTO> enviarRespuesta(
            @Valid @RequestBody RespuestaAlumnoRequestDTO request,
            @AuthenticationPrincipal Usuario usuarioLogueado) {
        RespuestaAlumnoResponseDTO response = respuestaAlumnoService.responderPregunta(request, usuarioLogueado);
        return new ResponseEntity<>(response, HttpStatus.CREATED);
    }

    @GetMapping("/prueba/{pruebaId}/alumno/{alumnoId}")
    public ResponseEntity<List<RespuestaAlumnoResponseDTO>> listarRespuestas(
            @PathVariable Long pruebaId,
            @PathVariable Long alumnoId,
            @AuthenticationPrincipal Usuario usuarioLogueado) {
        return ResponseEntity.ok(respuestaAlumnoService.obtenerRespuestasPorPruebaYAlumno(pruebaId, alumnoId, usuarioLogueado));
    }

    @GetMapping("/pendientes-correccion")
    public ResponseEntity<List<RespuestaAlumnoResponseDTO>> listarPendientes(
            @AuthenticationPrincipal Usuario usuarioLogueado) {
        return ResponseEntity.ok(respuestaAlumnoService.obtenerPendientesCorreccion(usuarioLogueado));
    }

    @PostMapping("/{respuestaId}/corregir")
    public ResponseEntity<RespuestaAlumnoResponseDTO> corregir(
            @PathVariable Long respuestaId,
            @Valid @RequestBody CorregirRespuestaRequestDTO request,
            @AuthenticationPrincipal Usuario usuarioLogueado) {
        return ResponseEntity.ok(respuestaAlumnoService.corregirRespuestaDesarrollo(respuestaId, request.getPuntos(), usuarioLogueado));
    }
}
