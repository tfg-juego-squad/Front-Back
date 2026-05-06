package org.example.backendapi.control;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.example.backendapi.dto.PruebaRequestDTO;
import org.example.backendapi.dto.PruebaResponseDTO;
import org.example.backendapi.model.entities.Usuario;
import org.example.backendapi.service.PruebaService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/tfg/pruebas")
@RequiredArgsConstructor
public class PruebaControl {

    private final PruebaService pruebaService;

    @PostMapping("/crear")
    @PreAuthorize("hasAuthority('ROL_PROFESOR')")
    public ResponseEntity<PruebaResponseDTO> crearPrueba(
            @Valid @RequestBody PruebaRequestDTO request,
            @AuthenticationPrincipal Usuario usuarioLogueado) {
        PruebaResponseDTO response = pruebaService.crearPrueba(request, usuarioLogueado);
        return new ResponseEntity<>(response, HttpStatus.CREATED);
    }

    @GetMapping("/aula/{aulaId}")
    public ResponseEntity<List<PruebaResponseDTO>> listarPorAula(
            @PathVariable Long aulaId,
            @AuthenticationPrincipal Usuario usuarioLogueado) {
        return ResponseEntity.ok(pruebaService.obtenerPruebasPorAula(aulaId, usuarioLogueado));
    }

    @GetMapping("/pendientes/{alumnoId}")
    public ResponseEntity<List<PruebaResponseDTO>> listarPruebasPendientes(
            @PathVariable Long alumnoId,
            @AuthenticationPrincipal Usuario usuarioLogueado) {
        return ResponseEntity.ok(pruebaService.obtenerPruebasPendientes(alumnoId, usuarioLogueado));
    }

    @PutMapping("/{pruebaId}")
    @PreAuthorize("hasAuthority('ROL_PROFESOR')")
    public ResponseEntity<PruebaResponseDTO> actualizarPrueba(
            @PathVariable Long pruebaId,
            @Valid @RequestBody PruebaRequestDTO request,
            @AuthenticationPrincipal Usuario usuarioLogueado) {
        return ResponseEntity.ok(pruebaService.actualizarPrueba(pruebaId, request, usuarioLogueado));
    }

    @DeleteMapping("/{pruebaId}")
    @PreAuthorize("hasAuthority('ROL_PROFESOR')")
    public ResponseEntity<Void> eliminarPrueba(
            @PathVariable Long pruebaId,
            @AuthenticationPrincipal Usuario usuarioLogueado) {
        pruebaService.eliminarPrueba(pruebaId, usuarioLogueado);
        return ResponseEntity.noContent().build();
    }
}