package org.example.backendapi.control;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.example.backendapi.dto.PuntuacionRequestDTO;
import org.example.backendapi.dto.PuntuacionResponseDTO;
import org.example.backendapi.model.entities.Usuario;
import org.example.backendapi.service.PuntuacionService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/tfg/puntuacion")
@RequiredArgsConstructor
public class PuntuacionControl {

    private final PuntuacionService puntuacionService;

    @GetMapping("/{id}")
    public ResponseEntity<PuntuacionResponseDTO> buscarPuntuacionPorId(@PathVariable Long id) {
        return ResponseEntity.ok(puntuacionService.buscarPorId(id));
    }

    @GetMapping("/aula/{aulaId}")
    public ResponseEntity<List<PuntuacionResponseDTO>> buscarPuntuacionPorAula(@PathVariable Long aulaId) {
        return ResponseEntity.ok(puntuacionService.buscarPorAula(aulaId));
    }

    @PostMapping("/alta")
    public ResponseEntity<PuntuacionResponseDTO> guardarPuntos(
            @Valid @RequestBody PuntuacionRequestDTO request,
            @AuthenticationPrincipal Usuario alumnoLogueado) {
        PuntuacionResponseDTO response = puntuacionService.crearPuntuacion(request, alumnoLogueado);
        return new ResponseEntity<>(response, HttpStatus.CREATED);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> borrarPuntuacion(@PathVariable Long id) {
        puntuacionService.borrarPuntuacion(id);
        return ResponseEntity.noContent().build();
    }
}