package org.example.backendapi.control;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.example.backendapi.dto.AulaRequestDTO;
import org.example.backendapi.dto.AulaResponseDTO;
import org.example.backendapi.dto.CredencialesResponseDTO;
import org.example.backendapi.dto.GenerarAlumnosRequestDTO;
import org.example.backendapi.dto.UsuarioResponseDTO;
import org.example.backendapi.exception.BadRequestException;
import org.example.backendapi.service.AulaService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/tfg/aulas")
@RequiredArgsConstructor
public class AulaControl {

    private final AulaService aulaService;

    @GetMapping("/profesor/{profesorId}")
    public ResponseEntity<List<AulaResponseDTO>> getAulasByProfesor(@PathVariable Integer profesorId) {
        return ResponseEntity.ok(aulaService.obtenerAulasPorProfesor(profesorId));
    }

    @GetMapping("/{aulaId}/alumnos")
    public ResponseEntity<List<UsuarioResponseDTO>> getAlumnosByAula(@PathVariable Integer aulaId) {
        return ResponseEntity.ok(aulaService.obtenerAlumnosPorAula(aulaId));
    }

    @PostMapping("/crear")
    public ResponseEntity<AulaResponseDTO> crearAula(@Valid @RequestBody AulaRequestDTO request) {
        AulaResponseDTO response = aulaService.crearAula(request);
        return new ResponseEntity<>(response, HttpStatus.CREATED);
    }

    @PostMapping("/{aulaId}/generar-alumnos")
    public ResponseEntity<List<CredencialesResponseDTO>> generarAlumnos(
            @PathVariable Integer aulaId,
            @Valid @RequestBody GenerarAlumnosRequestDTO request) {
        return ResponseEntity.ok(aulaService.generarAlumnosParaAula(aulaId, request.getCantidad()));
    }

    @PostMapping("/{aulaId}/importar-csv")
    public ResponseEntity<List<CredencialesResponseDTO>> importarAlumnosCSV(
            @PathVariable Integer aulaId,
            @RequestParam("file") MultipartFile file) {

        if (file.isEmpty() || file.getOriginalFilename() == null || !file.getOriginalFilename().endsWith(".csv")) {
            throw new BadRequestException("El archivo debe ser un CSV válido y no estar vacío.");
        }

        return ResponseEntity.ok(aulaService.importarAlumnosCSV(aulaId, file));
    }
}