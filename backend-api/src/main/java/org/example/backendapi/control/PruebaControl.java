package org.example.backendapi.control;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.example.backendapi.dto.PruebaRequestDTO;
import org.example.backendapi.dto.PruebaResponseDTO;
import org.example.backendapi.model.entities.Usuario;
import org.example.backendapi.service.PruebaService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/tfg/pruebas")
@RequiredArgsConstructor
public class PruebaControl {

    private final PruebaService pruebaService;

    @PostMapping("/crear")
    public ResponseEntity<PruebaResponseDTO> crearPrueba(@Valid @RequestBody PruebaRequestDTO request) {
        PruebaResponseDTO response = pruebaService.crearPrueba(request);
        return new ResponseEntity<>(response, HttpStatus.CREATED);
    }

    @GetMapping("/aula/{aulaId}")
    public ResponseEntity<List<PruebaResponseDTO>> listarPorAula(@PathVariable Long aulaId) {
        return ResponseEntity.ok(pruebaService.obtenerPruebasPorAula(aulaId));
    }

    @GetMapping("/pendientes/{alumnoId}")
    public ResponseEntity<List<PruebaResponseDTO>> listarPruebasPendientes(
            @PathVariable Long alumnoId,
            @AuthenticationPrincipal Usuario usuarioLogueado) {
        return ResponseEntity.ok(pruebaService.obtenerPruebasPendientes(alumnoId, usuarioLogueado));
    }

    @PutMapping("/{pruebaId}")
    public ResponseEntity<PruebaResponseDTO> actualizarPrueba(
            @PathVariable Long pruebaId,
            @Valid @RequestBody PruebaRequestDTO request) {
        return ResponseEntity.ok(pruebaService.actualizarPrueba(pruebaId, request));
    }

    @DeleteMapping("/{pruebaId}")
    public ResponseEntity<Void> eliminarPrueba(@PathVariable Long pruebaId) {
        pruebaService.eliminarPrueba(pruebaId);
        return ResponseEntity.noContent().build();
    }
}