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
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.example.backendapi.model.entities.Usuario;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/tfg/aulas")
@RequiredArgsConstructor
public class AulaControl {

    private final AulaService aulaService;

    @GetMapping("/profesor/{profesorId}")
    @PreAuthorize("hasAuthority('ROL_PROFESOR')")
    public ResponseEntity<List<AulaResponseDTO>> getAulasByProfesor(
            @PathVariable Long profesorId,
            @AuthenticationPrincipal Usuario usuarioLogueado) {
        return ResponseEntity.ok(aulaService.obtenerAulasPorProfesor(profesorId, usuarioLogueado));
    }

    @GetMapping("/{aulaId}/alumnos")
    @PreAuthorize("hasAuthority('ROL_PROFESOR')")
    public ResponseEntity<List<UsuarioResponseDTO>> getAlumnosByAula(
            @PathVariable Long aulaId,
            @AuthenticationPrincipal Usuario usuarioLogueado) {
        return ResponseEntity.ok(aulaService.obtenerAlumnosPorAula(aulaId, usuarioLogueado));
    }

    @PostMapping("/crear")
    @PreAuthorize("hasAuthority('ROL_PROFESOR')")
    public ResponseEntity<AulaResponseDTO> crearAula(
            @Valid @RequestBody AulaRequestDTO request,
            @AuthenticationPrincipal Usuario usuarioLogueado) {
        AulaResponseDTO response = aulaService.crearAula(request, usuarioLogueado);
        return new ResponseEntity<>(response, HttpStatus.CREATED);
    }

    @PostMapping("/{aulaId}/generar-alumnos")
    @PreAuthorize("hasAuthority('ROL_PROFESOR')")
    public ResponseEntity<List<CredencialesResponseDTO>> generarAlumnos(
            @PathVariable Long aulaId,
            @Valid @RequestBody GenerarAlumnosRequestDTO request,
            @AuthenticationPrincipal Usuario usuarioLogueado) {
        return ResponseEntity.ok(aulaService.generarAlumnosParaAula(aulaId, request.getCantidad(), usuarioLogueado));
    }

    @PostMapping("/{aulaId}/importar-csv")
    @PreAuthorize("hasAuthority('ROL_PROFESOR')")
    public ResponseEntity<List<CredencialesResponseDTO>> importarAlumnosCSV(
            @PathVariable Long aulaId,
            @RequestParam("file") MultipartFile file,
            @AuthenticationPrincipal Usuario usuarioLogueado) {

        if (file.isEmpty() || file.getOriginalFilename() == null || !file.getOriginalFilename().endsWith(".csv")) {
            throw new BadRequestException("El archivo debe ser un CSV válido y no estar vacío.");
        }

        return ResponseEntity.ok(aulaService.importarAlumnosCSV(aulaId, file, usuarioLogueado));
    }
}