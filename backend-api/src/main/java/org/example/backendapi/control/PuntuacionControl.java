package org.example.backendapi.control;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.example.backendapi.dto.PuntuacionManualRequestDTO;
import org.example.backendapi.dto.PuntuacionRequestDTO;
import org.example.backendapi.dto.PuntuacionResponseDTO;
import org.example.backendapi.model.entities.Usuario;
import org.example.backendapi.service.PuntuacionService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/tfg/puntuacion")
@RequiredArgsConstructor
public class PuntuacionControl {

    private final PuntuacionService puntuacionService;

    @GetMapping("/{id}")
    public ResponseEntity<PuntuacionResponseDTO> buscarPuntuacionPorId(
            @PathVariable Long id,
            @AuthenticationPrincipal Usuario usuarioLogueado) {
        return ResponseEntity.ok(puntuacionService.buscarPorId(id, usuarioLogueado));
    }

    @GetMapping("/aula/{aulaId}")
    @PreAuthorize("hasAuthority('ROL_PROFESOR')")
    public ResponseEntity<List<PuntuacionResponseDTO>> buscarPuntuacionPorAula(
            @PathVariable Long aulaId,
            @AuthenticationPrincipal Usuario usuarioLogueado) {
        return ResponseEntity.ok(puntuacionService.buscarPorAula(aulaId, usuarioLogueado));
    }

    @PostMapping("/alta")
    public ResponseEntity<PuntuacionResponseDTO> guardarPuntos(
            @Valid @RequestBody PuntuacionRequestDTO request,
            @AuthenticationPrincipal Usuario alumnoLogueado) {
        PuntuacionResponseDTO response = puntuacionService.crearPuntuacion(request, alumnoLogueado);
        return new ResponseEntity<>(response, HttpStatus.CREATED);
    }

    @PostMapping("/manual")
    @PreAuthorize("hasAuthority('ROL_PROFESOR')")
    public ResponseEntity<PuntuacionResponseDTO> notaManual(
            @Valid @RequestBody PuntuacionManualRequestDTO request,
            @AuthenticationPrincipal Usuario usuarioLogueado) {
        PuntuacionResponseDTO response = puntuacionService.crearPuntuacionManual(request, usuarioLogueado);
        return new ResponseEntity<>(response, HttpStatus.CREATED);
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAuthority('ROL_PROFESOR')")
    public ResponseEntity<Void> borrarPuntuacion(
            @PathVariable Long id,
            @AuthenticationPrincipal Usuario usuarioLogueado) {
        puntuacionService.borrarPuntuacion(id, usuarioLogueado);
        return ResponseEntity.noContent().build();
    }
}