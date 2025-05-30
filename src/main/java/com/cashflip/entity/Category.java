package com.cashflip.entity;

import jakarta.persistence.*;

@Entity
public class Category {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    private String name;
    private String icon;
    private String color;
    private Boolean isExpense; // true = расход, false = доход
    
    @ManyToOne
    @JoinColumn(name = "user_id")
    private User user;
    
    // Конструкторы, геттеры, сеттеры и т.д.
    // как в классе Account
}