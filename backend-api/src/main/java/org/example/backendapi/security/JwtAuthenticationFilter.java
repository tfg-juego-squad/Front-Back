package org.example.backendapi.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.NonNull;
import lombok.RequiredArgsConstructor;
import org.example.backendapi.model.entities.Aula;
import org.example.backendapi.model.entities.TipoRol;
import org.example.backendapi.model.entities.Usuario;
import org.example.backendapi.service.JwtService;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Collections;

@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtService jwtService;

    @Override
    protected void doFilterInternal(
            @NonNull HttpServletRequest request,
            @NonNull HttpServletResponse response,
            @NonNull FilterChain filterChain
    ) throws ServletException, IOException {
        final String authHeader = request.getHeader("Authorization");
        final String jwt;
        final String nombreUsuario;

        // Validación: Si no hay cabecera o no empieza por "Bearer ",
        // pasamos al siguiente filtro. (Dejamos que Spring Security decida luego si bloquea o no).
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        // Extraemos el token limpio (cortamos los primeros 7 caracteres: "Bearer ")
        jwt = authHeader.substring(7);

        try {
            nombreUsuario = jwtService.extractUsername(jwt);

            if (nombreUsuario != null && SecurityContextHolder.getContext().getAuthentication() == null) {
                // Obtenemos el rol directamente del token, sin ir a la BD
                String rol = jwtService.extractRol(jwt);
                Long id = jwtService.extractId(jwt);
                
                // Extraemos el aulaId (si es null no pasa nada)
                Long aulaId = null;
                try {
                    Object aulaIdObj = jwtService.extractClaim(jwt, claims -> claims.get("aulaId"));
                    if (aulaIdObj != null) {
                        aulaId = Long.valueOf(aulaIdObj.toString());
                    }
                } catch (Exception ignored) { }

                // Crear un usuario dummy solo con los datos del token para @AuthenticationPrincipal
                Usuario usuarioAuth = new Usuario();
                usuarioAuth.setId(id);
                usuarioAuth.setNombreUsuario(nombreUsuario);
                usuarioAuth.setRol(TipoRol.valueOf(rol));
                
                if (aulaId != null) {
                    Aula aulaDummy = new Aula();
                    aulaDummy.setId(aulaId);
                    usuarioAuth.setAula(aulaDummy);
                }

                if (jwtService.isTokenValid(jwt, usuarioAuth.getNombreUsuario())) {

                    // Creamos el token de Spring Security
                    UsernamePasswordAuthenticationToken authToken = new UsernamePasswordAuthenticationToken(
                            usuarioAuth,
                            null,
                            Collections.singletonList(new SimpleGrantedAuthority(rol))
                    );

                    // Detalles de la petición HTTP
                    authToken.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));

                    SecurityContextHolder.getContext().setAuthentication(authToken);
                }
            }
        } catch (Exception e) {
            // Si el token expira o es inválido, limpia el contexto
            SecurityContextHolder.clearContext();
        }

        filterChain.doFilter(request, response);
    }
}