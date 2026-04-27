package org.example.backendapi.service;

import jakarta.transaction.Transactional;
import org.example.backendapi.model.dao.IAulaDAO;
import org.example.backendapi.model.dao.IUsuarioDAO;
import org.example.backendapi.model.entities.Aula;
import org.example.backendapi.model.entities.TipoRol;
import org.example.backendapi.model.entities.Usuario;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
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

    public List<Map<String, String>> importarAlumnosCSV(String aulaId, MultipartFile file) throws Exception {
        Aula aula = aulaDAO.findAulaById(aulaId)
                .orElseThrow(() -> new RuntimeException("Aula no encontrada"));

        List<Map<String, String>> credencialesGeneradas = new ArrayList<>();

        try (BufferedReader br = new BufferedReader(new InputStreamReader(file.getInputStream(), StandardCharsets.UTF_8))) {
            String linea;
            boolean primeraLinea = true;

            while ((linea = br.readLine()) != null) {
                if (primeraLinea && linea.toLowerCase().contains("nombre")) {
                    primeraLinea = false;
                } else {
                    primeraLinea = false;

                    String[] datos = linea.split(",");

                    if (datos.length >= 2) {
                        String nombre = datos[0].trim();
                        String apellidos = datos[1].trim();

                        String nombreUsuario = generarNombreUsuarioCSV(nombre, apellidos);
                        String passwordPlana = securityService.generarPasswordAleatoria(6);

                        Usuario alumno = new Usuario();
                        alumno.setNombreUsuario(nombreUsuario);
                        alumno.setHashContrasena(securityService.hashPassword(passwordPlana));
                        alumno.setFechaCreacion(Instant.now());
                        alumno.setAula(aula);
                        alumno.setRol(TipoRol.ROL_ESTUDIANTE);

                        usuarioDAO.save(alumno);

                        Map<String, String> credenciales = new HashMap<>();
                        credenciales.put("alumnoReal", nombre + " " + apellidos);
                        credenciales.put("usuario", nombreUsuario);
                        credenciales.put("password", passwordPlana);
                        credencialesGeneradas.add(credenciales);
                    }
                }
            }
        }
        return credencialesGeneradas;
    }

    private String generarNombreUsuarioCSV(String nombre, String apellidos) {
        String base = (nombre + apellidos).replaceAll("[^a-zA-Z0-9]", "").toLowerCase();

        if (base.length() > 10) base = base.substring(0, 10);

        String sufijoUnico = UUID.randomUUID().toString().substring(0, 4);
        return base + "_" + sufijoUnico;
    }
}
