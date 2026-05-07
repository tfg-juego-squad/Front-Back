package org.example.backendapi.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Configuración de OpenAPI (Swagger) para la documentación de la API.
 * Esta clase genera automáticamente una interfaz web interactiva (Swagger UI)
 * que permite visualizar y probar todos los endpoints del backend.
 * Acceso: http://localhost:8081/swagger-ui/index.html
 */
@Configuration
public class OpenApiConfig {

    /**
     * Define la configuración personalizada de OpenAPI.
     * Configura la información general de la API y el sistema de seguridad JWT
     * para que podamos probar endpoints protegidos desde la propia interfaz de Swagger.
     */
    @Bean
    public OpenAPI customOpenAPI() {
        final String securitySchemeName = "bearerAuth";
        return new OpenAPI()
                // INFORMACIÓN GENERAL: Título, versión y descripción que aparecerán en la web.
                .info(new Info()
                        .title("TFG Juego Pokeducation API")
                        .version("1.0")
                        .description("Documentación de la API para el backend del TFG."))
                // REQUISITO DE SEGURIDAD GLOBAL: Indica que todos los endpoints pueden requerir este esquema.
                .addSecurityItem(new SecurityRequirement()
                        .addList(securitySchemeName))
                // COMPONENTES DE SEGURIDAD: Define CÓMO funciona el candado de seguridad en Swagger.
                .components(new Components()
                        .addSecuritySchemes(securitySchemeName,
                                new SecurityScheme()
                                        .name(securitySchemeName)
                                        // Tipo HTTP para usar cabeceras estándar
                                        .type(SecurityScheme.Type.HTTP)
                                        // Esquema 'bearer': Indica que enviamos un token de "portador"
                                        .scheme("bearer")
                                        // Formato informativo: Le dice al usuario que el token es un JWT
                                        .bearerFormat("JWT")));
    }
}
