package com.cashflip.controller;

import com.cashflip.dto.*;
import com.cashflip.service.AuthService;
import com.cashflip.util.JwtUtils;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;
    private final JwtUtils jwtUtils;
    private final UserDetailsService userDetailsService;

    // Ручной конструктор вместо @RequiredArgsConstructor
    public AuthController(AuthService authService, JwtUtils jwtUtils, UserDetailsService userDetailsService) {
        this.authService = authService;
        this.jwtUtils = jwtUtils;
        this.userDetailsService = userDetailsService;
    }

    @PostMapping("/register")
    public AuthResponse register(@RequestBody RegisterRequest request) {
        System.out.println("Received registration request for: " + request.getEmail());
        try {
            return authService.register(request);
        } catch (Exception e) {
            System.err.println("Error during registration: " + e.getMessage());
            e.printStackTrace();
            throw e;
        }
    }

    @PostMapping("/login")
    public AuthResponse login(@RequestBody LoginRequest request) {
        return authService.login(request);
    }

    @PostMapping("/refresh-token")
    public ResponseEntity<AuthResponse> refreshToken(@RequestHeader("Authorization") String authHeader) {
        // Извлечь текущий токен, проверить и создать новый
        String token = authHeader.substring(7);
        if (jwtUtils.canRefresh(token)) {
            String username = jwtUtils.extractUsername(token);
            UserDetails userDetails = userDetailsService.loadUserByUsername(username);
            String newToken = jwtUtils.generateToken(userDetails);
            return ResponseEntity.ok(new AuthResponse(newToken));
        }
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
    }
}