package org.example.backendapi.control;

import org.example.backendapi.model.dao.IPruebaDAO;
import org.example.backendapi.model.entities.Prueba;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@CrossOrigin("*")
@RequestMapping("/tfg/pruebas")
public class PruebaControl {
    @Autowired
    IPruebaDAO pruebaDAO;

    @GetMapping("/{id}")
    public ResponseEntity<Prueba> buscarPruebaPorId(@PathVariable("id") String id){
        Optional<Prueba> prueba = pruebaDAO.findPruebaById(id);
        if(prueba.isPresent()){
            return ResponseEntity.ok().body(prueba.get());
        }else{
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping("/nombre/{nombre}")
    public ResponseEntity<List<Prueba>> buscarPruebaPorNombre(@PathVariable("nombre") String nombre){
        List<Prueba> listaPruebas = pruebaDAO.findPruebaByNombre(nombre);
        if(!listaPruebas.isEmpty()){
            return ResponseEntity.ok().body(listaPruebas);
        }else{
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping("/descripcion/{descripcion}")
    public ResponseEntity<List<Prueba>> buscarPruebaPorDescripcion(@PathVariable("descripcion") String descripcion){
        List<Prueba> listaPruebas = pruebaDAO.findPruebaByDescripcion(descripcion);
        if(!listaPruebas.isEmpty()){
            return ResponseEntity.ok().body(listaPruebas);
        }else{
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping("/puntuacion/{puntuacion}")
    public ResponseEntity<List<Prueba>> buscarPruebaPorPuntuacion(@PathVariable("puntuacion") String puntuacion){
        try {
            int puntuacionNumber = Integer.parseInt(puntuacion);
            List<Prueba> listaPruebas = pruebaDAO.findPruebaByPuntuacionMaxima(puntuacionNumber);
            if(!listaPruebas.isEmpty()){
                return ResponseEntity.ok().body(listaPruebas);
            }else {
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @Validated
    @PostMapping("/alta")
    public Prueba guardarPrueba(@Validated @RequestBody Prueba prueba){
        return pruebaDAO.save(prueba);
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> actualizarPrueba(@RequestBody Prueba nuevaPrueba,
                                                    @PathVariable("id") String id) {
        Optional<Prueba> prueba = pruebaDAO.findById(id);
        if (prueba.isPresent()) {
            prueba.get().setNombre(nuevaPrueba.getNombre());
            prueba.get().setDescripcion(nuevaPrueba.getDescripcion());
            prueba.get().setPuntuacionMaxima(nuevaPrueba.getPuntuacionMaxima());
            pruebaDAO.save(prueba.get());
            return ResponseEntity.ok().body("Actualizado");
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> borrarPrueba(@PathVariable("id") String id) {
        Optional<Prueba> prueba = pruebaDAO.findPruebaById(id);
        if(prueba.isPresent()) {
            pruebaDAO.deleteById(id);
            return ResponseEntity.ok().body("Borrado");
        } else {
            return ResponseEntity.notFound().build();
        }
    }
}
