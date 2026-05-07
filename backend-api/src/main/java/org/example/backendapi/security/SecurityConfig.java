package org.example.backendapi.security;

import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.List;

/**
 * Configuración principal de Spring Security.
 * Define las reglas de acceso globales, integra el filtro JWT personalizado,
 * y habilita la seguridad a nivel de métodos (como @PreAuthorize).
 */
@Configuration
@EnableWebSecurity
@EnableMethodSecurity // Permite usar @PreAuthorize("hasAuthority('ROL_PROFESOR')") en los Controladores
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthFilter;

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                // Habilitamos CORS usando nuestra configuración personalizada (necesario para que Godot se pueda conectar)
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))
                // Desactivamos CSRF porque nuestra API es Stateless (no usa cookies de sesión, usa tokens JWT)
                .csrf(AbstractHttpConfigurer::disable)
                .authorizeHttpRequests(auth -> auth
                        // Rutas públicas que no requieren token
                        .requestMatchers("/tfg/usuarios/login", "/tfg/usuarios/profesor/alta").permitAll()
                        .requestMatchers("/swagger-ui/**", "/v3/api-docs/**").permitAll()
                        // Cualquier otra ruta exige que el usuario esté autenticado
                        .anyRequest().authenticated()
                )
                // Indicamos que no guarde sesiones en memoria
                .sessionManagement(session -> session
                        .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
                )
                // Colocamos nuestro filtro JWT ANTES del filtro estándar de usuario/contraseña
                .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    /**
     * Configuración de CORS (Cross-Origin Resource Sharing).
     * Permite que aplicaciones alojadas en otros dominios o puertos (ej. el juego en Godot o una web local)
     * puedan hacer peticiones a esta API sin ser bloqueadas por el navegador.
     */
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOriginPatterns(List.of("*")); // Permite peticiones de cualquier origen
        configuration.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(List.of("*"));
        configuration.setAllowCredentials(true);
        
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }
}