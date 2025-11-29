package com.crudguga.backend.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfig {

    @Value("${app.frontend.origin:http://192.168.100.44:5174}")
    private String frontendOrigin;

    @Bean
    public WebMvcConfigurer corsConfigurer() {
        return new WebMvcConfigurer() {
                @Override
                public void addCorsMappings(CorsRegistry registry) {
                // support multiple origins separated by comma in the property
                String[] origins = frontendOrigin == null ? new String[0]
                    : java.util.Arrays.stream(frontendOrigin.split(","))
                        .map(String::trim)
                        .filter(s -> !s.isEmpty())
                        .toArray(String[]::new);

                // API endpoints
                registry.addMapping("/api/**")
                    .allowedOrigins(origins)
                    .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                    .allowedHeaders("*")
                    .allowCredentials(true);

                // Expose actuator endpoints to frontend origins as well
                registry.addMapping("/actuator/**")
                    .allowedOrigins(origins)
                    .allowedMethods("GET", "POST", "OPTIONS")
                    .allowedHeaders("*")
                    .allowCredentials(true);
                }
        };
    }
}