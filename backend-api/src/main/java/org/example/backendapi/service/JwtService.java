package org.example.backendapi.service;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.example.backendapi.model.entities.Usuario;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.function.Function;

@Service
public class JwtService {

    // Inyectamos los valores de application.properties
    @Value("${security.jwt.secret-key}")
    private String secretKey;

    @Value("${security.jwt.expiration-time}")
    private long jwtExpiration;

    /**
     * 1. GENERACIÓN DEL TOKEN
     * Aquí fabricamos el token. Metemos datos extra (Claims) como el ID y el Rol
     * para no tener que ir a la base de datos a buscarlos en cada petición.
     */
    public String generateToken(Usuario usuario) {
        Map<String, Object> extraClaims = new HashMap<>();
        extraClaims.put("id", usuario.getId());
        extraClaims.put("rol", usuario.getRol().name()); // Guardamos ROL_PROFESOR o ROL_ESTUDIANTE

        return Jwts.builder()
                .claims(extraClaims)
                .subject(usuario.getNombreUsuario())
                .issuedAt(new Date(System.currentTimeMillis()))
                .expiration(new Date(System.currentTimeMillis() + jwtExpiration))
                .signWith(getSignInKey()) // Firmamos con nuestra clave secreta
                .compact();
    }

    /**
     * 2. EXTRACCIÓN DE DATOS (CLAIMS)
     * Métodos para leer la información dentro del token recibido desde Godot.
     */
    public String extractUsername(String token) {
        return extractClaim(token, Claims::getSubject);
    }

    public <T> T extractClaim(String token, Function<Claims, T> claimsResolver) {
        final Claims claims = extractAllClaims(token);
        return claimsResolver.apply(claims);
    }

    // Este método es el que verifica la firma criptográfica.
    // Si alguien manipuló el token, esto lanzará una excepción (SignatureException).
    private Claims extractAllClaims(String token) {
        return Jwts.parser()
                .verifyWith(getSignInKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    /**
     * 3. VALIDACIÓN DEL TOKEN
     * Comprueba si el token pertenece al usuario y si no ha caducado.
     */
    public boolean isTokenValid(String token, String username) {
        final String tokenUsername = extractUsername(token);
        return (tokenUsername.equals(username)) && !isTokenExpired(token);
    }

    private boolean isTokenExpired(String token) {
        return extractExpiration(token).before(new Date());
    }

    private Date extractExpiration(String token) {
        return extractClaim(token, Claims::getExpiration);
    }

    public Long extractId(String token) {
        return extractClaim(token, claims -> claims.get("id", Long.class));
    }

    public String extractRol(String token) {
        return extractClaim(token, claims -> claims.get("rol", String.class));
    }

    /**
     * 4. GENERACIÓN DE LA CLAVE DE FIRMA
     * Transforma el String del properties en una clave criptográfica real (HMAC-SHA).
     */
    private SecretKey getSignInKey() {
        byte[] keyBytes = secretKey.getBytes(StandardCharsets.UTF_8);
        return Keys.hmacShaKeyFor(keyBytes);
    }
}