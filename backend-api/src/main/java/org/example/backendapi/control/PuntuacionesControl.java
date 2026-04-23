package org.example.backendapi.control;

import org.example.backendapi.model.dao.IPuntuacionesDAO;
import org.example.backendapi.model.entities.Prueba;
import org.example.backendapi.model.entities.Puntuaciones;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@CrossOrigin("*")
@RequestMapping("/tfg/puntuaciones")
public class PuntuacionesControl {

    @Autowired
    IPuntuacionesDAO puntuacionesDAO;

    @GetMapping("/{id}")
    public ResponseEntity<Puntuaciones> buscarPuntuacionPorId(@PathVariable String id){
        Optional<Puntuaciones> puntuacion = puntuacionesDAO.findPuntuacionesById(id);
        if(puntuacion.isPresent()){
            return ResponseEntity.ok().body(puntuacion.get());
        }else{
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping("/prueba/{pruebaId}")
    public ResponseEntity<List<Puntuaciones>> buscarPuntuacionesPorPrueba(@PathVariable("pruebaId") Prueba prueba){
        List<Puntuaciones> listaPuntuaciones = puntuacionesDAO.findPuntuacionesByPrueba(prueba);
        if(!listaPuntuaciones.isEmpty()){
            return ResponseEntity.ok().body(listaPuntuaciones);
        }else{
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping("/prueba/titulo/{prueba_titulo}")
    public ResponseEntity<List<Puntuaciones>> buscarPuntuacionesPorTituloPrueba (@PathVariable("prueba_titulo") String tituloPrueba){
        List<Puntuaciones> listaPuntuaciones = puntuacionesDAO.findPuntuacionesByPrueba_Titulo(tituloPrueba);
        if(!listaPuntuaciones.isEmpty()){
            return ResponseEntity.ok().body(listaPuntuaciones);
        }else{
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping("/puntos/{puntos}")
    public ResponseEntity<List<Puntuaciones>> buscarPuntuacionesPorPuntos(@PathVariable int puntos){
        List<Puntuaciones> listaPuntuaciones = puntuacionesDAO.findPuntuacionesByPuntosObtenidos(puntos);
        if(!listaPuntuaciones.isEmpty()){
            return ResponseEntity.ok().body(listaPuntuaciones);
        }else{
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping("/aula/{aulaId}")
    public ResponseEntity<List<Puntuaciones>> buscarPuntuacionesPorAula(@PathVariable String aulaId){
        List<Puntuaciones> listaPuntuaciones = puntuacionesDAO.findPuntuacionesByPrueba_Aula_Id(aulaId);

        if (!listaPuntuaciones.isEmpty()) {
            return ResponseEntity.ok(listaPuntuaciones);
        } else {
            return ResponseEntity.noContent().build();
        }
    }

    @Validated
    @PostMapping("/alta")
    public Puntuaciones guardarPuntos(@Validated @RequestBody Puntuaciones puntuaciones){
        return puntuacionesDAO.save(puntuaciones);
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> actualizarPuntuaciones(@RequestBody Puntuaciones nuevasPuntuaciones,
                                                    @PathVariable String id) {
        Optional<Puntuaciones> puntuaciones = puntuacionesDAO.findById(id);
        if (puntuaciones.isPresent()) {
            puntuaciones.get().setPuntosObtenidos(nuevasPuntuaciones.getPuntosObtenidos());
            puntuaciones.get().setPrueba(nuevasPuntuaciones.getPrueba());
            puntuaciones.get().setFechaCompletado(nuevasPuntuaciones.getFechaCompletado());
            puntuacionesDAO.save(puntuaciones.get());
            return ResponseEntity.ok().body("Actualizado");
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> borrarPuntuaciones(@PathVariable String id) {
        Optional<Puntuaciones> puntuaciones = puntuacionesDAO.findPuntuacionesById(id);
        if(puntuaciones.isPresent()) {
            puntuacionesDAO.deleteById(id);
            return ResponseEntity.ok().body("Borrado");
        } else {
            return ResponseEntity.notFound().build();
        }
    }
}