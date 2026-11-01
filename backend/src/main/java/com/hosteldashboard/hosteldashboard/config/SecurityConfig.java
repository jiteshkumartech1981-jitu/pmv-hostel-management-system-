package com.hosteldashboard.hosteldashboard.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.security.config.Customizer;

@Configuration
public class SecurityConfig {

    private final JwtAuthFilter jwtAuthFilter;

    public SecurityConfig(JwtAuthFilter jwtAuthFilter) {
        this.jwtAuthFilter = jwtAuthFilter;
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
                .csrf(csrf -> csrf.disable())
                .cors(Customizer.withDefaults())
                .sessionManagement(session -> session
                        .sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                        // Public / Mobile App Endpoints
                        .requestMatchers("/api/auth/**").permitAll()
                        .requestMatchers("/api/students", "/api/students/**").permitAll()
                        .requestMatchers("/api/gatepass", "/api/gatepass/**").permitAll()
                        .requestMatchers("/api/scan", "/api/scan/**").permitAll()
                        .requestMatchers("/api/complaints", "/api/complaints/**").permitAll()
                        .requestMatchers("/api/meal-rating", "/api/meal-rating/**").permitAll()
                        .requestMatchers("/api/mess-menu", "/api/mess-menu/**").permitAll()
                        .requestMatchers("/api/mess-timing", "/api/mess-timing/**").permitAll()

                        // Menu and timing updates: restricted to SUPER_ADMIN or MESS_ADMIN
                        .requestMatchers(HttpMethod.POST, "/api/mess-menu/**", "/api/mess-timing/**")
                        .hasAnyRole("SUPER_ADMIN", "MESS_ADMIN")
                        .requestMatchers(HttpMethod.PUT, "/api/mess-menu/**", "/api/mess-timing/**")
                        .hasAnyRole("SUPER_ADMIN", "MESS_ADMIN")

                        .anyRequest().authenticated()
                )
                .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}