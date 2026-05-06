package org.example.backendapi.control;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.example.backendapi.dto.PreguntaRequestDTO;
import org.example.backendapi.dto.PreguntaResponseDTO;
import org.example.backendapi.model.entities.Usuario;
import org.example.backendapi.service.PreguntaService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/tfg/preguntas")
@RequiredArgsConstructor
public class PreguntaControl {

    private final PreguntaService preguntaService;

    @PostMapping("/crear")
    @PreAuthorize("hasAuthority('ROL_PROFESOR')")
    public ResponseEntity<PreguntaResponseDTO> crearPregunta(
            @Valid @RequestBody PreguntaRequestDTO request,
            @AuthenticationPrincipal Usuario usuarioLogueado) {
        PreguntaResponseDTO response = preguntaService.crearPregunta(request, usuarioLogueado);
        return new ResponseEntity<>(response, HttpStatus.CREATED);
    }

    @GetMapping("/prueba/{pruebaId}")
    public ResponseEntity<List<PreguntaResponseDTO>> listarPreguntasPorPrueba(
            @PathVariable Long pruebaId,
            @AuthenticationPrincipal Usuario usuarioLogueado) {
        return ResponseEntity.ok(preguntaService.obtenerPreguntasPorPrueba(pruebaId, usuarioLogueado));
    }
    
    @DeleteMapping("/{preguntaId}")
    @PreAuthorize("hasAuthority('ROL_PROFESOR')")
    public ResponseEntity<Void> eliminarPregunta(
            @PathVariable Long preguntaId,
            @AuthenticationPrincipal Usuario usuarioLogueado) {
        preguntaService.eliminarPregunta(preguntaId, usuarioLogueado);
        return ResponseEntity.noContent().build();
    }
}
