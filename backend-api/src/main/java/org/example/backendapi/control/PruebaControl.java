package org.example.backendapi.control;

import org.example.backendapi.model.entities.Prueba;
import org.example.backendapi.model.entities.TipoPrueba;
import org.example.backendapi.service.PruebaService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/tfg/pruebas")
public class PruebaControl {

    @Autowired
    private PruebaService pruebaService;

    @PostMapping("/crear")
    public ResponseEntity<?> crearPrueba(@RequestBody Map<String, Object> payload) {
        try {
            String aulaId = (String) payload.get("aulaId");
            String titulo = (String) payload.get("titulo");
            TipoPrueba tipo = TipoPrueba.valueOf((String) payload.get("tipo"));
            String contenido = (String) payload.get("contenido");
            int puntuacionMaxima = (int) payload.get("puntuacionMaxima");

            Prueba nueva = pruebaService.crearPrueba(aulaId, titulo, tipo, contenido, puntuacionMaxima);
            return ResponseEntity.ok(nueva);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Error al crear la prueba: " + e.getMessage());
        }
    }

    @GetMapping("/aula/{aulaId}")
    public ResponseEntity<List<Prueba>> listarPorAula(@PathVariable String aulaId) {
        List<Prueba> pruebas = pruebaService.obtenerPruebasPorAula(aulaId);
        return ResponseEntity.ok(pruebas);
    }

    @PutMapping("/{pruebaId}")
    public ResponseEntity<?> actualizarPrueba(@PathVariable String pruebaId, @RequestBody Map<String, Object> payload) {
        try {
            String titulo = (String) payload.get("titulo");
            String contenido = (String) payload.get("contenido");
            int puntuacionMaxima = (int) payload.get("puntuacionMaxima");

            Prueba actualizada = pruebaService.actualizarPrueba(pruebaId, titulo, contenido, puntuacionMaxima);
            return ResponseEntity.ok(actualizada);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Error al actualizar: " + e.getMessage());
        }
    }

    @DeleteMapping("/{pruebaId}")
    public ResponseEntity<?> eliminarPrueba(@PathVariable String pruebaId) {
        try {
            pruebaService.eliminarPrueba(pruebaId);
            return ResponseEntity.ok().body("Prueba eliminada correctamente");
        } catch (Exception e) {
            return ResponseEntity.status(404).body(e.getMessage());
        }
    }
}