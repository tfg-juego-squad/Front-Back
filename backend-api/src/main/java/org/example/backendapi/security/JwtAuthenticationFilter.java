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

/**
 * Filtro para interceptar las peticiones y validar el token JWT.
 */
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

        // Validar si la petición trae el token Bearer
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        // Quitar "Bearer " para quedarnos con el token
        jwt = authHeader.substring(7);

        try {
            nombreUsuario = jwtService.extractUsername(jwt);

            if (nombreUsuario != null && SecurityContextHolder.getContext().getAuthentication() == null) {
                // Sacar los datos necesarios del propio token
                String rol = jwtService.extractRol(jwt);
                Long id = jwtService.extractId(jwt);
                
                Long aulaId = null;
                try {
                    Object aulaIdObj = jwtService.extractClaim(jwt, claims -> claims.get("aulaId"));
                    if (aulaIdObj != null) {
                        aulaId = Long.valueOf(aulaIdObj.toString());
                    }
                } catch (Exception ignored) { }

                // Crear el objeto usuario para el contexto de seguridad
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
                    UsernamePasswordAuthenticationToken authToken = new UsernamePasswordAuthenticationToken(
                            usuarioAuth,
                            null,
                            Collections.singletonList(new SimpleGrantedAuthority(rol))
                    );

                    authToken.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                    SecurityContextHolder.getContext().setAuthentication(authToken);
                }
            }
        } catch (Exception e) {
            // Si el token falla, limpiar el contexto
            SecurityContextHolder.clearContext();
        }

        filterChain.doFilter(request, response);
    }
}