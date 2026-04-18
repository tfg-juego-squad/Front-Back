package org.example.backendapi.service;

import jakarta.transaction.Transactional;
import org.example.backendapi.model.dao.IAulaDAO;
import org.example.backendapi.model.dao.IUsuarioDAO;
import org.example.backendapi.model.entities.Aula;
import org.example.backendapi.model.entities.TipoRol;
import org.example.backendapi.model.entities.Usuario;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.*;

@Service
public class AulaService {

    @Autowired
    private IAulaDAO aulaDAO;

    @Autowired
    private IUsuarioDAO usuarioDAO;

    @Autowired
    private SecurityService securityService;

    public Aula crearAula(String nombreAula, String profesorId) {
        Usuario profesor = usuarioDAO.findUsuarioById(profesorId).orElseThrow(() -> new RuntimeException("Error: Profesor no encontrado"));

        Aula aula = new Aula();
        aula.setNombre(nombreAula);
        aula.setProfesor(profesor);

        aula.setCodigoInvitacion(UUID.randomUUID().toString().substring(0, 5).toUpperCase());

        return aulaDAO.save(aula);
    }

    @Transactional
    public List<Map<String, String>> generarAlumnosParaAula(String aulaId, int cantidad) {
        Aula aula = aulaDAO.findAulaById(aulaId).orElseThrow(() -> new RuntimeException("Aula no encontrada"));

        List<Map<String, String>> credencialesGeneradas = new ArrayList<>();

        for (int i = 1; i <= cantidad; i++) {
            Usuario alumno = new Usuario();

            String nombreUsuario = generarNombreUsuario(aula.getNombre(), i);
            String passwordPlana = securityService.generarPasswordAleatoria(6);

            alumno.setNombreUsuario(nombreUsuario);
            alumno.setHashContrasena(securityService.hashPassword(passwordPlana));
            alumno.setFechaCreacion(Instant.now());
            alumno.setAula(aula);
            alumno.setRol(TipoRol.ROL_ESTUDIANTE);

            usuarioDAO.save(alumno);

            Map<String, String> credenciales = new HashMap<>();
            credenciales.put("usuario", nombreUsuario);
            credenciales.put("password", passwordPlana);
            credencialesGeneradas.add(credenciales);
        }

        return credencialesGeneradas;
    }

    private String generarNombreUsuario(String nombreAula, int numero) {
        String base = nombreAula.replaceAll("\\s+", "").toLowerCase();
        String sufijoUnico = UUID.randomUUID().toString().substring(0, 5);
        return base + "_alumno" + numero + "_" + sufijoUnico;
    }
}
