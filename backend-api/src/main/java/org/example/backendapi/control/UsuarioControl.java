package org.example.backendapi.control;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.example.backendapi.dto.UsuarioLoginRequestDTO;
import org.example.backendapi.dto.UsuarioRegistroRequestDTO;
import org.example.backendapi.dto.UsuarioResponseDTO;
import org.example.backendapi.service.UsuarioService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/tfg/usuarios")
@RequiredArgsConstructor
public class UsuarioControl {

    private final UsuarioService usuarioService;

    @GetMapping("/{id}")
    public ResponseEntity<UsuarioResponseDTO> buscarUsuarioPorId(@PathVariable String id) {
        UsuarioResponseDTO response = usuarioService.buscarUsuarioPorId(id);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/nombre/{nombre}")
    public ResponseEntity<List<UsuarioResponseDTO>> buscarUsuariosPorNombre(@PathVariable String nombre) {
        List<UsuarioResponseDTO> response = usuarioService.buscarUsuariosPorNombre(nombre);
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

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> borrarUsuario (@PathVariable String id) {
        usuarioService.borrarUsuario(id);
        return ResponseEntity.noContent().build();
    }
}
