package br.com.elora.api.security;

import com.google.firebase.FirebaseApp;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.FirebaseToken;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.Map;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import tools.jackson.databind.ObjectMapper;

@Component
public class FirebaseTokenFilter extends OncePerRequestFilter {

    private final FirebaseAuth firebaseAuth;
    private final ObjectMapper objectMapper;

    public FirebaseTokenFilter(FirebaseApp firebaseApp, ObjectMapper objectMapper) {
        this.firebaseAuth = FirebaseAuth.getInstance(firebaseApp);
        this.objectMapper = objectMapper;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return request.getRequestURI().equals("/api/v1/health")
                || request.getRequestURI().equals("/actuator/health");
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {
        String authorization = request.getHeader(HttpHeaders.AUTHORIZATION);
        if (authorization == null || !authorization.startsWith("Bearer ")) {
            unauthorized(response, "Token Firebase ausente");
            return;
        }

        String idToken = authorization.substring(7).trim();
        if (idToken.isEmpty()) {
            unauthorized(response, "Token Firebase ausente");
            return;
        }

        try {
            // O segundo argumento também rejeita sessões explicitamente revogadas.
            FirebaseToken decoded = firebaseAuth.verifyIdToken(idToken, true);
            var authentication = UsernamePasswordAuthenticationToken.authenticated(
                    decoded.getUid(), null, java.util.List.of());
            SecurityContextHolder.getContext().setAuthentication(authentication);
            filterChain.doFilter(request, response);
        } catch (FirebaseAuthException exception) {
            SecurityContextHolder.clearContext();
            unauthorized(response, "Token Firebase inválido ou expirado");
        }
    }

    private void unauthorized(HttpServletResponse response, String message) throws IOException {
        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.setCharacterEncoding("UTF-8");
        objectMapper.writeValue(response.getWriter(), Map.of(
                "status", 401,
                "error", "Não autorizado",
                "message", message
        ));
    }
}

