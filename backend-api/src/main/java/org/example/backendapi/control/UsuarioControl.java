package org.example.backendapi.control;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.example.backendapi.dto.UsuarioLoginRequestDTO;
import org.example.backendapi.dto.UsuarioRegistroRequestDTO;
import org.example.backendapi.dto.UsuarioResponseDTO;
import org.example.backendapi.dto.UsuarioUpdateRequestDTO;
import org.example.backendapi.service.UsuarioService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.example.backendapi.model.entities.Usuario;

import java.util.List;

@RestController
@RequestMapping("/tfg/usuarios")
@RequiredArgsConstructor
public class UsuarioControl {

    private final UsuarioService usuarioService;

    @GetMapping("/{id}")
    public ResponseEntity<UsuarioResponseDTO> buscarUsuarioPorId(
            @PathVariable Long id,
            @AuthenticationPrincipal Usuario usuarioLogueado) {
        UsuarioResponseDTO response = usuarioService.buscarUsuarioPorId(id, usuarioLogueado);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/nombre/{nombre}")
    public ResponseEntity<List<UsuarioResponseDTO>> buscarUsuariosPorNombre(
            @PathVariable String nombre,
            @AuthenticationPrincipal Usuario usuarioLogueado) {
        List<UsuarioResponseDTO> response = usuarioService.buscarUsuariosPorNombre(nombre, usuarioLogueado);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/profesor/alta")
    public ResponseEntity<?> registrarProfesor(@Valid @RequestBody UsuarioRegistroRequestDTO request){
        UsuarioResponseDTO response = usuarioService.registrarProfesor(request);
        return new ResponseEntity<>(response, HttpStatus.CREATED);
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@Valid @RequestBody UsuarioLoginRequestDTO request) {
        UsuarioResponseDTO response = usuarioService.hacerLogin(request);
        return ResponseEntity.ok(response);
    }

    @PutMapping("/{id}")
    public ResponseEntity<UsuarioResponseDTO> actualizarUsuario(
            @PathVariable Long id,
            @Valid @RequestBody UsuarioUpdateRequestDTO request,
            @AuthenticationPrincipal Usuario usuarioLogueado) {
        UsuarioResponseDTO response = usuarioService.actualizarUsuario(id, request, usuarioLogueado);
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> borrarUsuario (@PathVariable Long id, @AuthenticationPrincipal Usuario usuarioLogueado) {
        usuarioService.borrarUsuario(id, usuarioLogueado);
        return ResponseEntity.noContent().build();
    }
}
