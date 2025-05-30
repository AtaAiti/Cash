package com.cashflip.backend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.domain.EntityScan;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;

@SpringBootApplication
@ComponentScan(basePackages = {"com.cashflip"})
@EntityScan("com.cashflip.entity")
@EnableJpaRepositories("com.cashflip.repository")
public class CashFlipApplication {

    public static void main(String[] args) {
        SpringApplication.run(CashFlipApplication.class, args);
    }
}
