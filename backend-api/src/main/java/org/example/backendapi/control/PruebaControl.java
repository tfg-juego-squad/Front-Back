package org.example.backendapi.control;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.example.backendapi.dto.PruebaRequestDTO;
import org.example.backendapi.dto.PruebaResponseDTO;
import org.example.backendapi.service.PruebaService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
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
    public ResponseEntity<List<PruebaResponseDTO>> listarPorAula(@PathVariable String aulaId) {
        return ResponseEntity.ok(pruebaService.obtenerPruebasPorAula(aulaId));
    }

    @PutMapping("/{pruebaId}")
    public ResponseEntity<PruebaResponseDTO> actualizarPrueba(
            @PathVariable String pruebaId,
            @Valid @RequestBody PruebaRequestDTO request) {
        return ResponseEntity.ok(pruebaService.actualizarPrueba(pruebaId, request));
    }

    @DeleteMapping("/{pruebaId}")
    public ResponseEntity<Void> eliminarPrueba(@PathVariable String pruebaId) {
        pruebaService.eliminarPrueba(pruebaId);
        return ResponseEntity.noContent().build();
    }
}