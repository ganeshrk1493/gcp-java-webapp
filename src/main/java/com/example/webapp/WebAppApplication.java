package com.example.webapp;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.Map;

@SpringBootApplication
@RestController
@RequestMapping("/api")
public class WebAppApplication {

    public static void main(String[] args) {
        SpringApplication.run(WebAppApplication.class, args);
    }

    @GetMapping("/status")
    public Map<String, String> getStatus() {
        String serviceName = System.getenv().getOrDefault("K_SERVICE", "local-dev");
        String revision = System.getenv().getOrDefault("K_REVISION", "v1-local");
        return Map.of(
            "status", "UP",
            "service", serviceName,
            "revision", revision,
            "timestamp", Instant.now().toString()
        );
    }
}